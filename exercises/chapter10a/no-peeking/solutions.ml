(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

(** Упражнение 1 (Лёгкое): PositiveInt --- smart constructor. *)
module PositiveInt : sig
  type t
  val make : int -> (t, string) result
  val value : t -> int
  val add : t -> t -> t
  val to_string : t -> string
end = struct
  type t = int

  let make n =
    if n > 0 then Ok n
    else Error "число должно быть положительным"

  let value t = t
  let add a b = a + b
  let to_string = string_of_int
end

(** Упражнение 2 (Среднее): Email --- smart constructor. *)
module Email : sig
  type t
  val make : string -> (t, string) result
  val to_string : t -> string
end = struct
  type t = string

  let make s =
    if String.length s = 0 then
      Error "email не может быть пустым"
    else if not (String.contains s '@') then
      Error "email должен содержать @"
    else
      let parts = String.split_on_char '@' s in
      match parts with
      | [_local; domain] when String.contains domain '.' -> Ok s
      | _ -> Error "некорректный домен"

  let to_string t = t
end

(** Упражнение 3 (Среднее): NonEmptyList. *)
module NonEmptyList : sig
  type 'a t
  val make : 'a list -> ('a t, string) result
  val singleton : 'a -> 'a t
  val head : 'a t -> 'a
  val tail : 'a t -> 'a list
  val to_list : 'a t -> 'a list
  val length : 'a t -> int
  val map : ('a -> 'b) -> 'a t -> 'b t
end = struct
  type 'a t = 'a * 'a list

  let make = function
    | [] -> Error "список не может быть пустым"
    | x :: xs -> Ok (x, xs)

  let singleton x = (x, [])
  let head (x, _) = x
  let tail (_, xs) = xs
  let to_list (x, xs) = x :: xs
  let length (_, xs) = 1 + List.length xs
  let map f (x, xs) = (f x, List.map f xs)
end

(** Упражнение 4 (Среднее): TrafficLight --- FSM на phantom types. *)
module TrafficLight : sig
  type red
  type yellow
  type green

  type 'state light

  val start : red light
  val red_to_green : red light -> green light
  val green_to_yellow : green light -> yellow light
  val yellow_to_red : yellow light -> red light
  val show : 'state light -> string
end = struct
  type red
  type yellow
  type green

  type 'state light = { color : string }

  let start = { color = "red" }
  let red_to_green _l = { color = "green" }
  let green_to_yellow _l = { color = "yellow" }
  let yellow_to_red _l = { color = "red" }
  let show l = l.color
end

(** Упражнение 5 (Сложное): Form --- строитель формы с накоплением ошибок. *)
