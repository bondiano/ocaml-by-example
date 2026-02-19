(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Добавить Mul к вариантному типу. *)
module VariantMul = struct
  type expr =
    | Int of int
    | Add of expr * expr
    | Mul of expr * expr

  let eval = function
    | Int _n -> failwith "todo"
    | Add (_a, _b) -> failwith "todo"
    | Mul (_a, _b) -> failwith "todo"

  let show = function
    | Int _n -> failwith "todo"
    | Add (_a, _b) -> failwith "todo"
    | Mul (_a, _b) -> failwith "todo"
end

(** Упражнение 2: Tagless Final pretty_print. *)
module TF_Pretty : Chapter10.Expr.EXPR with type t = string = struct
  type t = string
  let int_ (_n : int) : t = failwith "todo"
  let add (_a : t) (_b : t) : t = failwith "todo"
end

(** Упражнение 3: Полиморфные варианты с Neg. *)
type neg_expr = [ `Int of int | `Add of neg_expr * neg_expr | `Neg of neg_expr ]

let eval_neg (e : neg_expr) : int =
  match e with
  | `Int _n -> failwith "todo"
  | `Add (_a, _b) -> failwith "todo"
  | `Neg _a -> failwith "todo"

let show_neg (e : neg_expr) : string =
  match e with
  | `Int _n -> failwith "todo"
  | `Add (_a, _b) -> failwith "todo"
  | `Neg _a -> failwith "todo"

(** Упражнение 4: Tagless Final для булевых выражений. *)
module type BOOL_EXPR = sig
  type t
  val bool_ : bool -> t
  val and_ : t -> t -> t
  val or_ : t -> t -> t
  val not_ : t -> t
end

module Bool_Eval : BOOL_EXPR with type t = bool = struct
  type t = bool
  let bool_ (_b : bool) : t = failwith "todo"
  let and_ (_a : t) (_b : t) : t = failwith "todo"
  let or_ (_a : t) (_b : t) : t = failwith "todo"
  let not_ (_a : t) : t = failwith "todo"
end

module Bool_Show : BOOL_EXPR with type t = string = struct
  type t = string
  let bool_ (_b : bool) : t = failwith "todo"
  let and_ (_a : t) (_b : t) : t = failwith "todo"
  let or_ (_a : t) (_b : t) : t = failwith "todo"
  let not_ (_a : t) : t = failwith "todo"
end

(** Упражнение 5: Объединённый DSL. *)
module type COMBINED_EXPR = sig
  type t
  val int_ : int -> t
  val add : t -> t -> t
  val bool_ : bool -> t
  val and_ : t -> t -> t
  val or_ : t -> t -> t
  val not_ : t -> t
  val eq : t -> t -> t
end

module Combined_Show : COMBINED_EXPR with type t = string = struct
  type t = string
  let int_ (_n : int) : t = failwith "todo"
  let add (_a : t) (_b : t) : t = failwith "todo"
  let bool_ (_b : bool) : t = failwith "todo"
  let and_ (_a : t) (_b : t) : t = failwith "todo"
  let or_ (_a : t) (_b : t) : t = failwith "todo"
  let not_ (_a : t) : t = failwith "todo"
  let eq (_a : t) (_b : t) : t = failwith "todo"
end
