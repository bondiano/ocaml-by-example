(** Здесь вы можете писать свои решения упражнений. *)

open Chapter18.Todo_api

(* ===== Простые handlers ===== *)

(* Лёгкое *)
(** Упражнение 1: health_handler — health-check endpoint.

    Реализовать простой health-check endpoint, который возвращает
    JSON {"status":"ok"} со статусом 200 OK.

    Используется для проверки что сервер работает.

    Примеры:
    {[
      GET /health  →  200 OK
      {"status":"ok"}
    ]}

    Подсказки:
    1. Dream.json для создания JSON ответа
    2. Создать Yojson: `Assoc [("status", `String "ok")]
    3. Yojson.Safe.to_string для преобразования в строку
    4. Структура:
       {[
         let health_handler _req =
           let json = `Assoc [("status", `String "ok")] in
           Dream.json (Yojson.Safe.to_string json)
       ]}
    5. Dream.json автоматически добавляет Content-Type: application/json

    Связанные темы: Dream handlers, JSON responses, health checks
    Время: ~8 минут *)
let health_handler (_req : Dream.request) : Dream.response Lwt.t =
  ignore _req;
  failwith "todo"

(* ===== Вспомогательные функции ===== *)

(* Лёгкое *)
(** Упражнение 2: paginate — пагинация списка.

    Извлечь подмножество списка с заданным смещением и лимитом.

    Параметры:
    - offset: пропустить первые offset элементов
    - limit: взять максимум limit элементов

    Примеры:
    {[
      paginate ~offset:0 ~limit:3 [1;2;3;4;5] = [1;2;3]
      paginate ~offset:2 ~limit:2 [1;2;3;4;5] = [3;4]
      paginate ~offset:10 ~limit:5 [1;2;3] = []
    ]}

    Подсказки:
    1. List.drop offset (или fold_left для пропуска первых n)
    2. List.take limit (или fold_left для взятия первых n)
    3. Можно использовать List.filteri с индексом:
       {[
         List.filteri (fun i _ -> i >= offset && i < offset + limit) lst
       ]}
    4. Или рекурсия:
       {[
         let rec drop n = function
           | [] -> []
           | _ :: xs when n > 0 -> drop (n-1) xs
           | xs -> xs
         in
         let rec take n = function
           | [] -> []
           | _ when n <= 0 -> []
           | x :: xs -> x :: take (n-1) xs
       ]}

    Связанные темы: Pagination, list operations, REST API patterns
    Время: ~10 минут *)
let paginate ~(offset : int) ~(limit : int) (lst : 'a list) : 'a list =
  ignore offset; ignore limit; ignore lst;
  failwith "todo"

(* Лёгкое *)
(** Упражнение 3: search_todos — поиск задач по подстроке.

    Найти все задачи, в которых title содержит query (case-insensitive).

    Примеры:
    {[
      let todos = [
        {id=1; title="Buy milk"; completed=false};
        {id=2; title="Buy bread"; completed=true};
        {id=3; title="Read book"; completed=false}
      ]

      search_todos "buy" todos = [задачи 1 и 2]
      search_todos "MILK" todos = [задача 1]
      search_todos "xyz" todos = []
    ]}

    Подсказки:
    1. String.lowercase_ascii для приведения к нижнему регистру
    2. String.contains_s или Re для проверки вхождения
    3. List.filter для фильтрации
    4. Структура:
       {[
         let query_lower = String.lowercase_ascii query in
         List.filter (fun todo ->
           let title_lower = String.lowercase_ascii todo.title in
           (* проверка вхождения *)
         ) lst
       ]}
    5. Простой способ: использовать Str.string_match или Re

    Связанные темы: String matching, case-insensitive search, filtering
    Время: ~8 минут *)
let search_todos (query : string) (lst : todo list) : todo list =
  ignore query; ignore lst;
  failwith "todo"

(* ===== Middleware ===== *)

(* Среднее *)
(** Упражнение 4: auth_middleware — Bearer token аутентификация.

    Реализовать middleware для проверки Bearer token в заголовке Authorization.

    Формат заголовка: "Authorization: Bearer <token>"

    Если токен отсутствует или неверный → 401 Unauthorized
    Если токен правильный → пропустить к handler

    Примеры:
    {[
      Authorization: Bearer secret123  → OK (если expected_token = "secret123")
      Authorization: Bearer wrong      → 401 Unauthorized
      (нет заголовка)                  → 401 Unauthorized
    ]}

    Подсказки:
    1. Dream.header для чтения заголовка:
       Dream.header req "Authorization"
    2. Парсинг токена:
       {[
         match Dream.header req "Authorization" with
         | Some auth ->
             (match String.split_on_char ' ' auth with
              | ["Bearer"; token] -> if token = expected_token then ...
              | _ -> unauthorized)
         | None -> unauthorized
       ]}
    3. Dream.response для создания 401:
       {[
         Dream.response ~status:`Unauthorized "Unauthorized"
       ]}
    4. Если успешно: handler req

    Связанные темы: Middleware, authentication, Bearer tokens
    Время: ~18 минут *)
let auth_middleware (expected_token : string) : Dream.middleware =
  ignore expected_token;
  fun handler req ->
    ignore handler; ignore req;
    failwith "todo"

(* Среднее *)
(** Упражнение 5: cors_middleware — добавление CORS заголовков.

    Реализовать middleware, которое добавляет CORS-заголовки ко всем ответам.

    Заголовки:
    - Access-Control-Allow-Origin: *
    - Access-Control-Allow-Methods: GET, POST, PUT, DELETE
    - Access-Control-Allow-Headers: Content-Type

    Middleware должен:
    1. Вызвать handler для получения response
    2. Добавить CORS-заголовки к response
    3. Вернуть модифицированный response

    Подсказки:
    1. Вызвать handler: let%lwt response = handler req
    2. Dream.add_header для добавления заголовков:
       {[
         Dream.add_header response "Access-Control-Allow-Origin" "*";
         Dream.add_header response "Access-Control-Allow-Methods" "GET, POST, PUT, DELETE";
         Dream.add_header response "Access-Control-Allow-Headers" "Content-Type";
         Lwt.return response
       ]}
    3. Можно использовать Dream.set_header или add_header

    Связанные темы: CORS, middleware, response modification
    Время: ~15 минут *)
let cors_middleware : Dream.middleware =
  fun handler req ->
    ignore handler; ignore req;
    failwith "todo"

(* Лёгкое *)
(** Упражнение 6: json_error — JSON ответ с ошибкой.

    Создать вспомогательную функцию для возврата JSON с ошибкой.

    Формат JSON: {"error":"message"}

    Примеры:
    {[
      json_error `Bad_Request "Invalid input"
        → 400 Bad Request, {"error":"Invalid input"}

      json_error `Not_Found "Todo not found"
        → 404 Not Found, {"error":"Todo not found"}
    ]}

    Подсказки:
    1. Создать JSON:
       {[
         let json = `Assoc [("error", `String msg)] in
         let json_str = Yojson.Safe.to_string json in
       ]}
    2. Dream.json с явным статусом:
       {[
         Dream.json ~status json_str
       ]}
    3. Статусы Dream: `Bad_Request, `Not_Found, `Unauthorized, и т.д.

    Связанные темы: Error responses, JSON formatting, HTTP status codes
    Время: ~8 минут *)
let json_error (status : Dream.status) (msg : string) : Dream.response Lwt.t =
  ignore status; ignore msg;
  failwith "todo"

(* ===== POST handlers ===== *)

(* Среднее *)
(** Упражнение 7: create_todo_handler — создание задачи через POST.

    Реализовать POST /todos handler, который:
    1. Читает JSON из body запроса
    2. Парсит в create_todo структуру
    3. Создаёт задачу через create_todo
    4. Возвращает JSON с созданной задачей и статусом 201 Created

    При ошибке парсинга → 400 Bad Request с json_error.

    Примеры:
    {[
      POST /todos
      Body: {"title":"Buy milk"}

      → 201 Created
      {"id":1, "title":"Buy milk", "completed":false}

      POST /todos
      Body: {"invalid":"data"}

      → 400 Bad Request
      {"error":"Invalid JSON"}
    ]}

    Подсказки:
    1. Dream.body для чтения body:
       {[
         let%lwt body = Dream.body req in
       ]}
    2. Yojson.Safe.from_string для парсинга JSON:
       {[
         let json = Yojson.Safe.from_string body in
       ]}
    3. create_todo_of_yojson для преобразования (генерируется ppx):
       {[
         match create_todo_of_yojson json with
         | Ok data -> ...
         | Error msg -> json_error `Bad_Request msg
       ]}
    4. create_todo для создания задачи (из Chapter18.Todo_api)
    5. todo_to_yojson для обратного преобразования
    6. Dream.json ~status:`Created

    Связанные темы: POST handlers, JSON parsing, error handling
    Время: ~20 минут *)
let create_todo_handler (_req : Dream.request) : Dream.response Lwt.t =
  failwith "todo"

(* ===== Фильтрация ===== *)

(* Лёгкое *)
(** Упражнение 8: filter_todos — фильтрация по completed.

    Отфильтровать задачи по полю completed.

    Параметры:
    - filter: Some true → только completed
    - filter: Some false → только не completed
    - filter: None → все задачи

    Примеры:
    {[
      let todos = [
        {id=1; title="Task1"; completed=true};
        {id=2; title="Task2"; completed=false};
        {id=3; title="Task3"; completed=true}
      ]

      filter_todos (Some true) todos = [задачи 1 и 3]
      filter_todos (Some false) todos = [задача 2]
      filter_todos None todos = [все задачи]
    ]}

    Подсказки:
    1. Pattern match на filter:
       {[
         match filter with
         | None -> lst  (* все *)
         | Some expected ->
             List.filter (fun todo -> todo.completed = expected) lst
       ]}
    2. Или более кратко с Option.fold

    Связанные темы: Filtering, optional parameters, REST API
    Время: ~8 минут *)
let filter_todos (filter : bool option) (lst : todo list) : todo list =
  ignore filter; ignore lst;
  failwith "todo"
