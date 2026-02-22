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
let string ?min_length:_ ?max_length:_ ?pattern:_ () : schema =
  (* TODO: реализуйте конструктор String_schema
     См. GUIDE.md этап 1 *)
  failwith "todo"

let number ?minimum:_ ?maximum:_ ?multiple_of:_ () : schema =
  (* TODO: реализуйте конструктор Number_schema *)
  failwith "todo"

let boolean : schema =
  (* TODO: вернуть Boolean_schema *)
  failwith "todo"

let null : schema =
  (* TODO: вернуть Null_schema *)
  failwith "todo"

let array ?min_items:_ ?max_items:_ ?(unique = false) (_item_schema : schema) : schema =
  let _ = unique in
  (* TODO: реализуйте конструктор Array_schema *)
  failwith "todo"

let object_field (_name : string) (_schema : schema) (_required : bool)
    : string * schema * bool =
  (* TODO: просто вернуть кортеж *)
  failwith "todo"

let obj (_fields : (string * schema * bool) list) : schema =
  (* TODO: вернуть Object_schema *)
  failwith "todo"

let any_of (_schemas : schema list) : schema =
  (* TODO: вернуть Any_of *)
  failwith "todo"

let all_of (_schemas : schema list) : schema =
  (* TODO: вернуть All_of *)
  failwith "todo"

let rec schema_to_string (schema : schema) : string =
  (* TODO: опционально, для отладки *)
  match schema with
  | String_schema _ -> "String"
  | Number_schema _ -> "Number"
  | Boolean_schema -> "Boolean"
  | Null_schema -> "Null"
  | Array_schema (_, item) ->
      Printf.sprintf "Array[%s]" (schema_to_string item)
  | Object_schema fields ->
      let field_strs =
        List.map
          (fun (name, s, req) ->
            Printf.sprintf "%s%s: %s" name (if req then "*" else "")
              (schema_to_string s))
          fields
      in
      Printf.sprintf "{%s}" (String.concat ", " field_strs)
  | Any_of schemas ->
      Printf.sprintf "AnyOf[%s]"
        (String.concat " | " (List.map schema_to_string schemas))
  | All_of schemas ->
      Printf.sprintf "AllOf[%s]"
        (String.concat " & " (List.map schema_to_string schemas))

(* Парсинг JSON в schema — опционально для этапа 4 *)
let from_json (_json : Yojson.Safe.t) : (schema, string) result =
  (* TODO: распарсить JSON в schema
     См. GUIDE.md этап 4 для формата *)
  Error "not implemented"
