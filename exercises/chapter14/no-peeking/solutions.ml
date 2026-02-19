(** Референсные решения — не подсматривайте, пока не попробуете сами! *)

(* ====================================================================== *)
(*  JSON-упражнения (1–4)                                                  *)
(* ====================================================================== *)

type product = {
  title    : string;
  price    : float;
  in_stock : bool;
}

(** Упражнение 1: Ручная конвертация product -> JSON. *)
let product_to_json (p : product) : Yojson.Safe.t =
  `Assoc [
    ("title",    `String p.title);
    ("price",    `Float  p.price);
    ("in_stock", `Bool   p.in_stock);
  ]

(** Упражнение 2: Ручная конвертация JSON -> product. *)
let product_of_json (json : Yojson.Safe.t) : (product, string) result =
  match json with
  | `Assoc fields ->
    (match
       List.assoc_opt "title"    fields,
       List.assoc_opt "price"    fields,
       List.assoc_opt "in_stock" fields
     with
     | Some (`String title), Some (`Float price), Some (`Bool in_stock) ->
       Ok { title; price; in_stock }
     | _ -> Error "missing or invalid fields")
  | _ -> Error "expected JSON object"

(** Упражнение 3: Извлечь имена из JSON-массива объектов. *)
let extract_names (json : Yojson.Safe.t) : string list =
  match json with
  | `List items ->
    List.filter_map (fun item ->
      match item with
      | `Assoc fields ->
        (match List.assoc_opt "name" fields with
         | Some (`String name) -> Some name
         | _ -> None)
      | _ -> None
    ) items
  | _ -> []

(** Упражнение 4: ppx — тип с автоматической сериализацией. *)
type config = {
  host  : string;
  port  : int;
  debug : bool;
} [@@deriving yojson]

(* ====================================================================== *)
(*  FFI-упражнения (5–7)                                                   *)
(* ====================================================================== *)

(** Упражнение 5: external-привязка к caml_count_char.
    Тип: string -> char -> int
    Аргументы OCaml char передаются как int (Int_val в C). *)
external count_char : string -> char -> int = "caml_count_char"

(** Упражнение 6: привязка к caml_str_repeat + безопасная обёртка. *)
external raw_str_repeat : string -> int -> string = "caml_str_repeat"

let str_repeat (s : string) (n : int) : string =
  if n < 0 then "" else raw_str_repeat s n

(** Упражнение 7: привязка к caml_sum_int_array + mean. *)
external raw_sum_int_array : int array -> int = "caml_sum_int_array"

let mean (arr : int array) : float option =
  let len = Array.length arr in
  if len = 0 then None
  else Some (float_of_int (raw_sum_int_array arr) /. float_of_int len)
