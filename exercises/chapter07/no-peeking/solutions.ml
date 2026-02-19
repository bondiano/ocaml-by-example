(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Chapter07.Hashable

(** Множество целых чисел на сортированном списке. *)
module IntSet : Set_intf with type elt = int = struct
  type elt = int
  type t = int list

  let empty = []

  let rec add x = function
    | [] -> [x]
    | (y :: _) as lst when x < y -> x :: lst
    | y :: rest when x = y -> y :: rest
    | y :: rest -> y :: add x rest

  let rec mem x = function
    | [] -> false
    | y :: _ when x = y -> true
    | y :: rest when x > y -> mem x rest
    | _ -> false

  let elements s = s

  let size s = List.length s
end

(** Функтор MakeSet параметризованный по Comparable. *)
module MakeSet (Elt : Comparable) : Set_intf with type elt = Elt.t = struct
  type elt = Elt.t
  type t = Elt.t list

  let empty = []

  let rec add x = function
    | [] -> [x]
    | (y :: _) as lst when Elt.compare x y < 0 -> x :: lst
    | y :: rest when Elt.compare x y = 0 -> y :: rest
    | y :: rest -> y :: add x rest

  let rec mem x = function
    | [] -> false
    | y :: _ when Elt.compare x y = 0 -> true
    | y :: rest when Elt.compare x y > 0 -> mem x rest
    | _ -> false

  let elements s = s

  let size s = List.length s
end

(** max_element через модуль первого класса. *)
let max_element (type a) (module C : Comparable with type t = a) (lst : a list)
    : a option =
  match lst with
  | [] -> None
  | x :: rest ->
    Some (List.fold_left (fun acc y ->
      if C.compare y acc > 0 then y else acc
    ) x rest)

(** ExtendedIntSet --- IntSet с дополнительными операциями. *)
module ExtendedIntSet : sig
  include Set_intf with type elt = int
  val union : t -> t -> t
  val inter : t -> t -> t
end = struct
  include IntSet

  let union s1 s2 =
    List.fold_left (fun acc x -> add x acc) s1 (elements s2)

  let inter s1 s2 =
    elements s1 |> List.filter (fun x -> mem x s2)
    |> List.fold_left (fun acc x -> add x acc) empty
end

(** First semigroup. *)
module First : Chapter07.Monoid.Semigroup with type t = string = struct
  type t = string
  let combine a _b = a
end

(** concat_all через first-class module. *)
let concat_all (type a) (module M : Chapter07.Monoid.Monoid with type t = a)
    (lst : a list) : a =
  List.fold_left M.combine M.empty lst

(** Custom Set — Exercism Hard. *)
module type ORDERED = sig
  type t
  val compare : t -> t -> int
end

module MakeCustomSet (Elt : ORDERED) = struct
  type elt = Elt.t
  type t = elt list  (* sorted list *)

  let empty = []
  let is_empty = function [] -> true | _ -> false

  let rec add x = function
    | [] -> [x]
    | (y :: _) as lst when Elt.compare x y < 0 -> x :: lst
    | y :: rest when Elt.compare x y = 0 -> y :: rest
    | y :: rest -> y :: add x rest

  let rec mem x = function
    | [] -> false
    | y :: _ when Elt.compare x y = 0 -> true
    | y :: rest when Elt.compare x y > 0 -> mem x rest
    | _ -> false

  let rec remove x = function
    | [] -> []
    | y :: rest when Elt.compare x y = 0 -> rest
    | y :: rest when Elt.compare x y > 0 -> y :: remove x rest
    | lst -> lst

  let elements s = s
  let size s = List.length s

  let union s1 s2 = List.fold_left (fun acc x -> add x acc) s1 s2

  let inter s1 s2 = List.filter (fun x -> mem x s2) s1

  let diff s1 s2 = List.filter (fun x -> not (mem x s2)) s1
end
