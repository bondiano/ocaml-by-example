# Конвенции OCaml

Соглашения сообщества OCaml: именование, модули, pattern matching, обработка ошибок, форматирование.

## Содержание

- [Именование](#именование)
- [Модули](#модули)
- [Pattern matching](#pattern-matching)
- [Exceptions vs Result](#exceptions-vs-result)
- [Мутабельность](#мутабельность)
- [Форматирование](#форматирование)

---

## Именование

В OCaml используется `snake_case` для всего, кроме модулей и конструкторов (они пишутся с заглавной буквы):

```ocaml
(* Хорошо *)
let max_value = 100
let find_first_match xs = ...

(* Плохо *)
let maxValue = 100
let FindFirstMatch xs = ...
```

**`type t` — основной тип в модуле.** По конвенции, если модуль представляет один тип, этот тип называется `t`:

```ocaml
module User = struct
  type t = {
    name : string;
    age : int;
  }

  let create name age = { name; age }
end
```

**Конструкторы: `create`, `make`, `init`** — у каждого своя семантика:

- `create` — аллокация без инициализации содержимого:

```ocaml
let buf = Bytes.create 10
(* 10 байт, содержимое не определено *)
```

- `make` — инициализация одним значением:

```ocaml
let arr = Array.make 3 "x"
(* [| "x"; "x"; "x" |] *)
```

- `init` — инициализация функцией от индекса:

```ocaml
let arr = Array.init 3 (Printf.sprintf "x%d")
(* [| "x0"; "x1"; "x2" |] *)
```

**`of_x` / `to_x` — конвертация** между типами:

```ocaml
let s = String.of_seq (List.to_seq ['h'; 'i'])
(* "hi" *)

let n = int_of_string "42"
let s = string_of_int 42
```

**Суффикс `_exn`** обозначает функции, которые бросают исключения вместо возврата `option` или `result`. В стандартной библиотеке эта конвенция соблюдается не везде — некоторые старые функции бросают исключения без суффикса:

```ocaml
(* Stdlib: find_opt возвращает option, find бросает исключение (без _exn) *)
let x = List.find_opt (fun n -> n > 10) [1; 5; 20]
(* Some 20 *)
let y = List.find (fun n -> n > 10) [1; 2; 3]
(* Exception: Not_found *)

(* Конвенция _exn: int_of_string_opt / int_of_string *)
let a = int_of_string_opt "abc"   (* None *)
let b = int_of_string "abc"       (* Exception: Failure "int_of_string" *)

(* В библиотеках Base/Core суффикс _exn используется последовательно:
   List.find      : 'a list -> f:('a -> bool) -> 'a option
   List.find_exn  : 'a list -> f:('a -> bool) -> 'a       *)
```

---

## Модули

**Каждый значимый тип — в своём модуле.** Это основная единица организации кода в OCaml:

```ocaml
(* user.ml *)
type t = { name : string; email : string }

let create name email = { name; email }
let to_string u = Printf.sprintf "%s <%s>" u.name u.email
```

**Пишите `.mli` для публичных модулей.** Интерфейсный файл делает API явным и скрывает детали реализации:

```ocaml
(* user.mli *)
type t

val create : string -> string -> t
val to_string : t -> string
```

**Избегайте `open`, используйте qualified names.** Сразу видно, откуда пришла функция:

```ocaml
(* Хорошо — видно, что length из String *)
let n = String.length s

(* Хуже — непонятно, откуда length *)
open String
let n = length s
```

Исключение — модули, предназначенные для `open`: `Format`, `Effect.Deep` и подобные.

---

## Pattern matching

**Не используйте `hd` / `tl` — только pattern matching:**

```ocaml
(* Хорошо *)
let first_or_default default = function
  | x :: _ -> x
  | [] -> default

(* Плохо *)
let first_or_default default lst =
  if lst = [] then default
  else List.hd lst
```

**Не используйте catch-all `_` на конкретных типах — перечисляйте все конструкторы.** При добавлении нового конструктора компилятор укажет на все места, которые нужно обновить:

```ocaml
type color = Red | Green | Blue

(* Хорошо — компилятор предупредит, если добавится Yellow *)
let to_string = function
  | Red -> "red"
  | Green -> "green"
  | Blue -> "blue"

(* Плохо — добавление Yellow пройдёт незамеченным *)
let to_string = function
  | Red -> "red"
  | _ -> "other"
```

**Все клозы начинаются с `|`, включая первый:**

```ocaml
(* Хорошо *)
let describe = function
  | 0 -> "zero"
  | 1 -> "one"
  | _ -> "many"

(* Хуже — первый клоз без | *)
let describe = function
    0 -> "zero"
  | 1 -> "one"
  | _ -> "many"
```

**Не выравнивайте стрелки `->` между клозами:**

```ocaml
(* Хорошо *)
let f = function
  | Some x -> x + 1
  | None -> 0

(* Плохо — лишние пробелы для выравнивания *)
let f = function
  | Some x -> x + 1
  | None   -> 0
```

---

## Exceptions vs Result

**Exceptions** — для действительно исключительных ситуаций и performance-critical путей:

```ocaml
(* Исключение — программная ошибка, не должно происходить *)
let head = function
  | x :: _ -> x
  | [] -> invalid_arg "head: empty list"

(* Исключение — для производительности в горячем цикле *)
exception Found of int

let find_index pred arr =
  try
    for i = 0 to Array.length arr - 1 do
      if pred arr.(i) then raise (Found i)
    done;
    None
  with Found i -> Some i
```

**Result** — для ожидаемых ошибок и composable error handling:

```ocaml
let parse_int s =
  match int_of_string_opt s with
  | Some n -> Ok n
  | None -> Error (Printf.sprintf "not an integer: %s" s)

let parse_positive s =
  parse_int s
  |> Result.bind (fun n ->
    if n > 0 then Ok n
    else Error (Printf.sprintf "not positive: %d" n))
```

Суффикс **`_exn`** служит маркером: если есть `find` (возвращает `option`) и `find_exn` (бросает исключение), имя явно предупреждает о поведении.

---

## Мутабельность

**Immutable по умолчанию.** Используйте `ref` и `mutable` только когда это осознанно необходимо:

```ocaml
(* Хорошо — иммутабельно *)
let sum lst = List.fold_left ( + ) 0 lst

(* Допустимо — ref для локальной оптимизации *)
let sum_imperative lst =
  let acc = ref 0 in
  List.iter (fun x -> acc := !acc + x) lst;
  !acc

(* mutable — когда семантика требует изменяемости *)
type counter = { mutable count : int }

let increment c = c.count <- c.count + 1
```

---

## Форматирование

Основные правила:

- **Максимум 80--90 колонок** в строке.
- **Без табов** — только пробелы.
- **Пробелы вокруг операторов**, после запятых и `;`:

```ocaml
(* Хорошо *)
let x = a + b
let pair = (1, 2, 3)
let record = { name = "Alice"; age = 30 }

(* Плохо *)
let x=a+b
let pair = (1,2,3)
let record = {name="Alice";age=30}
```

- **Кортежи в скобках:**

```ocaml
(* Хорошо *)
let point = (1, 2, 3)

(* Плохо *)
let point = 1, 2, 3
```

- **Пробел вокруг `::`:**

```ocaml
(* Хорошо *)
let lst = x :: rest

(* Плохо *)
let lst = x::rest
```

- **Функции в пределах одного экрана** (~70 строк). Длинные функции разбивайте на вспомогательные.

Для автоматического форматирования используйте **ocamlformat** — подробнее в [приложении «Инструменты»](appendix_e.md#ocamlformat).
