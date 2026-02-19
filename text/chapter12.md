# FFI и JSON

## Цели главы

В этой главе мы изучим два важных аспекта практической разработки на OCaml:

- **FFI (Foreign Function Interface)** --- вызов C-функций из OCaml.
- **Работа с JSON** --- парсинг и генерация JSON с помощью библиотеки Yojson.
- **Автоматическая сериализация** --- ppx_deriving_yojson для генерации кодеков.
- Сравнение с подходом Haskell (aeson, FFI).

## Подготовка проекта

Код этой главы находится в `exercises/chapter12`. Соберите проект:

```text
$ cd exercises/chapter12
$ dune build
```

Для этой главы требуются библиотеки `yojson` и `ppx_deriving_yojson`. Убедитесь, что они установлены:

```text
$ opam install yojson ppx_deriving_yojson
```

## Часть 1: FFI --- вызов C-функций из OCaml

### Зачем нужен FFI?

OCaml --- компилируемый язык с эффективной средой выполнения, но иногда нужно:

- Использовать существующие C-библиотеки (OpenSSL, SQLite, zlib).
- Вызывать системные функции ОС.
- Оптимизировать критичные участки кода на C.
- Интегрироваться с экосистемой других языков через C ABI.

В Haskell для FFI используется ключевое слово `foreign import`:

```haskell
-- Haskell FFI
foreign import ccall "sin" c_sin :: CDouble -> CDouble
```

В OCaml аналогичную роль играет ключевое слово `external`.

### Ключевое слово `external`

`external` объявляет функцию, реализованную на C:

```ocaml
external c_sin : float -> float = "caml_sin_float" "sin"
  [@@unboxed] [@@noalloc]
external c_cos : float -> float = "caml_cos_float" "cos"
  [@@unboxed] [@@noalloc]
```

Разберём синтаксис:

- `external c_sin` --- имя функции в OCaml.
- `: float -> float` --- тип функции в OCaml.
- `= "caml_sin_float" "sin"` --- два имени C-функций: первое для байткод-компилятора, второе для нативного.
- `[@@unboxed]` --- аргументы и результат передаются без упаковки (boxing). Требует указания двух C-имён.
- `[@@noalloc]` --- функция не выделяет память в куче OCaml.

### Соответствие типов OCaml и C

| Тип OCaml | Тип C | Примечание |
|-----------|-------|------------|
| `int` | `intnat` | Машинное целое минус 1 бит (тег) |
| `float` | `double` | 64-битное число с плавающей точкой |
| `bool` | `intnat` | 0 = false, 1 = true |
| `string` | `char *` | Строки OCaml --- не нуль-терминированные! |
| `unit` | `value` | Представлен как `Val_unit` |
| `'a array` | `value` | Массив боксированных значений |

### Пример: математические функции из libm

Стандартная библиотека C `libm` содержит математические функции, которые можно вызывать напрямую:

```ocaml
external c_sin : float -> float = "caml_sin_float" "sin"
  [@@unboxed] [@@noalloc]
external c_cos : float -> float = "caml_cos_float" "cos"
  [@@unboxed] [@@noalloc]
external c_sqrt : float -> float = "caml_sqrt_float" "sqrt"
  [@@unboxed] [@@noalloc]
external c_exp : float -> float = "caml_exp_float" "exp"
  [@@unboxed] [@@noalloc]
external c_log : float -> float = "caml_log_float" "log"
  [@@unboxed] [@@noalloc]
```

Использование:

```text
# c_sin 0.0;;
- : float = 0.

# c_sin (Float.pi /. 2.0);;
- : float = 1.

# c_cos 0.0;;
- : float = 1.

# c_sqrt 2.0;;
- : float = 1.41421356237309515
```

Атрибуты `[@@unboxed]` и `[@@noalloc]` --- оптимизации для простых числовых функций. `[@@unboxed]` избегает упаковки `float` в блок кучи, а `[@@noalloc]` сообщает сборщику мусора, что вызов безопасен. При использовании `[@@unboxed]` обязательно указывать два имени C-функций --- для байткод-компилятора и для нативного.

### Простые external без атрибутов

Если не нужны оптимизации `[@@unboxed]` и `[@@noalloc]`, можно указать одно имя C-функции:

```ocaml
external c_abs : int -> int = "abs"
```

Это проще, но медленнее для числовых типов из-за боксинга.

### Функции с несколькими аргументами

Для C-функций с несколькими аргументами тоже нужно указать **два** имени --- для байткод-компилятора и нативного:

```ocaml
external c_pow : float -> float -> float
  = "caml_pow_bytecode" "pow" [@@unboxed] [@@noalloc]
```

Первое имя --- обёртка для байткода (все аргументы передаются как `value`), второе --- нативная C-функция.

### Безопасность FFI

FFI --- **небезопасная** операция. Компилятор OCaml **не проверяет** соответствие типов с C-функцией. Если вы объявите неправильный тип, программа может упасть с segfault:

```ocaml
(* ОПАСНО: неправильный тип! sin принимает double, а не int *)
external bad_sin : int -> int = "sin"
(* Это скомпилируется, но вызовет undefined behavior *)
```

Правила безопасности:

1. Убедитесь, что типы OCaml соответствуют типам C.
2. Не используйте `[@@noalloc]` если C-функция может вызвать callback в OCaml.
3. Будьте осторожны со строками --- строки OCaml не нуль-терминированы.
4. Не передавайте OCaml-значения в C без правильного маршаллинга.

### Библиотека ctypes

Для более сложного FFI (структуры, указатели, callbacks) существует библиотека **ctypes**, которая позволяет описывать C-привязки целиком на OCaml:

```ocaml
(* С ctypes (концептуально): *)
open Ctypes
open Foreign

let c_strlen = foreign "strlen" (string @-> returning int)
let c_puts = foreign "puts" (string @-> returning int)
```

`ctypes` безопаснее ручных `external`-объявлений, потому что генерирует правильный маршаллинг автоматически. Но `external` быстрее для простых случаев, так как не имеет накладных расходов.

Подробное изучение ctypes выходит за рамки этой главы, но знать о его существовании полезно.

## Часть 2: JSON с Yojson

### Зачем JSON?

JSON --- самый популярный формат обмена данными в веб-разработке и API. В OCaml основная библиотека для работы с JSON --- **Yojson**.

В Haskell для JSON используется `aeson`:

```haskell
-- Haskell: aeson
import Data.Aeson
data Person = Person { name :: Text, age :: Int }
  deriving (Generic, FromJSON, ToJSON)
```

В OCaml аналогичную роль играет связка `yojson` + `ppx_deriving_yojson`.

### Тип `Yojson.Safe.t`

`Yojson.Safe.t` --- алгебраический тип, представляющий любое JSON-значение:

```ocaml
type t =
  | `Null
  | `Bool of bool
  | `Int of int
  | `Float of float
  | `String of string
  | `List of t list
  | `Assoc of (string * t) list
```

Это **полиморфные варианты** (polymorphic variants). Обратите внимание на обратный апостроф перед именем конструктора.

Примеры:

```text
# `Null;;
- : [> `Null ] = `Null

# `Bool true;;
- : [> `Bool of bool ] = `Bool true

# `Int 42;;
- : [> `Int of int ] = `Int 42

# `String "hello";;
- : [> `String of string ] = `String "hello"

# `List [`Int 1; `Int 2; `Int 3];;
- : [> `List of [> `Int of int ] list ] = `List [`Int 1; `Int 2; `Int 3]

# `Assoc [("name", `String "Alice"); ("age", `Int 30)];;
- : ... = `Assoc [("name", `String "Alice"); ("age", `Int 30)]
```

### Парсинг JSON из строки

`Yojson.Safe.from_string` преобразует строку в `Yojson.Safe.t`:

```text
# Yojson.Safe.from_string {|{"name": "Alice", "age": 30}|};;
- : Yojson.Safe.t = `Assoc [("name", `String "Alice"); ("age", `Int 30)]

# Yojson.Safe.from_string {|[1, 2, 3]|};;
- : Yojson.Safe.t = `List [`Int 1; `Int 2; `Int 3]

# Yojson.Safe.from_string "null";;
- : Yojson.Safe.t = `Null
```

Обратите внимание на синтаксис **quoted strings** `{| ... |}` --- строки OCaml, в которых не нужно экранировать кавычки. Очень удобно для JSON.

### Генерация JSON в строку

`Yojson.Safe.to_string` преобразует `Yojson.Safe.t` обратно в строку:

```text
# let json = `Assoc [("name", `String "Bob"); ("age", `Int 25)] in
  Yojson.Safe.to_string json;;
- : string = "{\"name\":\"Bob\",\"age\":25}"

# Yojson.Safe.pretty_to_string json;;
- : string = "{\n  \"name\": \"Bob\",\n  \"age\": 25\n}"
```

`pretty_to_string` выводит JSON с отступами --- удобно для отладки.

### Ручной парсинг: сопоставление с образцом

Главная сила OCaml при работе с JSON --- **pattern matching**. Можно безопасно разобрать JSON-структуру:

```ocaml
let parse_name json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt "name" fields with
     | Some (`String name) -> Ok name
     | Some _ -> Error "name is not a string"
     | None -> Error "name field missing")
  | _ -> Error "expected JSON object"
```

Для вложенных структур парсинг выглядит так:

```ocaml
type address = {
  street : string;
  city : string;
  zip : string;
}

type contact = {
  name : string;
  age : int;
  email : string option;
  address : address;
}

let contact_of_json (json : Yojson.Safe.t) : (contact, string) result =
  match json with
  | `Assoc fields ->
    (match
       List.assoc_opt "name" fields,
       List.assoc_opt "age" fields,
       List.assoc_opt "email" fields,
       List.assoc_opt "address" fields
     with
     | Some (`String name), Some (`Int age), email_json, Some (`Assoc addr) ->
       let email = match email_json with
         | Some (`String e) -> Some e
         | _ -> None
       in
       (match
          List.assoc_opt "street" addr,
          List.assoc_opt "city" addr,
          List.assoc_opt "zip" addr
        with
        | Some (`String street), Some (`String city), Some (`String zip) ->
          Ok { name; age; email; address = { street; city; zip } }
        | _ -> Error "invalid address fields")
     | _ -> Error "missing or invalid fields")
  | _ -> Error "expected JSON object"
```

Ручной парсинг надёжен и явен, но **многословен**. Для каждого типа нужно писать конвертер вручную.

### Ручная генерация JSON

Построить JSON-значение из OCaml-типа тоже просто:

```ocaml
let contact_to_json (c : contact) : Yojson.Safe.t =
  `Assoc [
    ("name", `String c.name);
    ("age", `Int c.age);
    ("email", match c.email with Some e -> `String e | None -> `Null);
    ("address", `Assoc [
      ("street", `String c.address.street);
      ("city", `String c.address.city);
      ("zip", `String c.address.zip);
    ]);
  ]
```

### Вспомогательные функции

Полезно вынести повторяющиеся паттерны в утилиты:

```ocaml
let json_string_field key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`String s) -> Some s
     | _ -> None)
  | _ -> None

let json_int_field key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`Int n) -> Some n
     | _ -> None)
  | _ -> None
```

Использование:

```text
# let json = Yojson.Safe.from_string {|{"name": "Alice", "age": 30}|} in
  json_string_field "name" json;;
- : string option = Some "Alice"

# json_int_field "age" json;;
- : int option = Some 30

# json_string_field "missing" json;;
- : string option = None
```

## Часть 3: ppx_deriving_yojson

### Проблема ручных кодеков

Ручные конвертеры JSON имеют недостатки:

- Много шаблонного кода.
- Легко допустить ошибку в имени поля.
- При изменении типа нужно обновлять конвертеры вручную.

### Автоматическая генерация с `[@@deriving yojson]`

`ppx_deriving_yojson` --- PPX-расширение, которое автоматически генерирует функции сериализации и десериализации:

```ocaml
type address = {
  street : string;
  city : string;
  zip : string;
} [@@deriving yojson]

type contact = {
  name : string;
  age : int;
  email : string option;
  address : address;
} [@@deriving yojson]
```

Аннотация `[@@deriving yojson]` генерирует две функции:

- `address_to_yojson : address -> Yojson.Safe.t`
- `address_of_yojson : Yojson.Safe.t -> (address, string) result`

И аналогично для `contact`:

- `contact_to_yojson : contact -> Yojson.Safe.t`
- `contact_of_yojson : Yojson.Safe.t -> (contact, string) result`

### Использование

```text
# let alice = {
    name = "Alice"; age = 30; email = Some "alice@example.com";
    address = { street = "Main St"; city = "Moscow"; zip = "101000" }
  };;

# let json = contact_to_yojson alice;;
# Yojson.Safe.pretty_to_string json;;
- : string = {
  "name": "Alice",
  "age": 30,
  "email": ["Some", "alice@example.com"],
  "address": {
    "street": "Main St",
    "city": "Moscow",
    "zip": "101000"
  }
}
```

Обратите внимание: `option` сериализуется как `["Some", value]` или `"None"` по умолчанию. Это отличается от ручной сериализации, где мы использовали `null`.

### Десериализация

```text
# let json_str = {|{"name":"Bob","age":25,"email":"None",
    "address":{"street":"Elm St","city":"SPb","zip":"190000"}}|} in
  let json = Yojson.Safe.from_string json_str in
  contact_of_yojson json;;
- : (contact, string) result = Ok {name = "Bob"; age = 25; email = None; ...}
```

Функция `contact_of_yojson` возвращает `result` --- `Ok` при успехе или `Error` с описанием ошибки.

### Настройка dune

Для использования `ppx_deriving_yojson` нужно настроить `dune`:

```lisp
(library
 (name mylib)
 (libraries yojson)
 (preprocess (pps ppx_deriving_yojson)))
```

Ключевая строка --- `(preprocess (pps ppx_deriving_yojson))`, которая включает PPX-препроцессор.

### Только сериализация или десериализация

Можно сгенерировать только одну из двух функций:

```ocaml
type log_entry = {
  timestamp : float;
  message : string;
} [@@deriving to_yojson]
(* Генерирует только log_entry_to_yojson *)

type config = {
  host : string;
  port : int;
} [@@deriving of_yojson]
(* Генерирует только config_of_yojson *)
```

## Часть 4: Проект --- парсер конфигурации

Соберём всё вместе --- напишем парсер конфигурационного файла в формате JSON.

### Тип конфигурации

```ocaml
type database_config = {
  host : string;
  port : int;
  name : string;
} [@@deriving yojson]

type app_config = {
  debug : bool;
  log_level : string;
  database : database_config;
} [@@deriving yojson]
```

### Чтение конфигурации

```ocaml
let load_config path =
  let content = In_channel.with_open_text path In_channel.input_all in
  let json = Yojson.Safe.from_string content in
  app_config_of_yojson json

let save_config path config =
  let json = app_config_to_yojson config in
  let content = Yojson.Safe.pretty_to_string json in
  Out_channel.with_open_text path (fun oc ->
    Out_channel.output_string oc content)
```

### Пример конфигурации

```json
{
  "debug": true,
  "log_level": "info",
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "mydb"
  }
}
```

Этот паттерн --- типичный для OCaml-приложений: определить тип с `[@@deriving yojson]`, затем использовать `from_string` / `to_string` для ввода-вывода.

## Сравнение с Haskell

| Аспект | OCaml (yojson + ppx) | Haskell (aeson) |
|--------|---------------------|-----------------|
| Тип JSON | `Yojson.Safe.t` (полиморфные варианты) | `Value` (ADT) |
| Автодеривация | `[@@deriving yojson]` | `deriving (FromJSON, ToJSON)` |
| Генерируемые функции | `t_to_yojson`, `t_of_yojson` | `toJSON`, `parseJSON` |
| Возврат десериализации | `(t, string) result` | `Parser t` (монада) |
| Ручной парсинг | Pattern matching | `.:`, `.:?`, `withObject` |
| FFI | `external` + C stubs | `foreign import ccall` |
| Типобезопасность FFI | Нет (доверие программисту) | Нет (доверие программисту) |
| Высокоуровневый FFI | ctypes | inline-c, c2hs |

Общая идея одинакова: определить тип данных, автоматически получить сериализаторы, использовать их для ввода-вывода JSON.

## Ctypes --- высокоуровневый FFI

В разделе про FFI мы кратко упомянули библиотеку **ctypes**. Рассмотрим её подробнее --- ctypes позволяет описывать C-типы и вызывать C-функции **целиком на OCaml**, без написания C-кода и стабов вручную.

### Установка

```text
$ opam install ctypes ctypes-foreign
```

### Основы: вызов C-функций

Модуль `Foreign` предоставляет функцию `foreign`, которая связывает имя C-функции с описанием её типа:

```ocaml
open Ctypes
open Foreign

let c_sqrt = foreign "sqrt" (double @-> returning double)
let c_pow = foreign "pow" (double @-> double @-> returning double)
```

Оператор `@->` описывает аргументы, а `returning t` --- тип возвращаемого значения. Типы (`double`, `int`, `string` и т.д.) --- это значения модуля `Ctypes`, а не типы OCaml.

После объявления `c_sqrt` и `c_pow` --- обычные OCaml-функции:

```text
# c_sqrt 2.0;;
- : float = 1.41421356237309515

# c_pow 2.0 10.0;;
- : float = 1024.
```

### Определение C-структур

Ctypes позволяет описывать C-структуры:

```ocaml
type point
let point : point structure typ = structure "point"
let x = field point "x" double
let y = field point "y" double
let () = seal point

(* Создание и использование *)
let p = make point in
setf p x 3.0;
setf p y 4.0;
let dist = sqrt (getf p x ** 2.0 +. getf p y ** 2.0)
```

Порядок действий:

1. `structure "point"` --- объявить структуру с именем `point`.
2. `field point "x" double` --- добавить поле `x` типа `double`.
3. `seal point` --- завершить определение (вычислить размер и выравнивание).
4. `make point` --- создать экземпляр структуры.
5. `setf` / `getf` --- записать / прочитать поле.

**Частая ошибка:** если забыть вызвать `seal t`, при попытке использовать структуру вы получите исключение `Ctypes_static.IncompleteType`.

### Два подхода к связыванию

Ctypes поддерживает два режима работы:

1. **Dynamic linking** (через `libffi`) --- быстрый старт, не требует компиляции C-кода. Библиотека загружается в рантайме (`.so` на Linux, `.dylib` на macOS). Удобно для прототипирования.

2. **Stub generation** --- production-подход. Ctypes генерирует C-стабы на этапе сборки. Результат эффективнее (нет overhead от libffi), но сборка сложнее.

Для большинства задач dynamic linking достаточно. Stub generation имеет смысл, когда FFI-вызовы находятся на горячем пути.

### Ограничения

- Generated stubs не поддерживают атрибуты `[@noalloc]` и `[@unboxed]`, которые доступны при ручном `external`.
- Dynamic linking требует наличия `.so`/`.dylib` в системе в рантайме.
- Ctypes медленнее ручных `external` для простых числовых функций из-за дополнительного уровня абстракции.

Для простых числовых функций `external` с `[@@unboxed] [@@noalloc]` остаётся лучшим выбором. Ctypes раскрывает свою мощь при работе со структурами, указателями, массивами и сложными C API.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Среднее)** Реализуйте ручную конвертацию `product_to_json` для типа:

    ```ocaml
    type product = {
      title : string;
      price : float;
      in_stock : bool;
    }
    ```

    Функция должна возвращать `Yojson.Safe.t` --- JSON-объект с полями `"title"`, `"price"`, `"in_stock"`.

2. **(Среднее)** Реализуйте обратную конвертацию `product_of_json`:

    ```ocaml
    val product_of_json : Yojson.Safe.t -> (product, string) result
    ```

    При невалидном JSON верните `Error` с описанием ошибки.

3. **(Среднее)** Реализуйте функцию `extract_names`, которая из JSON-массива объектов извлекает значения поля `"name"`:

    ```ocaml
    val extract_names : Yojson.Safe.t -> string list
    ```

    Например, для `[{"name": "Alice"}, {"name": "Bob"}, {"age": 25}]` результат: `["Alice"; "Bob"]`. Объекты без поля `"name"` пропускаются.

4. **(Лёгкое)** Определите тип `config` с полями `host : string`, `port : int`, `debug : bool` и аннотацией `[@@deriving yojson]`. Убедитесь, что автоматическая сериализация и десериализация работают (тесты проверят roundtrip).

## Заключение

В этой главе мы:

- Изучили FFI: ключевое слово `external` для вызова C-функций.
- Разобрали соответствие типов OCaml и C.
- Познакомились с библиотекой Yojson и типом `Yojson.Safe.t`.
- Научились вручную парсить и генерировать JSON через pattern matching.
- Освоили `ppx_deriving_yojson` для автоматической сериализации.
- Написали парсер конфигурации --- типичный паттерн для OCaml-приложений.

В следующей главе мы изучим **обработчики эффектов (Effect Handlers)** --- одну из ключевых новинок OCaml 5, которая открывает новые подходы к структурированию побочных эффектов.
