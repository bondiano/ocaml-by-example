(** Примеры конкурентного программирования с Lwt. *)

(** Задержка на заданное количество секунд. *)
let delay seconds =
  Lwt_unix.sleep seconds

(** Последовательное выполнение списка Lwt-действий. *)
let sequence (tasks : 'a Lwt.t list) : 'a list Lwt.t =
  let open Lwt.Syntax in
  List.fold_left
    (fun acc task ->
      let* results = acc in
      let* result = task in
      Lwt.return (results @ [result]))
    (Lwt.return [])
    tasks

(** Запуск двух задач параллельно, возврат пары результатов. *)
let parallel2 (a : 'a Lwt.t) (b : 'b Lwt.t) : ('a * 'b) Lwt.t =
  Lwt.both a b

(** Первый из двух --- кто быстрее. *)
let race (a : 'a Lwt.t) (b : 'a Lwt.t) : 'a Lwt.t =
  Lwt.pick [a; b]

(** Пример: параллельная задержка. *)
let parallel_delays () =
  let open Lwt.Syntax in
  let t1 =
    let* () = delay 0.1 in
    Lwt.return "first"
  in
  let t2 =
    let* () = delay 0.2 in
    Lwt.return "second"
  in
  let* results = Lwt.all [t1; t2] in
  Lwt.return results

(** Пример: гонка задач. *)
let race_example () =
  let open Lwt.Syntax in
  let slow =
    let* () = delay 1.0 in
    Lwt.return "slow"
  in
  let fast =
    let* () = delay 0.01 in
    Lwt.return "fast"
  in
  race fast slow

(** === Продвинутые паттерны Lwt === *)

(** Timeout: выполнить задачу с ограничением по времени. *)
let with_timeout seconds task =
  Lwt.pick [
    task;
    (let open Lwt.Syntax in
     let* () = Lwt_unix.sleep seconds in
     Lwt.fail_with "timeout");
  ]

(** Never-promise: промис, который никогда не разрешится. *)
let never () : _ Lwt.t = fst (Lwt.wait ())

(** Retry: повторить операцию до N раз при ошибке. *)
let retry ~max_attempts f =
  let open Lwt.Syntax in
  let rec loop attempt =
    Lwt.catch f (fun exn ->
      if attempt >= max_attempts then Lwt.fail exn
      else
        let* () = Lwt_unix.sleep (0.1 *. float_of_int attempt) in
        loop (attempt + 1))
  in
  loop 1

(** Параллельная обработка списка с ограничением concurrency. *)
let map_with_concurrency ~max_concurrent f items =
  let open Lwt.Syntax in
  let sem = Lwt_mutex.create () in
  let count = ref 0 in
  let cond = Lwt_condition.create () in
  let process item =
    let rec wait_slot () =
      if !count >= max_concurrent then
        let* () = Lwt_condition.wait ~mutex:sem cond in
        wait_slot ()
      else (
        incr count;
        Lwt.return_unit)
    in
    let* () = Lwt_mutex.with_lock sem wait_slot in
    Lwt.finalize
      (fun () -> f item)
      (fun () ->
        Lwt_mutex.with_lock sem (fun () ->
          decr count;
          Lwt_condition.signal cond ();
          Lwt.return_unit))
  in
  Lwt_list.map_p process items
