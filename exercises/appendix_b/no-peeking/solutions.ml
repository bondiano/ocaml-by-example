(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

(** Упражнение 1: Последовательный map. *)
let sequential_map (f : 'a -> 'b Lwt.t) (lst : 'a list) : 'b list Lwt.t =
  let open Lwt.Syntax in
  List.fold_left
    (fun acc x ->
      let* results = acc in
      let* result = f x in
      Lwt.return (results @ [result]))
    (Lwt.return [])
    lst

(** Упражнение 2: Параллельный map. *)
let concurrent_map (f : 'a -> 'b Lwt.t) (lst : 'a list) : 'b list Lwt.t =
  Lwt.all (List.map f lst)

(** Упражнение 3: Таймаут. *)
let timeout (seconds : float) (promise : 'a Lwt.t) : 'a option Lwt.t =
  let open Lwt.Syntax in
  let timer =
    let* () = Lwt_unix.sleep seconds in
    Lwt.return None
  in
  let wrapped =
    let* v = promise in
    Lwt.return (Some v)
  in
  Lwt.pick [wrapped; timer]

(** Упражнение 4: Ограничение параллелизма. *)
let rate_limit (n : int) (tasks : (unit -> 'a Lwt.t) list) : 'a list Lwt.t =
  let open Lwt.Syntax in
  let sem = Lwt_mutex.create () in
  let running = ref 0 in
  let condition = Lwt_condition.create () in
  let run_task task =
    let rec wait () =
      if !running >= n then
        let* () = Lwt_condition.wait ~mutex:sem condition in
        wait ()
      else (
        running := !running + 1;
        Lwt.return ())
    in
    let* () = Lwt_mutex.with_lock sem (fun () -> wait ()) in
    Lwt.finalize
      (fun () -> task ())
      (fun () ->
        Lwt_mutex.with_lock sem (fun () ->
          running := !running - 1;
          Lwt_condition.signal condition ();
          Lwt.return ()))
  in
  Lwt.all (List.map run_task tasks)
