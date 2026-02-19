# Алгебраические типы данных

## Цели главы

В этой главе мы изучим **алгебраические типы данных** (algebraic data types, ADT). Это основной инструмент моделирования данных в OCaml.

Темы главы:

- Вариантные типы (variant types) — типы-суммы.
- Сопоставление с образцом (pattern matching).
- Вложенные паттерны, or-паттерны, as-паттерны.
- Паттерны для списков.
- Проверка полноты (exhaustiveness checking).
- Кортежи (tuples) и деструктуризация.
- Полиморфные варианты (polymorphic variants).
- Типы `option` и `result`.
- Проект: геометрические фигуры.

## Подготовка проекта

Код этой главы находится в `exercises/chapter05`. Основной модуль — `lib/shapes.ml`. Соберите проект:

```text
$ cd exercises/chapter05
$ dune build
```

## Вариантные типы

Вариантный тип (variant type) описывает значение, которое может принимать одну из нескольких форм. Каждая форма обозначается **конструктором** (constructor):

```ocaml
type color = Red | Green | Blue
```

Здесь `color` — тип с тремя конструкторами. Конструкторы начинаются с заглавной буквы.

Конструкторы могут нести данные:

```ocaml
type shape =
  | Circle of float
  | Rectangle of float * float
  | Triangle of float * float * float
```

`Circle of float` означает «круг с радиусом типа `float`». `Rectangle of float * float` — «прямоугольник с шириной и высотой». Символ `*` обозначает кортеж (tuple) — упорядоченную группу значений.

Создание значений:

```text
# Circle 5.0;;
- : shape = Circle 5.

# Rectangle (3.0, 4.0);;
- : shape = Rectangle (3., 4.)

# Triangle (3.0, 4.0, 5.0);;
- : shape = Triangle (3., 4., 5.)
```

Вариантные типы OCaml — аналог `data` в Haskell:

```
Haskell:  data Shape = Circle Double | Rectangle Double Double
OCaml:    type shape = Circle of float | Rectangle of float * float
```

Обратите внимание на различия: в OCaml имена типов пишутся в `snake_case`, а конструкторы — в `PascalCase`. Вместо `Double` используется `float`.

```admonish tip title="Для Python/TS-разработчиков"
Вариантные типы OCaml — это как `Enum` на стероидах. В Python вы бы использовали `@dataclass` с наследованием или `Union[Circle, Rectangle, Triangle]`. В TypeScript — discriminated union: `type Shape = { kind: "circle"; r: number } | { kind: "rect"; w: number; h: number }`. В OCaml то же самое записывается компактнее, а компилятор автоматически проверяет полноту обработки — в Python и TypeScript об этом нужно заботиться самостоятельно.
```

## Сопоставление с образцом

Сопоставление с образцом (pattern matching) — основной способ работы с вариантными типами. Выражение `match ... with` проверяет значение и извлекает данные:

```ocaml
let describe = function
  | Circle r -> "Круг с радиусом " ^ string_of_float r
  | Rectangle (w, h) ->
    "Прямоугольник " ^ string_of_float w ^ "x" ^ string_of_float h
  | Triangle (a, b, c) ->
    "Треугольник со сторонами " ^ string_of_float a
    ^ ", " ^ string_of_float b ^ ", " ^ string_of_float c
```

Функция возвращает `string`. Здесь `function` — сокращение для `fun x -> match x with`. Каждая ветка паттерна начинается с `|`. Переменные `r`, `w`, `h`, `a`, `b`, `c` привязываются к значениям внутри конструкторов.

```admonish tip title="Для Python/TS-разработчиков"
Pattern matching в OCaml — аналог `match/case` в Python 3.10+ (PEP 634) и предложения `pattern matching` в TC39 для JavaScript. Но в OCaml он значительно мощнее: поддерживает вложенные паттерны, деструктуризацию и проверку полноты на этапе компиляции. В Python `match` — это `switch` с паттернами; в OCaml — основной инструмент анализа данных.
```

Равнозначная запись с `match`:

```ocaml
let describe s =
  match s with
  | Circle r -> "Круг с радиусом " ^ string_of_float r
  | Rectangle (w, h) ->
    "Прямоугольник " ^ string_of_float w ^ "x" ^ string_of_float h
  | Triangle (a, b, c) ->
    "Треугольник со сторонами " ^ string_of_float a
    ^ ", " ^ string_of_float b ^ ", " ^ string_of_float c
```

### Паттерны для литералов

Сопоставление работает не только с вариантами, но и с литералами:

```ocaml
let is_zero = function
  | 0 -> true
  | _ -> false

let describe_bool = function
  | true -> "да"
  | false -> "нет"
```

`is_zero 0` вернёт `true`, для любого другого числа — `false`. `describe_bool` перечисляет все возможные значения `bool` явно, поэтому ветка `_` здесь не нужна. Символ `_` (подчёркивание) — подстановочный паттерн (wildcard), который совпадает с любым значением и не привязывает его к переменной.

### Вложенные паттерны

Паттерны можно вкладывать друг в друга:

```ocaml
type point = { x : float; y : float }

type located_shape =
  | Located of point * shape

let is_at_origin = function
  | Located ({ x = 0.0; y = 0.0 }, _) -> true
  | _ -> false
```

Здесь мы сопоставляем с конструктором `Located`, внутри которого проверяем запись `point` на равенство координат нулю. Второй элемент пары (фигура) нам не важен — он совпадает с `_`. Функция имеет тип `located_shape -> bool`.

### Or-паттерны

Or-паттерн `|` позволяет объединить несколько вариантов в одну ветку:

```ocaml
type day = Mon | Tue | Wed | Thu | Fri | Sat | Sun

let is_weekend = function
  | Sat | Sun -> true
  | Mon | Tue | Wed | Thu | Fri -> false
```

Or-паттерн удобен, когда несколько конструкторов должны обрабатываться одинаково. Важное ограничение: все ветки or-паттерна должны привязывать одинаковые переменные.

### As-паттерны

As-паттерн `as` привязывает значение к переменной, одновременно сопоставляя с образцом:

```ocaml
let first_if_positive = function
  | (x :: _) as lst when x > 0 -> Some lst
  | _ -> None
```

Функция возвращает `Some lst`, если первый элемент положителен — именно весь список, а не только первый элемент. Тип: `int list -> int list option`. Здесь `(x :: _) as lst` совпадает с непустым списком, привязывая первый элемент к `x`, а весь список к `lst`.

### Паттерны для списков

Списки в OCaml — это вариантный тип с двумя конструкторами: `[]` (пустой список) и `::` (cons — элемент + хвост). Поэтому с ними работает сопоставление:

```ocaml
let head_or_default default = function
  | [] -> default
  | x :: _ -> x

let rec length = function
  | [] -> 0
  | _ :: rest -> 1 + length rest
```

`head_or_default` безопасно возвращает первый элемент или значение по умолчанию — без исключений. В `length` базовый случай — пустой список (длина 0), рекурсивный — «один плюс длина хвоста». Например, `length [1; 2; 3]` = `1 + length [2; 3]` = `1 + 1 + length [3]` = `1 + 1 + 1 + length []` = `3`.

Можно сопоставлять с конкретным количеством элементов:

```ocaml
let describe_list = function
  | [] -> "пустой"
  | [_] -> "один элемент"
  | [_; _] -> "два элемента"
  | _ -> "три или более"
```

Паттерн `[x; y]` эквивалентен `x :: y :: []`.

## Проверка полноты

Компилятор OCaml проверяет, покрывает ли сопоставление **все** возможные случаи. Если нет — выдаёт предупреждение:

```ocaml
let area = function
  | Circle r -> Float.pi *. r *. r
  | Rectangle (w, h) -> w *. h
  (* Triangle не обработан — предупреждение! *)
```

```text
Warning 8: this pattern-matching is not exhaustive.
Here is an example of a case that is not matched:
Triangle (_, _, _)
```

Это одна из самых ценных особенностей OCaml: если вы добавите новый конструктор в тип, компилятор покажет **все** места, где нужно обработать новый случай.

Не подавляйте это предупреждение добавлением `| _ -> ...`, если вы не уверены, что обработали все значимые случаи. Подстановочный паттерн `_` скрывает от компилятора будущие конструкторы.

```admonish tip title="Для TypeScript-разработчиков"
Проверка полноты в OCaml — аналог `exhaustive checking` в TypeScript с `never`. В TS вы бы написали `const _exhaustive: never = shape` в `default`-ветке `switch`, чтобы компилятор ругался при добавлении нового варианта. В OCaml это встроено: компилятор автоматически проверяет каждый `match` и предупреждает о пропущенных случаях. Не нужен `never`-хак — язык делает это сам.
```

### Guard-выражения

Иногда паттернов недостаточно и нужна дополнительная проверка. Для этого используется `when`:

```ocaml
let classify_number = function
  | n when n < 0 -> "отрицательное"
  | 0 -> "ноль"
  | n when n mod 2 = 0 -> "положительное чётное"
  | _ -> "положительное нечётное"
```

Ветки проверяются сверху вниз: сначала проверяется условие `n < 0`, затем литерал `0`, затем условие чётности. Финальная ветка `_` ловит все оставшиеся случаи (положительные нечётные числа). Guard `when` добавляет произвольное условие к ветке. Обратите внимание: компилятор не может проверить полноту guard-выражений, поэтому обычно нужна финальная ветка с `_`.

## Кортежи

Кортеж (tuple) — упорядоченная группа значений фиксированной длины. В отличие от записей, элементы кортежа не имеют имён:

```text
# (1, "hello");;
- : int * string = (1, "hello")

# (true, 3.14, 'a');;
- : bool * float * char = (true, 3.14, 'a')
```

Тип кортежа записывается через `*`: `int * string`, `bool * float * char`.

### Деструктуризация кортежей

Кортежи разбираются через сопоставление с образцом или через `let`:

```text
# let (a, b) = (1, 2);;
val a : int = 1
val b : int = 2

# let swap (x, y) = (y, x);;
val swap : 'a * 'b -> 'b * 'a = <fun>

# swap (1, "hello");;
- : string * int = ("hello", 1)
```

Для пар есть стандартные функции `fst` и `snd`:

```text
# fst (1, "hello");;
- : int = 1

# snd (1, "hello");;
- : string = "hello"
```

Кортежи часто используются для возврата нескольких значений из функции:

```ocaml
let min_max lst =
  let mn = List.fold_left min max_int lst in
  let mx = List.fold_left max min_int lst in
  (mn, mx)
```

Начальные значения свёртки — `max_int` для минимума и `min_int` для максимума: любой элемент списка будет «лучше» стартового значения, поэтому результат после прохода по всему списку окажется верным. Функция возвращает пару `(минимум, максимум)`.

## Типы-записи vs кортежи

Когда использовать записи, а когда кортежи?

- **Записи** — когда полей больше двух или их назначение не очевидно из контекста. Имена полей служат документацией.
- **Кортежи** — для коротких группировок (пары, тройки), где назначение элементов очевидно: `(x, y)`, `(key, value)`, `(min, max)`.

## Рекурсивные типы

Вариантные типы могут ссылаться на себя — это рекурсивные типы. Классический пример — двоичное дерево:

```ocaml
type 'a tree =
  | Leaf
  | Node of 'a tree * 'a * 'a tree
```

`'a` — параметр типа (type parameter), аналог `a` в `data Tree a = ...` Haskell. Деревья строятся так:

```text
# Leaf;;
- : 'a tree = Leaf

# Node (Leaf, 42, Leaf);;
- : int tree = Node (Leaf, 42, Leaf)

# Node (Node (Leaf, 1, Leaf), 2, Node (Leaf, 3, Leaf));;
- : int tree = Node (Node (Leaf, 1, Leaf), 2, Node (Leaf, 3, Leaf))
```

Функции над рекурсивными типами сами рекурсивны:

```ocaml
let rec tree_size = function
  | Leaf -> 0
  | Node (left, _, right) -> 1 + tree_size left + tree_size right

let rec tree_depth = function
  | Leaf -> 0
  | Node (left, _, right) -> 1 + max (tree_depth left) (tree_depth right)
```

В обеих функциях базовый случай — `Leaf` (возвращает 0), рекурсивный — `Node`, где мы обходим оба поддерева. `tree_size` считает количество узлов, значение `_` (хранимые данные) игнорирует. `tree_depth` берёт максимум глубин левого и правого поддеревьев — это и есть глубина дерева.

## Тип `option`

Мы уже видели `option` в предыдущей главе. Теперь, зная вариантные типы, рассмотрим его определение:

```ocaml
type 'a option = None | Some of 'a
```

Это обычный вариантный тип с двумя конструкторами. `None` означает отсутствие значения, `Some x` — наличие. Работа с `option` через сопоставление:

```ocaml
let greet name =
  match name with
  | Some n -> "Привет, " ^ n ^ "!"
  | None -> "Привет, незнакомец!"
```

### Функции модуля `Option`

Стандартная библиотека предоставляет модуль `Option` с полезными функциями:

```text
# Option.map (fun x -> x * 2) (Some 5);;
- : int option = Some 10

# Option.map (fun x -> x * 2) None;;
- : int option = None

# Option.value ~default:0 (Some 42);;
- : int = 42

# Option.value ~default:0 None;;
- : int = 0

# Option.bind (Some 5) (fun x -> if x > 0 then Some (x * 2) else None);;
- : int option = Some 10

# Option.is_some (Some 1);;
- : bool = true

# Option.is_none None;;
- : bool = true
```

- `Option.map f opt` — применяет `f` к значению внутри `Some`, оставляет `None` как есть.
- `Option.value ~default opt` — извлекает значение из `Some` или возвращает `default`.
- `Option.bind opt f` — применяет функцию, которая сама возвращает `option` (цепочка вычислений).
- `Option.is_some`, `Option.is_none` — проверки.

## Тип `result`

Тип `result` — обобщение `option`, которое несёт информацию об ошибке:

```ocaml
type ('a, 'b) result = Ok of 'a | Error of 'b
```

`Ok x` — успешный результат. `Error e` — ошибка с описанием. В Haskell аналог — `Either`:

```
Haskell:  Either e a = Left e | Right a
OCaml:    ('a, 'e) result = Ok of 'a | Error of 'e
```

Пример — безопасное деление:

```ocaml
let safe_div a b =
  if b = 0 then Error "деление на ноль"
  else Ok (a / b)
```

```text
# safe_div 10 3;;
- : (int, string) result = Ok 3

# safe_div 10 0;;
- : (int, string) result = Error "деление на ноль"
```

Работа с `result` через сопоставление:

```ocaml
let show_result = function
  | Ok x -> "Результат: " ^ string_of_int x
  | Error msg -> "Ошибка: " ^ msg
```

Модуль `Result` предоставляет функции `Result.map`, `Result.bind`, `Result.is_ok`, `Result.is_error` — аналогично модулю `Option`. Подробно мы рассмотрим `result` в главе 8.

```admonish info title="Подробнее"
Глубокое погружение в вариантные типы и pattern matching: [Real World OCaml, глава «Variants»](https://dev.realworldocaml.org/variants.html)
```

## Полиморфные варианты

Помимо обычных вариантов, OCaml предлагает **полиморфные варианты** (polymorphic variants) — уникальную особенность, которой нет в Haskell. Полиморфные варианты обозначаются обратной кавычкой `` ` ``:

```text
# `Red;;
- : [> `Red ] = `Red

# `Circle 5.0;;
- : [> `Circle of float ] = `Circle 5.

# [`Red; `Green; `Blue];;
- : [> `Blue | `Green | `Red ] list = [`Red; `Green; `Blue]
```

Ключевое отличие: полиморфные варианты **не требуют предварительного объявления типа**. Конструктор `` `Red `` может появиться в любом месте, и компилятор выведет тип автоматически.

### Типовые аннотации

Типы полиморфных вариантов записываются в квадратных скобках:

```ocaml
type primary = [ `Red | `Green | `Blue ]
type extended = [ primary | `Yellow | `Cyan | `Magenta ]
```

Заметьте: `extended` **включает** все конструкторы `primary` через синтаксис включения. Это невозможно с обычными вариантами.

### Ограничения типов

Полиморфные варианты используют три формы ограничений:

- `[> ...]` — «хотя бы эти конструкторы» (открытый тип для чтения).
- `[< ...]` — «не более этих конструкторов» (закрытый тип для записи).
- `[ ... ]` — «ровно эти конструкторы» (точный тип).

```ocaml
(* Принимает Red, Green, Blue и любые другие *)
let is_red = function
  | `Red -> true
  | _ -> false
(* val is_red : [> `Red ] -> bool *)

(* Принимает только Red, Green, Blue *)
let to_string : [ `Red | `Green | `Blue ] -> string = function
  | `Red -> "red"
  | `Green -> "green"
  | `Blue -> "blue"
(* val to_string : [ `Red | `Green | `Blue ] -> string *)
```

### Когда использовать полиморфные варианты

Полиморфные варианты полезны, когда:

- Нужна **расширяемость**: разные модули добавляют свои конструкторы.
- Нужно передавать значения между типами без конвертации.
- Конструкторы из разных типов пересекаются.

Однако у них есть недостатки:

- Более сложные сообщения об ошибках.
- Нет проверки полноты без явной аннотации типа.
- Медленнее обычных вариантов.

Для большинства задач обычные варианты предпочтительнее. Используйте полиморфные варианты, когда их преимущества действительно нужны.

## Проект: геометрические фигуры

Рассмотрим модуль `lib/shapes.ml`, который объединяет концепции этой главы.

### Типы

```ocaml
type point = { x : float; y : float }

type shape =
  | Circle of point * float
  | Rectangle of point * float * float
  | Line of point * point
  | Text of point * string

type picture = shape list
```

`point` — запись с двумя полями. `shape` — вариантный тип с четырьмя конструкторами, каждый из которых несёт данные (центр/угол, размеры). `picture` — синоним для списка фигур.

### Ограничивающий прямоугольник

Ограничивающий прямоугольник (bounding box) — минимальный прямоугольник, содержащий фигуру:

```ocaml
type bounds = {
  min_x : float;
  min_y : float;
  max_x : float;
  max_y : float;
}
```

Вычисление bounds для каждой фигуры — классический пример сопоставления с образцом:

```ocaml
let shape_bounds = function
  | Circle ({ x; y }, r) ->
    { min_x = x -. r; min_y = y -. r;
      max_x = x +. r; max_y = y +. r }
  | Rectangle ({ x; y }, w, h) ->
    { min_x = x; min_y = y;
      max_x = x +. w; max_y = y +. h }
  | Line (p1, p2) ->
    { min_x = Float.min p1.x p2.x; min_y = Float.min p1.y p2.y;
      max_x = Float.max p1.x p2.x; max_y = Float.max p1.y p2.y }
  | Text (p, _) ->
    { min_x = p.x; min_y = p.y;
      max_x = p.x; max_y = p.y }
```

Обратите внимание на деструктуризацию:

- `Circle ({ x; y }, r)` — извлекаем поля записи `point` и радиус одновременно.
- `Line (p1, p2)` — привязываем обе точки к переменным.
- `Text (p, _)` — нам не нужен текст, поэтому используем `_`.

### Объединение bounds и bounds картинки

```ocaml
let union_bounds b1 b2 =
  { min_x = Float.min b1.min_x b2.min_x;
    min_y = Float.min b1.min_y b2.min_y;
    max_x = Float.max b1.max_x b2.max_x;
    max_y = Float.max b1.max_y b2.max_y }

let bounds = function
  | [] -> { min_x = 0.0; min_y = 0.0; max_x = 0.0; max_y = 0.0 }
  | s :: ss ->
    List.fold_left
      (fun acc shape -> union_bounds acc (shape_bounds shape))
      (shape_bounds s) ss
```

Функция `bounds` вычисляет ограничивающий прямоугольник всей картинки. Она использует:

- Сопоставление списка: `[]` (пустой) и `s :: ss` (голова + хвост).
- `List.fold_left` — свёртку списка (подробно рассмотрим в следующей главе).

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Среднее)** Реализуйте функцию `area`, которая вычисляет площадь фигуры.

    ```ocaml
    val area : shape -> float
    ```

    - `Circle` — π × r²
    - `Rectangle` — width × height
    - `Line` и `Text` — 0.0

    *Подсказка:* используйте `function` и `Float.pi`.

2. **(Среднее)** Реализуйте функцию `scale`, которая масштабирует фигуру на заданный множитель. Все координаты и размеры умножаются на множитель, текст остаётся без изменений.

    ```ocaml
    val scale : float -> shape -> shape
    ```

    Например, `scale 2.0 (Circle ({x=1.0; y=2.0}, 5.0))` должна вернуть `Circle ({x=2.0; y=4.0}, 10.0)`.

    *Подсказка:* создайте новую фигуру с пересчитанными координатами и размерами.

3. **(Лёгкое)** Реализуйте функцию `shape_text`, которая извлекает текст из фигуры `Text`. Для остальных фигур возвращает `None`.

    ```ocaml
    val shape_text : shape -> string option
    ```

    *Подсказка:* верните `Some s` для `Text` и `None` для всех остальных.

4. **(Лёгкое)** Реализуйте функцию `safe_head`, которая возвращает первый элемент списка, обёрнутый в `option`.

    ```ocaml
    val safe_head : 'a list -> 'a option
    ```

    `safe_head [1; 2; 3]` = `Some 1`, `safe_head []` = `None`.

    *Подсказка:* используйте сопоставление с образцом для списка.

## Заключение

В этой главе мы изучили вариантные типы и сопоставление с образцом, разобрали проверку полноты и кортежи, познакомились с рекурсивными типами, `option`, `result` и полиморфными вариантами.

Следующая глава — рекурсия, функции высшего порядка (`map`, `filter`, `fold`) и ленивые последовательности `Seq`.
