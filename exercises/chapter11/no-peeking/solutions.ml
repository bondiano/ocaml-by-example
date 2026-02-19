(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

(** Упражнение 1: Добавить Mul к вариантному типу. *)
module VariantMul = struct
  type expr =
    | Int of int
    | Add of expr * expr
    | Mul of expr * expr

  let rec eval = function
    | Int n -> n
    | Add (a, b) -> eval a + eval b
    | Mul (a, b) -> eval a * eval b

  let rec show = function
    | Int n -> string_of_int n
    | Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"
    | Mul (a, b) -> "(" ^ show a ^ " * " ^ show b ^ ")"
end

(** Упражнение 2: Tagless Final pretty_print.
    Совпадает с TF_Show --- скобки вокруг операций, без скобок у литералов. *)
module TF_Pretty : Chapter11.Expr.EXPR with type t = string = struct
  type t = string
  let int_ n = string_of_int n
  let add a b = "(" ^ a ^ " + " ^ b ^ ")"
end

(** Упражнение 3: Полиморфные варианты с Neg. *)
type 'a expr_neg = [> `Int of int | `Add of 'a * 'a | `Neg of 'a ] as 'a

let rec eval_neg : 'a expr_neg -> int = function
  | `Int n -> n
  | `Add (a, b) -> eval_neg a + eval_neg b
  | `Neg a -> -(eval_neg a)
  | _ -> failwith "unknown expression"

let rec show_neg : 'a expr_neg -> string = function
  | `Int n -> string_of_int n
  | `Add (a, b) -> "(" ^ show_neg a ^ " + " ^ show_neg b ^ ")"
  | `Neg a -> "(-" ^ show_neg a ^ ")"
  | _ -> failwith "unknown expression"

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
  let bool_ b = b
  let and_ a b = a && b
  let or_ a b = a || b
  let not_ a = not a
end

module Bool_Show : BOOL_EXPR with type t = string = struct
  type t = string
  let bool_ b = string_of_bool b
  let and_ a b = "(" ^ a ^ " && " ^ b ^ ")"
  let or_ a b = "(" ^ a ^ " || " ^ b ^ ")"
  let not_ a = "(!" ^ a ^ ")"
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
  let int_ n = string_of_int n
  let add a b = "(" ^ a ^ " + " ^ b ^ ")"
  let bool_ b = string_of_bool b
  let and_ a b = "(" ^ a ^ " && " ^ b ^ ")"
  let or_ a b = "(" ^ a ^ " || " ^ b ^ ")"
  let not_ a = "(!" ^ a ^ ")"
  let eq a b = "(" ^ a ^ " == " ^ b ^ ")"
end
