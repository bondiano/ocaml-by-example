# Рекурсия, map и свёртки

## Цели главы

В этой главе мы изучим рекурсию, функции высшего порядка и свёртки.

Темы главы:

- Рекурсия (`let rec`) и хвостовая рекурсия (tail recursion).
- Функции высшего порядка: `List.map`, `List.filter`, `List.filter_map`, `List.concat_map`.
- Свёртки: `List.fold_left` и `List.fold_right`.
- Оператор конвейера `|>` в цепочках обработки.
- Ленивые последовательности `Seq`.
- Проект: виртуальная файловая система.

## Подготовка проекта

Код этой главы находится в `exercises/chapter06`. Основной модуль — `lib/path.ml`. Соберите проект:

```text
$ cd exercises/chapter06
$ dune build
```

## Рекурсия

В предыдущих главах мы уже встречали `let rec`. Теперь рассмотрим рекурсию подробнее.

### Базовые примеры

Факториал — классический пример:

```ocaml
let rec factorial n =
  if n = 0 then 1
  else n * factorial (n - 1)
```

Базовый случай: `factorial 0 = 1`. Рекурсивный случай: `factorial n = n * factorial (n - 1)`. Например, `factorial 4` раскрывается как `4 * 3 * 2 * 1 * 1 = 24`.

Рекурсия на списках:

```ocaml
let rec sum = function
  | [] -> 0
  | x :: rest -> x + sum rest
```

Базовый случай — пустой список (сумма 0). Рекурсивный — добавляем голову к сумме хвоста: `sum [1; 2; 3]` = `1 + sum [2; 3]` = `1 + 2 + sum [3]` = `1 + 2 + 3 + 0` = `6`.

Каждая рекурсивная функция должна иметь **базовый случай** (условие остановки) и **рекурсивный случай** (шаг, приближающий к базовому).

### Взаимная рекурсия

OCaml поддерживает взаимную рекурсию через `and`:

```ocaml
let rec is_even n =
  if n = 0 then true
  else is_odd (n - 1)
and is_odd n =
  if n = 0 then false
  else is_even (n - 1)
```

Обе функции определяются одновременно через `let rec ... and ...`. Они вызывают друг друга поочерёдно: `is_even 4` → `is_odd 3` → `is_even 2` → `is_odd 1` → `is_even 0` → `true`. Такой подход корректен, но неэффективен — для больших чисел лучше использовать `n mod 2 = 0`.

## Хвостовая рекурсия

### Проблема стека

Рассмотрим функцию `sum`:

```ocaml
let rec sum = function
  | [] -> 0
  | x :: rest -> x + sum rest
```

При вызове `sum [1; 2; 3]` OCaml строит цепочку отложенных вычислений:

```
sum [1; 2; 3]
= 1 + sum [2; 3]
= 1 + (2 + sum [3])
= 1 + (2 + (3 + sum []))
= 1 + (2 + (3 + 0))
= 6
```

Каждый рекурсивный вызов занимает место в стеке. Для длинных списков (миллионы элементов) стек переполнится — `Stack_overflow`.

Это принципиальное отличие от Haskell, где ленивость позволяет обрабатывать бесконечные списки без переполнения стека. В OCaml вычисления строгие (strict), поэтому о стеке нужно заботиться явно.

### Решение: хвостовая рекурсия

Функция **хвостово-рекурсивна** (tail-recursive), если рекурсивный вызов — последняя операция в функции. Компилятор OCaml оптимизирует такие вызовы, превращая рекурсию в цикл:

```ocaml
let sum lst =
  let rec go acc = function
    | [] -> acc
    | x :: rest -> go (acc + x) rest
  in
  go 0 lst
```

Здесь `go` — хвостово-рекурсивная вспомогательная функция с аккумулятором `acc`. Вызов `go (acc + x) rest` — последняя операция, ничего не нужно делать после возврата. Компилятор превращает это в цикл, и стек не растёт.

### Паттерн «аккумулятор»

Преобразование в хвостовую рекурсию обычно следует паттерну:

1. Добавьте вспомогательную функцию с дополнительным параметром — аккумулятором.
2. Базовый случай возвращает аккумулятор вместо начального значения.
3. Рекурсивный шаг обновляет аккумулятор и вызывает себя.

Ещё примеры:

```ocaml
(* Длина списка — хвостовая рекурсия *)
let length lst =
  let rec go acc = function
    | [] -> acc
    | _ :: rest -> go (acc + 1) rest
  in
  go 0 lst

(* Реверс списка — хвостовая рекурсия *)
let rev lst =
  let rec go acc = function
    | [] -> acc
    | x :: rest -> go (x :: acc) rest
  in
  go [] lst
```

### Когда нужна хвостовая рекурсия

В OCaml хвостовая рекурсия важна для:

- Обработки длинных списков (> 10 000 элементов).
- Циклов с большим количеством итераций.
- Любых функций, которые должны работать с произвольным объёмом данных.

Для коротких списков и неглубокой рекурсии обычная рекурсия вполне допустима.

## Функции высшего порядка для списков

Функция высшего порядка (higher-order function) — функция, принимающая или возвращающая другие функции. Стандартная библиотека OCaml предоставляет богатый набор таких функций для списков.

### `List.map`

`List.map f lst` применяет функцию `f` к каждому элементу списка:

```text
# List.map (fun x -> x * 2) [1; 2; 3; 4];;
- : int list = [2; 4; 6; 8]

# List.map String.uppercase_ascii ["hello"; "world"];;
- : string list = ["HELLO"; "WORLD"]

# List.map string_of_int [1; 2; 3];;
- : string list = ["1"; "2"; "3"]
```

Тип: `('a -> 'b) -> 'a list -> 'b list`. Функция может менять тип элементов — это отражается в типе `'a -> 'b`.

```admonish tip title="Для Python/TS-разработчиков"
`List.map` — это аналог `map()` в Python и `Array.prototype.map()` в TypeScript/JavaScript. Разница в том, что в OCaml `map` — обычная функция, а не метод списка: `List.map f lst` вместо `lst.map(f)`. В сочетании с оператором конвейера `|>` запись становится похожей: `lst |> List.map f`. Ещё одно отличие: `List.map` в OCaml возвращает **новый** список (списки иммутабельны), а `Array.map` в JS тоже создаёт новый массив, но по соглашению, а не по гарантии типовой системы.
```

### `List.filter`

`List.filter pred lst` оставляет только элементы, для которых предикат `pred` возвращает `true`:

```text
# List.filter (fun x -> x mod 2 = 0) [1; 2; 3; 4; 5; 6];;
- : int list = [2; 4; 6]

# List.filter (fun s -> String.length s > 3) ["hi"; "hello"; "ok"; "world"];;
- : string list = ["hello"; "world"]
```

Тип: `('a -> bool) -> 'a list -> 'a list`.

```admonish tip title="Для Python/TS-разработчиков"
`List.filter` — аналог `filter()` в Python и `Array.prototype.filter()` в JS/TS. Python также поддерживает list comprehension: `[x for x in lst if x % 2 == 0]`. В OCaml list comprehension нет, но конвейер `|> List.filter ... |> List.map ...` даёт аналогичную выразительность.
```

### `List.filter_map`

`List.filter_map f lst` — комбинация `filter` и `map`. Функция `f` возвращает `option`: `Some x` оставляет элемент, `None` отбрасывает:

```text
# List.filter_map (fun x ->
    if x > 0 then Some (x * 10) else None
  ) [-1; 2; -3; 4; 5];;
- : int list = [20; 40; 50]
```

Тип: `('a -> 'b option) -> 'a list -> 'b list`. Это удобнее, чем отдельные `filter` + `map`, когда решение о включении и преобразование зависят друг от друга.

### `List.concat_map`

`List.concat_map f lst` применяет `f` к каждому элементу (каждый вызов возвращает список) и конкатенирует результаты:

```text
# List.concat_map (fun x -> [x; x * 10]) [1; 2; 3];;
- : int list = [1; 10; 2; 20; 3; 30]

# List.concat_map (fun s -> String.split_on_char ' ' s) ["hello world"; "foo bar baz"];;
- : string list = ["hello"; "world"; "foo"; "bar"; "baz"]
```

Тип: `('a -> 'b list) -> 'a list -> 'b list`. Аналог `concatMap` из Haskell.

### `List.find_opt` и `List.exists`

```text
# List.find_opt (fun x -> x > 3) [1; 2; 3; 4; 5];;
- : int option = Some 4

# List.exists (fun x -> x > 10) [1; 2; 3];;
- : bool = false

# List.for_all (fun x -> x > 0) [1; 2; 3];;
- : bool = true
```

`List.find_opt` возвращает первый подходящий элемент в `Some` или `None`, если ни один не подошёл. `List.exists` проверяет, выполняется ли предикат хотя бы для одного элемента. `List.for_all` проверяет, выполняется ли предикат для всех элементов.

### Цепочки с `|>`

Функции высшего порядка раскрывают свою мощь в цепочках с оператором конвейера `|>`:

```ocaml
let result =
  [1; 2; 3; 4; 5; 6; 7; 8; 9; 10]
  |> List.filter (fun x -> x mod 2 = 0)
  |> List.map (fun x -> x * x)
  |> List.fold_left ( + ) 0
```

Читается слева направо: «взять числа от 1 до 10, отфильтровать чётные, возвести в квадрат, сложить». Результат: 4 + 16 + 36 + 64 + 100 = 220.

## Свёртки

Свёртка (fold) — самая мощная функция обработки списков. Любую функцию на списках можно выразить через свёртку.

### `List.fold_left`

`List.fold_left f init lst` обрабатывает список **слева направо**, накапливая результат:

```
fold_left f init [a; b; c] = f (f (f init a) b) c
```

Примеры:

```text
# List.fold_left ( + ) 0 [1; 2; 3; 4];;
- : int = 10

# List.fold_left ( * ) 1 [1; 2; 3; 4];;
- : int = 24

# List.fold_left (fun acc x -> acc ^ ", " ^ x) "начало" ["а"; "б"; "в"];;
- : string = "начало, а, б, в"
```

Тип: `('acc -> 'a -> 'acc) -> 'acc -> 'a list -> 'acc`.

- `f` — функция, принимающая аккумулятор и текущий элемент, возвращающая новый аккумулятор.
- `init` — начальное значение аккумулятора.
- `lst` — список для обработки.

`List.fold_left` **хвостово-рекурсивна** и безопасна для длинных списков.

```admonish tip title="Для Python/TS-разработчиков"
`List.fold_left` — аналог `functools.reduce()` в Python и `Array.prototype.reduce()` в JavaScript/TypeScript. Например, `List.fold_left (+) 0 [1; 2; 3; 4]` — это `reduce(lambda acc, x: acc + x, [1, 2, 3, 4], 0)` в Python или `[1, 2, 3, 4].reduce((acc, x) => acc + x, 0)` в JS. Главное отличие: в OCaml `fold_left` — основной паттерн обработки списков, в то время как в Python предпочитают `sum()`, `max()` и другие специализированные функции.
```

### `List.fold_right`

`List.fold_right f lst init` обрабатывает список **справа налево**:

```
fold_right f [a; b; c] init = f a (f b (f c init))
```

```text
# List.fold_right (fun x acc -> x :: acc) [1; 2; 3] [];;
- : int list = [1; 2; 3]

# List.fold_right (fun x acc -> acc ^ string_of_int x) [1; 2; 3] "";;
- : string = "321"
```

Тип: `('a -> 'acc -> 'acc) -> 'a list -> 'acc -> 'acc`.

Обратите внимание: порядок аргументов отличается от `fold_left` — список идёт вторым аргументом, а начальное значение — третьим. Второй пример `acc ^ string_of_int x` накапливает строку справа налево, поэтому числа идут в обратном порядке.

`List.fold_right` **не хвостово-рекурсивна** и может вызвать `Stack_overflow` на длинных списках.

### Когда что использовать

| Функция | Направление | Хвостовая рекурсия | Типичное применение |
|---------|------------|--------------------|--------------------|
| `fold_left` | Слева направо | Да | Суммы, подсчёты, аккумуляция |
| `fold_right` | Справа налево | Нет | Построение списков, сохранение порядка |

Предпочитайте `fold_left`, если порядок не важен. Используйте `fold_right` для построения списков, когда нужно сохранить исходный порядок элементов.

### Выражение через свёртки

Многие стандартные функции можно выразить через свёртки:

```ocaml
(* map через fold_right *)
let map f lst =
  List.fold_right (fun x acc -> f x :: acc) lst []

(* filter через fold_right *)
let filter pred lst =
  List.fold_right (fun x acc -> if pred x then x :: acc else acc) lst []

(* length через fold_left *)
let length lst =
  List.fold_left (fun acc _ -> acc + 1) 0 lst

(* rev через fold_left *)
let rev lst =
  List.fold_left (fun acc x -> x :: acc) [] lst

(* flatten через fold_right *)
let flatten lst =
  List.fold_right (fun x acc -> x @ acc) lst []
```

`map` и `filter` используют `fold_right`, чтобы сохранить исходный порядок элементов — обход справа налево и добавление через `::` дают тот же порядок. `rev` использует `fold_left`, потому что добавление в начало аккумулятора естественно переворачивает список.

## Traverse: обработка списков с эффектами

Рассмотрим частую задачу: у нас есть список значений, каждое из которых нужно обработать функцией, возвращающей `option` или `result`. Если **все** обработки успешны, мы хотим получить список результатов. Если хотя бы одна неуспешна, вся операция должна провалиться.

### Проблема: `'a option list` → `'a list option`

Допустим, мы парсим список строк в числа:

```text
# List.map int_of_string_opt ["1"; "2"; "3"];;
- : int option list = [Some 1; Some 2; Some 3]

# List.map int_of_string_opt ["1"; "abc"; "3"];;
- : int option list = [Some 1; None; Some 3]
```

Мы получаем `int option list` — список, где каждый элемент может быть `Some` или `None`. Но нам нужен `int list option` — либо весь список целиком, либо `None`.

### `sequence_option`: сборка списка из option

```ocaml
let sequence_option lst =
  List.fold_right
    (fun x acc ->
      match x, acc with
      | Some v, Some vs -> Some (v :: vs)
      | _ -> None)
    lst (Some [])
```

```text
# sequence_option [Some 1; Some 2; Some 3];;
- : int list option = Some [1; 2; 3]

# sequence_option [Some 1; None; Some 3];;
- : int list option = None
```

`fold_right` обходит список справа налево. Если аккумулятор и текущий элемент оба `Some`, добавляем значение в список. Иначе — всё `None`.

### `traverse_option`: map + sequence за один проход

`sequence_option` требует сначала `List.map`, а потом сборку. Можно совместить оба шага:

```ocaml
let traverse_option f lst =
  List.fold_right
    (fun x acc ->
      match f x, acc with
      | Some v, Some vs -> Some (v :: vs)
      | _ -> None)
    lst (Some [])
```

```text
# traverse_option int_of_string_opt ["1"; "2"; "3"];;
- : int list option = Some [1; 2; 3]

# traverse_option int_of_string_opt ["1"; "abc"; "3"];;
- : int list option = None
```

`traverse_option f` = `sequence_option ∘ List.map f`, но за один проход.

### `traverse_result`: аналог для `Result`

Для `result` логика аналогична, но при ошибке мы сохраняем информацию о причине:

```ocaml
let traverse_result f lst =
  List.fold_right
    (fun x acc ->
      match f x, acc with
      | Ok v, Ok vs -> Ok (v :: vs)
      | Error e, _ -> Error e
      | _, Error e -> Error e)
    lst (Ok [])
```

```text
# let parse s =
    match int_of_string_opt s with
    | Some n -> Ok n
    | None -> Error (Printf.sprintf "не число: %s" s);;

# traverse_result parse ["1"; "2"; "3"];;
- : (int list, string) result = Ok [1; 2; 3]

# traverse_result parse ["1"; "abc"; "3"];;
- : (int list, string) result = Error "не число: abc"
```

### Связь с `List.filter_map`

`List.filter_map` — похожая функция, но с другой семантикой: она **молча отбрасывает** неуспешные элементы вместо того, чтобы провалить всю операцию:

```text
# List.filter_map int_of_string_opt ["1"; "abc"; "3"];;
- : int list = [1; 3]
```

Выбирайте по ситуации:

| Функция | При ошибке | Результат |
|---------|-----------|-----------|
| `filter_map` | Пропускает элемент | Всегда `'b list` |
| `traverse_option` | Провал всей операции | `'b list option` |
| `traverse_result` | Провал с сообщением | `('b list, 'e) result` |

### Практический пример: парсинг CSV-строки

```ocaml
type person = { name : string; age : int }

let parse_csv_line line =
  match String.split_on_char ',' line with
  | [name; age_str] ->
    (match int_of_string_opt (String.trim age_str) with
     | Some age -> Ok { name = String.trim name; age }
     | None -> Error (Printf.sprintf "некорректный возраст: %s" age_str))
  | _ -> Error (Printf.sprintf "неверный формат строки: %s" line)

let parse_csv lines = traverse_result parse_csv_line lines
```

```text
# parse_csv ["Alice, 30"; "Bob, 25"];;
- : (person list, string) result = Ok [{name = "Alice"; age = 30}; ...]

# parse_csv ["Alice, 30"; "Bob, xyz"];;
- : (person list, string) result = Error "некорректный возраст:  xyz"
```

Если хотя бы одна строка невалидна, весь парсинг провалится с понятным сообщением об ошибке.

## Ленивые последовательности: `Seq`

В Haskell все списки ленивые, что позволяет работать с бесконечными структурами. В OCaml списки строгие (strict) — все элементы вычисляются сразу. Для ленивых вычислений OCaml предоставляет модуль `Seq`.

### Что такое `Seq`

`Seq.t` — ленивая последовательность. Элементы вычисляются **по требованию** — только когда к ним обращаются:

```text
# let nats = Seq.ints 0;;
val nats : int Seq.t = <fun>

# Seq.take 5 nats |> List.of_seq;;
- : int list = [0; 1; 2; 3; 4]

# Seq.take 10 nats |> List.of_seq;;
- : int list = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9]
```

`Seq.ints 0` создаёт **бесконечную** последовательность 0, 1, 2, ... — но она не вычисляется вся сразу, а генерирует элементы по мере необходимости.

```admonish tip title="Для Python-разработчиков"
`Seq` в OCaml — аналог генераторов (`yield`) в Python. `Seq.ints 0` похож на `itertools.count(0)`. Как и Python-генераторы, `Seq` вычисляет элементы лениво. Разница в том, что `Seq` в OCaml — неизменяемая структура, которую можно обойти несколько раз, а Python-генератор исчерпывается после одного обхода.
```

```admonish info title="Подробнее"
Подробнее о списках, свёртках и рекурсии: [Real World OCaml, глава «Lists and Patterns»](https://dev.realworldocaml.org/lists-and-patterns.html)
```

### Создание последовательностей

```text
(* Из списка *)
# List.to_seq [1; 2; 3] |> List.of_seq;;
- : int list = [1; 2; 3]

(* Бесконечная последовательность *)
# Seq.ints 0 |> Seq.take 5 |> List.of_seq;;
- : int list = [0; 1; 2; 3; 4]

(* Генерация через unfold *)
# Seq.unfold (fun n -> if n > 5 then None else Some (n * n, n + 1)) 1
  |> List.of_seq;;
- : int list = [1; 4; 9; 16; 25]
```

`Seq.unfold f seed` — генерация последовательности: `f` принимает текущее состояние и возвращает `Some (element, next_state)` для продолжения или `None` для остановки.

### Операции над `Seq`

Модуль `Seq` предоставляет функции, аналогичные `List`:

```ocaml
(* Фильтрация + преобразование бесконечной последовательности *)
let even_squares =
  Seq.ints 0
  |> Seq.filter (fun x -> x mod 2 = 0)
  |> Seq.map (fun x -> x * x)
  |> Seq.take 5
  |> List.of_seq
(* = [0; 4; 16; 36; 64] *)
```

Конвейер работает с бесконечной последовательностью: фильтрует чётные числа (0, 2, 4, 6, 8, ...), возводит в квадрат (0, 4, 16, 36, 64, ...) и берёт первые 5 элементов. Ключевой момент: `Seq.filter` и `Seq.map` ленивы — они не вычисляют элементы заранее, а только при запросе. Весь конвейер материализуется в список лишь в конце через `List.of_seq`.

### Пример: числа Фибоначчи

Бесконечная последовательность Фибоначчи через `Seq.unfold`:

```ocaml
let fibs =
  Seq.unfold (fun (a, b) -> Some (a, (b, a + b))) (0, 1)
```

```text
# fibs |> Seq.take 10 |> List.of_seq;;
- : int list = [0; 1; 1; 2; 3; 5; 8; 13; 21; 34]
```

Состояние `(a, b)` хранит два последних числа: начальное состояние `(0, 1)` даёт первый элемент `0`, следующее состояние `(1, 1)` — элемент `1`, затем `(1, 2)` — элемент `1` и т.д. На каждом шаге выдаём `a` и переходим к `(b, a + b)`. Последовательность никогда не завершается — `unfold` всегда возвращает `Some`.

### `Seq.concat_map` — flat map паттерн

`Seq.concat_map` (также известный как `flat_map`) применяет функцию к каждому элементу и объединяет результаты в одну последовательность. Это комбинация `map` и `concat`:

```ocaml
(* Разбить каждое число на последовательность от 1 до n *)
let expand n =
  Seq.ints 1 |> Seq.take n

let nested =
  Seq.ints 1
  |> Seq.take 3
  |> Seq.concat_map expand
  |> List.of_seq
(* = [1; 1; 2; 1; 2; 3] *)
```

Здесь `Seq.take 3` даёт `[1; 2; 3]`, затем `concat_map expand` разворачивает:
- `expand 1` → `[1]`
- `expand 2` → `[1; 2]`
- `expand 3` → `[1; 2; 3]`

Результат: `[1; 1; 2; 1; 2; 3]` — все последовательности склеены в одну.

**Практический пример:** получить все пары `(x, y)`, где `x` и `y` берутся из двух диапазонов:

```ocaml
let pairs =
  Seq.ints 1
  |> Seq.take 3
  |> Seq.concat_map (fun x ->
       Seq.ints 1
       |> Seq.take 2
       |> Seq.map (fun y -> (x, y)))
  |> List.of_seq
(* = [(1, 1); (1, 2); (2, 1); (2, 2); (3, 1); (3, 2)] *)
```

```admonish tip title="Для Haskell-разработчиков"
`Seq.concat_map` — это `>>=` (bind) для последовательностей. Если вы знакомы с list comprehensions в Haskell (`[(x, y) | x <- [1..3], y <- [1..2]]`), то паттерн с `concat_map` решает ту же задачу в OCaml.
```

### `Seq.zip` — комбинирование последовательностей

`Seq.zip` соединяет две последовательности поэлементно в пары. Результат завершается, когда заканчивается более короткая последовательность:

```text
# Seq.zip (Seq.ints 0) (List.to_seq ['a'; 'b'; 'c']) |> List.of_seq;;
- : (int * char) list = [(0, 'a'); (1, 'b'); (2, 'c')]
```

Бесконечная последовательность чисел и конечный список букв дают три пары — по длине списка букв.

**Пример:** пронумеровать элементы списка через индексы:

```ocaml
let indexed lst =
  Seq.zip (Seq.ints 0) (List.to_seq lst) |> List.of_seq
(* indexed ["foo"; "bar"; "baz"] = [(0, "foo"); (1, "bar"); (2, "baz")] *)
```

Альтернативные функции для комбинирования последовательностей:

| Функция | Описание |
|---------|----------|
| `Seq.zip s1 s2` | Попарно объединяет элементы. Длина = min(len s1, len s2) |
| `Seq.map2 f s1 s2` | Применяет бинарную функцию к парам элементов |
| `Seq.interleave s1 s2` | Чередует элементы: s1[0], s2[0], s1[1], s2[1], ... |

### Конверсии из других структур данных

Большинство модулей стандартной библиотеки предоставляют функции `to_seq` для преобразования в ленивую последовательность. Это позволяет единообразно обрабатывать данные из разных источников:

```ocaml
(* Из массива *)
let arr = [| 10; 20; 30 |]
let seq_from_array = Array.to_seq arr
(* int Seq.t *)

(* Из строки — последовательность символов *)
let seq_from_string = String.to_seq "hello"
(* char Seq.t *)

(* Из хеш-таблицы — последовательность пар (ключ, значение) *)
let h = Hashtbl.create 10
let () = Hashtbl.add h "foo" 42
let () = Hashtbl.add h "bar" 17
let seq_from_hashtbl = Hashtbl.to_seq h
(* (string * int) Seq.t *)
```

**Практический паттерн:** фильтрация хеш-таблицы через `Seq`:

```ocaml
let filter_hashtbl pred tbl =
  Hashtbl.to_seq tbl
  |> Seq.filter pred
  |> Hashtbl.of_seq
```

Здесь `to_seq` преобразует таблицу в последовательность, `Seq.filter` отбирает элементы, `of_seq` собирает обратно в новую хеш-таблицу. Ленивость `Seq` позволяет избежать материализации промежуточного списка.

**Обратные конверсии** — `of_seq`:

| Функция | Тип |
|---------|-----|
| `List.of_seq` | `'a Seq.t -> 'a list` |
| `Array.of_seq` | `'a Seq.t -> 'a array` |
| `Hashtbl.of_seq` | `('a * 'b) Seq.t -> ('a, 'b) Hashtbl.t` |
| `String.of_seq` | `char Seq.t -> string` |

```admonish tip title="Для Python-разработчиков"
`to_seq` в OCaml — аналог превращения коллекции в итератор через `iter()` в Python. Но в отличие от Python, где `list(iter(...))` всегда материализует данные в память, OCaml-последовательности остаются ленивыми до момента вызова `of_seq` или `List.of_seq`.
```

## Проект: виртуальная файловая система

Модуль `lib/path.ml` моделирует файловую систему как рекурсивный тип данных.

### Тип `path`

```ocaml
type path =
  | File of string * int
  | Directory of string * path list
```

`File (name, size)` — файл с именем и размером. `Directory (name, children)` — директория с именем и списком вложенных элементов. Тип рекурсивный — директория может содержать другие директории.

### Базовые функции

```ocaml
let filename = function
  | File (name, _) -> name
  | Directory (name, _) -> name

let is_directory = function
  | Directory _ -> true
  | File _ -> false

let file_size = function
  | File (_, size) -> Some size
  | Directory _ -> None

let children = function
  | Directory (_, cs) -> cs
  | File _ -> []
```

### Обход дерева

```ocaml
let rec all_paths p =
  p :: List.concat_map all_paths (children p)
```

`all_paths` — обход в глубину (DFS). Для каждого узла: добавляем сам узел, затем рекурсивно обходим всех потомков. `List.concat_map` применяет `all_paths` к каждому потомку и конкатенирует результаты.

### Тестовое дерево

```ocaml
let root =
  Directory ("root", [
    File ("readme.txt", 100);
    Directory ("src", [
      File ("main.ml", 500);
      File ("utils.ml", 300);
      Directory ("lib", [
        File ("parser.ml", 800);
        File ("lexer.ml", 600);
      ]);
    ]);
    Directory ("test", [
      File ("test_main.ml", 400);
    ]);
    File (".gitignore", 50);
  ])
```

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Среднее)** Реализуйте функцию `all_files`, которая извлекает из дерева только файлы (не директории).

    ```ocaml
    val all_files : path -> path list
    ```

    *Подсказка:* используйте `all_paths` из библиотеки и `List.filter`.

2. **(Среднее)** Реализуйте функцию `largest_file`, которая находит файл с наибольшим размером и возвращает пару `(path, size)`. Для пустого дерева (директория без файлов) возвращает `None`.

    ```ocaml
    val largest_file : path -> (path * int) option
    ```

    *Подсказка:* используйте `all_files` и `List.fold_left`.

3. **(Среднее)** Реализуйте функцию `where_is`, которая ищет файл по имени и возвращает директорию, в которой он находится.

    ```ocaml
    val where_is : path -> string -> path option
    ```

    *Подсказка:* используйте рекурсию. Проверяйте `children` текущей директории — если среди них есть файл с нужным именем, возвращайте текущую директорию.

4. **(Среднее)** Реализуйте функцию `total_size`, которая вычисляет суммарный размер всех файлов в дереве.

    ```ocaml
    val total_size : path -> int
    ```

    *Подсказка:* используйте `all_files`, `List.filter_map` и `List.fold_left`.

5. **(Сложное)** Реализуйте бесконечную последовательность чисел Фибоначчи через `Seq.unfold`.

    ```ocaml
    val fibs : int Seq.t
    ```

    `Seq.take 7 fibs |> List.of_seq` = `[0; 1; 1; 2; 3; 5; 8]`.

    *Подсказка:* используйте `Seq.unfold` с состоянием-парой `(a, b)`, где `a` — текущее число, `b` — следующее.

6. **(Среднее)** Pangram — проверить, содержит ли строка все буквы английского алфавита (регистронезависимо).

    ```ocaml
    val is_pangram : string -> bool
    ```

    `is_pangram "The quick brown fox jumps over the lazy dog"` = `true`.

7. **(Среднее)** Isogram — проверить, что в слове нет повторяющихся букв (пробелы и дефисы не считаются).

    ```ocaml
    val is_isogram : string -> bool
    ```

8. **(Среднее)** Anagram — найти анаграммы заданного слова из списка кандидатов. Само слово не является своей анаграммой.

    ```ocaml
    val anagrams : string -> string list -> string list
    ```

    *Подсказка:* отсортируйте буквы слова и сравните.

9. **(Лёгкое)** Reverse String — перевернуть строку.

    ```ocaml
    val reverse_string : string -> string
    ```

10. **(Среднее)** Nucleotide Count — подсчитать количество каждого нуклеотида (A, C, G, T) в строке ДНК.

    ```ocaml
    val nucleotide_count : string -> (char * int) list
    ```

11. **(Среднее)** Hamming Distance — подсчитать количество различий между двумя строками одинаковой длины. Вернуть `Error`, если строки разной длины.

    ```ocaml
    val hamming_distance : string -> string -> (int, string) result
    ```

12. **(Среднее)** Run-Length Encoding — сжать строку методом RLE и декодировать обратно.

    ```ocaml
    val rle_encode : string -> string
    val rle_decode : string -> string
    ```

    `rle_encode "AABBBC"` = `"2A3B1C"`. `rle_decode "2A3B1C"` = `"AABBBC"`.

13. **(Среднее)** Реализуйте `traverse_option` и `traverse_result` — функции, которые применяют функцию к каждому элементу списка и собирают результат в `option`/`result`. Если хотя бы один вызов неуспешен, вся операция проваливается.

    ```ocaml
    val traverse_option : ('a -> 'b option) -> 'a list -> 'b list option
    val traverse_result : ('a -> ('b, 'e) result) -> 'a list -> ('b list, 'e) result
    ```

    *Подсказка:* используйте `List.fold_right`.

14. **(Сложное)** List Ops — реализуйте стандартные операции над списками **без использования функций модуля `List`**.

    ```ocaml
    module List_ops : sig
      val length : 'a list -> int
      val reverse : 'a list -> 'a list
      val map : ('a -> 'b) -> 'a list -> 'b list
      val filter : ('a -> bool) -> 'a list -> 'a list
      val fold_left : ('b -> 'a -> 'b) -> 'b -> 'a list -> 'b
      val fold_right : ('a -> 'b -> 'b) -> 'a list -> 'b -> 'b
      val append : 'a list -> 'a list -> 'a list
      val concat : 'a list list -> 'a list
    end
    ```

    *Подсказка:* `reverse` и `map` реализуйте через хвостовую рекурсию с аккумулятором. `append` и `concat` — через `fold_right`.

15. **(Среднее)** Windowed Pairs — создайте ленивую последовательность пар соседних элементов из исходной последовательности.

    ```ocaml
    val windowed_pairs : 'a Seq.t -> ('a * 'a) Seq.t
    ```

    `windowed_pairs (List.to_seq [1; 2; 3; 4]) |> List.of_seq` = `[(1, 2); (2, 3); (3, 4)]`.

    *Подсказка:* используйте `Seq.unfold` с состоянием, хранящим предыдущий элемент и оставшуюся последовательность. Или комбинируйте `Seq.zip` с `Seq.drop 1`.

16. **(Среднее)** Cartesian Product — создайте последовательность всех пар `(x, y)`, где `x` из первой последовательности, `y` из второй.

    ```ocaml
    val cartesian : 'a Seq.t -> 'b Seq.t -> ('a * 'b) Seq.t
    ```

    `cartesian (List.to_seq [1; 2]) (List.to_seq ['a'; 'b']) |> List.of_seq` = `[(1, 'a'); (1, 'b'); (2, 'a'); (2, 'b')]`.

    *Подсказка:* используйте `Seq.concat_map` — для каждого `x` из первой последовательности создайте последовательность пар `(x, y)` для всех `y` из второй.

## Заключение

В этой главе мы изучили рекурсию и хвостовую рекурсию с аккумулятором, функции высшего порядка, свёртки `fold_left` и `fold_right`, паттерн traverse и ленивые последовательности `Seq`.

Для подробного справочника по модулям `List`, `Seq`, `Option` и другим см. [Приложение «Стандартная библиотека OCaml»](appendix_f.md).

Следующая глава — модульная система OCaml: модули, сигнатуры, функторы и модули первого класса.
