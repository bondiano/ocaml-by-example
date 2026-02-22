# Веб-разработка с Dream

## Цели главы

В этой главе мы строим веб-сервер на OCaml с фреймворком **Dream**:

- **Dream** — философия «один плоский модуль», минималистичный API.
- **Обработчики** (handlers) — функции `request -> response Lwt.t`.
- **Маршрутизация** — `Dream.get`, `Dream.post`, параметры пути, области (scopes).
- **Middleware** — промежуточные обработчики для логирования, авторизации, таймингов.
- **JSON API** — работа с JSON через Yojson и `ppx_deriving_yojson` (из главы 14).
- **Проект: TODO API** — полноценный CRUD с хранением в памяти.
- Сравнение с Haskell-фреймворками (Servant, Scotty).

Dream построен поверх **Lwt** (приложение B) — все обработчики возвращают `Lwt.t`. Глава предполагает знакомство с промисами Lwt из предыдущей главы.

```admonish tip title="Для Python/TS-разработчиков"
Dream — это аналог Flask/FastAPI (Python) или Express (TypeScript/Node.js). Если вы писали `@app.get("/")` в FastAPI или `app.get("/", handler)` в Express, подход Dream покажется знакомым: `Dream.get "/" handler`. Главное отличие — Dream типобезопасен: обработчик имеет тип `request -> response Lwt.t`, и компилятор проверяет, что вы возвращаете корректный ответ. Также Dream использует промисы Lwt вместо `async/await`, хотя с `let*` синтаксис очень похож.
```

## Подготовка проекта

Код этой главы находится в `exercises/chapter18`. Установите необходимые библиотеки:

```text
$ opam install dream yojson ppx_deriving_yojson
$ cd exercises/chapter18
$ dune build
```

Файл `dune` для библиотеки:

```lisp
(library
 (name chapter18)
 (libraries dream yojson)
 (preprocess (pps ppx_deriving_yojson)))
```

## Dream: философия

Dream придерживается принципа **«один плоский модуль»**: весь API находится в модуле `Dream`. Нет глубоких иерархий модулей, нет сложных абстракций — всё вызывается как `Dream.something`.

Это сознательный выбор автора фреймворка. Вместо того чтобы разбивать функциональность на десятки подмодулей, Dream предлагает одно пространство имён с понятными именами:

- `Dream.run` — запустить сервер.
- `Dream.router` — маршрутизация запросов.
- `Dream.get`, `Dream.post`, `Dream.put`, `Dream.delete` — HTTP-методы.
- `Dream.html`, `Dream.json` — формирование ответов.
- `Dream.body` — чтение тела запроса.
- `Dream.param` — извлечение параметров пути.
- `Dream.logger` — логирование запросов.

## Hello World

Минимальное веб-приложение на Dream:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" (fun _req ->
      Dream.html "Hello, world!")
  ]
```

Разберём каждую часть:

- `Dream.run` — запускает HTTP-сервер (по умолчанию на порту 8080).
- `Dream.logger` — middleware, логирующий каждый запрос в консоль.
- `Dream.router [...]` — маршрутизатор, сопоставляющий URL с обработчиками.
- `Dream.get "/" handler` — маршрут для GET-запроса на корневой путь.
- `Dream.html "Hello, world!"` — ответ с типом `text/html`.

Оператор `@@` — это применение функции (`f @@ x` эквивалентно `f x`). Цепочка `@@` читается сверху вниз: `Dream.run` принимает middleware-конвейер, который заканчивается роутером.

```text
$ dune exec ./main.exe
18.02.2026 12:00:00.000       dream.log  INFO REQ 1 GET / 127.0.0.1:54321
18.02.2026 12:00:00.001       dream.log  INFO REQ 1 200 in 1 us
```

## Обработчики

Центральное понятие Dream — **обработчик** (handler). Это функция, принимающая запрос и возвращающая ответ в контексте Lwt:

```ocaml
type handler = Dream.request -> Dream.response Lwt.t
```

Любая функция с такой сигнатурой может быть обработчиком. Вот несколько примеров:

```ocaml
(* Простой обработчик — возвращает HTML *)
let hello_handler _req =
  Dream.html "Hello!"

(* Обработчик с параметром запроса *)
let greet_handler req =
  let name = Dream.param req "name" in
  Dream.html (Printf.sprintf "Привет, %s!" name)

(* Обработчик, читающий тело запроса *)
let echo_handler req =
  let open Lwt.Syntax in
  let* body = Dream.body req in
  Dream.html (Printf.sprintf "Вы отправили: %s" body)
```

Обратите внимание на `let*` — синтаксис let-операторов Lwt (из приложения B). `Dream.body req` возвращает `string Lwt.t`, поэтому мы используем `let*` для извлечения строки.

### Формирование ответов

Dream предоставляет несколько функций для создания ответов:

```ocaml
(* HTML-ответ со статусом 200 *)
let _ = Dream.html "содержимое"

(* JSON-ответ со статусом 200 *)
let _ = Dream.json {|{"key": "value"}|}

(* JSON-ответ с произвольным статусом *)
let _ = Dream.json ~status:`Created {|{"id": 1}|}
let _ = Dream.json ~status:`Not_Found {|{"error": "not found"}|}

(* Пустой ответ *)
let _ = Dream.empty `No_Content

(* Ответ с произвольными заголовками *)
let custom_response _req =
  let response = Dream.response ~status:`OK "данные" in
  Dream.set_header response "X-Custom" "value";
  Lwt.return response
```

`Dream.response` создаёт объект ответа, который затем можно мутировать через `Dream.set_header` перед возвратом. Поскольку ответ изменяется на месте, обработчик завершается явным `Lwt.return response`, а не автоматически.

Статус-коды записываются как полиморфные варианты: `` `OK ``, `` `Created ``, `` `Not_Found ``, `` `Bad_Request ``, `` `Internal_Server_Error `` и так далее.

## Маршрутизация

Dream предоставляет функции для всех стандартных HTTP-методов:

```ocaml
Dream.router [
  Dream.get    "/resource" get_handler;
  Dream.post   "/resource" create_handler;
  Dream.put    "/resource/:id" update_handler;
  Dream.delete "/resource/:id" delete_handler;
]
```

### Параметры пути

Сегменты пути, начинающиеся с `:`, становятся **параметрами**. Их значения извлекаются через `Dream.param`:

```ocaml
Dream.get "/users/:id" (fun req ->
  let id = Dream.param req "id" in
  Dream.html (Printf.sprintf "Пользователь %s" id))
```

`Dream.param` возвращает `string`. Для преобразования в другие типы используйте стандартные функции:

```ocaml
Dream.get "/users/:id" (fun req ->
  let id_str = Dream.param req "id" in
  match int_of_string_opt id_str with
  | Some id -> Dream.html (Printf.sprintf "Пользователь #%d" id)
  | None -> Dream.json ~status:`Bad_Request {|{"error":"invalid id"}|})
```

### Области (scopes)

`Dream.scope` группирует маршруты под общим префиксом:

```ocaml
Dream.router [
  Dream.get "/" (fun _ -> Dream.html "Главная страница");

  Dream.scope "/api" [] [
    Dream.get "/status" (fun _ ->
      Dream.json {|{"ok": true}|});

    Dream.scope "/v1" [] [
      Dream.get "/users" list_users_handler;
      Dream.get "/users/:id" get_user_handler;
    ];
  ];
]
```

Второй аргумент `Dream.scope` — список middleware, применяемых ко всем маршрутам внутри области. Пустой список `[]` означает отсутствие дополнительных middleware.

С этой конфигурацией:

- `GET /` — главная страница.
- `GET /api/status` — статус API.
- `GET /api/v1/users` — список пользователей.
- `GET /api/v1/users/42` — пользователь с id 42.

## Запрос и ответ

### Чтение запроса

```ocaml
(* Тело запроса (POST/PUT) *)
let body : string Lwt.t = Dream.body req

(* HTTP-метод *)
let meth : Dream.method_ = Dream.method_ req

(* Путь запроса *)
let path : string = Dream.target req

(* Заголовок *)
let content_type : string option = Dream.header req "Content-Type"

(* Query-параметры *)
let page : string option = Dream.query req "page"
```

### Статус-коды

Наиболее часто используемые статус-коды в REST API:

```ocaml
(* Успех *)
`OK                    (* 200 *)
`Created               (* 201 *)
`No_Content            (* 204 *)

(* Ошибки клиента *)
`Bad_Request           (* 400 *)
`Unauthorized          (* 401 *)
`Forbidden             (* 403 *)
`Not_Found             (* 404 *)

(* Ошибки сервера *)
`Internal_Server_Error (* 500 *)
```

## Middleware

Middleware — функция, которая **оборачивает** обработчик, добавляя логику до и/или после обработки запроса.

Тип middleware в Dream:

```ocaml
type middleware = handler -> handler
```

То есть middleware принимает «внутренний» обработчик и возвращает «внешний» обработчик. Это позволяет строить конвейер обработки.

### Встроенный middleware

Dream предоставляет несколько готовых middleware:

```ocaml
let () =
  Dream.run
  @@ Dream.logger          (* логирование запросов *)
  @@ Dream.router [ ... ]
```

`Dream.logger` выводит в консоль метод, путь, статус и время обработки каждого запроса.

### Пользовательский middleware

Напишем middleware для измерения времени обработки:

```ocaml
let timing_middleware inner_handler req =
  let t0 = Unix.gettimeofday () in
  let open Lwt.Syntax in
  let* response = inner_handler req in
  let dt = Unix.gettimeofday () -. t0 in
  Dream.log "Request %s %s took %.3fs"
    (Dream.method_to_string (Dream.method_ req))
    (Dream.target req)
    dt;
  Lwt.return response
```

Использование:

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ timing_middleware
  @@ Dream.router [ ... ]
```

Middleware компонуются сверху вниз: сначала `Dream.logger`, затем `timing_middleware`, затем роутер. Запрос проходит через каждый слой по очереди.

```admonish tip title="Для Python/TS-разработчиков"
Middleware в Dream работают как middleware в Express (TypeScript) или FastAPI/Starlette (Python): оборачивают обработчик, добавляя логику до и после обработки запроса. В Express вы пишете `app.use(logger)`, в Dream — `@@ Dream.logger`. В Python/FastAPI `@app.middleware("http")` — декоратор, в Dream — функция `handler -> handler`. Принцип одинаков: конвейер обработки запроса, где каждый слой может модифицировать запрос или ответ.
```

### Middleware для CORS

Пример middleware, добавляющего CORS-заголовки:

```ocaml
let cors_middleware inner_handler req =
  let open Lwt.Syntax in
  let* response = inner_handler req in
  Dream.set_header response "Access-Control-Allow-Origin" "*";
  Dream.set_header response "Access-Control-Allow-Methods"
    "GET, POST, PUT, DELETE";
  Dream.set_header response "Access-Control-Allow-Headers" "Content-Type";
  Lwt.return response
```

Middleware сначала вызывает внутренний обработчик и получает ответ, затем добавляет заголовки CORS к уже готовому ответу. Это паттерн «постобработка» — middleware работает как с запросом (до вызова `inner_handler`), так и с ответом (после).

### Middleware для области

Middleware можно применить только к определённой группе маршрутов через `Dream.scope`:

```ocaml
Dream.router [
  Dream.get "/" public_handler;

  Dream.scope "/admin" [auth_middleware] [
    Dream.get "/dashboard" dashboard_handler;
    Dream.get "/users" admin_users_handler;
  ];
]
```

Здесь `auth_middleware` применяется только к маршрутам внутри `/admin`.

## JSON API с Yojson

В главе 14 мы изучили `ppx_deriving_yojson` для автоматической сериализации. Теперь применим это для построения JSON API.

Напомним ключевые моменты:

```ocaml
type todo = {
  id : int;
  title : string;
  completed : bool;
} [@@deriving yojson]
```

Аннотация `[@@deriving yojson]` генерирует:

- `todo_to_yojson : todo -> Yojson.Safe.t` — сериализация.
- `todo_of_yojson : Yojson.Safe.t -> (todo, string) result` — десериализация.

**Важно:** `ppx_deriving_yojson` генерирует функции вида `t_to_yojson` / `t_of_yojson` (НЕ `yojson_of_t`). Это отличается от некоторых других ppx-расширений.

### Вспомогательные функции

Для удобной работы с JSON в обработчиках напишем хелперы:

```ocaml
(* Прочитать JSON из тела запроса *)
let read_json_body req =
  let open Lwt.Syntax in
  let* body = Dream.body req in
  try Lwt.return_ok (Yojson.Safe.from_string body)
  with Yojson.Json_error msg -> Lwt.return_error msg

(* Отправить JSON-ответ из Yojson.Safe.t *)
let json_response ?(status = `OK) json =
  Dream.json ~status (Yojson.Safe.to_string json)

(* Отправить ошибку в формате JSON *)
let json_error status message =
  let body = Printf.sprintf {|{"error": "%s"}|} message in
  Dream.json ~status body
```

## Проект: TODO API

Соберём всё вместе и построим полноценный REST API для управления списком задач (todo-list). Это классический пример для изучения веб-фреймворков.

### Типы данных

```ocaml
type todo = {
  id : int;
  title : string;
  completed : bool;
} [@@deriving yojson]

type create_todo = {
  title : string;
} [@@deriving yojson]

type update_todo = {
  title : string option; [@default None]
  completed : bool option; [@default None]
} [@@deriving yojson]

type todo_list = {
  todos : todo list;
  count : int;
} [@@deriving to_yojson]
```

Тип `create_todo` описывает тело POST-запроса — для создания задачи нужен только заголовок. Тип `update_todo` описывает тело PUT-запроса — оба поля необязательные (обновляем только то, что передали). Атрибут `[@default None]` говорит ppx, что при отсутствии поля в JSON нужно подставить `None`.

### Хранилище в памяти

Используем мутабельную ссылку (из главы 9) как простое хранилище:

```ocaml
let todos : todo list ref = ref []
let next_id : int ref = ref 1

let add_todo title =
  let todo = { id = !next_id; title; completed = false } in
  todos := todo :: !todos;
  next_id := !next_id + 1;
  todo

let find_todo id =
  List.find_opt (fun t -> t.id = id) !todos

let update_todo id ?title ?completed () =
  let updated = List.map (fun t ->
    if t.id = id then
      { t with
        title = (match title with Some s -> s | None -> t.title);
        completed = (match completed with Some b -> b | None -> t.completed);
      }
    else t
  ) !todos in
  todos := updated;
  find_todo id

let delete_todo id =
  let before = List.length !todos in
  todos := List.filter (fun t -> t.id <> id) !todos;
  List.length !todos < before
```

В реальном приложении вместо `ref` использовалась бы база данных, но для изучения фреймворка хранение в памяти вполне подходит.

### Обработчик: список всех задач

```ocaml
(* GET /todos *)
let list_todos_handler _req =
  let all = List.rev !todos in
  let response = { todos = all; count = List.length all } in
  json_response (todo_list_to_yojson response)
```

`List.rev` — потому что мы добавляем задачи в начало списка, а пользователь ожидает хронологический порядок.

### Обработчик: создание задачи

```ocaml
(* POST /todos *)
let create_todo_handler req =
  let open Lwt.Syntax in
  let* body = Dream.body req in
  match Yojson.Safe.from_string body |> create_todo_of_yojson with
  | Ok { title } ->
    let todo = add_todo title in
    json_response ~status:`Created (todo_to_yojson todo)
  | Error msg ->
    json_error `Bad_Request (Printf.sprintf "Invalid JSON: %s" msg)
  | exception Yojson.Json_error msg ->
    json_error `Bad_Request (Printf.sprintf "Malformed JSON: %s" msg)
```

Обратите внимание на обработку ошибок:

- `Yojson.Json_error` — строка не является валидным JSON.
- `Error msg` — JSON валиден, но не соответствует типу `create_todo`.

### Обработчик: получение задачи по id

```ocaml
(* GET /todos/:id *)
let get_todo_handler req =
  let id_str = Dream.param req "id" in
  match int_of_string_opt id_str with
  | None ->
    json_error `Bad_Request "id must be an integer"
  | Some id ->
    match find_todo id with
    | Some todo -> json_response (todo_to_yojson todo)
    | None -> json_error `Not_Found (Printf.sprintf "Todo %d not found" id)
```

### Обработчик: обновление задачи

```ocaml
(* PUT /todos/:id *)
let update_todo_handler req =
  let open Lwt.Syntax in
  let id_str = Dream.param req "id" in
  match int_of_string_opt id_str with
  | None ->
    json_error `Bad_Request "id must be an integer"
  | Some id ->
    match find_todo id with
    | None ->
      json_error `Not_Found (Printf.sprintf "Todo %d not found" id)
    | Some _existing ->
      let* body = Dream.body req in
      (match Yojson.Safe.from_string body |> update_todo_of_yojson with
       | Ok { title; completed } ->
         (match update_todo id ?title ?completed () with
          | Some updated -> json_response (todo_to_yojson updated)
          | None -> json_error `Internal_Server_Error "update failed")
       | Error msg ->
         json_error `Bad_Request (Printf.sprintf "Invalid JSON: %s" msg)
       | exception Yojson.Json_error msg ->
         json_error `Bad_Request (Printf.sprintf "Malformed JSON: %s" msg))
```

Обработчик обновления — самый сложный, потому что требует:

1. Проверить валидность `id`.
2. Убедиться, что задача существует.
3. Прочитать и разобрать тело запроса.
4. Применить обновление.

### Обработчик: удаление задачи

```ocaml
(* DELETE /todos/:id *)
let delete_todo_handler req =
  let id_str = Dream.param req "id" in
  match int_of_string_opt id_str with
  | None ->
    json_error `Bad_Request "id must be an integer"
  | Some id ->
    if delete_todo id then
      Dream.empty `No_Content
    else
      json_error `Not_Found (Printf.sprintf "Todo %d not found" id)
```

При успешном удалении возвращаем `204 No Content` — стандартная практика для DELETE-запросов.

### Сборка приложения

```ocaml
let () =
  Dream.run
  @@ Dream.logger
  @@ cors_middleware
  @@ Dream.router [
    Dream.get    "/todos"     list_todos_handler;
    Dream.post   "/todos"     create_todo_handler;
    Dream.get    "/todos/:id" get_todo_handler;
    Dream.put    "/todos/:id" update_todo_handler;
    Dream.delete "/todos/:id" delete_todo_handler;
  ]
```

### Тестирование с curl

```text
$ curl http://localhost:8080/todos
{"todos":[],"count":0}

$ curl -X POST http://localhost:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Купить молоко"}'
{"id":1,"title":"Купить молоко","completed":false}

$ curl -X POST http://localhost:8080/todos \
  -H "Content-Type: application/json" \
  -d '{"title":"Написать код"}'
{"id":2,"title":"Написать код","completed":false}

$ curl http://localhost:8080/todos
{"todos":[{"id":1,"title":"Купить молоко","completed":false},
          {"id":2,"title":"Написать код","completed":false}],
 "count":2}

$ curl http://localhost:8080/todos/1
{"id":1,"title":"Купить молоко","completed":false}

$ curl -X PUT http://localhost:8080/todos/1 \
  -H "Content-Type: application/json" \
  -d '{"completed":true}'
{"id":1,"title":"Купить молоко","completed":true}

$ curl -X DELETE http://localhost:8080/todos/2
(пустой ответ, статус 204)

$ curl http://localhost:8080/todos/999
{"error":"Todo 999 not found"}
```

## HTML-шаблоны

Помимо JSON API, Dream поддерживает серверный рендеринг HTML. Для простых случаев достаточно `Dream.html` с форматированием строк:

```ocaml
let page_handler _req =
  Dream.html
    (Printf.sprintf
       {|<!DOCTYPE html>
<html>
<head><title>TODO</title></head>
<body>
  <h1>Мои задачи</h1>
  <ul>%s</ul>
</body>
</html>|}
       (List.rev !todos
        |> List.map (fun t ->
             Printf.sprintf "<li>%s %s</li>"
               (if t.completed then "&#10003;" else "&#9744;")
               t.title)
        |> String.concat "\n    "))
```

Для более сложных шаблонов Dream предлагает встроенный **шаблонизатор** на основе PPX, позволяющий писать HTML прямо в OCaml-файлах с интерполяцией. Однако его детальное рассмотрение выходит за рамки этой главы — мы сосредоточимся на API-серверах.

## Расширенные возможности Dream

### Обработка ошибок

Dream позволяет настроить глобальную обработку ошибок через параметр `~error_handler`:

```ocaml
let error_handler _error _debug_info suggested_response =
  let status = Dream.status suggested_response in
  let code = Dream.status_to_int status in
  let body = Printf.sprintf {|{"error": "HTTP %d"}|} code in
  Dream.json ~status body

let () =
  Dream.run ~error_handler
  @@ Dream.logger
  @@ Dream.router [ ... ]
```

### Query-параметры

```ocaml
(* GET /todos?completed=true&page=2 *)
let filtered_handler req =
  let completed_filter =
    match Dream.query req "completed" with
    | Some "true" -> Some true
    | Some "false" -> Some false
    | _ -> None
  in
  let all = List.rev !todos in
  let filtered = match completed_filter with
    | Some c -> List.filter (fun t -> t.completed = c) all
    | None -> all
  in
  let response = { todos = filtered; count = List.length filtered } in
  json_response (todo_list_to_yojson response)
```

### Настройка порта и хоста

```ocaml
let () =
  Dream.run
    ~port:3000
    ~interface:"0.0.0.0"
  @@ Dream.logger
  @@ Dream.router [ ... ]
```

По умолчанию Dream слушает на `localhost:8080`. Параметр `~interface:"0.0.0.0"` позволяет принимать соединения с любого адреса.

## Сравнение с Haskell

| Аспект | OCaml (Dream) | Haskell (Servant) | Haskell (Scotty) |
|--------|--------------|-------------------|------------------|
| Стиль маршрутизации | Обычные функции | Типы-уровни (Type-level DSL) | Паттерн-матчинг |
| Типобезопасность маршрутов | Нет (строки) | Полная (типы) | Нет (строки) |
| JSON | ppx_deriving_yojson | aeson + Generic | aeson + Generic |
| Именование кодеков | `t_to_yojson`, `t_of_yojson` | `toJSON`, `parseJSON` | `toJSON`, `parseJSON` |
| Async-модель | Lwt (промисы) | IO + Warp | IO + Warp |
| Middleware | `handler -> handler` | Servant combinators | Scotty middleware |
| Генерация клиента | Нет | Из типов маршрутов | Нет |
| Документация API | Ручная | Из типов (Swagger) | Ручная |
| Порог входа | Низкий | Высокий | Низкий |

**Servant** — уникальный фреймворк, где маршруты описываются на уровне типов:

```haskell
-- Haskell Servant: маршруты как типы
type API =
       "todos" :> Get '[JSON] [Todo]
  :<|> "todos" :> ReqBody '[JSON] CreateTodo :> Post '[JSON] Todo
  :<|> "todos" :> Capture "id" Int :> Get '[JSON] Todo
```

Из такого описания Servant генерирует сервер, клиент и документацию. Это мощно, но требует глубокого понимания type-level программирования.

**Scotty** ближе к Dream по духу — простой, процедурный API:

```haskell
-- Haskell Scotty: похоже на Dream
main = scotty 8080 $ do
  get "/todos" $ json todos
  post "/todos" $ do
    body <- jsonData
    json (createTodo body)
```

Dream занимает аналогичную нишу в экосистеме OCaml: простой фреймворк для быстрого старта, не требующий продвинутых знаний системы типов.

```admonish tip title="Экосистема: Opium — альтернативный веб-фреймворк"
Помимо Dream, в экосистеме OCaml существует [Opium](https://github.com/rgrinberg/opium) — веб-фреймворк, вдохновлённый Sinatra (Ruby) и Express (Node.js). Opium старше Dream и предоставляет похожий API. Dream был создан позже и имеет более современный дизайн: встроенную поддержку WebSocket, шаблонизатор, интеграцию с CSRF-защитой. Для новых проектов рекомендуется Dream, но Opium всё ещё используется в существующих кодовых базах.
```

```admonish info title="Real World OCaml"
Подробнее о конкурентности и асинхронном программировании, на которых основан Dream, — в главе [Concurrent Programming with Async](https://dev.realworldocaml.org/concurrent-programming.html) книги Real World OCaml.
```

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Лёгкое)** Напишите обработчик `health_handler`, который возвращает JSON-ответ `{"status": "ok"}`.

    ```ocaml
    val health_handler : Dream.request -> Dream.response Lwt.t
    ```

    Обработчик должен возвращать ответ со статусом 200 и телом `{"status":"ok"}`.

    *Подсказка:* используйте `Dream.json`.

2. **(Среднее)** Реализуйте **чистую** функцию пагинации `paginate`, которая принимает offset, limit и список, возвращая соответствующий срез:

    ```ocaml
    val paginate : offset:int -> limit:int -> 'a list -> 'a list
    ```

    Offset — количество элементов, которые нужно пропустить. Limit — максимальное количество элементов в результате. Если offset выходит за пределы списка, верните пустой список.

    Примеры:
    - `paginate ~offset:0 ~limit:2 [1;2;3;4;5]` -> `[1;2]`
    - `paginate ~offset:2 ~limit:2 [1;2;3;4;5]` -> `[3;4]`
    - `paginate ~offset:4 ~limit:2 [1;2;3;4;5]` -> `[5]`
    - `paginate ~offset:10 ~limit:2 [1;2;3]` -> `[]`

    *Подсказка:* используйте рекурсию для пропуска первых `offset` элементов, затем для взятия `limit` элементов.

3. **(Среднее)** Реализуйте **чистую** функцию `search_todos`, которая фильтрует список задач по подстроке в заголовке:

    ```ocaml
    type todo = { id : int; title : string; completed : bool }

    val search_todos : string -> todo list -> todo list
    ```

    Примеры:
    - `search_todos "Buy" [...]` — возвращает задачи, содержащие «Buy» в заголовке.
    - `search_todos "" [...]` — возвращает все задачи (пустой запрос не фильтрует).

    *Подсказка:* для проверки вхождения подстроки напишите вспомогательную функцию через `String.length` и `String.sub`, проверяя все позиции в строке.

4. **(Сложное)** Реализуйте middleware `auth_middleware`, который проверяет наличие и корректность Bearer-токена в заголовке `Authorization`:

    ```ocaml
    val auth_middleware : string -> Dream.middleware
    ```

    Middleware принимает секретный токен и возвращает middleware-функцию. Логика:

    - Если заголовок `Authorization` отсутствует — вернуть 401 с `{"error":"missing authorization header"}`.
    - Если заголовок не начинается с `"Bearer "` — вернуть 401 с `{"error":"invalid authorization scheme"}`.
    - Если токен не совпадает с ожидаемым — вернуть 403 с `{"error":"invalid token"}`.
    - Если всё верно — передать запрос внутреннему обработчику.

    Пример использования:

    ```ocaml
    Dream.scope "/api" [auth_middleware "secret-token-123"] [
      Dream.get "/data" data_handler;
    ]
    ```

    *Подсказка:* используйте `Dream.header req "Authorization"` для чтения заголовка и `String.length` / `String.sub` для разбора значения.

5. **(Среднее)** Реализуйте middleware `cors_middleware`, которое добавляет CORS-заголовки ко всем HTTP-ответам:

    ```ocaml
    val cors_middleware : Dream.middleware
    ```

    Middleware должно добавлять следующие заголовки к ответу:
    - `Access-Control-Allow-Origin: *`
    - `Access-Control-Allow-Methods: GET, POST, PUT, DELETE`
    - `Access-Control-Allow-Headers: Content-Type`

    Пример использования:

    ```ocaml
    Dream.run
    @@ cors_middleware
    @@ Dream.router [ Dream.get "/" handler ]
    ```

    *Подсказка:* middleware принимает handler и request, вызывает handler, получает response и добавляет заголовки через `Dream.add_header`.

6. **(Лёгкое)** Реализуйте вспомогательную функцию `json_error` для создания JSON-ответа с ошибкой:

    ```ocaml
    val json_error : Dream.status -> string -> Dream.response Lwt.t
    ```

    Функция принимает HTTP-статус и сообщение об ошибке, возвращает Dream-ответ с JSON-телом в формате `{"error":"message"}`.

    Примеры:
    - `json_error `Bad_Request "invalid input"` → `{"error":"invalid input"}` со статусом 400
    - `json_error `Not_Found "resource not found"` → `{"error":"resource not found"}` со статусом 404

    *Подсказка:* используйте `Printf.sprintf` для форматирования JSON и `Dream.json ~status`.

7. **(Среднее)** Реализуйте обработчик `create_todo_handler` для создания новой задачи через POST-запрос:

    ```ocaml
    val create_todo_handler : Dream.request -> Dream.response Lwt.t
    ```

    Обработчик должен:
    1. Прочитать body запроса через `Dream.body`
    2. Распарсить JSON с помощью `create_todo_of_yojson` (тип `create_todo` уже определён в библиотеке)
    3. Создать задачу через `create_todo ~title`
    4. Вернуть JSON с созданной задачей и статусом `201 Created`
    5. При ошибке парсинга вернуть `400 Bad Request` с помощью `json_error`

    *Подсказка:* используйте let-оператор `let* =` из `Lwt.Syntax` для последовательной композиции Lwt-операций. Функция `create_todo_of_yojson` возвращает `(create_todo, error) result`.

8. **(Лёгкое)** Реализуйте **чистую** функцию `filter_todos` для фильтрации задач по статусу выполнения:

    ```ocaml
    val filter_todos : bool option -> todo list -> todo list
    ```

    Логика фильтрации:
    - `None` — вернуть все задачи без фильтрации
    - `Some true` — вернуть только выполненные задачи (`completed = true`)
    - `Some false` — вернуть только невыполненные задачи (`completed = false`)

    Примеры:
    - `filter_todos None [...]` → все задачи
    - `filter_todos (Some true) [...]` → только с `completed = true`
    - `filter_todos (Some false) [...]` → только с `completed = false`

    *Подсказка:* используйте `List.filter` с pattern matching на `filter`.

## Заключение

В этой главе:

- Разобрали Dream — веб-фреймворк для OCaml с API в одном модуле.
- Написали обработчики (`request -> response Lwt.t`) и маршруты.
- Написали middleware для таймингов и CORS.
- Построили CRUD API для списка задач с JSON-сериализацией.
- Обработали ошибки: невалидный JSON, несуществующие ресурсы, некорректные параметры.
- Сравнили Dream с Haskell-фреймворками Servant и Scotty.

### Итоги основного курса

Эта глава завершает практическую часть книги. Пройденный путь:

- **Главы 1--3** — введение, настройка окружения, обзор языка.
- **Главы 4--6** — функции, записи, алгебраические типы, рекурсия, `map` и свёртки.
- **Глава 7** — модульная система: сигнатуры, функторы, инкапсуляция.
- **Глава 8** — обработка ошибок через `option`, `result` и let-операторы.
- **Глава 9** — мутабельное состояние и прямые эффекты.
- **Глава 10** — проектирование через типы: smart constructors и state machines.
- **Глава 11** — Expression Problem и разные способы его решения.
- **Глава 12** — конкурентное программирование с Eio и доменами OCaml 5.
- **Глава 13** — обработчики эффектов в OCaml 5.
- **Глава 14** — FFI и JSON.
- **Глава 15** — CLI-приложения с Cmdliner.
- **Глава 16** — генеративное тестирование.
- **Глава 17** — парсер-комбинаторы (Angstrom) и GADT для типобезопасных DSL.
- **Глава 18** (эта глава) — JSON, Lwt, мутабельное состояние в веб-сервере на Dream.

В следующей главе: ppx и метапрограммирование — расширение OCaml на этапе компиляции.

### Что дальше

Темы за пределами книги:

- **Базы данных** — Caqti для SQL, Irmin для Git-подобного хранилища.
- **ORM и миграции** — Petrol, OCaml-migrate.
- **WebSocket** — Dream поддерживает из коробки.
- **GraphQL** — библиотека ocaml-graphql-server.
- **Формальная верификация** — Coq и F*.
- **Компиляция в JavaScript** — js_of_ocaml и Melange.
- **Развёртывание** — Docker-контейнеры, MirageOS unikernels, статическая линковка.
