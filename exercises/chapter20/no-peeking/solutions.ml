(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Chapter20.Todo_api

(** Упражнение 1: Health-check handler. *)
let health_handler (_req : Dream.request) : Dream.response Lwt.t =
  Dream.json {|{"status":"ok"}|}

(** Упражнение 2: Пагинация списка. *)
let paginate ~(offset : int) ~(limit : int) (lst : 'a list) : 'a list =
  let rec drop n = function
    | _ :: rest when n > 0 -> drop (n - 1) rest
    | l -> l
  in
  let rec take n = function
    | x :: rest when n > 0 -> x :: take (n - 1) rest
    | _ -> []
  in
  take limit (drop offset lst)

(** Упражнение 3: Поиск задач по подстроке. *)
let search_todos (query : string) (lst : todo list) : todo list =
  if query = "" then lst
  else
    let contains haystack needle =
      let nlen = String.length needle in
      let hlen = String.length haystack in
      if nlen > hlen then false
      else
        let rec check i =
          if i > hlen - nlen then false
          else if String.sub haystack i nlen = needle then true
          else check (i + 1)
        in
        check 0
    in
    List.filter (fun (t : todo) -> contains t.title query) lst

(** Упражнение 4: Bearer token auth middleware. *)
let auth_middleware (expected_token : string) : Dream.middleware =
  fun handler req ->
    match Dream.header req "Authorization" with
    | Some value ->
      let prefix = "Bearer " in
      let plen = String.length prefix in
      if String.length value > plen && String.sub value 0 plen = prefix then
        let token = String.sub value plen (String.length value - plen) in
        if token = expected_token then handler req
        else
          Dream.json ~status:`Unauthorized {|{"error":"invalid token"}|}
      else
        Dream.json ~status:`Unauthorized {|{"error":"invalid auth format"}|}
    | None ->
      Dream.json ~status:`Unauthorized {|{"error":"missing authorization"}|}
