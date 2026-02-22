(** Примеры конкурентных вычислений с Eio. *)

(** Вычислить число Фибоначчи (наивная рекурсия). *)
let rec fib n =
  if n <= 1 then n
  else fib (n - 1) + fib (n - 2)

(** Применить функцию к каждому элементу списка конкурентно. *)
let parallel_map f lst =
  Eio.Fiber.List.map f lst

(** Параллельная сумма: разбить список пополам и сложить конкурентно. *)
let parallel_sum lst =
  match lst with
  | [] -> 0
  | _ ->
    let n = List.length lst in
    let mid = n / 2 in
    let left = List.filteri (fun i _ -> i < mid) lst in
    let right = List.filteri (fun i _ -> i >= mid) lst in
    let sum_left = ref 0 in
    let sum_right = ref 0 in
    Eio.Fiber.both
      (fun () -> sum_left := List.fold_left ( + ) 0 left)
      (fun () -> sum_right := List.fold_left ( + ) 0 right);
    !sum_left + !sum_right

(** Producer-consumer: producer отправляет элементы, consumer собирает. *)
let produce_and_collect produce_fn =
  let stream = Eio.Stream.create 10 in
  let result = ref [] in
  Eio.Fiber.both
    (fun () -> produce_fn stream)
    (fun () ->
      let rec loop () =
        match Eio.Stream.take stream with
        | None -> ()
        | Some v ->
          result := v :: !result;
          loop ()
      in
      loop ());
  List.rev !result

(** === Buf_read и сетевое взаимодействие === *)

(** Пример: чтение строки из буферизованного потока. *)
let read_line_from_string s =
  let flow = Eio.Flow.string_source s in
  let buf = Eio.Buf_read.of_flow flow ~max_size:4096 in
  Eio.Buf_read.line buf

(** Парсить пары ключ=значение из потока. *)
let parse_key_values s =
  let flow = Eio.Flow.string_source s in
  let buf = Eio.Buf_read.of_flow flow ~max_size:4096 in
  let rec loop acc =
    match Eio.Buf_read.at_end_of_input buf with
    | true -> List.rev acc
    | false ->
      let line = Eio.Buf_read.line buf in
      (match String.split_on_char '=' line with
       | [key; value] -> loop ((String.trim key, String.trim value) :: acc)
       | _ -> loop acc)
  in
  loop []

(** === Дополнительные примеры === *)

(** Producer: отправляет числа от 1 до n в stream, затем None. *)
let producer stream n =
  for i = 1 to n do
    Eio.Stream.add stream (Some i)
  done;
  Eio.Stream.add stream None

(** Consumer: читает из stream до None, возвращает список. *)
let consumer stream =
  let rec loop acc =
    match Eio.Stream.take stream with
    | None -> List.rev acc
    | Some v -> loop (v :: acc)
  in
  loop []

(** Таймаут: выполнить функцию f или вернуть None через timeout секунд. *)
let with_timeout clock seconds f =
  Eio.Fiber.any [
    (fun () -> Some (f ()));
    (fun () -> Eio.Time.sleep clock seconds; None);
  ]
