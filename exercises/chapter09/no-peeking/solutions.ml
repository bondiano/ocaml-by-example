(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

(** Упражнение 1: Счётчик на ref. *)
let counter_create init = ref init

let counter_increment c = c := !c + 1

let counter_decrement c = c := !c - 1

let counter_reset c = c := 0

let counter_value c = !c

(** Упражнение 2: Логгер. *)
type logger = {
  mutable messages : string list;
}

let logger_create () = { messages = [] }

let logger_log l msg =
  l.messages <- l.messages @ [msg]

let logger_messages l = l.messages

let logger_clear l =
  l.messages <- []

let logger_count l =
  List.length l.messages

(** Упражнение 3: Форматирование таблицы. *)
let format_table rows =
  match rows with
  | [] -> ""
  | _ ->
    let max_key_len =
      List.fold_left (fun acc (k, _) -> max acc (String.length k)) 0 rows
    in
    rows
    |> List.map (fun (k, v) ->
      Printf.sprintf "%-*s | %s" max_key_len k v)
    |> String.concat "\n"

(** Упражнение 4: Сумма массива через for-цикл. *)
let array_sum_imperative arr =
  let sum = ref 0 in
  for i = 0 to Array.length arr - 1 do
    sum := !sum + arr.(i)
  done;
  !sum

(** Logger FC/IS --- Functional Core. *)
module LoggerPure = struct
  let add msgs msg = msgs @ [msg]
  let count msgs = List.length msgs
  let messages msgs = msgs
end

(** Logger FC/IS --- Imperative Shell. *)
module LoggerShell = struct
  type t = { mutable msgs : string list }
  let create () = { msgs = [] }
  let log l msg = l.msgs <- LoggerPure.add l.msgs msg
  let messages l = LoggerPure.messages l.msgs
  let count l = LoggerPure.count l.msgs
  let clear l = l.msgs <- []
end

(** Robot Name --- генерация уникальных имён формата AA000. *)
module Robot = struct
  type t = { name : string }
  let _used_names : (string, unit) Hashtbl.t = Hashtbl.create 100

  let generate_name () =
    let letter () = Char.chr (Char.code 'A' + Random.int 26) in
    let digit () = Char.chr (Char.code '0' + Random.int 10) in
    let rec try_name () =
      let name = Printf.sprintf "%c%c%c%c%c"
        (letter ()) (letter ()) (digit ()) (digit ()) (digit ()) in
      if Hashtbl.mem _used_names name then try_name ()
      else begin
        Hashtbl.add _used_names name ();
        name
      end
    in
    try_name ()

  let create () = { name = generate_name () }
  let name robot = robot.name
  let reset _robot =
    let new_name = generate_name () in
    { name = new_name }
end

(** Simple LRU cache. *)
module LRU = struct
  type ('k, 'v) t = {
    mutable entries : ('k * 'v) list;
    capacity : int;
  }

  let create capacity = { entries = []; capacity }

  let get cache key =
    match List.assoc_opt key cache.entries with
    | None -> None
    | Some v ->
      cache.entries <- (key, v) :: List.filter (fun (k, _) -> k <> key) cache.entries;
      Some v

  let put cache key value =
    let entries = List.filter (fun (k, _) -> k <> key) cache.entries in
    let entries = (key, value) :: entries in
    cache.entries <-
      if List.length entries > cache.capacity then
        List.filteri (fun i _ -> i < cache.capacity) entries
      else entries

  let size cache = List.length cache.entries
end

(** Bowling — подсчёт очков в боулинге. *)
module Bowling = struct
  type t = {
    mutable rolls : int list;
    mutable current_frame : int;
    mutable finished : bool;
  }

  let create () = { rolls = []; current_frame = 1; finished = false }

  let roll game pins =
    if game.finished then Error "Game is already over"
    else if pins < 0 || pins > 10 then Error "Invalid number of pins"
    else begin
      game.rolls <- game.rolls @ [pins];
      Ok ()
    end

  let score game =
    let rolls = Array.of_list game.rolls in
    let len = Array.length rolls in
    let total = ref 0 in
    let i = ref 0 in
    let frame = ref 0 in
    while !frame < 10 && !i < len do
      if rolls.(!i) = 10 then begin
        (* Strike *)
        total := !total + 10
          + (if !i + 1 < len then rolls.(!i + 1) else 0)
          + (if !i + 2 < len then rolls.(!i + 2) else 0);
        i := !i + 1
      end else if !i + 1 < len && rolls.(!i) + rolls.(!i + 1) = 10 then begin
        (* Spare *)
        total := !total + 10
          + (if !i + 2 < len then rolls.(!i + 2) else 0);
        i := !i + 2
      end else if !i + 1 < len then begin
        total := !total + rolls.(!i) + rolls.(!i + 1);
        i := !i + 2
      end else
        i := !i + 1;
      frame := !frame + 1
    done;
    !total
end
