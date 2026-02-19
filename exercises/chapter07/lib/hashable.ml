(** Библиотека хэширования на модулях и функторах. *)

(** Сигнатура для сравнимых типов. *)
module type Comparable = sig
  type t
  val compare : t -> t -> int
end

(** Сигнатура для хэшируемых типов. *)
module type Hashable = sig
  type t
  val hash : t -> int
end

(** Сигнатура множества. *)
module type Set_intf = sig
  type elt
  type t
  val empty : t
  val add : elt -> t -> t
  val mem : elt -> t -> bool
  val elements : t -> elt list
  val size : t -> int
end

(** Комбинирование хэшей. *)
let combine h1 h2 = h1 * 31 + h2

(** Хэширование целых чисел. *)
module IntHash : Hashable with type t = int = struct
  type t = int
  let hash x = x
end

(** Хэширование строк. *)
module StringHash : Hashable with type t = string = struct
  type t = string
  let hash s =
    String.fold_left (fun acc c -> combine acc (Char.code c)) 0 s
end

(** Функтор для хэширования пар. *)
module PairHash (H1 : Hashable) (H2 : Hashable)
  : Hashable with type t = H1.t * H2.t = struct
  type t = H1.t * H2.t
  let hash (a, b) = combine (H1.hash a) (H2.hash b)
end

(** Функтор для создания HashSet. *)
module MakeHashSet (H : Hashable) : sig
  type t
  val empty : t
  val add : H.t -> t -> t
  val mem : H.t -> t -> bool
  val to_list : t -> H.t list
end = struct
  let num_buckets = 16
  type t = H.t list array

  let empty = Array.make num_buckets []

  let bucket_index x = abs (H.hash x) mod num_buckets

  let add x s =
    let s' = Array.copy s in
    let i = bucket_index x in
    if not (List.mem x s'.(i)) then
      s'.(i) <- x :: s'.(i);
    s'

  let mem x s =
    List.mem x s.(bucket_index x)

  let to_list s =
    Array.to_list s |> List.concat
end

(** === Паттерн modules-as-types === *)

(** Пример: модуль User с type t и smart constructor. *)
module User = struct
  type t = {
    name : string;
    age : int;
  }

  let make ~name ~age =
    if age < 0 then invalid_arg "User.make: age must be non-negative";
    { name; age }

  let name u = u.name
  let age u = u.age
  let to_string u = Printf.sprintf "%s (age %d)" u.name u.age
end

(** === IO-агностичные библиотеки === *)

(** Сигнатура абстрактного IO. *)
module type IO = sig
  type +'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end

(** Сервис, параметризованный IO. *)
module Make_service (IO : IO) : sig
  val process : string -> string IO.t
  val process_all : string list -> string list IO.t
end = struct
  let process data =
    IO.bind (IO.return (String.uppercase_ascii data)) (fun upper ->
    IO.return ("processed: " ^ upper))

  let process_all items =
    List.fold_left (fun acc item ->
      IO.bind acc (fun results ->
      IO.bind (process item) (fun result ->
      IO.return (results @ [result])))
    ) (IO.return []) items
end

(** Синхронная реализация IO. *)
module Sync_IO : IO with type 'a t = 'a = struct
  type 'a t = 'a
  let return x = x
  let bind x f = f x
end

(** Инстанцирование сервиса для синхронного IO. *)
module Sync_service = Make_service(Sync_IO)
