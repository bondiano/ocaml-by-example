(* Путь к месту ошибки в JSON *)
type path = string list  (* ["user", "address", "zip"] *)

type error =
  | Type_mismatch of { expected : string; actual : string; path : path }
  | Missing_field of { field : string; path : path }
  | String_too_short of { min : int; actual : int; path : path }
  | String_too_long of { max : int; actual : int; path : path }
  | Pattern_mismatch of { pattern : string; value : string; path : path }
  | Number_too_small of { min : float; actual : float; path : path }
  | Number_too_large of { max : float; actual : float; path : path }
  | Not_multiple_of of { multiple : float; actual : float; path : path }
  | Array_too_short of { min : int; actual : int; path : path }
  | Array_too_long of { max : int; actual : int; path : path }
  | Duplicate_items of { path : path }
  | No_match_in_union of { errors : error list; path : path }

let show_path (_path : path) : string =
  (* TODO: реализуйте форматирование пути
     Пример: ["user"; "address"; "zip"] -> "user.address.zip"
     Корень: [] -> "root"
  *)
  failwith "todo"

let show_error (_err : error) : string =
  (* TODO: реализуйте человекочитаемые сообщения об ошибках
     Пример:
       String_too_short { min = 3; actual = 1; path = ["name"] }
       -> "Error at name: String too short (minimum: 3, actual: 1)"
  *)
  failwith "todo"
