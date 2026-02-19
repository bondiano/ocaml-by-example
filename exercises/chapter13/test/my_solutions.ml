(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Эффект Emit --- испускание значений. *)
type _ Effect.t += Emit : int -> unit Effect.t

let run_emit (f : unit -> 'a) : 'a * int list =
  ignore f;
  failwith "todo"

(** Упражнение 2: Эффект Reader --- чтение из окружения. *)
type _ Effect.t += Ask : string Effect.t

let run_reader (env : string) (f : unit -> 'a) : 'a =
  ignore (env, f);
  failwith "todo"

(** Упражнение 3: Композиция State + Emit. *)
let count_and_emit (n : int) : unit =
  ignore n;
  failwith "todo"

(** Упражнение 4: Эффект Fail с обработкой ошибок. *)
type _ Effect.t += Fail : string -> 'a Effect.t

let run_fail (f : unit -> 'a) : ('a, string) result =
  ignore f;
  failwith "todo"

(** Упражнение 5: Генератор квадратов. *)
type _ Effect.t += Yield : int -> unit Effect.t

let squares (_n : int) : int list =
  failwith "todo"

(** Упражнение 6: Async/await через эффекты. *)
type _ Effect.t += Async : (unit -> 'a) -> 'a Effect.t

let run_async (f : unit -> 'a) : 'a =
  ignore f;
  failwith "todo"
