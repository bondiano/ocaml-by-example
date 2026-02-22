(** Reference solutions for Chapter 10b *)

module Form : sig
  type 'a validated
  val field : string -> string -> (string -> ('a, string) result) -> 'a validated
  val map2 : ('a -> 'b -> 'c) -> 'a validated -> 'b validated -> 'c validated
  val map3 : ('a -> 'b -> 'c -> 'd) ->
    'a validated -> 'b validated -> 'c validated -> 'd validated
  val run : 'a validated -> ('a, (string * string) list) result
end = struct
  type 'a validated = ('a, (string * string) list) result

  let field name raw parser =
    match parser raw with
    | Ok v -> Ok v
    | Error msg -> Error [(name, msg)]

  let map2 f a b =
    match a, b with
    | Ok a, Ok b -> Ok (f a b)
    | Error ea, Error eb -> Error (ea @ eb)
    | Error e, _ | _, Error e -> Error e

  let map3 f a b c =
    match a, b, c with
    | Ok a, Ok b, Ok c -> Ok (f a b c)
    | _ ->
      let errors =
        (match a with Error e -> e | Ok _ -> [])
        @ (match b with Error e -> e | Ok _ -> [])
        @ (match c with Error e -> e | Ok _ -> [])
      in
      Error errors

  let run v = v
end

(** Упражнение 6 (Сложное): FileHandle --- phantom types для файловых дескрипторов. *)
module FileHandle : sig
  type opened
  type closed

  type 'state handle

  val open_file : string -> opened handle
  val read : opened handle -> string
  val write : opened handle -> string -> opened handle
  val close : opened handle -> closed handle
  val name : 'state handle -> string
end = struct
  type opened
  type closed

  type 'state handle = {
    name : string;
    content : string;
  }

  let open_file path =
    { name = path; content = "" }

  let read h = h.content

  let write h data =
    { name = h.name; content = h.content ^ data }

  let close h =
    { name = h.name; content = h.content }

  let name h = h.name
end
