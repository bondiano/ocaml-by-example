(** Примеры обработчиков эффектов OCaml 5. *)

(** --- Эффект State --- *)

type _ Effect.t += Get : int Effect.t
type _ Effect.t += Set : int -> unit Effect.t

(** Выполнить вычисление с эффектом State, начиная с init. *)
let run_state (init : int) (f : unit -> 'a) : 'a =
  let state = ref init in
  Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Get -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            Effect.Deep.continue k !state)
        | Set v -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            state := v;
            Effect.Deep.continue k ())
        | _ -> None }

(** --- Эффект Log --- *)

type _ Effect.t += Log : string -> unit Effect.t

(** Выполнить вычисление, собирая логи в список. *)
let run_log (f : unit -> 'a) : 'a * string list =
  let logs = ref [] in
  let result = Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Log msg -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            logs := msg :: !logs;
            Effect.Deep.continue k ())
        | _ -> None }
  in
  (result, List.rev !logs)

(** Пример: вычисление с State. *)
let state_example () =
  let x = Effect.perform Get in
  Effect.perform (Set (x + 10));
  let y = Effect.perform Get in
  x + y

(** Пример: вычисление с Log. *)
let log_example () =
  Effect.perform (Log "start");
  let result = 2 + 3 in
  Effect.perform (Log (Printf.sprintf "result = %d" result));
  Effect.perform (Log "done");
  result

(** Пример: комбинация State + Log. *)
let combined_example () =
  Effect.perform (Log "начинаем");
  let x = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "текущее значение: %d" x));
  Effect.perform (Set (x * 2));
  let y = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "новое значение: %d" y));
  y
