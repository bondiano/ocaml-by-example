(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

(** Эффект Emit. *)
type _ Effect.t += Emit : int -> unit Effect.t

let run_emit (f : unit -> 'a) : 'a * int list =
  let items = ref [] in
  let result = Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Emit v -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            items := v :: !items;
            Effect.Deep.continue k ())
        | _ -> None }
  in
  (result, List.rev !items)

(** Эффект Reader. *)
type _ Effect.t += Ask : string Effect.t

let run_reader (env : string) (f : unit -> 'a) : 'a =
  Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Ask -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            Effect.Deep.continue k env)
        | _ -> None }

(** Композиция State + Emit. *)
let count_and_emit (n : int) : unit =
  for i = 1 to n do
    let current = Effect.perform Chapter13.Effects.Get in
    Effect.perform (Chapter13.Effects.Set (current + i));
    Effect.perform (Emit (current + i))
  done

(** Эффект Fail. *)
type _ Effect.t += Fail : string -> 'a Effect.t

let run_fail (f : unit -> 'a) : ('a, string) result =
  Effect.Deep.match_with f ()
    { retc = (fun x -> Ok x);
      exnc = (fun e -> raise e);
      effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Fail msg -> Some (fun (_k : (a, _) Effect.Deep.continuation) ->
            Error msg)
        | _ -> None }
