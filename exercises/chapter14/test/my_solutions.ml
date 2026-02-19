(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Ручная конвертация product -> JSON. *)
type product = {
  title : string;
  price : float;
  in_stock : bool;
}

let product_to_json (_p : product) : Yojson.Safe.t =
  failwith "todo"

(** Упражнение 2: Ручная конвертация JSON -> product. *)
let product_of_json (_json : Yojson.Safe.t) : (product, string) result =
  failwith "todo"

(** Упражнение 3: Преобразование списка JSON-объектов --- извлечь имена. *)
let extract_names (_json : Yojson.Safe.t) : string list =
  failwith "todo"

(** Упражнение 4: ppx --- тип с автоматической сериализацией. *)
type config = {
  host : string;
  port : int;
  debug : bool;
} [@@deriving yojson]
