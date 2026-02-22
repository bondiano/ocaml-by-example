# Проект 2: Валидатор JSON-схем

## Обзор

Создайте инструмент для валидации JSON-данных против упрощённых JSON-схем. Проект объединяет концепции из глав 10 (Фантомные типы), 14 (JSON), и 16 (Property-Based Testing).

**Время выполнения:** 4-6 часов
**Сложность:** Средняя

## Архитектура

```
lib/
├── schema.ml        -- Определение схем и их комбинаторов
├── validator.ml     -- Валидация JSON против схем
└── error.ml         -- Типы ошибок валидации

bin/
└── main.ml          -- CLI: validate <schema-file> <data-file>

test/
└── test_validator.ml -- Тесты + property-based тесты
```

## Этап 1: Типы схем (45 мин)

### Задача
Определите типы для представления JSON-схем.

### Файл: `lib/schema.ml`

```ocaml
(* Базовые типы JSON *)
type json_type =
  | String
  | Number
  | Boolean
  | Object
  | Array
  | Null

(* Ограничения для строк *)
type string_constraint = {
  min_length : int option;
  max_length : int option;
  pattern : string option;  (* regex *)
}

(* Ограничения для чисел *)
type number_constraint = {
  minimum : float option;
  maximum : float option;
  multiple_of : float option;
}

(* Ограничения для массивов *)
type array_constraint = {
  min_items : int option;
  max_items : int option;
  unique_items : bool;
}

(* Определение схемы *)
type schema =
  | String_schema of string_constraint
  | Number_schema of number_constraint
  | Boolean_schema
  | Null_schema
  | Array_schema of array_constraint * schema  (* items schema *)
  | Object_schema of (string * schema * bool) list  (* field, schema, required *)
  | Any_of of schema list  (* union types *)
  | All_of of schema list  (* intersection types *)

(* Конструкторы для удобства *)
val string : ?min_length:int -> ?max_length:int -> ?pattern:string -> unit -> schema
val number : ?minimum:float -> ?maximum:float -> ?multiple_of:float -> unit -> schema
val boolean : schema
val null : schema
val array : ?min_items:int -> ?max_items:int -> ?unique:bool -> schema -> schema
val object_field : string -> schema -> bool -> (string * schema * bool)
val obj : (string * schema * bool) list -> schema
val any_of : schema list -> schema
val all_of : schema list -> schema
```

**TODO:**
1. Реализуйте конструкторы схем
2. Добавьте функцию `schema_to_string : schema -> string` для отладки

### Подсказка
Конструкторы упрощают создание схем:
```ocaml
let user_schema = obj [
  object_field "name" (string ~min_length:1 ()) true;
  object_field "age" (number ~minimum:0. ()) true;
  object_field "email" (string ~pattern:".*@.*" ()) false;
]
```

## Этап 2: Типы ошибок (30 мин)

### Задача
Создайте информативные типы ошибок валидации.

### Файл: `lib/error.ml`

```ocaml
(* Путь к месту ошибки в JSON *)
type path = string list  (* ["user", "address", "zip"] *)

type error =
  | Type_mismatch of { expected : string; actual : string; path : path }
  | Missing_field of { field : string; path : path }
  | String_too_short of { min : int; actual : int; path : path }
  | String_too_long of { max : int; actual : int; path : path }
  | Pattern_mismatch of { pattern : string; value : string; path : path }
  | Number_too_small of { min : float; actual : float; path : path }
  | Number_too_large of { max : float; actual : float; path : path }
  | Not_multiple_of of { multiple : float; actual : float; path : path }
  | Array_too_short of { min : int; actual : int; path : path }
  | Array_too_long of { max : int; actual : int; path : path }
  | Duplicate_items of { path : path }
  | No_match_in_union of { errors : error list; path : path }

val show_error : error -> string
val show_path : path -> string
```

**TODO:**
1. Реализуйте `show_error` для человекочитаемых сообщений
2. Реализуйте `show_path` (например: `"user.address.zip"`)

### Пример вывода
```
Error at user.email: String doesn't match pattern ".*@.*" (value: "invalid")
Error at user.age: Number too small (minimum: 0, actual: -5)
```

## Этап 3: Валидатор (90 мин)

### Задача
Реализуйте валидацию JSON против схем.

### Файл: `lib/validator.ml`

```ocaml
open Schema
open Error

(* Используем Yojson для представления JSON *)
type json = Yojson.Safe.t

val validate : schema -> json -> (unit, error list) result
```

**TODO:**
1. Реализуйте `validate` с проверкой всех ограничений
2. Собирайте ВСЕ ошибки, а не только первую
3. Правильно формируйте пути к ошибкам

### Псевдокод
```ocaml
let rec validate schema json =
  match schema, json with
  | String_schema constraints, `String s ->
      validate_string_constraints constraints s []
  | Number_schema constraints, `Float f ->
      validate_number_constraints constraints f []
  | Array_schema (constraints, item_schema), `List items ->
      let constraint_errors = validate_array_constraints constraints items [] in
      let item_errors = List.mapi (fun i item ->
        match validate item_schema item with
        | Ok () -> []
        | Error errs -> add_index_to_path i errs
      ) items |> List.concat in
      combine_errors [constraint_errors; item_errors]
  | Object_schema fields, `Assoc assoc ->
      validate_object_fields fields assoc []
  | ... -> Type_mismatch ...
```

### Подсказки
- Используйте `Result.bind` и `Result.map_error` для композиции валидаций
- Для регулярных выражений: `Str.string_match (Str.regexp pattern) value 0`
- Для уникальности массива: сравните длину с длиной `List.sort_uniq`

## Этап 4: CLI (45 мин)

### Задача
Создайте интерфейс командной строки.

### Файл: `bin/main.ml`

```ocaml
open Cmdliner
open Schema_validator

let validate_cmd =
  let validate schema_file data_file =
    (* TODO:
       1. Прочитать schema_file (JSON со схемой)
       2. Распарсить в Schema.schema (нужна функция parse_schema)
       3. Прочитать data_file (JSON с данными)
       4. Вызвать Validator.validate
       5. Вывести результат
    *)
    Printf.printf "TODO: validate %s against %s\n" data_file schema_file
  in
  let schema_arg = Arg.(required & pos 0 (some file) None & info []) in
  let data_arg = Arg.(required & pos 1 (some file) None & info []) in
  let doc = "Validate JSON data against schema" in
  Cmd.v (Cmd.info "validate" ~doc) Term.(const validate $ schema_arg $ data_arg)

let () =
  let doc = "JSON Schema Validator" in
  exit (Cmd.eval (Cmd.group (Cmd.info "schema-validator" ~doc) [validate_cmd]))
```

**TODO:**
1. Реализуйте чтение файлов (`Yojson.Safe.from_file`)
2. Добавьте `Schema.from_json : Yojson.Safe.t -> (schema, string) result`
3. Выводите ошибки с форматированием

### Формат схемы (JSON)
```json
{
  "type": "object",
  "properties": {
    "name": { "type": "string", "minLength": 1 },
    "age": { "type": "number", "minimum": 0 },
    "email": { "type": "string", "pattern": ".*@.*" }
  },
  "required": ["name", "age"]
}
```

## Этап 5: Property-Based Testing (60 мин)

### Задача
Напишите property-based тесты для валидатора.

### Файл: `test/test_validator.ml`

```ocaml
open QCheck
open Schema_validator

(* Генераторы валидных данных для схемы *)
let rec gen_valid_json (schema : Schema.schema) : Yojson.Safe.t Gen.t =
  match schema with
  | String_schema { min_length; max_length; _ } ->
      let min = Option.value min_length ~default:0 in
      let max = Option.value max_length ~default:20 in
      Gen.(map (fun s -> `String s) (string_size ~gen:(min -- max)))
  | Number_schema { minimum; maximum; _ } ->
      let min = Option.value minimum ~default:(-1000.) in
      let max = Option.value maximum ~default:1000. in
      Gen.(map (fun f -> `Float f) (float_range min max))
  | Boolean_schema ->
      Gen.(map (fun b -> `Bool b) bool)
  | Array_schema (constraints, item_schema) ->
      (* TODO: генерировать массивы с учётом ограничений *)
      failwith "todo"
  | Object_schema fields ->
      (* TODO: генерировать объекты со всеми required полями *)
      failwith "todo"
  | _ -> failwith "todo"

(* Свойство: валидные данные всегда проходят валидацию *)
let prop_valid_data_validates =
  Test.make ~name:"valid data validates"
    (make (gen_valid_json (Schema.string ~min_length:1 ~max_length:10 ())))
    (fun json ->
      match Validator.validate (Schema.string ~min_length:1 ~max_length:10 ()) json with
      | Ok () -> true
      | Error _ -> false
    )

(* TODO: Добавьте больше свойств:
   - Невалидные данные должны давать ошибки
   - Ошибки должны указывать правильные пути
   - Валидация детерминирована (одинаковые данные → одинаковый результат)
*)
```

**TODO:**
1. Реализуйте генераторы для всех типов схем
2. Напишите property: "валидные данные всегда проходят"
3. Напишите property: "невалидные данные всегда отклоняются"
4. Добавьте shrinking для лучших counterexamples

## Этап 6: Расширенные функции (опционально, 60+ мин)

### 6.1 Фантомные типы для безопасности
Используйте фантомные типы из главы 10:

```ocaml
type validated
type unvalidated

type ('a, _) json =
  | Unvalidated : Yojson.Safe.t -> (Yojson.Safe.t, unvalidated) json
  | Validated : Yojson.Safe.t -> schema -> (Yojson.Safe.t, validated) json

val validate : schema -> (Yojson.Safe.t, unvalidated) json
            -> ((Yojson.Safe.t, validated) json, error list) result
```

Это предотвращает использование невалидированных данных в компилируемом коде!

### 6.2 JSON Schema Draft 7
Добавьте больше возможностей:
- `oneOf`, `not` комбинаторы
- `const`, `enum` для константных значений
- `$ref` для ссылок на определения
- Форматы строк: `email`, `uri`, `date-time`

### 6.3 Производительность
- Кешируйте скомпилированные regex
- Используйте хеш-таблицы для быстрого поиска полей объекта

## Примеры использования

### Пример 1: Простая схема
```bash
# schema.json
{
  "type": "string",
  "minLength": 3,
  "maxLength": 10
}

# valid.json
"hello"

# invalid.json
"ab"

$ schema-validator schema.json valid.json
✓ Valid

$ schema-validator schema.json invalid.json
✗ Invalid
Error at root: String too short (minimum: 3, actual: 2)
```

### Пример 2: Вложенная схема
```json
{
  "type": "object",
  "properties": {
    "user": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "contacts": {
          "type": "array",
          "items": { "type": "string", "pattern": ".*@.*" }
        }
      },
      "required": ["name"]
    }
  },
  "required": ["user"]
}
```

## Критерии успеха

- [ ] Все базовые типы JSON поддерживаются
- [ ] Все ограничения корректно проверяются
- [ ] Ошибки включают полные пути
- [ ] CLI работает с файлами
- [ ] Property-based тесты проходят
- [ ] Код хорошо типизирован

## Ресурсы

- [JSON Schema Spec](https://json-schema.org/)
- [Yojson Docs](https://ocaml-community.github.io/yojson/)
- Глава 10: Фантомные типы
- Глава 14: JSON processing
- Глава 16: Property-Based Testing
