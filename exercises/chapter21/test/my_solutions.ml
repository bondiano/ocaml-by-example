(** Здесь вы можете писать свои решения упражнений. *)
open Chapter21.Hashcons_ast

(** Упражнение 1: Unboxed-тип для положительных float. *)
type positive_float = Pos of float [@@unboxed]

let mk_positive (_x : float) : positive_float option =
  failwith "todo"

let get_value (_pf : positive_float) : float =
  failwith "todo"

(** Упражнение 2: Hash-consing для бинарных деревьев. *)
type tree_node = Leaf | Node of hc_tree * hc_tree
and hc_tree = tree_node hcons

let mk_leaf : unit -> hc_tree = fun () ->
  failwith "todo"

let mk_node (_l : hc_tree) (_r : hc_tree) : hc_tree =
  failwith "todo"

let tree_size (_t : hc_tree) : int =
  failwith "todo"

(** Упражнение 3: Упрощение hash-consed выражений. *)
let simplify (_e : hc_expr) : hc_expr =
  failwith "todo"

(** Упражнение 4: Подсчёт узлов. *)
let count_unique_nodes (_e : hc_expr) : int =
  failwith "todo"

let count_nodes_regular (_e : expr) : int =
  ignore _e;
  failwith "todo"

(** Упражнение 5: Hash-consed формулы пропозициональной логики. *)
type prop_node =
  | PVar of string
  | PAnd of hc_prop * hc_prop
  | POr of hc_prop * hc_prop
  | PNot of hc_prop
  | PTrue
  | PFalse
and hc_prop = prop_node hcons

let mk_pvar (_x : string) : hc_prop =
  failwith "todo"

let mk_pand (_a : hc_prop) (_b : hc_prop) : hc_prop =
  failwith "todo"

let mk_por (_a : hc_prop) (_b : hc_prop) : hc_prop =
  failwith "todo"

let mk_pnot (_a : hc_prop) : hc_prop =
  failwith "todo"

let mk_ptrue : unit -> hc_prop = fun () ->
  failwith "todo"

let mk_pfalse : unit -> hc_prop = fun () ->
  failwith "todo"

let nnf (_p : hc_prop) : hc_prop =
  failwith "todo"

let eval_prop (_env : string -> bool) (_p : hc_prop) : bool =
  failwith "todo"
