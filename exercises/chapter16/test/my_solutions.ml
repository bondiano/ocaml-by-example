(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Парсер списка целых чисел "[1, 2, 3]". *)
let int_list_parser : int list Angstrom.t =
  Angstrom.fail "todo"

(** Упражнение 2: Парсер key=value пар "key=value". *)
let key_value_parser : (string * string) Angstrom.t =
  Angstrom.fail "todo"

(** Упражнение 3: GADT --- добавить оператор Not для bool expr. *)
type _ extended_expr =
  | Int : int -> int extended_expr
  | Bool : bool -> bool extended_expr
  | Add : int extended_expr * int extended_expr -> int extended_expr
  | Not : bool extended_expr -> bool extended_expr
  | Gt : int extended_expr * int extended_expr -> bool extended_expr

let eval_extended : type a. a extended_expr -> a = function
  | _ -> failwith "todo"

(** Упражнение 4: Парсер арифметических выражений с [+] и [*]. *)
let arith_parser : int Angstrom.t =
  Angstrom.fail "todo"

(** Упражнение: Matching Brackets — проверка парности скобок. *)
let matching_brackets (_s : string) : bool = failwith "todo"

(** Упражнение: Word Count — подсчёт слов в строке. *)
let word_count (_s : string) : (string * int) list = failwith "todo"
