(** Примеры FFI и работы с JSON. *)

(** FFI: вызов C-функции sin из libm. *)
external c_sin : float -> float = "caml_sin_float" "sin"
  [@@unboxed] [@@noalloc]
external c_cos : float -> float = "caml_cos_float" "cos"
  [@@unboxed] [@@noalloc]

(** Тип для адреса. *)
type address = {
  street : string;
  city : string;
  zip : string;
} [@@deriving yojson]

(** Тип для контакта. *)
type contact = {
  name : string;
  age : int;
  email : string option;
  address : address;
} [@@deriving yojson]

(** Ручная конвертация: contact -> Yojson.Safe.t *)
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

(** Ручная конвертация: Yojson.Safe.t -> contact *)
let contact_of_json (json : Yojson.Safe.t) : (contact, string) result =
  match json with
  | `Assoc fields ->
    (match
       List.assoc_opt "name" fields,
       List.assoc_opt "age" fields,
       List.assoc_opt "email" fields,
       List.assoc_opt "address" fields
     with
     | Some (`String name), Some (`Int age), email_json, Some (`Assoc addr_fields) ->
       let email = match email_json with
         | Some (`String e) -> Some e
         | _ -> None
       in
       (match
          List.assoc_opt "street" addr_fields,
          List.assoc_opt "city" addr_fields,
          List.assoc_opt "zip" addr_fields
        with
        | Some (`String street), Some (`String city), Some (`String zip) ->
          Ok { name; age; email; address = { street; city; zip } }
        | _ -> Error "invalid address fields")
     | _ -> Error "missing or invalid fields")
  | _ -> Error "expected JSON object"

(** Утилита: извлечь строку из JSON-объекта по ключу. *)
let json_string_field key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`String s) -> Some s
     | _ -> None)
  | _ -> None

(** Утилита: извлечь число из JSON-объекта по ключу. *)
let json_int_field key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`Int n) -> Some n
     | _ -> None)
  | _ -> None

(** === Ctypes: высокоуровневый FFI === *)

(** Примечание: для использования ctypes нужно установить:
    opam install ctypes ctypes-foreign

    Пример использования ctypes для math.h:

    open Ctypes
    open Foreign

    let c_sqrt = foreign "sqrt" (double @-> returning double)
    let c_pow = foreign "pow" (double @-> double @-> returning double)
    let c_ceil = foreign "ceil" (double @-> returning double)
    let c_floor = foreign "floor" (double @-> returning double)

    Пример определения C-структуры:

    type point
    let point : point structure typ = structure "point"
    let px = field point "x" double
    let py = field point "y" double
    let () = seal point

    Не забудьте вызвать seal --- иначе получите
    Ctypes_static.IncompleteType *)

(** Обёртка над math.h через стандартный external (без ctypes). *)
let math_sqrt = Float.sqrt
let math_ceil = ceil
let math_floor = floor
let math_pow base exp = base ** exp
