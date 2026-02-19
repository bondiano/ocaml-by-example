(** Расширяемый калькулятор --- три подхода к Expression Problem. *)

(** === Способ 1: Варианты (алгебраические типы) === *)

module Variant = struct
  (** Тип выражения. *)
  type expr =
    | Int of int
    | Add of expr * expr

  (** Вычислить выражение. *)
  let rec eval = function
    | Int n -> n
    | Add (a, b) -> eval a + eval b

  (** Отобразить выражение в строку. *)
  let rec show = function
    | Int n -> string_of_int n
    | Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"
end

(** === Способ 2: Tagless Final (модули) === *)

(** Сигнатура арифметического DSL. *)
module type EXPR = sig
  type t
  val int_ : int -> t
  val add : t -> t -> t
end

(** Интерпретация: вычисление. *)
module TF_Eval : EXPR with type t = int = struct
  type t = int
  let int_ n = n
  let add a b = a + b
end

(** Интерпретация: отображение в строку. *)
module TF_Show : EXPR with type t = string = struct
  type t = string
  let int_ n = string_of_int n
  let add a b = "(" ^ a ^ " + " ^ b ^ ")"
end

(** Расширенная сигнатура с умножением. *)
module type EXPR_MUL = sig
  include EXPR
  val mul : t -> t -> t
end

(** Расширенное вычисление с умножением. *)
module TF_EvalMul : EXPR_MUL with type t = int = struct
  include TF_Eval
  let mul a b = a * b
end

(** Расширенное отображение с умножением. *)
module TF_ShowMul : EXPR_MUL with type t = string = struct
  include TF_Show
  let mul a b = "(" ^ a ^ " * " ^ b ^ ")"
end

(** === Способ 3: Полиморфные варианты === *)

module PolyVar = struct
  (** Базовый тип выражения с Int и Add (замкнутый рекурсивный тип). *)
  type base_expr = [ `Int of int | `Add of base_expr * base_expr ]

  (** Вычислить базовое выражение. *)
  let rec eval (e : base_expr) : int =
    match e with
    | `Int n -> n
    | `Add (a, b) -> eval a + eval b

  (** Отобразить базовое выражение. *)
  let rec show (e : base_expr) : string =
    match e with
    | `Int n -> string_of_int n
    | `Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"

  (** Расширенный тип с умножением. *)
  type mul_expr = [ `Int of int | `Add of mul_expr * mul_expr | `Mul of mul_expr * mul_expr ]

  (** Вычислить выражение с умножением. *)
  let rec eval_mul (e : mul_expr) : int =
    match e with
    | `Int n -> n
    | `Add (a, b) -> eval_mul a + eval_mul b
    | `Mul (a, b) -> eval_mul a * eval_mul b

  (** Отобразить выражение с умножением. *)
  let rec show_mul (e : mul_expr) : string =
    match e with
    | `Int n -> string_of_int n
    | `Add (a, b) -> "(" ^ show_mul a ^ " + " ^ show_mul b ^ ")"
    | `Mul (a, b) -> "(" ^ show_mul a ^ " * " ^ show_mul b ^ ")"
end
