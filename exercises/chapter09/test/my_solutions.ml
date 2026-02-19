(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Счётчик на ref. *)
let counter_create (_init : int) : int ref =
  failwith "todo"

let counter_increment (_c : int ref) : unit =
  failwith "todo"

let counter_decrement (_c : int ref) : unit =
  failwith "todo"

let counter_reset (_c : int ref) : unit =
  failwith "todo"

let counter_value (_c : int ref) : int =
  failwith "todo"

(** Упражнение 2: Логгер. *)
type logger = {
  mutable messages : string list;
}

let logger_create () : logger =
  failwith "todo"

let logger_log (_l : logger) (_msg : string) : unit =
  failwith "todo"

let logger_messages (_l : logger) : string list =
  failwith "todo"

let logger_clear (_l : logger) : unit =
  failwith "todo"

let logger_count (_l : logger) : int =
  failwith "todo"

(** Упражнение 3: Форматирование таблицы. *)
let format_table (_rows : (string * string) list) : string =
  failwith "todo"

(** Упражнение 4: Сумма массива через for-цикл. *)
let array_sum_imperative (_arr : int array) : int =
  failwith "todo"

(** Упражнение: Robot Name — уникальные имена роботов. *)
module Robot = struct
  type t = { name : string }
  let _used_names : (string, unit) Hashtbl.t = Hashtbl.create 100

  let create () : t = failwith "todo"
  let name (_robot : t) : string = failwith "todo"
  let reset (_robot : t) : t = failwith "todo"
end

(** Упражнение: simple LRU cache. *)
module LRU = struct
  type ('k, 'v) t = {
    mutable entries : ('k * 'v) list;
    capacity : int;
  }

  let create (_capacity : int) : ('k, 'v) t = failwith "todo"
  let get (_cache : ('k, 'v) t) (_key : 'k) : 'v option = failwith "todo"
  let put (_cache : ('k, 'v) t) (_key : 'k) (_value : 'v) : unit = failwith "todo"
  let size (_cache : ('k, 'v) t) : int = failwith "todo"
end

(** Упражнение 7: Logger FC/IS --- Functional Core. *)
module LoggerPure = struct
  let add (_msgs : string list) (_msg : string) : string list = failwith "todo"
  let count (_msgs : string list) : int = failwith "todo"
  let messages (_msgs : string list) : string list = failwith "todo"
end

(** Logger FC/IS --- Imperative Shell. *)
module LoggerShell = struct
  type t = { mutable msgs : string list }
  let create () : t = failwith "todo"
  let log (_l : t) (_msg : string) : unit = failwith "todo"
  let messages (_l : t) : string list = failwith "todo"
  let count (_l : t) : int = failwith "todo"
  let clear (_l : t) : unit = failwith "todo"
end

(** Упражнение: Bowling — подсчёт очков в боулинге. *)
module Bowling = struct
  type t = {
    mutable rolls : int list;
    mutable current_frame : int;
    mutable finished : bool;
  }

  let create () : t = failwith "todo"
  let roll (_game : t) (_pins : int) : (unit, string) result = failwith "todo"
  let score (_game : t) : int = failwith "todo"
end
