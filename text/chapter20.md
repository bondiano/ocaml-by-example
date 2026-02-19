# Веб-разработка с Dream

## Цели главы

В этой главе мы изучим веб-разработку на OCaml с использованием фреймворка **Dream** --- минималистичного, но мощного инструмента для создания серверных приложений:

- **Dream** --- философия «один плоский модуль», минималистичный API.
- **Обработчики** (handlers) --- функции `request -> response Lwt.t`.
- **Маршрутизация** --- `Dream.get`, `Dream.post`, параметры пути, области (scopes).
- **Middleware** --- промежуточные обработчики для логирования, авторизации, таймингов.
- **JSON API** --- работа с JSON через Yojson и `ppx_deriving_yojson` (из главы 10).
- **Проект: TODO API** --- полноценный CRUD с хранением в памяти.
- Сравнение с Haskell-фреймворками (Servant, Scotty).

Dream построен поверх **Lwt** (глава 17), поэтому все обработчики возвращают `Lwt.t`. Если вы ещё не знакомы с промисами Lwt, рекомендуется сначала прочитать предыдущую главу.

## Подготовка проекта

Код этой главы находится в `exercises/chapter20`. Установите необходимые библиотеки:

```text
$ opam install dream yojson ppx_deriving_yojson
$ cd exercises/chapter20
$ dune build
```

Файл `dune` для библиотеки:

```lisp
(library
 (name chapter20)
 (libraries dream yojson)
 (preprocess (pps ppx_deriving_yojson)))
```

## Dream: философия

Dream придерживается принципа **«один плоский модуль»**: весь API находится в модуле `Dream`. Нет глубоких иерархий модулей, нет сложных абстракций --- всё вызывается как `Dream.something`.

Это сознательный выбор автора фреймворка. Вместо того чтобы разбивать функциональность на десятки подмодулей, Dream предлагает одно пространство имён с понятными именами:

- `Dream.run` --- запустить сервер.
- `Dream.router` --- маршрутизация запросов.
- `Dream.get`, `Dream.post`, `Dream.put`, `Dream.delete` --- HTTP-методы.
- `Dream.html`, `Dream.json` --- формирование ответов.
- `Dream.body` --- чтение тела запроса.
- `Dream.param` --- извлечение параметров пути.
- `Dream.logger` --- логирование запросов.

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

- `Dream.run` --- запускает HTTP-сервер (по умолчанию на порту 8080).
- `Dream.logger` --- middleware, логирующий каждый запрос в консоль.
- `Dream.router [...]` --- маршрутизатор, сопоставляющий URL с обработчиками.
- `Dream.get "/" handler` --- маршрут для GET-запроса на корневой путь.
- `Dream.html "Hello, world!"` --- ответ с типом `text/html`.

Оператор `@@` --- это применение функции (`f @@ x` эквивалентно `f x`). Цепочка `@@` читается сверху вниз: `Dream.run` принимает middleware-конвейер, который заканчивается роутером.

```text
$ dune exec ./main.exe
18.02.2026 12:00:00.000       dream.log  INFO REQ 1 GET / 127.0.0.1:54321
18.02.2026 12:00:00.001       dream.log  INFO REQ 1 200 in 1 us
```

## Обработчики

Центральное понятие Dream --- **обработчик** (handler). Это функция, принимающая запрос и возвращающая ответ в контексте Lwt:

```ocaml
type handler = Dream.request -> Dream.response Lwt.t
```

Любая функция с такой сигнатурой может быть обработчиком. Вот несколько примеров:

```ocaml
(* Простой обработчик --- возвращает HTML *)
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

Обратите внимание на `let*` --- синтаксис let-операторов Lwt (из главы 17). `Dream.body req` возвращает `string Lwt.t`, поэтому мы используем `let*` для извлечения строки.

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

Второй аргумент `Dream.scope` --- список middleware, применяемых ко всем маршрутам внутри области. Пустой список `[]` означает отсутствие дополнительных middleware.

С этой конфигурацией:

- `GET /` --- главная страница.
- `GET /api/status` --- статус API.
- `GET /api/v1/users` --- список пользователей.
- `GET /api/v1/users/42` --- пользователь с id 42.

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

Middleware --- функция, которая **оборачивает** обработчик, добавляя логику до и/или после обработки запроса.

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

В главе 12 мы изучили `ppx_deriving_yojson` для автоматической сериализации. Теперь применим это для построения JSON API.

Напомним ключевые моменты:

```ocaml
type todo = {
  id : int;
  title : string;
  completed : bool;
} [@@deriving yojson]
```

Аннотация `[@@deriving yojson]` генерирует:

- `todo_to_yojson : todo -> Yojson.Safe.t` --- сериализация.
- `todo_of_yojson : Yojson.Safe.t -> (todo, string) result` --- десериализация.

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

Тип `create_todo` описывает тело POST-запроса --- для создания задачи нужен только заголовок. Тип `update_todo` описывает тело PUT-запроса --- оба поля необязательные (обновляем только то, что передали). Атрибут `[@default None]` говорит ppx, что при отсутствии поля в JSON нужно подставить `None`.

### Хранилище в памяти

Используем мутабельную ссылку (из главы 8) как простое хранилище:

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

`List.rev` --- потому что мы добавляем задачи в начало списка, а пользователь ожидает хронологический порядок.

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

- `Yojson.Json_error` --- строка не является валидным JSON.
- `Error msg` --- JSON валиден, но не соответствует типу `create_todo`.

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

Обработчик обновления --- самый сложный, потому что требует:

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

При успешном удалении возвращаем `204 No Content` --- стандартная практика для DELETE-запросов.

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

Для более сложных шаблонов Dream предлагает встроенный **шаблонизатор** на основе PPX, позволяющий писать HTML прямо в OCaml-файлах с интерполяцией. Однако его детальное рассмотрение выходит за рамки этой главы --- мы сосредоточимся на API-серверах.

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

**Servant** --- уникальный фреймворк, где маршруты описываются на уровне типов:

```haskell
-- Haskell Servant: маршруты как типы
type API =
       "todos" :> Get '[JSON] [Todo]
  :<|> "todos" :> ReqBody '[JSON] CreateTodo :> Post '[JSON] Todo
  :<|> "todos" :> Capture "id" Int :> Get '[JSON] Todo
```

Из такого описания Servant генерирует сервер, клиент и документацию. Это мощно, но требует глубокого понимания type-level программирования.

**Scotty** ближе к Dream по духу --- простой, процедурный API:

```haskell
-- Haskell Scotty: похоже на Dream
main = scotty 8080 $ do
  get "/todos" $ json todos
  post "/todos" $ do
    body <- jsonData
    json (createTodo body)
```

Dream занимает аналогичную нишу в экосистеме OCaml: простой фреймворк для быстрого старта, не требующий продвинутых знаний системы типов.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Лёгкое)** Напишите обработчик `health_handler`, который возвращает JSON-ответ `{"status": "ok"}`.

    ```ocaml
    val health_handler : Dream.request -> Dream.response Lwt.t
    ```

    Обработчик должен возвращать ответ со статусом 200 и телом `{"status":"ok"}`.

    *Подсказка:* используйте `Dream.json`.

2. **(Среднее)** Реализуйте **чистую** функцию пагинации `paginate`, которая принимает список, номер страницы и размер страницы и возвращает соответствующий срез:

    ```ocaml
    val paginate : page:int -> per_page:int -> 'a list -> 'a list
    ```

    Нумерация страниц начинается с 1. Если страница выходит за пределы списка, верните пустой список. Если `page < 1` или `per_page < 1`, верните пустой список.

    Примеры:
    - `paginate ~page:1 ~per_page:2 [1;2;3;4;5]` -> `[1;2]`
    - `paginate ~page:2 ~per_page:2 [1;2;3;4;5]` -> `[3;4]`
    - `paginate ~page:3 ~per_page:2 [1;2;3;4;5]` -> `[5]`
    - `paginate ~page:4 ~per_page:2 [1;2;3;4;5]` -> `[]`

    *Подсказка:* используйте комбинацию `List.filteri` или ручную рекурсию с `List.nth`.

3. **(Среднее)** Реализуйте **чистую** функцию `search_todos`, которая фильтрует список задач по подстроке в заголовке (без учёта регистра):

    ```ocaml
    type todo = { id : int; title : string; completed : bool }

    val search_todos : query:string -> todo list -> todo list
    ```

    Примеры:
    - `search_todos ~query:"молоко" [...]` --- возвращает задачи, содержащие «молоко» в заголовке.
    - `search_todos ~query:"" [...]` --- возвращает все задачи (пустой запрос не фильтрует).

    *Подсказка:* используйте `String.lowercase_ascii` для регистронезависимого поиска. Для проверки вхождения подстроки можно написать вспомогательную функцию через `String.length` и `String.sub`, или воспользоваться `Str` / ручной рекурсией.

4. **(Сложное)** Реализуйте middleware `auth_middleware`, который проверяет наличие и корректность Bearer-токена в заголовке `Authorization`:

    ```ocaml
    val auth_middleware : string -> Dream.middleware
    ```

    Middleware принимает секретный токен и возвращает middleware-функцию. Логика:

    - Если заголовок `Authorization` отсутствует --- вернуть 401 с `{"error":"missing authorization header"}`.
    - Если заголовок не начинается с `"Bearer "` --- вернуть 401 с `{"error":"invalid authorization scheme"}`.
    - Если токен не совпадает с ожидаемым --- вернуть 403 с `{"error":"invalid token"}`.
    - Если всё верно --- передать запрос внутреннему обработчику.

    Пример использования:

    ```ocaml
    Dream.scope "/api" [auth_middleware "secret-token-123"] [
      Dream.get "/data" data_handler;
    ]
    ```

    *Подсказка:* используйте `Dream.header req "Authorization"` для чтения заголовка и `String.length` / `String.sub` для разбора значения.

## Заключение

В этой главе мы:

- Познакомились с Dream --- минималистичным веб-фреймворком для OCaml.
- Изучили обработчики (`request -> response Lwt.t`) и маршрутизацию.
- Написали пользовательские middleware для таймингов и CORS.
- Построили полноценный CRUD API для списка задач с JSON-сериализацией.
- Освоили обработку ошибок в обработчиках: невалидный JSON, несуществующие ресурсы, некорректные параметры.
- Сравнили Dream с Haskell-фреймворками Servant и Scotty.

### Итоги основного курса

Эта глава завершает основной курс книги «OCaml на примерах». За 20 глав мы прошли путь от базового синтаксиса до построения веб-сервера:

- **Главы 1--5** заложили основу: типы, функции, рекурсия, алгебраические типы, `map` и свёртки.
- **Глава 6** раскрыла модульную систему OCaml --- сигнатуры, функторы, инкапсуляция.
- **Глава 7** научила обработке ошибок через `option`, `result` и let-операторы.
- **Глава 8** познакомила с мутабельным состоянием и прямыми эффектами.
- **Глава 9** раскрыла проектирование через типы --- smart constructors и state machines.
- **Глава 10** исследовала Expression Problem и разные способы его решения.
- **Глава 11** открыла мир конкурентного программирования с Eio и доменами OCaml 5.
- **Глава 12** связала OCaml с внешним миром через FFI и JSON.
- **Глава 13** показала обработчики эффектов --- одну из главных новинок OCaml 5.
- **Глава 14** продемонстрировала графику с raylib.
- **Глава 15** научила генеративному тестированию --- автоматическому поиску контрпримеров.
- **Глава 16** раскрыла парсер-комбинаторы (Angstrom) и GADT для типобезопасных DSL.
- **Глава 17** показала создание CLI-приложений с Cmdliner.
- **Глава 18** погрузила в метапрограммирование через ppx.
- **Глава 19** познакомила с промисами и Lwt --- асинхронным программированием в стиле колбэков.
- **Глава 20** (эта глава) соединила всё вместе: JSON, Lwt, мутабельное состояние --- в веб-сервере на Dream.

В следующих главах мы рассмотрим продвинутые темы --- оптимизации и рекурсивные схемы.

### Что дальше

За пределами этой книги остаётся множество тем для изучения:

- **Базы данных** --- Caqti для SQL, Irmin для Git-подобного хранилища.
- **ORM и миграции** --- Petrol, OCaml-migrate.
- **WebSocket** --- Dream поддерживает WebSocket из коробки.
- **GraphQL** --- библиотека ocaml-graphql-server.
- **Формальная верификация** --- OCaml тесно связан с Coq и F*.
- **Компиляция в JavaScript** --- js_of_ocaml и Melange позволяют писать фронтенд на OCaml.
- **Развёртывание** --- Docker-контейнеры, MirageOS unikernels, статическая линковка.

Надеемся, что эта книга дала вам прочную основу для дальнейшего изучения OCaml и функционального программирования. Удачи в ваших проектах!
