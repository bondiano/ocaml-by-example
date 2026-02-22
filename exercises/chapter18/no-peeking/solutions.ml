(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Chapter18.Todo_api

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

(** Упражнение 5: CORS middleware. *)
let cors_middleware : Dream.middleware =
  fun handler req ->
    let open Lwt.Syntax in
    let* response = handler req in
    Dream.add_header response "Access-Control-Allow-Origin" "*";
    Dream.add_header response "Access-Control-Allow-Methods" "GET, POST, PUT, DELETE";
    Dream.add_header response "Access-Control-Allow-Headers" "Content-Type";
    Lwt.return response

(** Упражнение 6: JSON error helper. *)
let json_error (status : Dream.status) (msg : string) : Dream.response Lwt.t =
  let body = Printf.sprintf {|{"error":"%s"}|} msg in
  Dream.json ~status body

(** Упражнение 7: POST handler для создания задачи. *)
let create_todo_handler (req : Dream.request) : Dream.response Lwt.t =
  let open Lwt.Syntax in
  let* body = Dream.body req in
  match create_todo_of_yojson (Yojson.Safe.from_string body) with
  | Ok { title } ->
    let todo = create_todo ~title in
    Dream.json ~status:`Created (Yojson.Safe.to_string (todo_to_yojson todo))
  | Error msg ->
    json_error `Bad_Request msg

(** Упражнение 8: Фильтрация по completed. *)
let filter_todos (filter : bool option) (lst : todo list) : todo list =
  match filter with
  | None -> lst
  | Some expected ->
    List.filter (fun (t : todo) -> t.completed = expected) lst
