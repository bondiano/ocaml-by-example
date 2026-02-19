(** Здесь вы можете писать свои решения упражнений. *)

open Chapter20.Todo_api

(** Упражнение 1: Health-check handler, возвращает {"status":"ok"}. *)
let health_handler (_req : Dream.request) : Dream.response Lwt.t =
  ignore _req;
  failwith "todo"

(** Упражнение 2: Пагинация списка. *)
let paginate ~(offset : int) ~(limit : int) (lst : 'a list) : 'a list =
  ignore offset; ignore limit; ignore lst;
  failwith "todo"

(** Упражнение 3: Поиск задач по подстроке в title. *)
let search_todos (query : string) (lst : todo list) : todo list =
  ignore query; ignore lst;
  failwith "todo"

(** Упражнение 4: Middleware для Bearer-token аутентификации. *)
let auth_middleware (expected_token : string) : Dream.middleware =
  ignore expected_token;
  fun handler req ->
    ignore handler; ignore req;
    failwith "todo"
