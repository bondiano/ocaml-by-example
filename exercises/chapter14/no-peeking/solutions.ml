(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

type product = {
  title : string;
  price : float;
  in_stock : bool;
}

(** Ручная конвертация product -> JSON. *)
let product_to_json (p : product) : Yojson.Safe.t =
  `Assoc [
    ("title", `String p.title);
    ("price", `Float p.price);
    ("in_stock", `Bool p.in_stock);
  ]

(** Ручная конвертация JSON -> product. *)
let product_of_json (json : Yojson.Safe.t) : (product, string) result =
  match json with
  | `Assoc fields ->
    (match
       List.assoc_opt "title" fields,
       List.assoc_opt "price" fields,
       List.assoc_opt "in_stock" fields
     with
     | Some (`String title), Some (`Float price), Some (`Bool in_stock) ->
       Ok { title; price; in_stock }
     | _ -> Error "missing or invalid fields")
  | _ -> Error "expected JSON object"

(** Извлечь имена из JSON-массива объектов. *)
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

type config = {
  host : string;
  port : int;
  debug : bool;
} [@@deriving yojson]
