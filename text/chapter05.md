# Рекурсия, map и свёртки

## Цели главы

В этой главе мы изучим рекурсию, функции высшего порядка и свёртки --- основные инструменты обработки данных в функциональном стиле:

- Рекурсия (`let rec`) и хвостовая рекурсия (tail recursion).
- Функции высшего порядка: `List.map`, `List.filter`, `List.filter_map`, `List.concat_map`.
- Свёртки: `List.fold_left` и `List.fold_right`.
- Оператор конвейера `|>` в цепочках обработки.
- Ленивые последовательности `Seq`.
- Проект: виртуальная файловая система.

## Подготовка проекта

Код этой главы находится в `exercises/chapter05`. Основной модуль --- `lib/path.ml`. Соберите проект:

```text
$ cd exercises/chapter05
$ dune build
```

## Рекурсия

В предыдущих главах мы уже встречали `let rec`. Теперь рассмотрим рекурсию подробнее.

### Базовые примеры

Факториал --- классический пример:

```ocaml
let rec factorial n =
  if n = 0 then 1
  else n * factorial (n - 1)
```

Рекурсия на списках:

```ocaml
let rec sum = function
  | [] -> 0
  | x :: rest -> x + sum rest
```

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

Обе функции определяются одновременно через `let rec ... and ...`.

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

Каждый рекурсивный вызов занимает место в стеке. Для длинных списков (миллионы элементов) стек переполнится --- `Stack_overflow`.

Это принципиальное отличие от Haskell, где ленивость позволяет обрабатывать бесконечные списки без переполнения стека. В OCaml вычисления строгие (strict), поэтому о стеке нужно заботиться явно.

### Решение: хвостовая рекурсия

Функция **хвостово-рекурсивна** (tail-recursive), если рекурсивный вызов --- последняя операция в функции. Компилятор OCaml оптимизирует такие вызовы, превращая рекурсию в цикл:

```ocaml
let sum lst =
  let rec go acc = function
    | [] -> acc
    | x :: rest -> go (acc + x) rest
  in
  go 0 lst
```

Здесь `go` --- хвостово-рекурсивная вспомогательная функция с аккумулятором `acc`. Вызов `go (acc + x) rest` --- последняя операция, ничего не нужно делать после возврата. Компилятор превращает это в цикл, и стек не растёт.

### Паттерн «аккумулятор»

Преобразование в хвостовую рекурсию обычно следует паттерну:

1. Добавьте вспомогательную функцию с дополнительным параметром --- аккумулятором.
2. Базовый случай возвращает аккумулятор вместо начального значения.
3. Рекурсивный шаг обновляет аккумулятор и вызывает себя.

Ещё примеры:

```ocaml
(* Длина списка --- хвостовая рекурсия *)
let length lst =
  let rec go acc = function
    | [] -> acc
    | _ :: rest -> go (acc + 1) rest
  in
  go 0 lst

(* Реверс списка --- хвостовая рекурсия *)
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

Функция высшего порядка (higher-order function) --- функция, принимающая или возвращающая другие функции. Стандартная библиотека OCaml предоставляет богатый набор таких функций для списков.

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

Тип: `('a -> 'b) -> 'a list -> 'b list`. Функция может менять тип элементов --- это отражается в типе `'a -> 'b`.

### `List.filter`

`List.filter pred lst` оставляет только элементы, для которых предикат `pred` возвращает `true`:

```text
# List.filter (fun x -> x mod 2 = 0) [1; 2; 3; 4; 5; 6];;
- : int list = [2; 4; 6]

# List.filter (fun s -> String.length s > 3) ["hi"; "hello"; "ok"; "world"];;
- : string list = ["hello"; "world"]
```

Тип: `('a -> bool) -> 'a list -> 'a list`.

### `List.filter_map`

`List.filter_map f lst` --- комбинация `filter` и `map`. Функция `f` возвращает `option`: `Some x` оставляет элемент, `None` отбрасывает:

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

Свёртка (fold) --- самая мощная функция обработки списков. Любую функцию на списках можно выразить через свёртку.

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

- `f` --- функция, принимающая аккумулятор и текущий элемент, возвращающая новый аккумулятор.
- `init` --- начальное значение аккумулятора.
- `lst` --- список для обработки.

`List.fold_left` **хвостово-рекурсивна** и безопасна для длинных списков.

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

Тип: `('a -> 'acc -> 'acc) -> 'a list -> 'acc -> 'a list`.

Обратите внимание: порядок аргументов отличается от `fold_left` --- список идёт вторым аргументом, а начальное значение --- третьим.

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

## Ленивые последовательности: `Seq`

В Haskell все списки ленивые, что позволяет работать с бесконечными структурами. В OCaml списки строгие (strict) --- все элементы вычисляются сразу. Для ленивых вычислений OCaml предоставляет модуль `Seq`.

### Что такое `Seq`

`Seq.t` --- ленивая последовательность. Элементы вычисляются **по требованию** --- только когда к ним обращаются:

```text
# let nats = Seq.ints 0;;
val nats : int Seq.t = <fun>

# Seq.take 5 nats |> List.of_seq;;
- : int list = [0; 1; 2; 3; 4]

# Seq.take 10 nats |> List.of_seq;;
- : int list = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9]
```

`Seq.ints 0` создаёт **бесконечную** последовательность 0, 1, 2, ... --- но она не вычисляется вся сразу, а генерирует элементы по мере необходимости.

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

`Seq.unfold f seed` --- генерация последовательности: `f` принимает текущее состояние и возвращает `Some (element, next_state)` для продолжения или `None` для остановки.

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

Состояние `(a, b)` хранит два последних числа. На каждом шаге выдаём `a` и переходим к `(b, a + b)`.

## Проект: виртуальная файловая система

Модуль `lib/path.ml` моделирует файловую систему как рекурсивный тип данных.

### Тип `path`

```ocaml
type path =
  | File of string * int
  | Directory of string * path list
```

`File (name, size)` --- файл с именем и размером. `Directory (name, children)` --- директория с именем и списком вложенных элементов. Тип рекурсивный --- директория может содержать другие директории.

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

`all_paths` --- обход в глубину (DFS). Для каждого узла: добавляем сам узел, затем рекурсивно обходим всех потомков. `List.concat_map` применяет `all_paths` к каждому потомку и конкатенирует результаты.

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

    *Подсказка:* используйте рекурсию. Проверяйте `children` текущей директории --- если среди них есть файл с нужным именем, возвращайте текущую директорию.

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

    *Подсказка:* используйте `Seq.unfold` с состоянием-парой `(a, b)`, где `a` --- текущее число, `b` --- следующее.

6. **(Среднее)** Pangram --- проверить, содержит ли строка все буквы английского алфавита (регистронезависимо).

    ```ocaml
    val is_pangram : string -> bool
    ```

    `is_pangram "The quick brown fox jumps over the lazy dog"` = `true`.

7. **(Среднее)** Isogram --- проверить, что в слове нет повторяющихся букв (пробелы и дефисы не считаются).

    ```ocaml
    val is_isogram : string -> bool
    ```

8. **(Среднее)** Anagram --- найти анаграммы заданного слова из списка кандидатов. Само слово не является своей анаграммой.

    ```ocaml
    val anagrams : string -> string list -> string list
    ```

    *Подсказка:* отсортируйте буквы слова и сравните.

9. **(Лёгкое)** Reverse String --- перевернуть строку.

    ```ocaml
    val reverse_string : string -> string
    ```

10. **(Среднее)** Nucleotide Count --- подсчитать количество каждого нуклеотида (A, C, G, T) в строке ДНК.

    ```ocaml
    val nucleotide_count : string -> (char * int) list
    ```

11. **(Среднее)** Hamming Distance --- подсчитать количество различий между двумя строками одинаковой длины. Вернуть `Error`, если строки разной длины.

    ```ocaml
    val hamming_distance : string -> string -> (int, string) result
    ```

12. **(Среднее)** Run-Length Encoding --- сжать строку методом RLE и декодировать обратно.

    ```ocaml
    val rle_encode : string -> string
    val rle_decode : string -> string
    ```

    `rle_encode "AABBBC"` = `"2A3B1C"`. `rle_decode "2A3B1C"` = `"AABBBC"`.

13. **(Сложное)** List Ops --- реализуйте стандартные операции над списками **без использования функций модуля `List`**.

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

    *Подсказка:* `reverse` и `map` реализуйте через хвостовую рекурсию с аккумулятором. `append` и `concat` --- через `fold_right`.

## Заключение

В этой главе мы:

- Изучили рекурсию и хвостовую рекурсию с аккумулятором.
- Познакомились с функциями высшего порядка: `List.map`, `List.filter`, `List.filter_map`, `List.concat_map`.
- Разобрали свёртки `List.fold_left` (хвостовая, слева направо) и `List.fold_right` (не хвостовая, справа налево).
- Научились строить цепочки обработки данных с оператором `|>`.
- Познакомились с ленивыми последовательностями `Seq` --- аналогом бесконечных списков Haskell.

В следующей главе мы изучим модульную систему OCaml --- модули, сигнатуры, функторы и модули первого класса.
