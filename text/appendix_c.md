# Рекурсивные схемы ★

## Цели главы

**Рекурсивные схемы** (recursion schemes) — техника обобщения рекурсивных вычислений. Один паттерн fold/unfold вместо отдельной рекурсии для списков, деревьев и AST.

- **Мотивация** — повторяющийся паттерн fold/unfold.
- **Fix-point типы** — отделение «формы» данных от рекурсии.
- **Catamorphism** (катаморфизм) — обобщённый fold.
- **Anamorphism** (анаморфизм) — обобщённый unfold.
- **Hylomorphism** (гиломорфизм) — unfold + fold без промежуточной структуры.
- **Paramorphism** (параморфизм) — fold с доступом к исходным подструктурам.
- **Модульная обобщённость** — использование функторного модуля вместо ad-hoc полиморфизма.
- **Сравнение с Haskell** — библиотека `recursion-schemes` и классы типов.
- **Проект** — обработка JSON через рекурсивные схемы.

Никаких внешних библиотек не требуется — всё реализуется с нуля.

## Подготовка проекта

Код этой главы находится в `exercises/appendix_c`. Соберите проект:

```text
$ cd exercises/appendix_c
$ dune build
```

Файл `dune` для библиотеки:

```lisp
(library
 (name chapter22))
```

Внешние зависимости не нужны — мы реализуем все конструкции самостоятельно.

## Мотивация: повторяющийся паттерн fold/unfold

Представьте, что у вас есть несколько структур данных:

```ocaml
(* Список *)
type int_list = Nil | Cons of int * int_list

(* Двоичное дерево *)
type tree = Leaf | Node of tree * int * tree

(* Арифметическое выражение *)
type expr =
  | Lit of int
  | Add of expr * expr
  | Mul of expr * expr
```

Для каждой из них вы пишете функцию свёртки:

```ocaml
(* Свёртка списка *)
let rec fold_list f z = function
  | Nil -> z
  | Cons (x, rest) -> f x (fold_list f z rest)

(* Свёртка дерева *)
let rec fold_tree f_leaf f_node = function
  | Leaf -> f_leaf
  | Node (l, x, r) ->
    f_node (fold_tree f_leaf f_node l) x (fold_tree f_leaf f_node r)

(* Вычисление выражения *)
let rec eval = function
  | Lit n -> n
  | Add (a, b) -> eval a + eval b
  | Mul (a, b) -> eval a * eval b
```

Паттерн один и тот же: рекурсивно обойти структуру, на каждом шаге «свернуть» один уровень. Различается только **форма** данных. Рекурсивные схемы позволяют написать рекурсию **один раз**, а форму данных задавать отдельно.

```admonish tip title="Для Python/TS-разработчиков"
В Python и TypeScript аналогом катаморфизма является `functools.reduce()` / `Array.reduce()`. Но `reduce` работает только со списками. Рекурсивные схемы обобщают эту идею на *любые* рекурсивные структуры: деревья, JSON, AST. Представьте, что у вас есть универсальный `reduce`, который автоматически работает для списков, деревьев и вложенных JSON-объектов — это и есть катаморфизм. Анаморфизм — это обратное: обобщённый `unfold`, как `itertools.count()` или генераторы в Python, но для произвольных структур.
```

Аналогичная ситуация с развёрткой (unfold):

```ocaml
(* Генерация списка 1..n *)
let rec range n =
  if n = 0 then Nil
  else Cons (n, range (n - 1))

(* Генерация сбалансированного дерева *)
let rec balanced_tree depth =
  if depth = 0 then Leaf
  else Node (balanced_tree (depth - 1), depth, balanced_tree (depth - 1))
```

Здесь тоже паттерн общий: из «зерна» (seed) на каждом шаге порождается один уровень структуры. Рекурсивные схемы дают единую абстракцию и для этого.

## Fix-point типы

### Отделение рекурсии от структуры

Ключевая идея — отделить **форму** одного уровня структуры от **рекурсии**. Возьмём список. Обычный рекурсивный тип:

```ocaml
type int_list = Nil | Cons of int * int_list
(*                                  ^^^^^^^^ рекурсивная ссылка *)
```

Заменим рекурсивную ссылку на **параметр типа**:

```ocaml
type 'a list_f =
  | Nil
  | Cons of int * 'a
```

Тип `list_f` описывает **один уровень** списка. Параметр `'a` — это «дырка», куда потом подставится остаток структуры. Сам по себе `list_f` не рекурсивен — это **функтор** (не путать с модульными функторами OCaml). Название «функтор» здесь используется в категорно-теоретическом смысле: тип с одним параметром, для которого определена операция `map`.

Определим `map` для `list_f`:

```ocaml
let map_list_f (f : 'a -> 'b) : 'a list_f -> 'b list_f = function
  | Nil -> Nil
  | Cons (x, rest) -> Cons (x, f rest)
```

Обратите внимание: `map_list_f` применяет функцию `f` только к рекурсивной позиции — к «хвосту» списка. Значение `x` остаётся нетронутым.

Аналогично для дерева:

```ocaml
type 'a tree_f =
  | Leaf
  | Node of 'a * int * 'a

let map_tree_f (f : 'a -> 'b) : 'a tree_f -> 'b tree_f = function
  | Leaf -> Leaf
  | Node (l, x, r) -> Node (f l, x, f r)
```

### Завязка рекурсии

Теперь нужен способ «завязать» рекурсию обратно. Для этого вводится **fix-point тип**:

```ocaml
type 'f fix = Fix of 'f
  constraint 'f = 'a fix -> 'a
```

Но в OCaml нет Higher-Kinded Types, поэтому мы не можем параметризовать `fix` по конструктору типа напрямую. Вместо этого определим fix-point конкретно для каждого функтора:

```ocaml
(* Fix-point для list_f *)
type fix_list = Fix_list of fix_list list_f

(* Fix-point для tree_f *)
type fix_tree = Fix_tree of fix_tree tree_f
```

Развернём `fix_list`. Значение `Fix_list (Cons (1, Fix_list (Cons (2, Fix_list Nil))))` — это список `[1; 2]`. Каждый уровень обёрнут в `Fix_list`, а рекурсивная позиция содержит `fix_list` — самого себя.

Вспомогательные функции для конструирования и деконструирования:

```ocaml
let fix_list (l : fix_list list_f) : fix_list = Fix_list l
let unfix_list (Fix_list l) : fix_list list_f = l

let fix_tree (t : fix_tree tree_f) : fix_tree = Fix_tree t
let unfix_tree (Fix_tree t) : fix_tree tree_f = t
```

Создадим список `[1; 2; 3]` через fix-point:

```text
# let lst =
    Fix_list (Cons (1,
      Fix_list (Cons (2,
        Fix_list (Cons (3,
          Fix_list Nil))))));;
val lst : fix_list = ...
```

Многословно? Да. Но выигрыш — в возможности написать рекурсию **один раз**.

```admonish tip title="Для Python/TS-разработчиков"
Fix-point типы могут показаться абстрактными, но идея проста: отделить «форму» одного уровня данных от рекурсии. В TypeScript это похоже на разницу между `type List<T> = { head: T; tail: List<T> | null }` (рекурсивный тип) и `type ListF<T, R> = { head: T; tail: R } | null` (один уровень, где `R` — «дырка» для рекурсии). Fix-point — это способ «завязать» эту дырку обратно: `type FixList<T> = ListF<T, FixList<T>>`. В Python аналога нет, но концепция используется неявно: `json.loads()` возвращает вложенные `dict` и `list` — каждый уровень имеет одинаковую «форму».
```

## Catamorphism (катаморфизм) — обобщённый fold

### Определение

Катаморфизм — это обобщённая свёртка. Он принимает **алгебру** (функцию, сворачивающую один уровень) и применяет её снизу вверх по всей структуре.

Для списка:

```ocaml
(* Алгебра — функция, сворачивающая один уровень *)
(* 'a list_f -> 'a *)

let rec cata_list (alg : 'a list_f -> 'a) (Fix_list layer) : 'a =
  alg (map_list_f (cata_list alg) layer)
```

Разберём по шагам:

1. `Fix_list layer` — разворачиваем один уровень, получая `fix_list list_f`.
2. `map_list_f (cata_list alg) layer` — рекурсивно применяем `cata_list` ко всем подструктурам. Результат: `'a list_f` — один уровень, где все рекурсивные позиции уже свёрнуты в `'a`.
3. `alg (...)` — применяем алгебру к этому уровню, получая итоговый `'a`.

Для дерева — полностью аналогично:

```ocaml
let rec cata_tree (alg : 'a tree_f -> 'a) (Fix_tree layer) : 'a =
  alg (map_tree_f (cata_tree alg) layer)
```

### Примеры: сумма и длина списка

```ocaml
(* Сумма элементов списка *)
let sum_alg : int list_f -> int = function
  | Nil -> 0
  | Cons (x, acc) -> x + acc

let sum (lst : fix_list) : int = cata_list sum_alg lst
```

```text
# let lst =
    Fix_list (Cons (1,
      Fix_list (Cons (2,
        Fix_list (Cons (3,
          Fix_list Nil))))));;
# sum lst;;
- : int = 6
```

Обратите внимание: `sum_alg` не содержит рекурсии! Рекурсия спрятана в `cata_list`. Алгебра описывает только **один шаг** свёртки:

- `Nil` -> `0` (базовый случай)
- `Cons (x, acc)` -> `x + acc` (здесь `acc` — уже свёрнутый хвост)

Длина списка:

```ocaml
let length_alg : int list_f -> int = function
  | Nil -> 0
  | Cons (_, acc) -> 1 + acc

let length (lst : fix_list) : int = cata_list length_alg lst
```

### Пример: вычисление дерева

```ocaml
(* Сумма значений в дереве *)
let tree_sum_alg : int tree_f -> int = function
  | Leaf -> 0
  | Node (l, x, r) -> l + x + r

let tree_sum (t : fix_tree) : int = cata_tree tree_sum_alg t
```

```text
# let t =
    Fix_tree (Node (
      Fix_tree (Node (Fix_tree Leaf, 1, Fix_tree Leaf)),
      2,
      Fix_tree (Node (Fix_tree Leaf, 3, Fix_tree Leaf))));;
# tree_sum t;;
- : int = 6
```

```ocaml
(* Глубина дерева *)
let depth_alg : int tree_f -> int = function
  | Leaf -> 0
  | Node (l, _, r) -> 1 + max l r

let depth (t : fix_tree) : int = cata_tree depth_alg t
```

## Anamorphism (анаморфизм) — обобщённый unfold

### Определение

Анаморфизм — это обобщённая развёртка. Он принимает **коалгебру** (функцию, разворачивающую одно «зерно» в один уровень структуры) и строит структуру сверху вниз.

Для списка:

```ocaml
(* Коалгебра — функция, из зерна строящая один уровень *)
(* 'a -> 'a list_f *)

let rec ana_list (coalg : 'a -> 'a list_f) (seed : 'a) : fix_list =
  Fix_list (map_list_f (ana_list coalg) (coalg seed))
```

Разберём:

1. `coalg seed` — из зерна `seed` строим один уровень `'a list_f`.
2. `map_list_f (ana_list coalg) (...)` — рекурсивно разворачиваем все подструктуры.
3. `Fix_list (...)` — заворачиваем уровень в fix-point.

Для дерева:

```ocaml
let rec ana_tree (coalg : 'a -> 'a tree_f) (seed : 'a) : fix_tree =
  Fix_tree (map_tree_f (ana_tree coalg) (coalg seed))
```

### Примеры

Генерация списка `[n, n-1, ..., 1]`:

```ocaml
let range_coalg : int -> int list_f = function
  | 0 -> Nil
  | n -> Cons (n, n - 1)

let range (n : int) : fix_list = ana_list range_coalg n
```

```text
# range 3;;
- : fix_list =
  Fix_list (Cons (3,
    Fix_list (Cons (2,
      Fix_list (Cons (1,
        Fix_list Nil))))))
```

Генерация сбалансированного дерева заданной глубины:

```ocaml
let balanced_coalg : int -> int tree_f = function
  | 0 -> Leaf
  | n -> Node (n - 1, n, n - 1)

let balanced (depth : int) : fix_tree = ana_tree balanced_coalg depth
```

```text
# balanced 2;;
- : fix_tree =
  Fix_tree (Node (
    Fix_tree (Node (Fix_tree Leaf, 1, Fix_tree Leaf)),
    2,
    Fix_tree (Node (Fix_tree Leaf, 1, Fix_tree Leaf))))
```

Коалгебра `balanced_coalg` не содержит рекурсии. Она только описывает один шаг: если глубина 0 — лист, иначе — узел с уменьшенной глубиной в обоих поддеревьях.

## Hylomorphism (гиломорфизм) — unfold + fold без промежуточной структуры

### Определение

Гиломорфизм — это композиция анаморфизма и катаморфизма. Сначала разворачиваем зерно в структуру (ana), затем сворачиваем результат (cata). Но ключевое наблюдение: промежуточную структуру можно **не строить**.

```ocaml
let rec hylo_list
    (alg : 'b list_f -> 'b)
    (coalg : 'a -> 'a list_f)
    (seed : 'a) : 'b =
  alg (map_list_f (hylo_list alg coalg) (coalg seed))
```

Сравните с `cata_list` и `ana_list`. Гиломорфизм объединяет обе рекурсии в одну: на каждом шаге коалгебра разворачивает один уровень, а алгебра тут же его сворачивает. Промежуточный `fix_list` нигде не появляется.

Для дерева:

```ocaml
let rec hylo_tree
    (alg : 'b tree_f -> 'b)
    (coalg : 'a -> 'a tree_f)
    (seed : 'a) : 'b =
  alg (map_tree_f (hylo_tree alg coalg) (coalg seed))
```

### Факториал как гиломорфизм

Факториал можно выразить как гиломорфизм над списком: сначала «разворачиваем» число `n` в список `[n, n-1, ..., 1]`, затем «сворачиваем» его произведением.

```ocaml
(* Коалгебра: разворачиваем число в список *)
let fact_coalg : int -> int list_f = function
  | 0 -> Nil
  | n -> Cons (n, n - 1)

(* Алгебра: сворачиваем список произведением *)
let fact_alg : int list_f -> int = function
  | Nil -> 1
  | Cons (x, acc) -> x * acc

let factorial (n : int) : int =
  hylo_list fact_alg fact_coalg n
```

```text
# factorial 5;;
- : int = 120
```

Промежуточный список `[5; 4; 3; 2; 1]` никогда не строится в памяти — каждый элемент порождается коалгеброй и тут же потребляется алгеброй.

## Paramorphism (параморфизм) — fold с доступом к исходной структуре

Катаморфизм передаёт в алгебру только **результаты** рекурсивной обработки подструктур. Иногда этого недостаточно — нужен доступ к **исходным** подструктурам.

Параморфизм решает эту проблему. Его алгебра получает пару: результат свёртки подструктуры **и** саму подструктуру.

```ocaml
let rec para_list
    (alg : (fix_list * 'a) list_f -> 'a)
    (Fix_list layer) : 'a =
  let mapped = map_list_f
    (fun sub -> (sub, para_list alg sub))
    layer
  in
  alg mapped
```

Разберём:

1. `Fix_list layer` — разворачиваем один уровень.
2. Для каждой рекурсивной позиции формируем пару `(sub, para_list alg sub)`:
   - `sub` — исходная подструктура (неизменённая).
   - `para_list alg sub` — результат рекурсивной свёртки.
3. `alg mapped` — алгебра получает уровень, где в каждой рекурсивной позиции стоит пара.

Обратите внимание на типы. Если обычная алгебра катаморфизма имеет тип `'a list_f -> 'a`, то алгебра параморфизма — `(fix_list * 'a) list_f -> 'a`. Тип `(fix_list * 'a) list_f` — это:

- `Nil` — без изменений.
- `Cons of int * (fix_list * 'a)` — элемент и пара (исходный хвост, свёрнутый хвост).

### Пример: tails

Классический пример — функция `tails`, которая возвращает все суффиксы списка:

```ocaml
(* tails [1; 2; 3] = [[1; 2; 3]; [2; 3]; [3]; []] *)

let tails_alg : (fix_list * fix_list list) list_f -> fix_list list = function
  | Nil -> [Fix_list Nil]
  | Cons (_, (original_tail, tails_of_tail)) ->
    (* Восстанавливаем текущий список: Cons (x, original_tail) *)
    (* Но нам не нужен x для восстановления — мы берём original_tail *)
    (* и добавляем его перед tails_of_tail *)
    original_tail :: tails_of_tail

(* Примечание: полный tails включает и сам исходный список, *)
(* поэтому результат нужно обернуть вручную *)
```

В катаморфизме `original_tail` был бы недоступен — мы видели бы только `tails_of_tail`. Параморфизм даёт и то, и другое.

Для дерева параморфизм аналогичен:

```ocaml
let rec para_tree
    (alg : (fix_tree * 'a) tree_f -> 'a)
    (Fix_tree layer) : 'a =
  let mapped = map_tree_f
    (fun sub -> (sub, para_tree alg sub))
    layer
  in
  alg mapped
```

## Обобщение через модульный Functor

До сих пор мы писали `cata_list`, `cata_tree`, `ana_list`, `ana_tree` — отдельные функции для каждого типа данных. Они отличаются только вызовом `map`. В Haskell эта проблема решается через класс типов `Functor`. В OCaml мы используем **модульную систему**.

Определим сигнатуру модульного функтора (в категорно-теоретическом смысле):

```ocaml
module type FUNCTOR = sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end
```

И сигнатуру fix-point:

```ocaml
module type FIX = sig
  type 'a f
  type fix = Fix of fix f
  val fix : fix f -> fix
  val unfix : fix -> fix f
end
```

Теперь напишем модуль рекурсивных схем, параметризованный по функтору:

```ocaml
module MakeSchemes (F : sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end) = struct
  type fix = Fix of fix F.t

  let fix (layer : fix F.t) : fix = Fix layer
  let unfix (Fix layer) : fix F.t = layer

  let rec cata (alg : 'a F.t -> 'a) (Fix layer : fix) : 'a =
    alg (F.map (cata alg) layer)

  let rec ana (coalg : 'a -> 'a F.t) (seed : 'a) : fix =
    Fix (F.map (ana coalg) (coalg seed))

  let rec hylo (alg : 'b F.t -> 'b) (coalg : 'a -> 'a F.t) (seed : 'a) : 'b =
    alg (F.map (hylo alg coalg) (coalg seed))

  let rec para (alg : (fix * 'a) F.t -> 'a) (Fix layer : fix) : 'a =
    let mapped = F.map (fun sub -> (sub, para alg sub)) layer in
    alg mapped
end
```

Использование:

```ocaml
module ListF = struct
  type 'a t = Nil | Cons of int * 'a
  let map f = function
    | Nil -> Nil
    | Cons (x, rest) -> Cons (x, f rest)
end

module ListSchemes = MakeSchemes (ListF)
open ListSchemes

(* Теперь cata, ana, hylo, para работают для списков *)
let sum =
  cata (function
    | ListF.Nil -> 0
    | ListF.Cons (x, acc) -> x + acc)

let range n =
  ana (function
    | 0 -> ListF.Nil
    | n -> ListF.Cons (n, n - 1)) n
```

Аналогично для деревьев:

```ocaml
module TreeF = struct
  type 'a t = Leaf | Node of 'a * int * 'a
  let map f = function
    | Leaf -> Leaf
    | Node (l, x, r) -> Node (f l, x, f r)
end

module TreeSchemes = MakeSchemes (TreeF)

let depth =
  TreeSchemes.cata (function
    | TreeF.Leaf -> 0
    | TreeF.Node (l, _, r) -> 1 + max l r)
```

Один и тот же `MakeSchemes` работает для любого функтора. Рекурсия написана ровно один раз.

## Сравнение с Haskell (recursion-schemes library)

В Haskell рекурсивные схемы реализованы в библиотеке [recursion-schemes](https://hackage.haskell.org/package/recursion-schemes) (Эдвард Кметт). Ключевые отличия от нашего подхода в OCaml:

### Haskell: классы типов

```haskell
-- Haskell: Fix определён обобщённо
newtype Fix f = Fix { unFix :: f (Fix f) }

-- cata работает для любого Functor
cata :: Functor f => (f a -> a) -> Fix f -> a
cata alg = alg . fmap (cata alg) . unFix
```

В Haskell `Fix` параметризован по конструктору типа `f` (Higher-Kinded Type). Функция `cata` использует класс типов `Functor` для вызова `fmap`. Один и тот же `cata` работает для всех функторов автоматически.

### OCaml: модули

```ocaml
(* OCaml: Fix определяется через модульный функтор *)
module MakeSchemes (F : sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end) = struct
  type fix = Fix of fix F.t
  let rec cata alg (Fix layer) = alg (F.map (cata alg) layer)
  (* ... *)
end
```

В OCaml нет Higher-Kinded Types, поэтому `Fix` нельзя определить обобщённо на уровне типов. Вместо этого мы используем модульный функтор `MakeSchemes`, который генерирует `fix`, `cata`, `ana` и так далее для каждого конкретного функтора.

### Таблица сравнения

| Аспект | Haskell (`recursion-schemes`) | OCaml (наш подход) |
|--------|-------------------------------|---------------------|
| Абстракция | Класс типов `Functor` | Модуль с сигнатурой `FUNCTOR` |
| Fix-point | `newtype Fix f = Fix (f (Fix f))` | `type fix = Fix of fix F.t` (в модуле) |
| HKT | Да (Kind `* -> *`) | Нет — эмулируется через функторы |
| Обобщённый cata | Одна функция для всех Functor | Один `MakeSchemes` для всех модулей |
| Deriving | `deriving Functor` автогенерирует `fmap` | `map` пишется вручную |
| Дополнительные схемы | histo, futu, chrono, zygo, ... | Реализуются аналогично |
| Ergonomics | `cata alg tree` — один вызов | `TreeSchemes.cata alg tree` — через модуль |

### Base functor

В Haskell `recursion-schemes` использует семейство типов `Base` для автоматического вычисления функтора из рекурсивного типа:

```haskell
type family Base t :: * -> *
type instance Base [a] = ListF a
type instance Base (Tree a) = TreeF a
```

В OCaml аналога нет — функтор задаётся явно при создании модуля через `MakeSchemes`.

```admonish info title="Real World OCaml"
Подробнее о функторах (модульных), которые используются для обобщения рекурсивных схем, — в главе [Functors](https://dev.realworldocaml.org/functors.html) книги Real World OCaml. Понимание модульной системы OCaml необходимо для эффективного использования `MakeSchemes` и подобных конструкций.
```

## Проект: обработка JSON через рекурсивные схемы

Применим рекурсивные схемы к практической задаче — работе с JSON. JSON — рекурсивная структура данных, идеально подходящая для этой техники.

### JSON как функтор

Определим один уровень JSON-структуры:

```ocaml
type 'a json_f =
  | JNull
  | JBool of bool
  | JNumber of float
  | JString of string
  | JArray of 'a list
  | JObject of (string * 'a) list

let map_json_f (f : 'a -> 'b) : 'a json_f -> 'b json_f = function
  | JNull -> JNull
  | JBool b -> JBool b
  | JNumber n -> JNumber n
  | JString s -> JString s
  | JArray items -> JArray (List.map f items)
  | JObject fields -> JObject (List.map (fun (k, v) -> (k, f v)) fields)
```

Обратите внимание: `JArray` и `JObject` содержат **списки** рекурсивных позиций. Функция `map_json_f` применяет `f` к каждой из них.

### Fix-point для JSON

```ocaml
module JsonF = struct
  type 'a t = 'a json_f
  let map = map_json_f
end

module JsonSchemes = MakeSchemes (JsonF)

type json = JsonSchemes.fix
```

Теперь `json` — это fix-point JSON, и мы можем использовать `cata`, `ana`, `hylo`, `para` через `JsonSchemes`.

### Конструкторы для удобства

```ocaml
let jnull = JsonSchemes.fix JNull
let jbool b = JsonSchemes.fix (JBool b)
let jnumber n = JsonSchemes.fix (JNumber n)
let jstring s = JsonSchemes.fix (JString s)
let jarray items = JsonSchemes.fix (JArray items)
let jobject fields = JsonSchemes.fix (JObject fields)
```

Пример:

```ocaml
let example_json =
  jobject [
    ("name", jstring "OCaml");
    ("version", jnumber 5.0);
    ("is_fun", jbool true);
    ("features", jarray [
      jstring "modules";
      jstring "pattern matching";
      jstring "effects"
    ]);
    ("metadata", jnull)
  ]
```

### Pretty-printer через cata

```ocaml
let pretty_print (json : json) : string =
  let indent n s =
    let pad = String.make (n * 2) ' ' in
    pad ^ s
  in
  (* Мы используем cata, но нам нужен уровень отступа.
     Решение: алгебра возвращает функцию int -> string *)
  let alg : (int -> string) json_f -> (int -> string) = function
    | JNull -> fun _ -> "null"
    | JBool b -> fun _ -> string_of_bool b
    | JNumber n -> fun _ ->
      if Float.is_integer n then string_of_int (int_of_float n)
      else string_of_float n
    | JString s -> fun _ -> Printf.sprintf "\"%s\"" s
    | JArray items -> fun depth ->
      if items = [] then "[]"
      else
        let inner = List.map (fun f -> indent (depth + 1) (f (depth + 1))) items in
        "[\n" ^ String.concat ",\n" inner ^ "\n" ^ indent depth "]"
    | JObject fields -> fun depth ->
      if fields = [] then "{}"
      else
        let inner = List.map (fun (k, f) ->
          indent (depth + 1) (Printf.sprintf "\"%s\": %s" k (f (depth + 1)))
        ) fields in
        "{\n" ^ String.concat ",\n" inner ^ "\n" ^ indent depth "}"
  in
  (JsonSchemes.cata alg json) 0
```

```text
# print_string (pretty_print example_json);;
{
  "name": "OCaml",
  "version": 5,
  "is_fun": true,
  "features": [
    "modules",
    "pattern matching",
    "effects"
  ],
  "metadata": null
}
```

### Глубина JSON через cata

```ocaml
let json_depth (json : json) : int =
  let alg : int json_f -> int = function
    | JNull | JBool _ | JNumber _ | JString _ -> 0
    | JArray items ->
      1 + (List.fold_left max 0 items)
    | JObject fields ->
      1 + (List.fold_left (fun acc (_, d) -> max acc d) 0 fields)
  in
  JsonSchemes.cata alg json
```

### Генерация JSON через ana

Допустим, мы хотим сгенерировать JSON-схему — объект с описанием типов:

```ocaml
type schema =
  | SNull
  | SBool
  | SNumber
  | SString
  | SArray of schema
  | SObject of (string * schema) list

let schema_to_json (s : schema) : json =
  let coalg : schema -> schema json_f = function
    | SNull -> JString "null"
    | SBool -> JString "boolean"
    | SNumber -> JString "number"
    | SString -> JString "string"
    | SArray inner ->
      JObject [("type", SString); ("items", inner)]
    | SObject fields ->
      JObject (("type", SString) :: List.map (fun (k, v) -> (k, v)) fields)
  in
  JsonSchemes.ana coalg s
```

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

Во всех упражнениях используйте типы и функции из `Chapter22.Schemes`.

1. **(Среднее)** Реализуйте `cata_tree` для дерева (`tree_f`) и используйте его для вычисления **глубины** (`tree_depth`) и **количества узлов** (`tree_size`).

    ```ocaml
    val cata_tree : ('a tree_f -> 'a) -> fix_tree -> 'a
    val tree_depth : fix_tree -> int
    val tree_size : fix_tree -> int
    ```

    Глубина листа — 0, глубина узла — `1 + max (глубина левого) (глубина правого)`.
    Размер листа — 0, размер узла — `1 + размер_левого + размер_правого`.

    *Подсказка:* `cata_tree` разворачивает один уровень через `unfix_tree`, применяет `map_tree_f` для рекурсивного прохода и вызывает алгебру.

2. **(Среднее)** Реализуйте `ana_tree` и используйте его для генерации **сбалансированного дерева** заданной глубины (`gen_balanced`).

    ```ocaml
    val ana_tree : ('a -> 'a tree_f) -> 'a -> fix_tree
    val gen_balanced : int -> fix_tree
    ```

    `gen_balanced 0` — `Leaf`. `gen_balanced n` — `Node` с поддеревьями глубины `n - 1` и значением `n` в узле.

    *Подсказка:* коалгебра — функция `int -> int tree_f`.

3. **(Среднее)** Реализуйте `hylo_list` и используйте его для **сортировки слиянием** (`merge_sort`).

    ```ocaml
    val hylo_list : ('b list_f -> 'b) -> ('a -> 'a list_f) -> 'a -> 'b
    val merge_sort : int list -> int list
    ```

    Идея: разворачиваем список в список (пошагово берём минимальный элемент — selection sort как unfold), затем сворачиваем в результат. Коалгебра: если список пуст — `Nil`, иначе — `Cons (минимальный_элемент, список_без_минимума)`. Алгебра: `Nil` -> `[]`, `Cons (x, sorted)` -> `x :: sorted`.

    *Подсказка:* для нахождения и удаления минимума напишите вспомогательную функцию `extract_min : int list -> (int * int list) option`.

4. **(Сложное)** Реализуйте `para_list` (параморфизм) и используйте его для вычисления **всех суффиксов** списка (`tails`).

    ```ocaml
    val para_list : ((fix_list * 'a) list_f -> 'a) -> fix_list -> 'a
    val tails : fix_list -> fix_list list
    ```

    `tails (Fix_list (Cons (1, Fix_list (Cons (2, Fix_list Nil)))))` должен вернуть:

    ```
    [Fix_list (Cons (1, Fix_list (Cons (2, Fix_list Nil))));
     Fix_list (Cons (2, Fix_list Nil));
     Fix_list Nil]
    ```

    Алгебра параморфизма получает `(fix_list * fix_list list) list_f`, где в каждой рекурсивной позиции стоит пара (исходный хвост, уже вычисленные tails хвоста).

    *Подсказка:* для `Cons (_, (original_tail, tails_of_tail))` — текущий суффикс можно восстановить через `Fix_list (Cons (x, original_tail))`, но вам понадобится значение `x`. Подумайте, как его получить из `list_f`.

5. **(Сложное)** Реализуйте функцию `replace_nulls`, которая через `cata` заменяет все `JNull` в JSON-структуре на заданное значение по умолчанию.

    ```ocaml
    val replace_nulls : json -> json -> json
    ```

    `replace_nulls default_value json` — возвращает новый JSON, в котором каждый `JNull` заменён на `default_value`. Замена должна быть **рекурсивной** — `JNull` внутри массивов и объектов тоже заменяются.

    *Подсказка:* алгебра катаморфизма имеет тип `json json_f -> json`. Для `JNull` возвращаем `default_value`, для остальных — оборачиваем обратно через `JsonSchemes.fix`.

## Заключение

- Fix-point типы отделяют форму данных от рекурсии.
- Четыре схемы: catamorphism (fold), anamorphism (unfold), hylomorphism (unfold+fold), paramorphism (fold с доступом к подструктурам).
- Функтор `MakeSchemes` обобщает все схемы — рекурсия пишется один раз.
- OCaml использует модули там, где Haskell использует классы типов и HKT.
- Практика: pretty-print, глубина, генерация и трансформация JSON через схемы.

Рекурсивные схемы дают общий словарь: вместо «обходит дерево и собирает результат» — «катаморфизм с такой-то алгеброй».
