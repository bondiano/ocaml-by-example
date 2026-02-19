(** Здесь вы можете писать свои решения упражнений. *)

open Chapter04.Address_book

let find_entry_by_street (_street_name : string) (_book : entry list) : entry option =
  failwith "todo"

let entry_exists ~first_name:(_first_name : string) ~last_name:(_last_name : string)
    (_book : entry list) : bool =
  failwith "todo"

let remove_duplicates (_book : entry list) : entry list =
  failwith "todo"

(** Упражнение: Two-Fer *)
let two_fer ?(name = "you") () : string = ignore name; failwith "todo"

(** Упражнение: Grade School — управление списком учеников по классам. *)
module GradeSchool = struct
  type t = (int * string list) list

  let empty : t = []
  let add (_student : string) (_grade : int) (_school : t) : t = failwith "todo"
  let grade (_grade : int) (_school : t) : string list = failwith "todo"
  let sorted (_school : t) : (int * string list) list = failwith "todo"
end
