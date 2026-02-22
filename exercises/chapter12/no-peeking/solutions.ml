(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

(** Вычислить число Фибоначчи. *)
let rec fib n =
  if n <= 1 then n
  else fib (n - 1) + fib (n - 2)

(** Параллельное вычисление двух чисел Фибоначчи. *)
let parallel_fib n m =
  let result_n = ref 0 in
  let result_m = ref 0 in
  Eio.Fiber.both
    (fun () -> result_n := fib n)
    (fun () -> result_m := fib m);
  !result_n + !result_m

(** Конкурентный map. *)
let concurrent_map f lst =
  Eio.Fiber.List.map f lst

(** Producer-consumer с суммированием. *)
let produce_consume n =
  let stream = Eio.Stream.create 10 in
  let total = ref 0 in
  Eio.Fiber.both
    (fun () ->
      for i = 1 to n do
        Eio.Stream.add stream (Some i)
      done;
      Eio.Stream.add stream None)
    (fun () ->
      let rec loop () =
        match Eio.Stream.take stream with
        | None -> ()
        | Some v ->
          total := !total + v;
          loop ()
      in
      loop ());
  !total

(** Гонка --- результат первой завершившейся функции. *)
let race tasks =
  Eio.Fiber.any tasks

(** Uppercase echo server. *)
let uppercase_echo_server ~net ~port =
  let addr = `Tcp (Eio.Net.Ipaddr.V4.any, port) in
  Eio.Net.listen net addr ~backlog:10 ~reuse_addr:true (fun flow _addr ->
    try
      let buf = Eio.Buf_read.of_flow flow ~max_size:4096 in
      while true do
        let line = Eio.Buf_read.line buf in
        let upper = String.uppercase_ascii line in
        Eio.Flow.copy_string (upper ^ "\n") flow
      done
    with End_of_file -> ())

(** Rate limiter. *)
let rate_limit ~clock f items delay =
  let rec process = function
    | [] -> []
    | x :: xs ->
      let result = f x in
      if xs <> [] then Eio.Time.sleep clock delay;
      result :: process xs
  in
  process items

(** Worker pool. *)
let worker_pool n_workers tasks =
  let task_stream = Eio.Stream.create (List.length tasks) in
  let result_stream = Eio.Stream.create (List.length tasks) in

  (* Добавить все задачи в очередь *)
  List.iter (fun task -> Eio.Stream.add task_stream (Some task)) tasks;
  for _ = 1 to n_workers do
    Eio.Stream.add task_stream None
  done;

  Eio.Switch.run @@ fun sw ->
  (* Создать воркеры *)
  for _ = 1 to n_workers do
    Eio.Fiber.fork ~sw (fun () ->
      let rec worker_loop () =
        match Eio.Stream.take task_stream with
        | None -> ()
        | Some task ->
          let result = task () in
          Eio.Stream.add result_stream (Some result);
          worker_loop ()
      in
      worker_loop ())
  done;

  (* Собрать результаты *)
  let rec collect n acc =
    if n = 0 then List.rev acc
    else
      match Eio.Stream.take result_stream with
      | None -> List.rev acc
      | Some v -> collect (n - 1) (v :: acc)
  in
  collect (List.length tasks) []

(** Параллельная обработка файлов. *)
let parallel_process f files =
  let results = Eio.Fiber.List.map f files in
  List.fold_left (+) 0 results
