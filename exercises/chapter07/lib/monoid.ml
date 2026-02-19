(** Полугруппы и моноиды. *)

(** Полугруппа: тип с ассоциативной операцией. *)
module type Semigroup = sig
  type t
  val combine : t -> t -> t
end

(** Моноид: полугруппа с нейтральным элементом. *)
module type Monoid = sig
  include Semigroup
  val empty : t
end

(** Моноид целых чисел (сложение). *)
module IntSumMonoid : Monoid with type t = int = struct
  type t = int
  let combine = ( + )
  let empty = 0
end

(** Моноид целых чисел (умножение). *)
module IntProductMonoid : Monoid with type t = int = struct
  type t = int
  let combine = ( * )
  let empty = 1
end

(** Моноид строк (конкатенация). *)
module StringMonoid : Monoid with type t = string = struct
  type t = string
  let combine = ( ^ )
  let empty = ""
end

(** Функтор: из полугруппы делаем моноид через option. *)
module OptionMonoid (S : Semigroup) : Monoid with type t = S.t option = struct
  type t = S.t option
  let empty = None
  let combine a b =
    match a, b with
    | None, x | x, None -> x
    | Some x, Some y -> Some (S.combine x y)
end

(** Свернуть список через моноид. *)
let concat_all (type a) (module M : Monoid with type t = a) (lst : a list) : a =
  List.fold_left M.combine M.empty lst
