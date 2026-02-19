(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Последовательный map --- применить async-функцию к списку по порядку. *)
let sequential_map (f : 'a -> 'b Lwt.t) (lst : 'a list) : 'b list Lwt.t =
  ignore f; ignore lst;
  failwith "todo"

(** Упражнение 2: Параллельный map --- применить async-функцию к списку конкурентно. *)
let concurrent_map (f : 'a -> 'b Lwt.t) (lst : 'a list) : 'b list Lwt.t =
  ignore f; ignore lst;
  failwith "todo"

(** Упражнение 3: Таймаут --- обернуть промис с ограничением по времени. *)
let timeout (seconds : float) (promise : 'a Lwt.t) : 'a option Lwt.t =
  ignore seconds; ignore promise;
  failwith "todo"

(** Упражнение 4: Ограничение параллелизма --- выполнять не более N задач одновременно. *)
let rate_limit (n : int) (tasks : (unit -> 'a Lwt.t) list) : 'a list Lwt.t =
  ignore n; ignore tasks;
  failwith "todo"
