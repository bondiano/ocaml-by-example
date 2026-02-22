(** Здесь вы можете писать свои решения упражнений. *)

(* ===== Расширение вариантных типов ===== *)

(* Лёгкое *)
(** Упражнение 1: VariantMul — добавить операцию умножения.

    Расширить вариантный тип expr добавлением конструктора Mul.

    Исходный тип:
    {[
      type expr =
        | Int of int
        | Add of expr * expr
    ]}

    Новый тип (добавлен Mul):
    {[
      type expr =
        | Int of int
        | Add of expr * expr
        | Mul of expr * expr
    ]}

    Реализовать:
    - eval: вычислить выражение
    - show: преобразовать в строку с правильными скобками

    Примеры:
    {[
      let e1 = Add (Int 2, Mul (Int 3, Int 4))
      VariantMul.eval e1 = 14  (* 2 + (3 * 4) *)
      VariantMul.show e1 = "2 + (3 * 4)"

      let e2 = Mul (Add (Int 1, Int 2), Int 3)
      VariantMul.eval e2 = 9   (* (1 + 2) * 3 *)
      VariantMul.show e2 = "(1 + 2) * 3"
    ]}

    Подсказки:
    1. eval: pattern matching на все три случая
       | Int n -> n
       | Add (a, b) -> eval a + eval b
       | Mul (a, b) -> eval a * eval b
    2. show: используйте Printf.sprintf для форматирования
    3. Добавляйте скобки для вложенных выражений

    Связанные темы: Variant types, expression problem, recursion
    Время: ~8 минут *)
module VariantMul = struct
  type expr =
    | Int of int
    | Add of expr * expr
    | Mul of expr * expr

  let rec eval = function
    | Int _n -> failwith "todo"
    | Add (_a, _b) -> failwith "todo"
    | Mul (_a, _b) -> failwith "todo"

  let rec show = function
    | Int _n -> failwith "todo"
    | Add (_a, _b) -> failwith "todo"
    | Mul (_a, _b) -> failwith "todo"
end

(* ===== Tagless Final ===== *)

(* Среднее *)
(** Упражнение 2: TF_Pretty — pretty printer в Tagless Final стиле.

    Реализовать интерпретатор pretty-printing для выражений.

    Сигнатура (определена в lib):
    {[
      module type EXPR = sig
        type t
        val int_ : int -> t
        val add : t -> t -> t
      end
    ]}

    Задача: реализовать модуль TF_Pretty где type t = string

    Примеры:
    {[
      TF_Pretty.int_ 42 = "42"
      TF_Pretty.add (TF_Pretty.int_ 1) (TF_Pretty.int_ 2) = "(1 + 2)"
    ]}

    Подсказки:
    1. type t = string — представление это строка
    2. int_ n = string_of_int n
    3. add a b = Printf.sprintf "(%s + %s)" a b
    4. Скобки для ясности структуры

    Связанные темы: Tagless final, interpreter pattern, pretty printing
    Время: ~12 минут *)
module TF_Pretty : Chapter11.Expr.EXPR with type t = string = struct
  type t = string
  let int_ (_n : int) : t = failwith "todo"
  let add (_a : t) (_b : t) : t = failwith "todo"
end

(* ===== Полиморфные варианты ===== *)

(* Среднее *)
(** Упражнение 3: Polymorphic Variants с Neg — расширение без модификации.

    Полиморфные варианты позволяют добавлять конструкторы без изменения
    исходного определения типа.

    Тип:
    {[
      type neg_expr = [ `Int of int | `Add of neg_expr * neg_expr | `Neg of neg_expr ]
    ]}

    Реализовать:
    - eval_neg: вычислить выражение (Neg инвертирует знак)
    - show_neg: преобразовать в строку

    Примеры:
    {[
      eval_neg (`Int 5) = 5
      eval_neg (`Add (`Int 3, `Int 4)) = 7
      eval_neg (`Neg (`Int 5)) = -5
      eval_neg (`Neg (`Add (`Int 3, `Int 2))) = -5

      show_neg (`Int 42) = "42"
      show_neg (`Neg (`Int 5)) = "-(5)"
      show_neg (`Add (`Int 1, `Neg (`Int 2))) = "(1 + -(2))"
    ]}

    Подсказки:
    1. Рекурсивные функции с pattern matching
    2. `Neg a -> -(eval_neg a)
    3. Скобки для отрицательных подвыражений

    Связанные темы: Polymorphic variants, expression problem, extensibility
    Время: ~15 минут *)
type neg_expr = [ `Int of int | `Add of neg_expr * neg_expr | `Neg of neg_expr ]

let rec eval_neg (e : neg_expr) : int =
  match e with
  | `Int _n -> failwith "todo"
  | `Add (_a, _b) -> failwith "todo"
  | `Neg _a -> failwith "todo"

let rec show_neg (e : neg_expr) : string =
  match e with
  | `Int _n -> failwith "todo"
  | `Add (_a, _b) -> failwith "todo"
  | `Neg _a -> failwith "todo"

(* ===== Tagless Final — булевы выражения ===== *)

(* Среднее *)
(** Упражнение 4: Bool_Eval и Bool_Show — DSL для булевых выражений.

    Создать DSL для булевых выражений в стиле Tagless Final.

    Сигнатура:
    {[
      module type BOOL_EXPR = sig
        type t
        val bool_ : bool -> t
        val and_ : t -> t -> t
        val or_ : t -> t -> t
        val not_ : t -> t
      end
    ]}

    Реализовать два интерпретатора:
    - Bool_Eval: вычислить (type t = bool)
    - Bool_Show: преобразовать в строку (type t = string)

    Примеры:
    {[
      (* Eval *)
      Bool_Eval.bool_ true = true
      Bool_Eval.and_ (Bool_Eval.bool_ true) (Bool_Eval.bool_ false) = false
      Bool_Eval.not_ (Bool_Eval.bool_ false) = true

      (* Show *)
      Bool_Show.bool_ true = "true"
      Bool_Show.and_ (Bool_Show.bool_ true) (Bool_Show.bool_ false) = "(true && false)"
      Bool_Show.or_ (Bool_Show.bool_ true) (Bool_Show.bool_ false) = "(true || false)"
      Bool_Show.not_ (Bool_Show.bool_ true) = "!true"
    ]}

    Подсказки:
    1. Bool_Eval: используйте встроенные операторы (&&), (||), not
    2. Bool_Show: форматируйте с помощью Printf.sprintf
    3. and_ a b = Printf.sprintf "(%s && %s)" a b
    4. not_ a = "!" ^ a

    Связанные темы: Tagless final, DSL design, multiple interpretations
    Время: ~18 минут *)
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

(* ===== Объединение DSL ===== *)

(* Сложное *)
(** Упражнение 5: Combined_Show — объединённый DSL для арифметики и булевых операций.

    Создать единый DSL который поддерживает:
    - Арифметические выражения (int, add)
    - Булевы выражения (bool, and, or, not)
    - Сравнение (eq)

    Сигнатура:
    {[
      module type COMBINED_EXPR = sig
        type t
        val int_ : int -> t
        val add : t -> t -> t
        val bool_ : bool -> t
        val and_ : t -> t -> t
        val or_ : t -> t -> t
        val not_ : t -> t
        val eq : t -> t -> t  (* равенство *)
      end
    ]}

    Реализовать Combined_Show: type t = string

    Примеры:
    {[
      Combined_Show.int_ 42 = "42"
      Combined_Show.bool_ true = "true"
      Combined_Show.add (Combined_Show.int_ 1) (Combined_Show.int_ 2) = "(1 + 2)"
      Combined_Show.and_ (Combined_Show.bool_ true) (Combined_Show.bool_ false) = "(true && false)"

      (* Сравнение *)
      Combined_Show.eq (Combined_Show.int_ 5) (Combined_Show.int_ 5) = "(5 == 5)"

      (* Комбинированное выражение *)
      Combined_Show.and_
        (Combined_Show.eq (Combined_Show.int_ 1) (Combined_Show.int_ 1))
        (Combined_Show.bool_ true)
        = "((1 == 1) && true)"
    ]}

    Подсказки:
    1. type t = string — всё представляется строками
    2. int_ n = string_of_int n
    3. bool_ b = string_of_bool b
    4. add a b = Printf.sprintf "(%s + %s)" a b
    5. and_ a b = Printf.sprintf "(%s && %s)" a b
    6. or_ a b = Printf.sprintf "(%s || %s)" a b
    7. not_ a = "!" ^ a
    8. eq a b = Printf.sprintf "(%s == %s)" a b

    Связанные темы: Tagless final, DSL composition, unified syntax
    Время: ~25 минут *)
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
