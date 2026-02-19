(** Здесь вы можете писать свои решения упражнений. *)

open Chapter06.Hashable

(** Упражнение 1: IntSet --- множество целых чисел на сортированном списке. *)
module IntSet : Set_intf with type elt = int = struct
  type elt = int
  type t = int list

  let empty = []

  let add _x _s = failwith "todo"

  let mem _x _s = failwith "todo"

  let elements s = s

  let size s = List.length s
end

(** Упражнение 2: Функтор MakeSet параметризованный по Comparable. *)
module MakeSet (Elt : Comparable) : Set_intf with type elt = Elt.t = struct
  type elt = Elt.t
  type t = Elt.t list

  let empty = []

  let add _x _s = failwith "todo"

  let mem _x _s = failwith "todo"

  let elements s = s

  let size s = List.length s
end

(** Упражнение 3: max_element через модуль первого класса. *)
let max_element (type a) (module C : Comparable with type t = a) (_lst : a list)
    : a option =
  ignore (module C : Comparable with type t = a);
  failwith "todo"

(** Упражнение 4: ExtendedIntSet --- IntSet с дополнительными операциями. *)
module ExtendedIntSet : sig
  include Set_intf with type elt = int
  val union : t -> t -> t
  val inter : t -> t -> t
end = struct
  include IntSet

  let union _s1 _s2 = failwith "todo"

  let inter _s1 _s2 = failwith "todo"
end

(** Упражнение 5: First semigroup. *)
module First : Chapter06.Monoid.Semigroup with type t = string = struct
  type t = string
  let combine _a _b = failwith "todo"
end

(** Упражнение 6: concat_all через first-class module. *)
let concat_all (type a) (module M : Chapter06.Monoid.Monoid with type t = a)
    (_lst : a list) : a =
  ignore (module M : Chapter06.Monoid.Monoid with type t = a);
  failwith "todo"

(** Упражнение: Custom Set — множество через модуль с сигнатурой. *)
module type ORDERED = sig
  type t
  val compare : t -> t -> int
end

module MakeCustomSet (Elt : ORDERED) : sig
  type t
  type elt = Elt.t
  val empty : t
  val add : elt -> t -> t
  val mem : elt -> t -> bool
  val remove : elt -> t -> t
  val elements : t -> elt list
  val size : t -> int
  val union : t -> t -> t
  val inter : t -> t -> t
  val diff : t -> t -> t
  val is_empty : t -> bool
end = struct
  type elt = Elt.t
  type t = elt list (* заменить на реальную реализацию *)
  let empty = []
  let add _x _s = failwith "todo"
  let mem _x _s = failwith "todo"
  let remove _x _s = failwith "todo"
  let elements _s = failwith "todo"
  let size _s = failwith "todo"
  let union _s1 _s2 = failwith "todo"
  let inter _s1 _s2 = failwith "todo"
  let diff _s1 _s2 = failwith "todo"
  let is_empty _s = failwith "todo"
end
