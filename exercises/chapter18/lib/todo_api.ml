(** TODO API с Dream. *)

(** Тип задачи. *)
type todo = {
  id : int;
  title : string;
  completed : bool;
} [@@deriving yojson]

(** Тип списка задач (для JSON-сериализации). *)
type todo_list = todo list [@@deriving yojson]

(** Тип запроса на создание задачи. *)
type create_todo = {
  title : string;
} [@@deriving yojson]

(** Тип запроса на обновление задачи. *)
type update_todo = {
  title : string option; [@default None]
  completed : bool option; [@default None]
} [@@deriving yojson]

(** In-memory хранилище. *)
let todos : todo list ref = ref []
let next_id : int ref = ref 1

(** Сбросить хранилище (для тестов). *)
let reset_store () =
  todos := [];
  next_id := 1

(** Получить все задачи. *)
let list_todos () = !todos

(** Найти задачу по id. *)
let find_todo id =
  List.find_opt (fun t -> t.id = id) !todos

(** Создать задачу. *)
let create_todo ~title =
  let todo = { id = !next_id; title; completed = false } in
  next_id := !next_id + 1;
  todos := !todos @ [todo];
  todo

(** Обновить задачу. *)
let update_todo id ?title ?completed () =
  let updated = List.map (fun t ->
    if t.id = id then
      { t with
        title = (match title with Some t -> t | None -> t.title);
        completed = (match completed with Some c -> c | None -> t.completed);
      }
    else t
  ) !todos
  in
  todos := updated;
  find_todo id

(** Удалить задачу. *)
let delete_todo id =
  let found = find_todo id in
  todos := List.filter (fun t -> t.id <> id) !todos;
  found

(** JSON-ответ с ошибкой. *)
let json_error status msg =
  let body = Printf.sprintf {|{"error":"%s"}|} msg in
  Dream.json ~status body

(** Маршрутизатор TODO API. *)
let todo_router =
  Dream.router [
    Dream.get "/todos" (fun _req ->
      let json = todo_list_to_yojson (list_todos ()) in
      Dream.json (Yojson.Safe.to_string json));

    Dream.post "/todos" (fun req ->
      let open Lwt.Syntax in
      let* body = Dream.body req in
      match create_todo_of_yojson (Yojson.Safe.from_string body) with
      | Ok { title } ->
        let todo = create_todo ~title in
        Dream.json ~status:`Created (Yojson.Safe.to_string (todo_to_yojson todo))
      | Error msg ->
        json_error `Bad_Request msg);

    Dream.get "/todos/:id" (fun req ->
      let id = int_of_string (Dream.param req "id") in
      match find_todo id with
      | Some todo ->
        Dream.json (Yojson.Safe.to_string (todo_to_yojson todo))
      | None ->
        json_error `Not_Found "not found");

    Dream.put "/todos/:id" (fun req ->
      let open Lwt.Syntax in
      let id = int_of_string (Dream.param req "id") in
      let* body = Dream.body req in
      match update_todo_of_yojson (Yojson.Safe.from_string body) with
      | Ok { title; completed } ->
        (match update_todo id ?title ?completed () with
         | Some todo ->
           Dream.json (Yojson.Safe.to_string (todo_to_yojson todo))
         | None ->
           json_error `Not_Found "not found")
      | Error msg ->
        json_error `Bad_Request msg);

    Dream.delete "/todos/:id" (fun req ->
      let id = int_of_string (Dream.param req "id") in
      match delete_todo id with
      | Some _ -> Dream.json ~status:`OK {|{"deleted":true}|}
      | None -> json_error `Not_Found "not found");
  ]
