# Стандартная библиотека OCaml

Справочник по основным модулям стандартной библиотеки с примерами использования.

## Содержание

- [List — списки](#list--списки)
- [Array — массивы](#array--массивы)
- [Hashtbl — хеш-таблицы](#hashtbl--хеш-таблицы)
- [Map — иммутабельные словари](#map--иммутабельные-словари)
- [Set — иммутабельные множества](#set--иммутабельные-множества)
- [Buffer — буферизованное построение строк](#buffer--буферизованное-построение-строк)
- [Format — форматированный вывод](#format--форматированный-вывод)
- [String и Bytes](#string-и-bytes)
- [Option и Result](#option-и-result)

---

## List — списки

Иммутабельные односвязные списки. Доступ к голове — O(1), к хвосту — O(n).

### Создание

```ocaml
let empty = []
let nums = [1; 2; 3]
let chars = ['a'; 'b'; 'c']

(* Cons-оператор :: *)
let lst = 1 :: 2 :: 3 :: []
(* = [1; 2; 3] *)
```

### Основные функции

| Функция | Тип | Описание |
|---------|-----|----------|
| `List.length` | `'a list -> int` | Длина списка (O(n)) |
| `List.hd` | `'a list -> 'a` | Первый элемент (бросает исключение на пустом списке) |
| `List.tl` | `'a list -> 'a list` | Хвост без первого элемента (бросает исключение) |
| `List.nth` | `'a list -> int -> 'a` | N-й элемент (O(n), бросает исключение) |
| `List.rev` | `'a list -> 'a list` | Перевернуть список |
| `List.append` | `'a list -> 'a list -> 'a list` | Склеить два списка (также `@`) |
| `List.concat` | `'a list list -> 'a list` | Объединить список списков |

```ocaml
List.length [1; 2; 3]        (* = 3 *)
List.rev [1; 2; 3]           (* = [3; 2; 1] *)
[1; 2] @ [3; 4]              (* = [1; 2; 3; 4] *)
List.concat [[1; 2]; [3]; []] (* = [1; 2; 3] *)
```

```admonish warning title="Избегайте hd и tl"
Функции `List.hd` и `List.tl` бросают исключения на пустом списке. Вместо них используйте pattern matching:

\`\`\`ocaml
(* Плохо *)
let first = List.hd lst

(* Хорошо *)
let first = match lst with
  | x :: _ -> Some x
  | [] -> None
\`\`\`
```

### Map, filter, fold

```ocaml
(* Преобразование *)
List.map (fun x -> x * 2) [1; 2; 3]
(* = [2; 4; 6] *)

(* Фильтрация *)
List.filter (fun x -> x mod 2 = 0) [1; 2; 3; 4]
(* = [2; 4] *)

(* Комбинированное преобразование и фильтрация *)
List.filter_map (fun x ->
  if x mod 2 = 0 then Some (x * 2) else None
) [1; 2; 3; 4]
(* = [4; 8] *)

(* Свёртка слева *)
List.fold_left ( + ) 0 [1; 2; 3; 4]
(* = 10 *)

(* Свёртка справа *)
List.fold_right (fun x acc -> x :: acc) [1; 2; 3] []
(* = [1; 2; 3] *)
```

### Поиск

```ocaml
(* Поиск элемента *)
List.find (fun x -> x > 5) [1; 3; 7; 2]
(* = 7, бросает Not_found если не найдено *)

List.find_opt (fun x -> x > 5) [1; 3; 7; 2]
(* = Some 7 *)

List.find_opt (fun x -> x > 10) [1; 3; 7; 2]
(* = None *)

(* Проверка наличия *)
List.exists (fun x -> x > 5) [1; 3; 7]
(* = true *)

List.for_all (fun x -> x > 0) [1; 2; 3]
(* = true *)
```

### Partition и группировка

```ocaml
(* Разбить на два списка по предикату *)
List.partition (fun x -> x mod 2 = 0) [1; 2; 3; 4; 5]
(* = ([2; 4], [1; 3; 5]) *)

(* Удалить дубликаты (сохраняет порядок, O(n²)) *)
List.sort_uniq compare [3; 1; 2; 1; 3]
(* = [1; 2; 3] *)
```

### Комбинирование списков

```ocaml
(* Попарное комбинирование *)
List.combine [1; 2; 3] ['a'; 'b'; 'c']
(* = [(1, 'a'); (2, 'b'); (3, 'c')] *)

(* Разбить на пары *)
List.split [(1, 'a'); (2, 'b'); (3, 'c')]
(* = ([1; 2; 3], ['a'; 'b'; 'c']) *)

(* Zip с функцией преобразования *)
List.map2 ( + ) [1; 2; 3] [10; 20; 30]
(* = [11; 22; 33] *)
```

---

## Array — массивы

Мутабельные массивы фиксированного размера. Доступ по индексу — O(1).

### Создание

```ocaml
(* Пустой массив *)
let arr = [| |]

(* Литерал *)
let nums = [| 1; 2; 3 |]

(* Создать без инициализации (неопределённое содержимое) *)
let buf = Bytes.create 10

(* Создать с одинаковым значением *)
Array.make 5 0
(* = [|0; 0; 0; 0; 0|] *)

(* Создать с функцией инициализации *)
Array.init 5 (fun i -> i * i)
(* = [|0; 1; 4; 9; 16|] *)
```

### Доступ и изменение

```ocaml
let arr = [| 10; 20; 30 |]

(* Чтение *)
arr.(0)  (* = 10 *)
Array.get arr 0  (* = 10, то же самое *)

(* Запись *)
arr.(1) <- 99
(* arr = [|10; 99; 30|] *)

Array.set arr 2 42
(* arr = [|10; 99; 42|] *)

(* Длина *)
Array.length arr  (* = 3 *)
```

### Операции

```ocaml
(* Map — создаёт новый массив *)
Array.map (fun x -> x * 2) [| 1; 2; 3 |]
(* = [|2; 4; 6|] *)

(* Fold *)
Array.fold_left ( + ) 0 [| 1; 2; 3; 4 |]
(* = 10 *)

(* Итерация с индексом *)
Array.iteri (fun i x ->
  Printf.printf "arr[%d] = %d\n" i x
) [| 10; 20; 30 |]

(* Сортировка in-place *)
let arr = [| 3; 1; 2 |]
Array.sort compare arr
(* arr = [|1; 2; 3|] *)
```

### Конверсии

```ocaml
(* Из списка *)
Array.of_list [1; 2; 3]
(* = [|1; 2; 3|] *)

(* В список *)
Array.to_list [| 1; 2; 3 |]
(* = [1; 2; 3] *)

(* Из последовательности *)
Array.of_seq (Seq.ints 0 |> Seq.take 5)
(* = [|0; 1; 2; 3; 4|] *)
```

---

## Hashtbl — хеш-таблицы

Мутабельные хеш-таблицы с произвольными ключами. Среднее время операций — O(1).

### Создание

```ocaml
(* Создать пустую таблицу с начальным размером *)
let h = Hashtbl.create 10

(* Добавить элементы *)
Hashtbl.add h "foo" 42
Hashtbl.add h "bar" 17

(* Из списка пар *)
let h2 = Hashtbl.of_seq (List.to_seq [("x", 1); ("y", 2)])
```

### Операции

```ocaml
let h = Hashtbl.create 10
Hashtbl.add h "key" 100

(* Поиск *)
Hashtbl.find h "key"  (* = 100, бросает Not_found если нет *)
Hashtbl.find_opt h "key"  (* = Some 100 *)
Hashtbl.find_opt h "missing"  (* = None *)

(* Замена значения *)
Hashtbl.replace h "key" 200
(* Если ключ существовал, старое значение перезаписывается *)

(* Удаление *)
Hashtbl.remove h "key"

(* Проверка наличия *)
Hashtbl.mem h "key"  (* = false после удаления *)

(* Размер *)
Hashtbl.length h  (* = 0 *)
```

### Итерация

```ocaml
let h = Hashtbl.of_seq (List.to_seq [("a", 1); ("b", 2); ("c", 3)])

(* Итерация *)
Hashtbl.iter (fun key value ->
  Printf.printf "%s -> %d\n" key value
) h

(* Преобразование в список *)
let pairs = Hashtbl.fold (fun k v acc -> (k, v) :: acc) h []
(* = [("c", 3); ("b", 2); ("a", 1)] или в другом порядке *)

(* В последовательность *)
Hashtbl.to_seq h |> List.of_seq
```

```admonish warning title="Порядок не гарантирован"
`Hashtbl` не сохраняет порядок вставки. Для упорядоченного словаря используйте `Map`.
```

---

## Map — иммутабельные словари

Сбалансированные бинарные деревья (Red-Black Tree). Все операции — O(log n).

### Создание

`Map` — функтор. Нужно создать модуль для конкретного типа ключа:

```ocaml
module StringMap = Map.Make(String)

let empty = StringMap.empty

let m = StringMap.empty
  |> StringMap.add "foo" 42
  |> StringMap.add "bar" 17
```

### Операции

```ocaml
let m = StringMap.empty
  |> StringMap.add "x" 10
  |> StringMap.add "y" 20

(* Поиск *)
StringMap.find "x" m  (* = 10, бросает Not_found *)
StringMap.find_opt "x" m  (* = Some 10 *)
StringMap.find_opt "z" m  (* = None *)

(* Обновление (возвращает новый map) *)
let m2 = StringMap.add "x" 99 m
(* m2 = {"x" -> 99, "y" -> 20}
   m  = {"x" -> 10, "y" -> 20}  (не изменился) *)

(* Удаление *)
let m3 = StringMap.remove "y" m

(* Проверка наличия *)
StringMap.mem "x" m  (* = true *)

(* Размер *)
StringMap.cardinal m  (* = 2 *)
```

### Итерация

```ocaml
(* Map — преобразование значений *)
StringMap.map (fun v -> v * 2) m
(* = {"x" -> 20, "y" -> 40} *)

(* Фильтрация *)
StringMap.filter (fun _k v -> v > 15) m
(* = {"y" -> 20} *)

(* Fold *)
StringMap.fold (fun k v acc -> (k, v) :: acc) m []
(* = [("y", 20); ("x", 10)] в отсортированном порядке ключей *)

(* В последовательность *)
StringMap.to_seq m |> List.of_seq
```

```admonish tip title="Map vs Hashtbl"
- **Map**: иммутабельный, упорядоченный, O(log n).
- **Hashtbl**: мутабельный, неупорядоченный, O(1) среднее.

Используйте `Map`, если нужна иммутабельность и упорядоченность ключей. Используйте `Hashtbl` для максимальной скорости при больших объёмах данных.
```

---

## Set — иммутабельные множества

Реализованы как сбалансированные бинарные деревья (как `Map`, но без значений).

### Создание

```ocaml
module IntSet = Set.Make(Int)

let s = IntSet.empty
  |> IntSet.add 1
  |> IntSet.add 3
  |> IntSet.add 2
(* = {1, 2, 3} *)

let s2 = IntSet.of_list [5; 1; 3; 1]
(* = {1, 3, 5}, дубликаты удалены *)
```

### Операции

```ocaml
let s = IntSet.of_list [1; 2; 3]

(* Проверка наличия *)
IntSet.mem 2 s  (* = true *)

(* Добавление *)
let s2 = IntSet.add 4 s
(* = {1, 2, 3, 4} *)

(* Удаление *)
let s3 = IntSet.remove 2 s
(* = {1, 3} *)

(* Размер *)
IntSet.cardinal s  (* = 3 *)

(* Объединение *)
IntSet.union (IntSet.of_list [1; 2]) (IntSet.of_list [2; 3])
(* = {1, 2, 3} *)

(* Пересечение *)
IntSet.inter (IntSet.of_list [1; 2; 3]) (IntSet.of_list [2; 3; 4])
(* = {2, 3} *)

(* Разность *)
IntSet.diff (IntSet.of_list [1; 2; 3]) (IntSet.of_list [2])
(* = {1, 3} *)
```

### Итерация

```ocaml
(* Итерация в возрастающем порядке *)
IntSet.iter (Printf.printf "%d ") (IntSet.of_list [3; 1; 2])
(* Выведет: 1 2 3 *)

(* Fold *)
IntSet.fold ( + ) (IntSet.of_list [1; 2; 3]) 0
(* = 6 *)

(* В список *)
IntSet.elements (IntSet.of_list [3; 1; 2])
(* = [1; 2; 3] *)
```

---

## Buffer — буферизованное построение строк

Мутабельный буфер для эффективной конкатенации строк. Используйте вместо `s1 ^ s2 ^ s3 ^ ...`.

### Создание

```ocaml
(* Создать буфер с начальным размером *)
let buf = Buffer.create 16

(* Добавить строку *)
Buffer.add_string buf "Hello, "
Buffer.add_string buf "world!"

(* Получить содержимое *)
Buffer.contents buf
(* = "Hello, world!" *)
```

### Операции

```ocaml
let buf = Buffer.create 16

Buffer.add_string buf "foo"
Buffer.add_char buf ' '
Buffer.add_int buf 42
(* Внутри buf: "foo 42" *)

(* Очистить буфер *)
Buffer.reset buf
Buffer.length buf  (* = 0 *)

(* Использовать буфер для построения строки *)
let build_csv values =
  let buf = Buffer.create 64 in
  List.iteri (fun i v ->
    if i > 0 then Buffer.add_char buf ',';
    Buffer.add_string buf v
  ) values;
  Buffer.contents buf

build_csv ["apple"; "banana"; "cherry"]
(* = "apple,banana,cherry" *)
```

```admonish tip title="Производительность"
Конкатенация строк через `^` — O(n) на каждую операцию, так как создаётся новая строка. При построении большой строки из множества фрагментов используйте `Buffer` — O(1) амортизированное время добавления.
```

---

## Format — форматированный вывод

Модуль для pretty-printing с управлением разрывами строк и отступами.

### Базовое использование

```ocaml
(* Печать в stdout *)
Format.printf "Значение: %d@." 42
(* @. — завершить строку и сбросить буфер *)

(* Печать в строку *)
Format.asprintf "x = %d, y = %d" 10 20
(* = "x = 10, y = 20" *)
```

### Форматные строки

| Спецификатор | Тип | Описание |
|--------------|-----|----------|
| `%d` | `int` | Целое число |
| `%s` | `string` | Строка |
| `%f` | `float` | Число с плавающей точкой |
| `%b` | `bool` | Boolean (`true`/`false`) |
| `%a` | `'a printer` | Custom printer |
| `@.` | — | Перевод строки + flush |
| `@,` | — | Место для разрыва строки (если не влезает) |
| `@[` `@]` | — | Открыть/закрыть "box" (группировка) |

### Pretty-printing с boxes

```ocaml
(* Вертикальная группировка *)
Format.printf "@[<v>Line 1@,Line 2@,Line 3@]@."
(* Выведет:
   Line 1
   Line 2
   Line 3
*)

(* Горизонтальная группировка (или вертикальная, если не влезает) *)
Format.printf "@[<hov 2>let x =@ 1 +@ 2 +@ 3@]@."
(* Если влезает: let x = 1 + 2 + 3
   Если нет:
   let x =
     1 +
     2 +
     3
*)
```

### Custom printers

```ocaml
type point = { x : int; y : int }

let pp_point fmt p =
  Format.fprintf fmt "(%d, %d)" p.x p.y

let p = { x = 10; y = 20 }
Format.printf "Point: %a@." pp_point p
(* Выведет: Point: (10, 20) *)
```

```admonish info title="Подробнее"
Модуль `Format` — мощный инструмент для форматированного вывода. Подробнее: [OCaml Manual: Format](https://v2.ocaml.org/api/Format.html).
```

---

## String и Bytes

`String` — иммутабельные строки. `Bytes` — мутабельные байтовые последовательности.

### String

```ocaml
(* Длина *)
String.length "hello"  (* = 5 *)

(* Доступ к символу *)
"hello".[0]  (* = 'h' *)
String.get "hello" 0  (* = 'h' *)

(* Подстрока *)
String.sub "hello world" 0 5  (* = "hello" *)

(* Конкатенация *)
"foo" ^ "bar"  (* = "foobar" *)
String.concat ", " ["a"; "b"; "c"]  (* = "a, b, c" *)

(* Разделение *)
String.split_on_char ',' "a,b,c"  (* = ["a"; "b"; "c"] *)

(* Изменение регистра *)
String.uppercase_ascii "hello"  (* = "HELLO" *)
String.lowercase_ascii "HELLO"  (* = "hello" *)

(* Trim — удалить пробелы с краёв *)
String.trim "  hello  "  (* = "hello" *)

(* Проверка префикса/суффикса (OCaml 4.13+) *)
String.starts_with ~prefix:"http" "https://example.com"  (* = false *)
String.ends_with ~suffix:".ml" "main.ml"  (* = true *)
```

### Bytes

```ocaml
(* Создать из строки *)
let b = Bytes.of_string "hello"

(* Изменить символ *)
Bytes.set b 0 'H'
(* b = "Hello" *)

(* В строку *)
Bytes.to_string b  (* = "Hello" *)

(* Создать неинициализированный буфер *)
let buf = Bytes.create 10
```

```admonish warning title="String vs Bytes"
До OCaml 4.02 строки были мутабельными. Теперь для изменяемых строк используйте `Bytes`. Если вам нужно модифицировать строку, преобразуйте её в `Bytes`, изменяйте и преобразуйте обратно.
```

---

## Option и Result

Стандартные типы для обработки отсутствующих значений и ошибок.

### Option

```ocaml
type 'a option = None | Some of 'a

(* Создание *)
let x = Some 42
let y = None

(* Базовые функции *)
Option.is_some x  (* = true *)
Option.is_none y  (* = true *)

Option.value x ~default:0  (* = 42 *)
Option.value y ~default:0  (* = 0 *)

(* Map — применить функцию к значению внутри Some *)
Option.map (fun x -> x * 2) (Some 5)  (* = Some 10 *)
Option.map (fun x -> x * 2) None  (* = None *)

(* Bind — монадическая композиция *)
Option.bind (Some 5) (fun x -> if x > 0 then Some (x * 2) else None)
(* = Some 10 *)

(* Операторы (OCaml 4.08+) *)
let ( let* ) = Option.bind

let* x = Some 10 in
let* y = Some 20 in
Some (x + y)
(* = Some 30 *)
```

### Result

```ocaml
type ('a, 'e) result = Ok of 'a | Error of 'e

(* Создание *)
let success = Ok 42
let failure = Error "something went wrong"

(* Базовые функции *)
Result.is_ok success  (* = true *)
Result.is_error failure  (* = true *)

(* Map *)
Result.map (fun x -> x * 2) (Ok 5)  (* = Ok 10 *)
Result.map (fun x -> x * 2) (Error "err")  (* = Error "err" *)

(* Map_error — преобразовать ошибку *)
Result.map_error String.uppercase_ascii (Error "fail")
(* = Error "FAIL" *)

(* Bind *)
Result.bind (Ok 5) (fun x ->
  if x > 0 then Ok (x * 2) else Error "negative"
)
(* = Ok 10 *)

(* Операторы *)
let ( let* ) = Result.bind

let divide x y =
  if y = 0 then Error "division by zero" else Ok (x / y)

let* a = divide 10 2 in
let* b = divide a 5 in
Ok b
(* = Ok 1 *)
```

```admonish tip title="Когда использовать"
- **Option** — для отсутствующих значений (например, поиск в списке).
- **Result** — для операций, которые могут завершиться с ошибкой (парсинг, валидация, I/O).
```

---

## Заключение

Стандартная библиотека OCaml предоставляет надёжные и эффективные структуры данных. Основные принципы:

- **Списки** — иммутабельные, линейный доступ. Используйте для рекурсивной обработки.
- **Массивы** — мутабельные, O(1) доступ. Используйте для индексированных данных.
- **Hashtbl** — мутабельные хеш-таблицы, O(1) среднее. Для быстрого доступа по ключу.
- **Map/Set** — иммутабельные, O(log n), упорядоченные. Для функциональных паттернов.
- **Buffer** — эффективное построение строк из фрагментов.
- **Format** — форматированный вывод с управлением разрывами строк.
- **Option/Result** — безопасная обработка отсутствующих значений и ошибок.

Для углублённого изучения: [OCaml API Reference](https://v2.ocaml.org/api/index.html).
