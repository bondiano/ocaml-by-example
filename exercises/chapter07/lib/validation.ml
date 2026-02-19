(** Библиотека валидации. *)

(** Адрес. *)
type address = {
  street : string;
  city : string;
  state : string;
}

(** Персона. *)
type person = {
  first_name : string;
  last_name : string;
  address : address;
}

(** Список ошибок. *)
type errors = string list

(** Let-операторы для Result. *)
module Result_syntax = struct
  let ( let* ) = Result.bind
  let ( let+ ) x f = Result.map f x
end

(** Проверка: строка не пустая. *)
let non_empty field_name value =
  if String.length (String.trim value) = 0 then
    Error (field_name ^ " не может быть пустым")
  else Ok ()

(** Проверка: максимальная длина. *)
let max_length field_name n value =
  if String.length value > n then
    Error (field_name ^ " не может быть длиннее " ^ string_of_int n ^ " символов")
  else Ok ()

(** Проверка: минимальная длина. *)
let min_length field_name n value =
  if String.length value < n then
    Error (field_name ^ " должен быть не короче " ^ string_of_int n ^ " символов")
  else Ok ()

(** Проверка: все символы --- цифры. *)
let digits_only field_name value =
  if String.length value > 0
     && not (String.for_all (fun c -> c >= '0' && c <= '9') value) then
    Error (field_name ^ " должен содержать только цифры")
  else Ok ()

(** Применить список валидаций и собрать все ошибки. *)
let validate_all validations input =
  let errors = List.filter_map (fun v ->
    match v input with
    | Ok () -> None
    | Error e -> Some e
  ) validations
  in
  match errors with
  | [] -> Ok input
  | es -> Error es

(** Валидация адреса с накоплением ошибок. *)
let validate_address street city state =
  let errors =
    (match validate_all [non_empty "Улица"; max_length "Улица" 100] street with
     | Ok _ -> [] | Error es -> es)
    @ (match validate_all [non_empty "Город"; max_length "Город" 50] city with
       | Ok _ -> [] | Error es -> es)
    @ (match validate_all [non_empty "Регион"; max_length "Регион" 50] state with
       | Ok _ -> [] | Error es -> es)
  in
  match errors with
  | [] -> Ok { street; city; state }
  | es -> Error es

(** Конвертация option -> result. *)
let option_to_result ~error = function
  | Some x -> Ok x
  | None -> Error error

(** Конвертация result -> option. *)
let result_to_option = function
  | Ok x -> Some x
  | Error _ -> None

(** === Продвинутая обработка ошибок === *)

(** Полиморфные варианты для composable ошибок. *)

(** Парсер с типизированными ошибками. *)
module Parser = struct
  type tree = Leaf of string | Node of tree * tree

  type error = [ `SyntaxError of string | `UnexpectedChar of char ]

  let parse (s : string) : (tree, [> error]) result =
    if String.length s = 0 then Error (`SyntaxError "empty input")
    else if s.[0] = '!' then Error (`UnexpectedChar '!')
    else Ok (Leaf s)
end

(** Валидатор с типизированными ошибками. *)
module Validator = struct
  type error = [ `TooShort of int | `TooLong of int ]

  let validate (tree : Parser.tree) : (Parser.tree, [> error]) result =
    match tree with
    | Leaf s when String.length s < 2 -> Error (`TooShort (String.length s))
    | Leaf s when String.length s > 100 -> Error (`TooLong (String.length s))
    | _ -> Ok tree
end

(** Композиция ошибок через let* — типы объединяются автоматически. *)
let process_input (s : string)
    : (Parser.tree, [> Parser.error | Validator.error]) result =
  let ( let* ) = Result.bind in
  let* tree = Parser.parse s in
  let* tree = Validator.validate tree in
  Ok tree

(** and* оператор для параллельного сбора ошибок. *)
let ( and* ) left right =
  match left, right with
  | Ok l, Ok r -> Ok (l, r)
  | Error l, Error r -> Error (l @ r)
  | Error e, _ | _, Error e -> Error e

(** Outcome type — результат с возможными предупреждениями. *)
type ('ok, 'warning) outcome = {
  result : 'ok option;
  warnings : 'warning list;
}

let outcome_ok ?(warnings = []) result =
  { result = Some result; warnings }

let outcome_fail warnings =
  { result = None; warnings }

let outcome_map f o =
  { o with result = Option.map f o.result }
