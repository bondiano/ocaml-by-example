# Обработка ошибок и валидация

## Цели главы

В этой главе мы подробно изучим идиоматическую обработку ошибок в OCaml:

- Тип `option` --- когда значения может не быть.
- Тип `result` --- когда нужна информация об ошибке.
- **Let-операторы** (`let*`, `let+`) --- синтаксический сахар для цепочек вычислений.
- **Накопление ошибок** --- паттерн, аналогичный аппликативной валидации Haskell.
- **Исключения** vs `result` --- когда что использовать.
- Проект: валидация формы.

## Подготовка проекта

Код этой главы находится в `exercises/chapter08`. Соберите проект:

```text
$ cd exercises/chapter08
$ dune build
```

## Тип `option`: подробно

Мы уже знакомы с `option` из главы 5. Теперь рассмотрим его использование как инструмент обработки ошибок.

### Проблема: цепочки `option`

Допустим, нам нужно извлечь значение из вложенной структуры:

```ocaml
type user = { name : string; address : address option }
and address = { city : string; zip : string option }
```

Чтобы получить почтовый индекс пользователя, нужно проверить каждый уровень:

```ocaml
let get_zip user =
  match user.address with
  | None -> None
  | Some addr ->
    match addr.zip with
    | None -> None
    | Some z -> Some z
```

Вложенные `match` быстро становятся нечитаемыми. Решение --- `Option.bind`.

### `Option.bind` --- цепочка вычислений

```ocaml
let get_zip user =
  Option.bind user.address (fun addr -> addr.zip)
```

`Option.bind opt f` --- если `opt` = `Some x`, вызывает `f x`. Если `opt` = `None`, возвращает `None`. Это позволяет строить цепочки:

```ocaml
let get_zip user =
  user.address
  |> Option.bind (fun addr -> addr.zip)
```

Для более длинных цепочек:

```ocaml
let process user =
  user.address
  |> Option.bind (fun addr -> addr.zip)
  |> Option.map (fun zip -> "ZIP: " ^ zip)
  |> Option.value ~default:"нет индекса"
```

## Тип `result`: подробно

`option` не объясняет **почему** значения нет. `result` добавляет информацию об ошибке:

```ocaml
type ('a, 'e) result = Ok of 'a | Error of 'e
```

### Создание результатов

```ocaml
let parse_int s =
  match int_of_string_opt s with
  | Some n -> Ok n
  | None -> Error ("не число: " ^ s)

let non_negative n =
  if n >= 0 then Ok n
  else Error ("отрицательное число: " ^ string_of_int n)
```

```text
# parse_int "42";;
- : (int, string) result = Ok 42

# parse_int "abc";;
- : (int, string) result = Error "не число: abc"
```

### `Result.bind` --- цепочка

```ocaml
let parse_positive s =
  Result.bind (parse_int s) non_negative
```

Или через `|>`:

```ocaml
let parse_positive s =
  parse_int s
  |> Result.bind non_negative
```

```text
# parse_positive "42";;
- : (int, string) result = Ok 42

# parse_positive "-5";;
- : (int, string) result = Error "отрицательное число: -5"

# parse_positive "abc";;
- : (int, string) result = Error "не число: abc"
```

Цепочка прерывается на первой ошибке --- это поведение **fail-fast** (как `Either` в Haskell).

```admonish tip title="Для Python/TS-разработчиков"
`result` в OCaml решает ту же проблему, что `try/except` в Python и `try/catch` в TypeScript, но на уровне типов. Вместо `try: x = parse_int(s) except ValueError: ...` вы пишете `match parse_int s with Ok n -> ... | Error e -> ...`. Ключевое преимущество: тип `(int, string) result` в сигнатуре **явно говорит**, что функция может вернуть ошибку. В Python `def parse_int(s: str) -> int` скрывает возможность `ValueError`.
```

### `Result.map`

```ocaml
let double_positive s =
  parse_positive s
  |> Result.map (fun n -> n * 2)
```

`Result.map f r` --- если `r = Ok x`, возвращает `Ok (f x)`. Если `r = Error e`, возвращает `Error e` без изменений.

## Let-операторы

Цепочки `Result.bind` работают, но выглядят громоздко. **Let-операторы** (binding operators) --- синтаксический сахар, делающий код линейным:

### Определение let-операторов

```ocaml
let ( let* ) = Result.bind
let ( let+ ) x f = Result.map f x
```

- `let*` --- bind (цепочка с возможной ошибкой).
- `let+` --- map (преобразование успешного результата).

### Использование

```ocaml
let parse_and_sum a b =
  let* x = parse_int a in
  let* y = parse_int b in
  Ok (x + y)
```

Это эквивалентно:

```ocaml
let parse_and_sum a b =
  Result.bind (parse_int a) (fun x ->
    Result.bind (parse_int b) (fun y ->
      Ok (x + y)))
```

Let-операторы превращают вложенную структуру в линейную последовательность шагов, читающуюся сверху вниз.

```admonish tip title="Для TypeScript-разработчиков"
Let-операторы `let*` в OCaml напоминают `async/await` в TypeScript. Как `await` «разворачивает» `Promise`, так `let*` «разворачивает» `Result`. Сравните: в TS `const x = await parseAsync(a); const y = await parseAsync(b); return x + y;` --- и в OCaml `let* x = parse_int a in let* y = parse_int b in Ok (x + y)`. Структура кода практически одинакова, но `let*` работает не только с асинхронностью, а с любым типом-обёрткой: `option`, `result`, и даже пользовательскими.
```

### Сравнение с do-нотацией Haskell

```
-- Haskell (do-нотация)
parseAndSum a b = do
  x <- parseInt a
  y <- parseInt b
  return (x + y)
```

```ocaml
(* OCaml (let-операторы) *)
let parse_and_sum a b =
  let* x = parse_int a in
  let* y = parse_int b in
  Ok (x + y)
```

Структура практически идентична. `let*` соответствует `<-`, `Ok` соответствует `return`.

### Let-операторы для `option`

Аналогично можно определить let-операторы для `option`:

```ocaml
let ( let* ) = Option.bind
let ( let+ ) x f = Option.map f x
```

```ocaml
let get_zip user =
  let* addr = user.address in
  addr.zip
```

### Область видимости

Let-операторы --- обычные значения OCaml. Они подчиняются обычным правилам области видимости. Чтобы не путать `let*` для `option` и `result`, определяйте их в отдельных модулях:

```ocaml
module Option_syntax = struct
  let ( let* ) = Option.bind
  let ( let+ ) x f = Option.map f x
end

module Result_syntax = struct
  let ( let* ) = Result.bind
  let ( let+ ) x f = Result.map f x
end
```

Использование:

```ocaml
let get_zip user =
  let open Option_syntax in
  let* addr = user.address in
  addr.zip

let parse_and_sum a b =
  let open Result_syntax in
  let* x = parse_int a in
  let* y = parse_int b in
  Ok (x + y)
```

## Накопление ошибок

`Result.bind` (и `let*`) прерывает цепочку на **первой** ошибке. Но иногда нужно собрать **все** ошибки --- например, при валидации формы.

В Haskell для этого используется аппликативный функтор `Validation`. В OCaml мы реализуем тот же паттерн проще:

### Подход: список валидаций

```ocaml
let validate_all validations input =
  let errors =
    List.filter_map (fun validate ->
      match validate input with
      | Ok () -> None
      | Error e -> Some e
    ) validations
  in
  match errors with
  | [] -> Ok input
  | es -> Error es
```

Каждая валидация --- функция `'a -> (unit, string) result`. Мы запускаем **все** валидации и собираем ошибки:

```ocaml
let non_empty field_name value =
  if String.length value = 0 then Error (field_name ^ " не может быть пустым")
  else Ok ()

let min_length field_name n value =
  if String.length value < n then
    Error (field_name ^ " должен быть не короче " ^ string_of_int n ^ " символов")
  else Ok ()

let validate_name name =
  validate_all [
    non_empty "Имя";
    min_length "Имя" 2;
  ] name
```

```text
# validate_name "";;
- : (string, string list) result =
Error ["Имя не может быть пустым"; "Имя должен быть не короче 2 символов"]

# validate_name "A";;
- : (string, string list) result = Error ["Имя должен быть не короче 2 символов"]

# validate_name "Иван";;
- : (string, string list) result = Ok "Иван"
```

### Комбинирование валидаций нескольких полей

```ocaml
let combine_results results =
  let oks, errors =
    List.fold_left (fun (oks, errs) r ->
      match r with
      | Ok v -> (v :: oks, errs)
      | Error es -> (oks, es @ errs)
    ) ([], []) results
  in
  match errors with
  | [] -> Ok (List.rev oks)
  | es -> Error es
```

## Исключения vs `result`

OCaml поддерживает оба подхода к ошибкам: исключения и `result`.

### Исключения

```ocaml
exception Invalid_input of string

let parse_int_exn s =
  match int_of_string_opt s with
  | Some n -> n
  | None -> raise (Invalid_input ("не число: " ^ s))
```

Перехват:

```ocaml
let safe_parse s =
  try Ok (parse_int_exn s)
  with Invalid_input msg -> Error msg
```

### Когда что использовать

| Ситуация | Подход | Причина |
|----------|--------|---------|
| Ожидаемая ошибка (ввод пользователя, файл не найден) | `result` | Ошибка --- часть логики, должна быть в типе |
| Программная ошибка (нарушение инварианта, баг) | Исключение | Не должна возникать в корректной программе |
| Высокопроизводительный код | Исключение | Нет аллокации при успехе (zero-cost happy path) |
| API библиотеки | `result` | Пользователь видит все возможные ошибки в типе |
| Локальное восстановление | `result` | Легко обрабатывать через `match` и `let*` |
| Глобальный обработчик (top-level) | Исключение | `try ... with` на верхнем уровне |

### Конвертация

```ocaml
(* result -> exception *)
let unwrap = function
  | Ok x -> x
  | Error msg -> failwith msg

(* exception -> result *)
let try_result f =
  try Ok (f ())
  with exn -> Error (Printexc.to_string exn)
```

Идиоматический OCaml часто предоставляет оба варианта: `List.find` (бросает `Not_found`) и `List.find_opt` (возвращает `option`).

```admonish info title="Подробнее"
Детальное описание обработки ошибок в OCaml: [Real World OCaml, глава «Error Handling»](https://dev.realworldocaml.org/error-handling.html)
```

## Конвертация `option` ↔ `result`

```ocaml
let option_to_result ~error = function
  | Some x -> Ok x
  | None -> Error error

let result_to_option = function
  | Ok x -> Some x
  | Error _ -> None
```

```text
# option_to_result ~error:"не найдено" (Some 42);;
- : (int, string) result = Ok 42

# option_to_result ~error:"не найдено" None;;
- : (int, string) result = Error "не найдено"
```

Также есть `Option.to_result` и `Result.to_option` в стандартной библиотеке.

## Проект: валидация формы

Модуль `lib/validation.ml` реализует систему валидации, объединяющую все концепции главы.

### Типы

```ocaml
type address = {
  street : string;
  city : string;
  state : string;
}

type person = {
  first_name : string;
  last_name : string;
  address : address;
}

type errors = string list
```

### Валидаторы

```ocaml
let non_empty field_name value =
  if String.length (String.trim value) = 0 then
    Error (field_name ^ " не может быть пустым")
  else Ok ()

let max_length field_name n value =
  if String.length value > n then
    Error (field_name ^ " не может быть длиннее " ^ string_of_int n ^ " символов")
  else Ok ()
```

### Валидация с накоплением ошибок

```ocaml
let validate_all validations input =
  let errors = List.filter_map (fun v ->
    match v input with
    | Ok () -> None
    | Error e -> Some e
  ) validations
  in
  match errors with
  | [] -> Ok input
  | es -> Error es

let validate_address street city state =
  let errors =
    (match validate_all [non_empty "Улица"; max_length "Улица" 100] street with
     | Ok _ -> [] | Error es -> es)
    @ (match validate_all [non_empty "Город"; max_length "Город" 50] city with
       | Ok _ -> [] | Error es -> es)
    @ (match validate_all [non_empty "Регион"; max_length "Регион" 50] state with
       | Ok _ -> [] | Error es -> es)
  in
  match errors with
  | [] -> Ok { street; city; state }
  | es -> Error es
```

## Сравнение подходов к обработке ошибок

В OCaml существует несколько подходов к обработке ошибок. Каждый имеет свои компромиссы. Рассмотрим их от простого к наиболее выразительному.

### 1. Исключения

Самый простой подход --- использовать исключения:

```ocaml
let parse_age s =
  let n = int_of_string s in  (* бросает Failure *)
  if n < 0 then failwith "отрицательный возраст"
  else n

let parse_name s =
  if String.length s = 0 then failwith "пустое имя"
  else s
```

**Плюсы:** просто, мало кода, нет оборачивания в `Ok`/`Error`.

**Минусы:** из сигнатуры функции `val parse_age : string -> int` невозможно понять, что она может завершиться ошибкой. Вызывающий код не обязан обрабатывать ошибку --- компилятор не предупредит. Ошибка «невидима» в типе.

### 2. `(_, string) result` --- явная ошибка

```ocaml
let parse_age s : (int, string) result =
  match int_of_string_opt s with
  | None -> Error ("не число: " ^ s)
  | Some n when n < 0 -> Error "отрицательный возраст"
  | Some n -> Ok n

let parse_name s : (string, string) result =
  if String.length s = 0 then Error "пустое имя"
  else Ok s
```

**Плюсы:** ошибка явно указана в типе. Компилятор заставляет обработать `Error`.

**Минусы:** ошибки --- просто строки. Нельзя программно различить «не число» и «отрицательный возраст». Нельзя написать exhaustive match по вариантам ошибок.

### 3. `(_, custom_error) result` --- различимые ошибки

```ocaml
type age_error = NotANumber of string | NegativeAge of int

let parse_age s : (int, age_error) result =
  match int_of_string_opt s with
  | None -> Error (NotANumber s)
  | Some n when n < 0 -> Error (NegativeAge n)
  | Some n -> Ok n

type name_error = EmptyName

let parse_name s : (string, name_error) result =
  if String.length s = 0 then Error EmptyName
  else Ok s
```

**Плюсы:** ошибки различимые, можно pattern match по вариантам. Exhaustive checking --- компилятор предупредит, если забыли обработать вариант.

**Минусы:** **не composable**. Нельзя просто скомпоновать `parse_age` и `parse_name` через `let*`, потому что типы ошибок разные (`age_error` vs `name_error`):

```ocaml
(* Не компилируется: age_error ≠ name_error *)
let parse_person age_str name_str =
  let* age = parse_age age_str in
  let* name = parse_name name_str in
  Ok (name, age)
```

Пришлось бы создавать объединяющий тип и вручную оборачивать ошибки:

```ocaml
type person_error = AgeError of age_error | NameError of name_error

let parse_person age_str name_str =
  let* age = parse_age age_str |> Result.map_error (fun e -> AgeError e) in
  let* name = parse_name name_str |> Result.map_error (fun e -> NameError e) in
  Ok (name, age)
```

Это работает, но требует boilerplate для каждой новой комбинации.

### 4. `(_, [> poly_variant]) result` --- composable, различимые, exhaustive

Полиморфные варианты решают проблему композиции:

```ocaml
let parse_age s : (int, [> `NotANumber of string | `NegativeAge of int]) result =
  match int_of_string_opt s with
  | None -> Error (`NotANumber s)
  | Some n when n < 0 -> Error (`NegativeAge n)
  | Some n -> Ok n

let parse_name s : (string, [> `EmptyName]) result =
  if String.length s = 0 then Error `EmptyName
  else Ok s
```

Теперь композиция работает **без дополнительного кода**:

```ocaml
let parse_person age_str name_str =
  let* age = parse_age age_str in
  let* name = parse_name name_str in
  Ok (name, age)
(* inferred: (string * int, [> `NotANumber of string | `NegativeAge of int | `EmptyName]) result *)
```

**Плюсы:** composable (типы ошибок объединяются автоматически), различимые (можно match), exhaustive (компилятор проверяет полноту).

**Минусы:** более сложные типы в сигнатурах, непривычный синтаксис для новичков.

## Полиморфные варианты для composable ошибок

Рассмотрим подробнее, как использовать полиморфные варианты для построения composable системы ошибок.

### Определение ошибок в модулях

Каждый модуль определяет свой тип ошибок как полиморфный вариант:

```ocaml
module Parser : sig
  type tree = Leaf of string | Node of tree * tree
  type error = [ `SyntaxError of string | `UnexpectedChar of char ]

  val parse : string -> (tree, [> error]) result
end

module Validator : sig
  type error = [ `TooShort of int | `TooLong of int ]

  val validate : Parser.tree -> (Parser.tree, [> error]) result
end
```

Обратите внимание на `[> error]` --- «открытый» полиморфный вариант. Это означает: «содержит как минимум эти варианты, но может содержать и другие». Именно это свойство позволяет типам автоматически объединяться.

### Автоматический union при композиции

Когда мы используем `let*` для цепочки функций с разными типами ошибок, OCaml автоматически вычисляет объединение:

```ocaml
let process_input (source : string) =
  let ( let* ) = Result.bind in
  let* tree = Parser.parse source in
  let* tree = Validator.validate tree in
  Ok tree
(* inferred: (Parser.tree, [> Parser.error | Validator.error ]) result *)
```

Компилятор выведет тип, содержащий **все** возможные варианты ошибок из обоих модулей. Никакого ручного оборачивания или `map_error` не нужно.

### Обработка ошибок

При обработке ошибок можно делать exhaustive match:

```ocaml
let handle result =
  match result with
  | Ok tree -> print_endline "Успех"
  | Error (`SyntaxError msg) -> Printf.printf "Синтаксическая ошибка: %s\n" msg
  | Error (`UnexpectedChar c) -> Printf.printf "Неожиданный символ: %c\n" c
  | Error (`TooShort n) -> Printf.printf "Слишком коротко: %d\n" n
  | Error (`TooLong n) -> Printf.printf "Слишком длинно: %d\n" n
```

Если тип замкнут (закрытый полиморфный вариант `[ ... ]` без `>`), компилятор предупредит, если вы забыли обработать вариант.

## `and*` для параллельного сбора ошибок

`let*` останавливается на первой ошибке (fail-fast). Но иногда нужно собрать **все** ошибки сразу --- например, при валидации формы. Для этого используется оператор `and*`.

### Определение `and*`

```ocaml
let ( and* ) left right =
  match left, right with
  | Ok l, Ok r -> Ok (l, r)
  | Error l, Error r -> Error (l @ r)
  | Error e, _ | _, Error e -> Error e
```

`and*` работает так: если оба результата --- `Ok`, объединяет значения в пару. Если оба --- `Error`, конкатенирует списки ошибок. Если ошибка только в одном --- возвращает её.

### Использование

```ocaml
let validate_name input =
  if String.length input.name = 0 then Error ["имя пустое"]
  else Ok input.name

let validate_age input =
  if input.age < 0 then Error ["возраст отрицательный"]
  else Ok input.age

let validate_email input =
  if not (String.contains input.email '@') then Error ["нет @ в email"]
  else Ok input.email

let validate input =
  let* name = validate_name input
  and* age = validate_age input
  and* email = validate_email input
  in Ok { name; age; email }
```

```admonish tip title="Для Python/TS-разработчиков"
Накопление ошибок решает ту же задачу, что библиотеки валидации вроде `pydantic` в Python или `zod`/`yup` в TypeScript. Например, в `zod` вы пишете `schema.safeParse(data)` и получаете объект с массивом ошибок. В OCaml паттерн с `and*` и `validate_all` даёт то же поведение, но без внешних зависимостей и с проверкой типов на этапе компиляции.
```

Если несколько валидаций провалились, все ошибки будут собраны в один список:

```text
# validate { name = ""; age = -1; email = "bad" };;
- : ... = Error ["имя пустое"; "возраст отрицательный"; "нет @ в email"]
```

### Отличие `let*` от `and*`

- `let*` --- **последовательная** цепочка. Каждый шаг зависит от результата предыдущего. Останавливается на первой ошибке.
- `and*` --- **параллельная** валидация. Все проверки выполняются независимо. Ошибки накапливаются.

Комбинация `let*` и `and*` даёт гибкую систему: зависимые проверки через `let*`, независимые через `and*`.

## Outcome type

Иногда разделение на `Ok` и `Error` слишком грубое. Бывают ситуации, когда операция **успешна, но с предупреждениями** (warnings). Для этого можно использовать тип `outcome`:

```ocaml
type ('ok, 'warning) outcome = {
  result : 'ok option;
  errors : 'warning list;
}
```

Поле `result` содержит `Some value`, если операция успешна (возможно, с предупреждениями), или `None`, если провалилась. Поле `errors` содержит список предупреждений или ошибок.

### Конструкторы

```ocaml
let outcome_ok ?(warnings = []) result =
  { result = Some result; warnings }

let outcome_fail warnings =
  { result = None; warnings }
```

### Пример использования

```ocaml
let validate_password password =
  let warnings = [] in
  let warnings =
    if String.length password < 12 then
      "рекомендуется пароль длиннее 12 символов" :: warnings
    else warnings
  in
  let warnings =
    if not (String.exists (fun c -> c >= '0' && c <= '9') password) then
      "рекомендуется добавить цифры" :: warnings
    else warnings
  in
  if String.length password < 6 then
    outcome_fail ["пароль слишком короткий"]
  else
    outcome_ok ~warnings:(List.rev warnings) password
```

```text
# validate_password "abc";;
- : (string, string) outcome =
  { result = None; errors = ["пароль слишком короткий"] }

# validate_password "abcdef";;
- : (string, string) outcome =
  { result = Some "abcdef";
    errors = ["рекомендуется пароль длиннее 12 символов";
              "рекомендуется добавить цифры"] }

# validate_password "myStr0ngPa55word";;
- : (string, string) outcome =
  { result = Some "myStr0ngPa55word"; errors = [] }
```

Outcome полезен для recoverable errors --- ситуаций, где операция может продолжиться, но стоит предупредить пользователя.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Среднее)** Реализуйте функцию `validate_phone`, которая проверяет телефонный номер. Номер валиден, если: непустой, все символы --- цифры, длина >= 7.

    ```ocaml
    val validate_phone : string -> (string, string list) result
    ```

    Используйте `validate_all` из библиотеки. Функция должна накапливать все ошибки.

    *Подсказка:* для проверки символов используйте `String.for_all` (OCaml >= 4.13) или `String.iter` с `ref`.

2. **(Среднее)** Реализуйте функцию `validate_person`, которая валидирует все поля персоны и накапливает ошибки.

    ```ocaml
    val validate_person :
      string -> string -> string -> string -> string ->
      (person, string list) result
    ```

    Аргументы: first_name, last_name, street, city, state. Используйте `non_empty` из библиотеки.

    *Подсказка:* соберите ошибки из всех полей через конкатенацию списков.

3. **(Среднее)** Реализуйте функцию `traverse_result`, которая применяет функцию к каждому элементу списка, собирая все успехи или все ошибки.

    ```ocaml
    val traverse_result :
      ('a -> ('b, 'e) result) -> 'a list -> ('b list, 'e list) result
    ```

    Если все вызовы вернули `Ok` --- возвращает `Ok` со списком результатов. Если хотя бы один вернул `Error` --- возвращает `Error` со списком всех ошибок.

    *Подсказка:* используйте `List.fold_left`, накапливая и успехи, и ошибки.

4. **(Лёгкое)** Реализуйте функции конвертации между `option` и `result`.

    ```ocaml
    val option_to_result : error:'e -> 'a option -> ('a, 'e) result
    val result_to_option : ('a, 'e) result -> 'a option
    ```

5. **(Среднее)** ISBN Verifier --- проверить валидность ISBN-10. Формула: (d1 x 10 + d2 x 9 + ... + d10 x 1) mod 11 = 0. Символ 'X' на последней позиции означает 10. Дефисы в строке игнорируются.

    ```ocaml
    val isbn_verifier : string -> bool
    ```

    *Подсказка:* отфильтруйте дефисы, проверьте длину = 10, преобразуйте символы в числа (с учётом 'X'), вычислите контрольную сумму.

6. **(Среднее)** Luhn algorithm --- проверить номер по алгоритму Луна. Алгоритм: удалить пробелы; если осталась одна цифра или меньше --- невалидно; удвоить каждую вторую цифру справа; если результат > 9, вычесть 9; сумма всех цифр должна делиться на 10.

    ```ocaml
    val luhn : string -> bool
    ```

    *Подсказка:* переверните список цифр, удваивайте элементы с нечётным индексом (1, 3, 5, ...).

7. **(Среднее)** `validate_email` --- валидация email с полиморфными вариантами. Возвращает `(string, [> \`EmptyEmail | \`NoAtSign | \`InvalidDomain of string]) result`. Пустая строка --- `EmptyEmail`, нет '@' --- `NoAtSign`, домен без точки --- `InvalidDomain`.

    ```ocaml
    val validate_email : string ->
      (string, [> `EmptyEmail | `NoAtSign | `InvalidDomain of string]) result
    ```

    *Подсказка:* используйте `String.contains` и `String.split_on_char`.

## Заключение

В этой главе мы:

- Подробно изучили `option` и `result` как инструменты обработки ошибок.
- Познакомились с let-операторами (`let*`, `let+`) --- синтаксическим сахаром для цепочек.
- Реализовали накопление ошибок --- аналог аппликативной валидации Haskell, но проще.
- Сравнили исключения и `result` --- когда использовать каждый подход.
- Научились конвертировать между `option` и `result`.
- Сравнили четыре подхода к обработке ошибок: от исключений до полиморфных вариантов.
- Изучили полиморфные варианты для composable, различимых и exhaustive ошибок.
- Познакомились с оператором `and*` для параллельного сбора ошибок.
- Рассмотрели Outcome type для ситуаций, когда нужны предупреждения наряду с результатом.

В следующей главе мы изучим мутабельное состояние и прямые эффекты --- ввод-вывод, работу с файлами и ссылки `ref`.
