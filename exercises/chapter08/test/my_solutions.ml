(** Здесь вы можете писать свои решения упражнений. *)

open Chapter08.Validation

let validate_phone (_phone : string) : (string, string list) result =
  failwith "todo"

let validate_person (_first : string) (_last : string)
    (_street : string) (_city : string) (_state : string)
    : (person, string list) result =
  failwith "todo"

let traverse_result : ('a -> ('b, 'e) result) -> 'a list -> ('b list, 'e list) result =
  fun _f _lst -> failwith "todo"

let option_to_result ~error:(_error : 'e) (_opt : 'a option) : ('a, 'e) result =
  failwith "todo"

let result_to_option (_r : ('a, 'e) result) : 'a option =
  failwith "todo"

(** Упражнение: ISBN Verifier *)
let isbn_verifier (_isbn : string) : bool = failwith "todo"

(** Упражнение: Luhn algorithm *)
let luhn (_number : string) : bool = failwith "todo"

(** Упражнение: валидация с полиморфными вариантами *)
let validate_email (_email : string)
    : (string, [> `EmptyEmail | `NoAtSign | `InvalidDomain of string]) result =
  failwith "todo"
