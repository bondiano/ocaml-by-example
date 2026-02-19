# Оптимизации в OCaml

## Цели главы

В этой главе мы изучим внутреннее устройство значений в рантайме OCaml и техники оптимизации, позволяющие писать быстрый и экономный по памяти код:

- **Представление значений в памяти** --- immediate vs boxed, структура блока (header word, tag, size).
- **`[@@unboxed]` и `[@@immediate]`** --- аннотации для управления представлением типов.
- **Hash-consing** --- разделение памяти между структурно равными значениями.
- **Flambda** --- оптимизирующий бэкенд компилятора OCaml.
- **Другие техники** --- `Bigarray`, специализация, минимизация аллокаций, замеры производительности.
- **Проект** --- hash-consed AST с замером потребления памяти через `Gc.stat`.

Эта глава будет полезна тем, кто хочет понять, как OCaml работает «под капотом», и научиться осознанно писать производительный код.

## Подготовка проекта

Код этой главы находится в `exercises/chapter20`. Для работы не требуются внешние библиотеки --- мы реализуем всё с нуля, используя только стандартную библиотеку:

```text
$ cd exercises/chapter20
$ dune build
```

Файл `dune` для библиотеки:

```lisp
(library
 (name chapter21))
```

## Представление значений в памяти

Чтобы оптимизировать OCaml-код, нужно понимать, как значения представлены в памяти на уровне рантайма. OCaml использует единое представление `value` --- машинное слово (64 бита на современных платформах), которое может быть либо **immediate** (непосредственным), либо **указателем на блок в куче** (boxed).

### Боксирование (boxing): immediate vs boxed values

**Immediate values** --- значения, которые помещаются прямо в машинное слово без аллокации в куче. В OCaml к ним относятся:

- **`int`** --- целые числа. Используются 63 бита (один бит занят тегом --- об этом ниже).
- **`bool`** --- `false` представлен как `0`, `true` как `1` (с учётом тега).
- **`unit`** --- представлен как `0`.
- **`char`** --- код символа.
- Варианты без данных (константные конструкторы) --- `None`, `[]`, конструкторы перечислений.

Для отличия immediate-значений от указателей на блоки рантайм OCaml использует **младший бит**: у immediate-значений он установлен в `1`, у указателей --- в `0` (указатели всегда выровнены). Поэтому `int` хранит 63 бита, а не 64 --- один бит «украден» для тега.

```ocaml
# Obj.is_int (Obj.repr 42);;
- : bool = true

# Obj.is_int (Obj.repr true);;
- : bool = true

# Obj.is_int (Obj.repr ());;
- : bool = true

# Obj.is_int (Obj.repr 'a');;
- : bool = true
```

**Boxed values** --- значения, для которых в куче выделяется блок памяти. К ним относятся:

- **`float`** --- 64 бита, не помещается в tagged word.
- **Строки** (`string`).
- **Записи** (`record`).
- **Кортежи** (`tuple`).
- **Варианты с данными** (`Some 42`, `x :: xs`).
- **Массивы** (`array`).
- **Ссылки** (`ref`).

```ocaml
# Obj.is_int (Obj.repr 3.14);;
- : bool = false

# Obj.is_int (Obj.repr "hello");;
- : bool = false

# Obj.is_int (Obj.repr (1, 2));;
- : bool = false

# Obj.is_int (Obj.repr (Some 42));;
- : bool = false
```

> **Для хаскеллистов.** В Haskell все значения по умолчанию «заворачиваются» (boxed) и ленивы. В OCaml, напротив, `int`, `bool`, `char` и `unit` --- immediate-значения. Это означает, что арифметика целых чисел и паттерн-матчинг по `bool` в OCaml не требуют обращения к куче --- всё происходит в регистрах. В Haskell аналогичной оптимизацией занимается GHC через unboxed types (`Int#`, `Bool#`) и strictness analysis, но в OCaml это поведение по умолчанию.

### Структура блока (header word, tag, size)

Каждый boxed-объект в куче представлен как **блок** --- непрерывная область памяти, начинающаяся с **заголовочного слова** (header word):

```
+------------------+-------+----------+
|    size (54 бит) | color | tag (8 бит) |
+------------------+-------+----------+
|    field 0                           |
+--------------------------------------+
|    field 1                           |
+--------------------------------------+
|    ...                               |
+--------------------------------------+
```

- **size** (54 бита) --- количество полей (слов) в блоке.
- **color** (2 бита) --- используется сборщиком мусора (GC) для пометки.
- **tag** (8 бит) --- тип блока.

Некоторые важные значения тега:

| Tag | Значение |
|-----|----------|
| 0--245 | Обычные блоки (варианты с данными, записи, кортежи) |
| 246 | Lazy |
| 247 | Closure |
| 248 | Object |
| 249 | Infix |
| 250 | Forward |
| 251 | Abstract |
| 252 | String |
| 253 | Double (float) |
| 254 | Double_array |
| 255 | Custom |

Для вариантных типов tag указывает номер конструктора (среди конструкторов с данными). Записи и кортежи всегда имеют tag = 0.

```ocaml
# Obj.tag (Obj.repr (1, 2, 3));;
- : int = 0

# Obj.size (Obj.repr (1, 2, 3));;
- : int = 3

# Obj.tag (Obj.repr 3.14);;
- : int = 253

# Obj.tag (Obj.repr "hello");;
- : int = 252
```

> **Предупреждение.** Модуль `Obj` --- низкоуровневый и небезопасный. Используйте его только для изучения и отладки, но никогда в продакшн-коде.

```admonish tip title="Для Python/TS-разработчиков"
В Python **все** значения boxed --- даже `int` и `bool` являются объектами в куче с подсчётом ссылок. В JavaScript/TypeScript числа тоже обычно boxed (хотя V8 использует Smi-оптимизацию для малых целых). В OCaml `int`, `bool`, `char` и `unit` --- immediate-значения, которые хранятся прямо в машинном слове без аллокации. Это одна из причин, почему OCaml значительно быстрее Python на числовых задачах --- арифметика происходит в регистрах, без обращений к куче и без нагрузки на сборщик мусора.
```

## [@@unboxed] и [@@immediate]

OCaml предоставляет две аннотации для управления представлением типов на уровне рантайма.

### [@@unboxed]

Аннотация `[@@unboxed]` применяется к типам-обёрткам --- записям или вариантам с ровно одним полем. Она говорит компилятору: «не создавай отдельный блок в куче, храни значение напрямую».

```ocaml
(* Без [@@unboxed] --- каждое значение Meters создаёт блок в куче *)
type meters = Meters of float

(* С [@@unboxed] --- Meters x представлен так же, как просто float *)
type meters_unboxed = Meters_u of float [@@unboxed]
```

Проверим:

```ocaml
# Obj.is_int (Obj.repr (Meters 1.0));;
- : bool = false  (* boxed --- блок-обёртка *)

# Obj.tag (Obj.repr (Meters 1.0));;
- : int = 0  (* обычный блок, содержащий float *)

# Obj.size (Obj.repr (Meters 1.0));;
- : int = 1  (* одно поле *)
```

С `[@@unboxed]` обёртка исчезает --- значение представлено как сам `float`:

```ocaml
# Obj.tag (Obj.repr (Meters_u 1.0));;
- : int = 253  (* Double tag --- это просто float *)
```

То же работает для записей:

```ocaml
type positive_float = { value : float } [@@unboxed]
```

**Когда использовать:**

- Типы-фантомы и newtype-обёртки, где обёртка нужна только для типовой безопасности:

```ocaml
type 'a id = Id of int [@@unboxed]

type user
type post

let user_id : user id = Id 42
let post_id : post id = Id 7
```

- Обёртки для FFI, где нужно контролировать представление.

> **Для хаскеллистов.** `[@@unboxed]` --- аналог `newtype` в Haskell. `newtype Meters = Meters Double` не аллоцирует --- это просто `Double` в рантайме. В OCaml обычный `type meters = Meters of float` аллоцирует блок, и только `[@@unboxed]` убирает эту обёртку.

### [@@immediate]

Аннотация `[@@immediate]` утверждает, что все значения данного типа являются immediate (не требуют аллокации в куче). Это полезно для полиморфного кода, который может использовать более эффективные операции для immediate-типов.

```ocaml
type color = Red | Green | Blue [@@immediate]
```

Компилятор проверит, что все конструкторы `color` действительно не содержат данных. Если какой-то конструктор содержит данные, компиляция завершится ошибкой.

```ocaml
(* Ошибка компиляции: Named of string не immediate *)
(* type bad = Named of string | Anonymous [@@immediate] *)
```

`[@@immediate]` часто используется в библиотеках для типов-перечислений, чтобы гарантировать отсутствие аллокаций при их использовании.

## Hash-Consing

### Идея: структурно равные значения разделяют память

**Hash-consing** --- техника, при которой структурно равные значения представляются одним и тем же объектом в памяти. Вместо того чтобы создавать новое значение каждый раз, мы проверяем: «не существует ли уже такое же значение?» Если существует --- возвращаем его.

Преимущества:

1. **Экономия памяти** --- одинаковые поддеревья хранятся один раз.
2. **Быстрое сравнение на равенство** --- вместо структурного сравнения `O(n)` достаточно сравнить указатели `O(1)`.
3. **Быстрое хеширование** --- хеш вычисляется при создании и хранится в узле.

### Почему OCaml знаменит Hash-Consing (Filliâtre)

Hash-consing особенно популярен в OCaml-сообществе благодаря работам **Jean-Christophe Filliâtre** --- французского учёного, создавшего библиотеку `hashcons` и ряд формально верифицированных структур данных. Его статья *«Type-Safe Modular Hash-Consing»* (2006) стала классической.

Причины, по которым hash-consing хорошо ложится на OCaml:

- **Алгебраические типы данных** --- идеальны для представления деревьев и AST.
- **Модульная система** --- позволяет создавать generic hash-consing через функторы.
- **Сборщик мусора** --- weak-указатели (слабые ссылки) позволяют GC собирать неиспользуемые hash-consed значения.

Hash-consing широко используется в:

- **Символьных вычислениях** --- формальные доказательства, решатели SAT/SMT.
- **Компиляторах** --- представление промежуточных языков (IR).
- **BDD (Binary Decision Diagrams)** --- классический пример hash-consing.

### Реализация с нуля (hash-таблица + smart constructors)

Реализуем hash-consing вручную, используя стандартный `Hashtbl`. Идея проста:

1. Каждому значению присваиваем **уникальный идентификатор** и **хеш**.
2. Храним все созданные значения в **hash-таблице**.
3. При создании нового значения сначала проверяем таблицу.

```ocaml
(** Обёрнутое значение с уникальным id и предвычисленным хешем. *)
type 'a hcons = {
  node : 'a;
  id : int;
  hkey : int;
}
```

Здесь `node` --- само значение, `id` --- уникальный номер, `hkey` --- хеш-код. Благодаря `id` сравнение на равенство --- это просто `a.id = b.id`, то есть `O(1)`.

### Пример: формулы пропозициональной логики

Построим hash-consed представление для формул пропозициональной логики:

```
φ ::= Var(x) | And(φ, φ) | Or(φ, φ) | Not(φ) | True | False
```

Сначала определим тип формулы:

```ocaml
type formula_node =
  | Var of string
  | And of formula * formula
  | Or of formula * formula
  | Not of formula
  | True
  | False
and formula = formula_node hcons
```

Тип `formula` --- это `formula_node hcons`, то есть узел с id и хешем. Обратите внимание на взаимную рекурсию: `formula_node` ссылается на `formula`, а `formula` определён через `formula_node`.

Теперь создадим hash-таблицу и smart-конструкторы:

```ocaml
(** Глобальный счётчик для уникальных id. *)
let next_id = ref 0

(** Hash-таблица для хранения всех созданных формул.
    Ключ --- formula_node, значение --- formula (обёрнутый узел). *)
let formula_table : (formula_node, formula) Hashtbl.t = Hashtbl.create 251

(** Создать или найти hash-consed значение. *)
let hashcons (node : formula_node) : formula =
  match Hashtbl.find_opt formula_table node with
  | Some existing -> existing
  | None ->
    let id = !next_id in
    incr next_id;
    let hkey = Hashtbl.hash node in
    let hc = { node; id; hkey } in
    Hashtbl.add formula_table node hc;
    hc
```

Smart-конструкторы --- единственный способ создания формул:

```ocaml
let mk_var x    = hashcons (Var x)
let mk_and a b  = hashcons (And (a, b))
let mk_or a b   = hashcons (Or (a, b))
let mk_not a    = hashcons (Not a)
let mk_true     = hashcons True
let mk_false    = hashcons False
```

Проверим разделение памяти:

```ocaml
# let p = mk_var "p";;
val p : formula = ...

# let q = mk_var "q";;
val q : formula = ...

# let f1 = mk_and p q;;
val f1 : formula = ...

# let f2 = mk_and p q;;
val f2 : formula = ...

# f1.id = f2.id;;
- : bool = true     (* тот же объект! *)

# f1 == f2;;
- : bool = true     (* физическое равенство *)
```

`f1` и `f2` --- это буквально один и тот же объект в памяти. Оператор `==` проверяет физическое (pointer) равенство, в отличие от `=`, который проверяет структурное равенство.

### Когда использовать

Hash-consing полезен, когда:

- В программе много **структурно одинаковых значений** (деревья с общими поддеревьями).
- Часто выполняется **сравнение на равенство** (hash-consing даёт `O(1)`).
- Нужна **мемоизация** по структуре (хеш уже вычислен).
- Работа с **символьными выражениями** --- формулы, AST, BDD.

Hash-consing **не нужен**, если:

- Значения уникальны (нет повторяющихся поддеревьев).
- Overhead хеш-таблицы превышает экономию памяти.
- Программа не сравнивает значения на равенство.

```admonish tip title="Для Python/TS-разработчиков"
Hash-consing похож на `sys.intern()` в Python для строк или на `String.intern()` в Java: одинаковые значения хранятся в одном экземпляре. В Python интернирование строк применяется автоматически для коротких строк и идентификаторов. В OCaml hash-consing реализуется вручную, но для произвольных структур данных --- не только строк. Это мощная оптимизация для компиляторов, SAT-солверов и символьных вычислений, где одинаковые поддеревья встречаются часто.
```

## Flambda

### Что оптимизирует (inlining, unboxing, specialization)

**Flambda** --- оптимизирующий бэкенд компилятора OCaml, выполняющий агрессивные преобразования промежуточного представления. Стандартный компилятор OCaml генерирует достаточно быстрый код, но Flambda может дать дополнительный прирост от 5% до 30% на вычислительно интенсивных задачах.

Основные оптимизации Flambda:

1. **Inlining (встраивание функций)** --- замена вызова функции её телом. Особенно эффективна для маленьких функций и замыканий.

2. **Unboxing (удаление боксирования)** --- если функция принимает `float` и Flambda может доказать, что значение не «убежит», она хранит его в регистре, а не в куче.

3. **Specialization (специализация)** --- создание специализированных версий полиморфных функций для конкретных типов.

4. **Dead code elimination (удаление мёртвого кода)** --- удаление неиспользуемых вычислений.

5. **Constant propagation (распространение констант)** --- вычисление константных выражений на этапе компиляции.

### Как включить (opam switch)

Flambda --- это **вариант компилятора**, а не флаг. Чтобы его использовать, нужно создать отдельный switch в opam:

```text
$ opam switch create 5.2.0+flambda --packages=ocaml-variants.5.2.0+options,ocaml-option-flambda
$ eval $(opam env)
```

Проверить, что Flambda включена:

```text
$ ocamlopt -config | grep flambda
flambda: true
```

Или из кода:

```ocaml
# Sys.ocaml_release.suffix;;
- : string option = Some "+flambda"
```

### Аннотации [@inline always], [@unrolled]

Flambda учитывает аннотации, помогающие компилятору принимать решения об оптимизациях:

**`[@inline always]`** --- принудительное встраивание функции:

```ocaml
let[@inline always] add x y = x + y
```

**`[@inline never]`** --- запрет встраивания (полезно для отладки):

```ocaml
let[@inline never] expensive_computation x = ...
```

**`[@unrolled n]`** --- развёртка рекурсивной функции на `n` шагов:

```ocaml
let[@unrolled 3] rec sum = function
  | [] -> 0
  | x :: xs -> x + sum xs
```

Это превратит первые 3 итерации в прямой код без вызовов.

**`[@specialise always]`** --- специализация полиморфной функции:

```ocaml
let[@specialise always] map f = function
  | [] -> []
  | x :: xs -> f x :: map f xs
```

> **Для хаскеллистов.** Аннотации Flambda похожи на прагмы GHC: `{-# INLINE #-}`, `{-# SPECIALISE #-}`. Разница в том, что GHC применяет инлайнинг и специализацию гораздо агрессивнее по умолчанию, а в OCaml без Flambda оптимизации минимальны.

## Другие техники

### Bigarray

`Bigarray` --- модуль стандартной библиотеки для работы с массивами, хранящимися вне кучи OCaml. Это полезно для:

- **Числовых вычислений** --- элементы хранятся как обычные C-значения (unboxed float, int32, int64).
- **Взаимодействия с C** --- `Bigarray` можно передавать в C-функции без копирования.
- **Избежания давления на GC** --- GC не сканирует `Bigarray`.

```ocaml
# open Bigarray;;

# let arr = Array1.create float64 c_layout 1000;;
val arr : (float, float64_elt, c_layout) Array1.t = <abstr>

# Array1.set arr 0 3.14;;
- : unit = ()

# Array1.get arr 0;;
- : float = 3.14
```

### Специализация

Полиморфные функции в OCaml работают через uniform representation --- все значения имеют размер одного слова. Это означает, что `Array.map` для `int array` и `float array` использует один и тот же код, но для `float array` каждое обращение к элементу требует boxing/unboxing.

Для числовых вычислений лучше использовать специализированные модули:

```ocaml
(* Вместо полиморфного Array.map *)
let sum_float (arr : float array) =
  let n = Array.length arr in
  let acc = ref 0.0 in
  for i = 0 to n - 1 do
    acc := !acc +. Array.unsafe_get arr i
  done;
  !acc
```

### Минимизация аллокаций

Каждая аллокация в куче --- это работа для сборщика мусора. Несколько приёмов для минимизации:

1. **Используйте `int` вместо `float`, где возможно** --- `int` immediate и не аллоцируется.

2. **Мутабельные записи вместо создания новых** --- вместо `{ r with x = 42 }` иногда лучше `r.x <- 42`.

3. **`Buffer` вместо конкатенации строк** --- `"a" ^ "b" ^ "c"` создаёт промежуточные строки.

4. **Избегайте лишних замыканий** --- каждое замыкание с захваченными переменными аллоцируется.

### Замеры

Для замера производительности используйте модуль `Gc` и системные функции:

```ocaml
(** Замер времени выполнения. *)
let time_it label f =
  let t0 = Sys.time () in
  let result = f () in
  let dt = Sys.time () -. t0 in
  Printf.printf "%s: %.4f сек\n" label dt;
  result

(** Замер аллокаций через Gc.stat. *)
let measure_alloc f =
  Gc.full_major ();
  let before = Gc.stat () in
  let result = f () in
  let after = Gc.stat () in
  let alloc_words =
    after.Gc.minor_words -. before.Gc.minor_words
    +. after.Gc.major_words -. before.Gc.major_words
  in
  Printf.printf "Аллоцировано: %.0f слов (%.0f КБ)\n"
    alloc_words (alloc_words *. 8.0 /. 1024.0);
  result
```

`Gc.stat` возвращает запись с множеством полезных полей:

```ocaml
# let st = Gc.stat ();;
val st : Gc.stat = ...

# st.Gc.minor_words;;
- : float = ...    (* слов аллоцировано в минорной куче *)

# st.Gc.major_words;;
- : float = ...    (* слов аллоцировано в мажорной куче *)

# st.Gc.live_words;;
- : int = ...      (* живых слов в текущий момент *)

# st.Gc.heap_words;;
- : int = ...      (* общий размер кучи в словах *)
```

## Проект: hash-consed AST

Создадим hash-consed AST для арифметических выражений и измерим экономию памяти по сравнению с обычным представлением.

### Обычный AST

```ocaml
(** Обычное (не hash-consed) арифметическое выражение. *)
type expr =
  | Num of int
  | Var of string
  | Add of expr * expr
  | Mul of expr * expr
```

### Hash-consed AST

```ocaml
(** Обёртка hash-consing. *)
type 'a hcons = {
  node : 'a;
  id : int;
  hkey : int;
}

(** Узел hash-consed выражения. *)
type hc_expr_node =
  | HNum of int
  | HVar of string
  | HAdd of hc_expr * hc_expr
  | HMul of hc_expr * hc_expr
and hc_expr = hc_expr_node hcons
```

Smart-конструкторы:

```ocaml
let hc_next_id = ref 0
let hc_table : (hc_expr_node, hc_expr) Hashtbl.t = Hashtbl.create 251

let hc_make (node : hc_expr_node) : hc_expr =
  match Hashtbl.find_opt hc_table node with
  | Some existing -> existing
  | None ->
    let id = !hc_next_id in
    incr hc_next_id;
    let hkey = Hashtbl.hash node in
    let hc = { node; id; hkey } in
    Hashtbl.add hc_table node hc;
    hc

let hc_num n     = hc_make (HNum n)
let hc_var x     = hc_make (HVar x)
let hc_add a b   = hc_make (HAdd (a, b))
let hc_mul a b   = hc_make (HMul (a, b))
```

### Вычисление

```ocaml
(** Вычисление обычного выражения. *)
let rec eval_expr env = function
  | Num n -> n
  | Var x -> (match List.assoc_opt x env with Some v -> v | None -> 0)
  | Add (a, b) -> eval_expr env a + eval_expr env b
  | Mul (a, b) -> eval_expr env a * eval_expr env b

(** Вычисление hash-consed выражения. *)
let rec eval_hc_expr env (e : hc_expr) =
  match e.node with
  | HNum n -> n
  | HVar x -> (match List.assoc_opt x env with Some v -> v | None -> 0)
  | HAdd (a, b) -> eval_hc_expr env a + eval_hc_expr env b
  | HMul (a, b) -> eval_hc_expr env a * eval_hc_expr env b
```

### Замер памяти

Построим выражение с большим количеством разделяемых поддеревьев и сравним потребление памяти:

```ocaml
(** Построение глубокого дерева с разделяемыми поддеревьями.
    f(0) = Var "x"
    f(n) = Add(f(n-1), f(n-1))

    Без hash-consing: 2^n узлов.
    С hash-consing: n+1 узлов.  *)
let rec build_shared_tree n =
  if n = 0 then Num 1
  else
    let sub = build_shared_tree (n - 1) in
    Add (sub, sub)

let rec build_shared_hc n =
  if n = 0 then hc_num 1
  else
    let sub = build_shared_hc (n - 1) in
    hc_add sub sub

let () =
  let n = 20 in

  Gc.full_major ();
  let before = Gc.stat () in
  let _tree = build_shared_tree n in
  Gc.full_major ();
  let after = Gc.stat () in
  Printf.printf "Обычный AST (n=%d): live_words = %d\n"
    n (after.Gc.live_words - before.Gc.live_words);

  Gc.full_major ();
  let before2 = Gc.stat () in
  let _hc_tree = build_shared_hc n in
  Gc.full_major ();
  let after2 = Gc.stat () in
  Printf.printf "Hash-consed AST (n=%d): live_words = %d\n"
    n (after2.Gc.live_words - before2.Gc.live_words)
```

В обычном AST `build_shared_tree 20` создаёт дерево, которое выглядит как 2^20 = ~1 миллион узлов (хотя OCaml физически разделит поддеревья через `let sub = ...`). С hash-consing создаётся ровно 21 уникальный узел --- по одному на каждый уровень.

> **Важная тонкость:** в OCaml `let sub = build_shared_tree (n-1) in Add (sub, sub)` уже создаёт физическое разделение --- оба поля `Add` указывают на один и тот же объект `sub`. Однако без hash-consing **отдельные** вызовы `build_shared_tree` с одинаковым `n` создадут **разные** объекты. Hash-consing гарантирует глобальное разделение.

### Проверка физического равенства

```ocaml
# let a = build_shared_hc 5;;
# let b = build_shared_hc 5;;
# a == b;;
- : bool = true   (* один и тот же объект --- hash-consing *)

# let c = build_shared_tree 5;;
# let d = build_shared_tree 5;;
# c == d;;
- : bool = false   (* разные объекты --- обычный AST *)
# c = d;;
- : bool = true    (* но структурно равны *)
```

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Лёгкое)** Создайте unboxed-тип обёртку `positive_float` с конструктором `Pos` и аннотацией `[@@unboxed]`. Напишите функцию `mk_positive : float -> positive_float option`, которая возвращает `Some (Pos x)`, если `x > 0.0`, и `None` иначе. Также напишите функцию `get_value : positive_float -> float`.

    ```ocaml
    type positive_float = Pos of float [@@unboxed]
    val mk_positive : float -> positive_float option
    val get_value : positive_float -> float
    ```

2. **(Среднее)** Реализуйте hash-consing для бинарных деревьев:

    ```ocaml
    type tree_node = Leaf | Node of hc_tree * hc_tree
    and hc_tree = tree_node hcons
    ```

    Напишите smart-конструкторы `mk_leaf` и `mk_node`, а также функцию `tree_size : hc_tree -> int`, возвращающую количество узлов в дереве (считая каждый уникальный узел один раз --- используйте `id` для отслеживания).

3. **(Среднее)** Добавьте функцию `simplify` к hash-consed AST арифметических выражений. Функция должна упрощать выражения по правилам:

    - `0 + x = x`, `x + 0 = x`
    - `0 * x = 0`, `x * 0 = 0`
    - `1 * x = x`, `x * 1 = x`

    ```ocaml
    val simplify : hc_expr -> hc_expr
    ```

    Результат тоже должен быть hash-consed.

4. **(Среднее)** Напишите функцию `count_unique_nodes : hc_expr -> int`, которая подсчитывает количество уникальных узлов в hash-consed выражении (используя `id` для отслеживания посещённых узлов). Сравните результат с `count_nodes_regular : expr -> int` --- подсчётом всех узлов в обычном AST (считая повторы).

    ```ocaml
    val count_unique_nodes : hc_expr -> int
    val count_nodes_regular : expr -> int
    ```

5. **(Сложное)** Реализуйте hash-consed формулы пропозициональной логики:

    ```ocaml
    type prop_node =
      | PVar of string
      | PAnd of hc_prop * hc_prop
      | POr of hc_prop * hc_prop
      | PNot of hc_prop
      | PTrue
      | PFalse
    and hc_prop = prop_node hcons
    ```

    Напишите:
    - Smart-конструкторы.
    - Функцию `nnf : hc_prop -> hc_prop` --- преобразование в **негативную нормальную форму** (NNF), где отрицания применяются только к переменным.
      - `Not (And (a, b))` -> `Or (Not a, Not b)` (закон Де Моргана)
      - `Not (Or (a, b))` -> `And (Not a, Not b)` (закон Де Моргана)
      - `Not (Not a)` -> `a` (двойное отрицание)
      - `Not True` -> `False`, `Not False` -> `True`
    - Функцию `eval_prop : (string -> bool) -> hc_prop -> bool` --- вычисление формулы при данном назначении переменных.

## Заключение

В этой главе мы:

- Изучили, как OCaml представляет значения в памяти: immediate-значения (int, bool, char, unit) хранятся прямо в машинном слове, а boxed-значения (float, строки, записи, кортежи) --- в блоках в куче.
- Разобрали структуру блока в куче: заголовочное слово с тегом, размером и битами для GC.
- Освоили аннотации `[@@unboxed]` для устранения обёрток и `[@@immediate]` для гарантии immediate-представления.
- Реализовали hash-consing с нуля --- технику разделения памяти между структурно равными значениями, дающую `O(1)` сравнение и экономию памяти.
- Познакомились с Flambda --- оптимизирующим бэкендом OCaml, его аннотациями для управления инлайнингом и специализацией.
- Построили hash-consed AST и измерили разницу в потреблении памяти через `Gc.stat`.

Понимание внутреннего представления значений --- ключ к написанию эффективного OCaml-кода. В большинстве случаев рантайм OCaml достаточно быстр «из коробки», но для числовых вычислений, компиляторов и символьных систем описанные в этой главе техники могут дать значительный прирост производительности.

```admonish info title="Real World OCaml"
Подробнее о внутреннем устройстве рантайма OCaml, сборщике мусора и профилировании --- в главах [Memory Representation of Values](https://dev.realworldocaml.org/runtime-memory-layout.html) и [Understanding the Garbage Collector](https://dev.realworldocaml.org/garbage-collector.html) книги Real World OCaml.
```
