# Быстрый обзор языка

## Цели главы

Прежде чем погружаться в детали, полезно увидеть язык целиком. В этой главе мы бегло пройдёмся по основным конструкциям OCaml --- без упражнений, но с большим количеством примеров. Цель --- сформировать общую картину и подготовиться к следующим главам, где каждая тема будет разобрана подробно.

Что мы рассмотрим:

- Базовые типы: `int`, `float`, `string`, `bool`, `char`.
- Работу со строками и форматный вывод через `Printf`.
- Списки и кортежи.
- Let-привязки и область видимости.
- Условные выражения `if/then/else`.
- Базовое сопоставление с образцом.
- Чтение из stdin и работу с файлами.

## Базовые типы

OCaml --- язык со строгой статической типизацией. Компилятор выводит типы автоматически, но вы всегда можете указать их явно. Попробуйте в utop:

```text
# 42;;
- : int = 42

# 3.14;;
- : float = 3.14

# "привет";;
- : string = "привет"

# true;;
- : bool = true

# 'x';;
- : char = 'x'
```

```admonish tip title="Для Python-разработчиков"
В Python `42` и `3.14` --- это просто числа, и можно свободно их складывать: `42 + 3.14`.
В OCaml `int` и `float` --- разные типы. Для сложения целых --- `+`, для дробных --- `+.` (с точкой). Конвертация явная: `float_of_int 42 +. 3.14`.
```

### Целые числа и арифметика

```ocaml
let a = 10 + 32          (* 42 *)
let b = 100 - 58         (* 42 *)
let c = 6 * 7            (* 42 *)
let d = 84 / 2           (* 42, целочисленное деление *)
let e = 85 mod 43        (* 42, остаток от деления *)
```

Для чисел с плавающей точкой используются отдельные операторы:

```ocaml
let pi = 3.14159
let tau = pi *. 2.0       (* 6.28318 *)
let half = pi /. 2.0      (* 1.5708 *)
```

```admonish tip title="Для TypeScript-разработчиков"
В TypeScript все числа --- `number` (IEEE 754 double). В OCaml `int` и `float` --- разные типы, и смешивать их нельзя. Это ловит целый класс ошибок на этапе компиляции.
```

### Логические значения

```ocaml
let is_valid = true
let is_empty = false

(* Логические операторы --- короткие замыкания *)
let both = is_valid && not is_empty   (* true *)
let either = is_valid || is_empty     (* true *)
```

### Строки и символы

Строки (`string`) --- последовательности байтов, символы (`char`) --- одиночные байты:

```ocaml
let greeting = "Hello, OCaml!"
let first_char = greeting.[0]         (* 'H' *)
let length = String.length greeting   (* 13 *)
```

Конкатенация строк --- оператор `^`:

```ocaml
let full = "Hello" ^ ", " ^ "world!"  (* "Hello, world!" *)
```

Модуль `String` предоставляет полезные функции:

```ocaml
let upper = String.uppercase_ascii "hello"   (* "HELLO" *)
let lower = String.lowercase_ascii "HELLO"   (* "hello" *)
let sub = String.sub "abcdef" 1 3            (* "bcd" *)
let trimmed = String.trim "  hello  "        (* "hello" *)
```

```admonish tip title="Для Python-разработчиков"
В Python строки --- это объекты с методами: `"hello".upper()`.
В OCaml строки --- обычные значения, а функции находятся в модуле `String`: `String.uppercase_ascii "hello"`. Это типичный ФП-подход: данные и функции разделены.
```

## Printf и форматный вывод

Для простого вывода строки используйте `print_endline`:

```ocaml
let () = print_endline "Hello, world!"
```

Для форматного вывода --- `Printf.printf`:

```ocaml
let () =
  let name = "OCaml" in
  let version = 5 in
  Printf.printf "Язык: %s, версия: %d\n" name version
```

Основные спецификаторы формата:

| Спецификатор | Тип | Пример |
|---|---|---|
| `%d` | `int` | `Printf.printf "%d" 42` |
| `%f` | `float` | `Printf.printf "%.2f" 3.14` |
| `%s` | `string` | `Printf.printf "%s" "hi"` |
| `%b` | `bool` | `Printf.printf "%b" true` |
| `%c` | `char` | `Printf.printf "%c" 'x'` |

```admonish tip title="Для Python-разработчиков"
`Printf.printf` в OCaml похож на f-строки Python, но с важным отличием: **формат проверяется на этапе компиляции**. Если написать `Printf.printf "%d" "hello"`, код не скомпилируется --- компилятор знает, что `%d` ожидает `int`, а не `string`.
```

Для форматирования строки без вывода используйте `Printf.sprintf`:

```ocaml
let msg = Printf.sprintf "Результат: %d" (6 * 7)
(* msg = "Результат: 42" *)
```

## Let-привязки и область видимости

В OCaml значения связываются с именами через `let`:

```ocaml
let x = 42
let y = x + 1   (* 43 *)
```

Let-выражение с `in` создаёт локальную привязку:

```ocaml
let result =
  let a = 10 in
  let b = 32 in
  a + b
(* result = 42, a и b недоступны за пределами выражения *)
```

Привязки неизменяемы. «Переопределение» создаёт новую привязку, затеняя (shadowing) предыдущую:

```ocaml
let x = 1
let x = x + 1   (* новая привязка x = 2, старый x = 1 больше недоступен *)
```

```admonish tip title="Для Python/TS-разработчиков"
Затенение в OCaml --- это не мутация. Каждый `let` создаёт новую неизменяемую привязку. Это похоже на `const` в TypeScript, но без возможности `let` для переменных. Для мутации в OCaml используются ссылки (`ref`) --- мы рассмотрим их в главе 9.
```

## Условные выражения

`if/then/else` в OCaml --- это **выражение**, возвращающее значение:

```ocaml
let abs_value x =
  if x >= 0 then x
  else -x

let category age =
  if age < 13 then "ребёнок"
  else if age < 18 then "подросток"
  else "взрослый"
```

```admonish tip title="Для TypeScript-разработчиков"
В TypeScript есть оператор `if` и тернарный оператор `? :`. В OCaml `if/then/else` --- всегда выражение, как тернарный оператор, но читается лучше. Обе ветви должны возвращать значения одного типа.
```

## Списки

Список --- основная структура данных для коллекций в OCaml. Все элементы должны быть одного типа:

```ocaml
let nums = [1; 2; 3; 4; 5]
let empty = []
let words = ["hello"; "world"]
```

Добавление элемента в начало --- оператор `::` (cons):

```ocaml
let extended = 0 :: nums   (* [0; 1; 2; 3; 4; 5] *)
```

Конкатенация списков --- оператор `@`:

```ocaml
let combined = [1; 2] @ [3; 4]   (* [1; 2; 3; 4] *)
```

Модуль `List` предоставляет множество функций:

```ocaml
let len = List.length nums              (* 5 *)
let doubled = List.map (fun x -> x * 2) nums   (* [2; 4; 6; 8; 10] *)
let evens = List.filter (fun x -> x mod 2 = 0) nums  (* [2; 4] *)
let sum = List.fold_left ( + ) 0 nums   (* 15 *)
let found = List.find_opt (fun x -> x > 3) nums  (* Some 4 *)
```

```admonish tip title="Для Python-разработчиков"
В Python: `[x * 2 for x in nums]`. В OCaml: `List.map (fun x -> x * 2) nums`.
В Python: `[x for x in nums if x % 2 == 0]`. В OCaml: `List.filter (fun x -> x mod 2 = 0) nums`.
В Python: `sum(nums)`. В OCaml: `List.fold_left ( + ) 0 nums`.
Подробно `map`, `filter` и `fold` разберём в главе 6.
```

## Кортежи

Кортеж (tuple) --- фиксированный набор значений, возможно, разных типов:

```ocaml
let pair = (1, "one")              (* int * string *)
let triple = (3.14, true, "pi")    (* float * bool * string *)
```

Доступ к элементам --- через `fst`/`snd` (для пар) или через деструктуризацию:

```ocaml
let (x, y) = pair    (* x = 1, y = "one" *)
let first = fst pair  (* 1 *)
let second = snd pair (* "one" *)
```

```admonish tip title="Для Python-разработчиков"
Кортежи OCaml работают так же, как в Python: `(1, "one")`. Деструктуризация тоже аналогична: `x, y = (1, "one")` в Python vs `let (x, y) = (1, "one")` в OCaml. Ключевое отличие: в OCaml тип кортежа фиксирует количество и типы элементов на этапе компиляции.
```

## Функции

Функции определяются через `let`:

```ocaml
let square x = x * x
let add a b = a + b
```

Анонимные функции (лямбды) --- через `fun`:

```ocaml
let double = fun x -> x * 2
```

Функции в OCaml каррированы: функция от нескольких аргументов --- это цепочка функций от одного аргумента:

```ocaml
let add a b = a + b
let add5 = add 5       (* частичное применение *)
let result = add5 3     (* 8 *)
```

Оператор конвейера `|>` передаёт значение слева как последний аргумент:

```ocaml
let result =
  [1; 2; 3; 4; 5]
  |> List.filter (fun x -> x mod 2 = 0)
  |> List.map (fun x -> x * 10)
  |> List.fold_left ( + ) 0
(* result = 60 *)
```

```admonish tip title="Для TypeScript-разработчиков"
Оператор `|>` в OCaml аналогичен цепочке методов в TypeScript:
```typescript
[1, 2, 3, 4, 5]
  .filter(x => x % 2 === 0)
  .map(x => x * 10)
  .reduce((a, b) => a + b, 0)
```
В TypeScript методы привязаны к объектам; в OCaml `|>` работает с любыми функциями.
```

## Сопоставление с образцом

Pattern matching --- одна из самых мощных возможностей OCaml:

```ocaml
let describe_number n =
  match n with
  | 0 -> "ноль"
  | 1 -> "один"
  | n when n < 0 -> "отрицательное"
  | _ -> "другое положительное"
```

Сопоставление со списками:

```ocaml
let describe_list lst =
  match lst with
  | [] -> "пустой"
  | [x] -> Printf.sprintf "один элемент: %d" x
  | [x; y] -> Printf.sprintf "два элемента: %d и %d" x y
  | _ -> "много элементов"
```

Компилятор проверяет полноту сопоставления --- если вы забыли случай, он предупредит:

```text
Warning 8: this pattern-matching is not exhaustive.
```

```admonish tip title="Для TypeScript-разработчиков"
Pattern matching в OCaml --- это `switch` на стероидах. В отличие от TypeScript, OCaml проверяет **полноту** сопоставления и **деструктурирует** данные. Это как `switch` + `if` + деструктуризация + проверка полноты --- в одной конструкции.
```

## Тип option

Для представления «может быть значение, а может не быть» OCaml использует `option`:

```ocaml
let find_positive lst =
  List.find_opt (fun x -> x > 0) lst

let () =
  match find_positive [-1; -2; 3] with
  | Some x -> Printf.printf "Нашли: %d\n" x
  | None -> print_endline "Не нашли"
```

```admonish tip title="Для TypeScript-разработчиков"
`option` в OCaml --- это типобезопасная замена `null`/`undefined`. Вместо `string | null` в TypeScript, OCaml использует `string option`. Компилятор **заставляет** обработать оба случая (`Some` и `None`), что исключает null pointer exceptions.
```

## Чтение из stdin

Для чтения строки из стандартного ввода:

```ocaml
let () =
  print_string "Как вас зовут? ";
  let name = read_line () in
  Printf.printf "Привет, %s!\n" name
```

Для чтения числа:

```ocaml
let () =
  print_string "Введите число: ";
  let n = read_line () |> int_of_string in
  Printf.printf "Квадрат: %d\n" (n * n)
```

## Работа с файлами

OCaml 5.4 предоставляет модули `In_channel` и `Out_channel` для работы с файлами:

```ocaml
(* Чтение всего файла в строку *)
let contents = In_channel.with_open_text "input.txt" In_channel.input_all

(* Чтение файла построчно *)
let lines =
  In_channel.with_open_text "input.txt" (fun ic ->
    let rec read_all acc =
      match In_channel.input_line ic with
      | Some line -> read_all (line :: acc)
      | None -> List.rev acc
    in
    read_all [])
```

Запись в файл:

```ocaml
let () =
  Out_channel.with_open_text "output.txt" (fun oc ->
    Out_channel.output_string oc "Hello, file!\n";
    Printf.fprintf oc "Число: %d\n" 42)
```

```admonish tip title="Для Python-разработчиков"
Конструкция `In_channel.with_open_text "file" f` аналогична `with open("file") as f:` в Python --- она гарантирует закрытие файла даже при исключении.
```

## Unit и побочные эффекты

Тип `unit` имеет единственное значение `()`. Он используется, когда функция выполняет побочный эффект и не возвращает полезного значения:

```ocaml
let greet name =
  Printf.printf "Привет, %s!\n" name
(* greet : string -> unit *)
```

Привязка `let () = ...` говорит «выполни это выражение ради его побочного эффекта»:

```ocaml
let () = print_endline "Программа запущена"
```

Для выполнения нескольких действий подряд используется `;`:

```ocaml
let () =
  print_endline "первое";
  print_endline "второе";
  print_endline "третье"
```

## Что дальше

Это был быстрый обзор основных конструкций OCaml. Не переживайте, если что-то осталось непонятным --- каждая тема будет подробно разобрана в следующих главах:

- **Глава 4** --- функции, записи, каррирование и `option`.
- **Глава 5** --- алгебраические типы данных и сопоставление с образцом.
- **Глава 6** --- рекурсия, `map`, `filter` и свёртки.
- **Глава 7** --- модули, сигнатуры и функторы.
- **Глава 8** --- обработка ошибок.

В следующей главе мы подробно разберём функции и записи --- два строительных блока программ на OCaml.
