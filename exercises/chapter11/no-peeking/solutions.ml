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
