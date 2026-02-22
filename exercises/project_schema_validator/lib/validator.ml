open Schema
open Error

(* Используем Yojson для представления JSON *)
type json = Yojson.Safe.t

(* Вспомогательная функция для комбинирования ошибок *)
let combine_errors (error_lists : error list list) : (unit, error list) result =
  let all_errors = List.concat error_lists in
  if all_errors = [] then Ok () else Error all_errors

(* Валидация строковых ограничений *)
let validate_string_constraints (_constraints : string_constraint) (_value : string)
    (_path : path) : error list =
  (* TODO: проверить min_length, max_length, pattern
     Вернуть список ошибок (может быть пустым)
     См. GUIDE.md этап 3
  *)
  failwith "todo"

(* Валидация числовых ограничений *)
let validate_number_constraints (_constraints : number_constraint) (_value : float)
    (_path : path) : error list =
  (* TODO: проверить minimum, maximum, multiple_of *)
  failwith "todo"

(* Валидация ограничений массива *)
let validate_array_constraints (_constraints : array_constraint)
    (_items : json list) (_path : path) : error list =
  (* TODO: проверить min_items, max_items, unique_items *)
  failwith "todo"

(* Валидация полей объекта *)
let validate_object_fields (_fields : (string * schema * bool) list)
    (_assoc : (string * json) list) (_path : path) (_validate_fn : schema -> json -> path -> error list) : error list =
  (* TODO:
     1. Проверить, что все required поля присутствуют
     2. Валидировать каждое поле согласно его схеме
     3. Добавить имя поля к path при валидации
  *)
  failwith "todo"

(* Основная функция валидации *)
let validate (schema : schema) (json : json) : (unit, error list) result =
  (* Вспомогательная функция для рекурсивной валидации с путём *)
  let rec validate_with_path (schema : schema) (json : json) (path : path)
      : error list =
    match (schema, json) with
    | String_schema constraints, `String s ->
        validate_string_constraints constraints s path
    | Number_schema constraints, `Float f ->
        validate_number_constraints constraints f path
    | Number_schema constraints, `Int i ->
        validate_number_constraints constraints (float_of_int i) path
    | Boolean_schema, `Bool _ -> []
    | Null_schema, `Null -> []
    | Array_schema (constraints, item_schema), `List items ->
        let constraint_errors = validate_array_constraints constraints items path in
        let item_errors =
          List.mapi
            (fun i item ->
              let item_path = path @ [ string_of_int i ] in
              validate_with_path item_schema item item_path)
            items
          |> List.concat
        in
        constraint_errors @ item_errors
    | Object_schema fields, `Assoc assoc ->
        validate_object_fields fields assoc path validate_with_path
    | Any_of _schemas, _json ->
        (* TODO: хотя бы одна схема должна подходить *)
        failwith "todo"
    | All_of _schemas, _json ->
        (* TODO: все схемы должны подходить *)
        failwith "todo"
    | _, json ->
        (* Type mismatch *)
        let expected = schema_to_string schema in
        let actual =
          match json with
          | `String _ -> "String"
          | `Float _ | `Int _ -> "Number"
          | `Bool _ -> "Boolean"
          | `Null -> "Null"
          | `List _ -> "Array"
          | `Assoc _ -> "Object"
          | _ -> "Unknown"
        in
        [ Type_mismatch { expected; actual; path } ]
  in
  match validate_with_path schema json [] with
  | [] -> Ok ()
  | errors -> Error errors
