# RSS Reader — Пошаговый гайд

## 📋 Обзор проекта

Вы создадите консольный RSS-агрегатор, который:
- Валидирует RSS URL
- Скачивает фиды конкурентно
- Парсит XML
- Хранит и отображает посты
- Обнаруживает дубликаты

**Время:** 6-8 часов  
**Сложность:** Средняя  
**Используемые главы:** 8 (валидация), 12 (Eio), 14 (HTTP/XML), 15 (CLI)

## 🎯 Требования

### Функциональные

1. **Валидация**
   - Проверка корректности URL
   - Проверка что URL ведёт на RSS фид
   - Обнаружение дубликатов (один URL нельзя добавить дважды)

2. **Загрузка**
   - Конкурентная загрузка нескольких фидов через Eio
   - Обработка network ошибок
   - Timeout для медленных запросов

3. **Парсинг**
   - Парсинг RSS 2.0 формата
   - Извлечение заголовков, описаний, дат
   - Обработка невалидного XML

4. **Хранение**
   - In-memory хранилище фидов и постов
   - Deduplicate постов по GUID/link

5. **CLI**
   - `add <url>` — добавить фид
   - `list` — показать все фиды
   - `posts` — показать последние 10 постов
   - `update` — обновить все фиды

### Технические

- Использовать `cohttp-eio` для HTTP
- Использовать `ezxmlm` для парсинга XML
- Использовать `cmdliner` для CLI
- Unit тесты для парсера
- Mock HTTP запросы в тестах

## 📝 Шаг 1: Валидация URL (45 минут)

### 1.1. Создайте модуль Validator

**Файл:** `lib/validator.ml`

```ocaml
(** URL валидатор для RSS фидов. *)

type url = string

type validation_error =
  | Empty_url
  | Invalid_scheme  (* только http/https *)
  | Invalid_format
  | Already_exists

(** Валидировать URL.
    Ok url если валиден, Error причина если нет. *)
let validate_url (url : url) ~(existing : url list) : (url, validation_error) result =
  (* TODO: реализуйте валидацию *)
  failwith "TODO: Implement validate_url"

(** Показать ошибку в читаемом виде *)
let show_error : validation_error -> string = function
  | Empty_url -> "URL не может быть пустым"
  | Invalid_scheme -> "URL должен начинаться с http:// или https://"
  | Invalid_format -> "Некорректный формат URL"
  | Already_exists -> "Этот URL уже добавлен"
```

**Подсказки:**
1. Проверьте что URL не пустой
2. Проверьте что начинается с http:// или https://
3. Проверьте что URL валиден (содержит домен)
4. Проверьте что URL не в списке existing

### 1.2. Тесты для валидатора

**Файл:** `test/test_validator.ml`

```ocaml
let valid_url_tests =
  let open Alcotest in
  [
    test_case "валидный HTTP URL проходит" `Quick (fun () ->
      match Rss_reader.Validator.validate_url "http://example.com/feed" ~existing:[] with
      | Ok _ -> ()
      | Error e -> fail (Rss_reader.Validator.show_error e));

    test_case "пустой URL отклоняется" `Quick (fun () ->
      match Rss_reader.Validator.validate_url "" ~existing:[] with
      | Error Empty_url -> ()
      | _ -> fail "должна быть ошибка Empty_url");

    test_case "дубликат URL отклоняется" `Quick (fun () ->
      let url = "http://example.com/feed" in
      match Rss_reader.Validator.validate_url url ~existing:[url] with
      | Error Already_exists -> ()
      | _ -> fail "должна быть ошибка Already_exists");
  ]
```

**Задачи:**
- [ ] Реализуйте `validate_url`
- [ ] Добавьте тесты для FTP схемы (должна отклоняться)
- [ ] Добавьте тесты для невалидных URL
- [ ] Запустите `dune test`

## 📝 Шаг 2: Парсинг RSS XML (90 минут)

### 2.1. Типы для RSS

**Файл:** `lib/feed_parser.ml`

```ocaml
(** RSS feed parser. *)

type post = {
  title : string;
  link : string;
  description : string option;
  pub_date : string option;
  guid : string option;
}

type feed = {
  title : string;
  link : string;
  description : string;
  posts : post list;
}

(** Парсить RSS XML строку. *)
let parse (xml_string : string) : (feed, string) result =
  (* TODO: реализуйте парсер *)
  failwith "TODO: Implement RSS parser"
```

**Задачи:**
- [ ] Установите `ezxmlm`: `opam install ezxmlm`
- [ ] Реализуйте парсинг RSS 2.0
- [ ] Добавьте фикстуры с примерами RSS
- [ ] Протестируйте парсер

## 📝 Шаг 3: HTTP загрузка с Eio (60 минут)

**Файл:** `lib/downloader.ml`

```ocaml
type download_error =
  | Network_error of string
  | Timeout

(** Скачать URL с timeout через Eio и cohttp-eio *)
let fetch ~(sw : Eio.Switch.t) ~(net : Eio.Net.t) ~(timeout : float) (url : string) 
    : (string, download_error) result =
  (* TODO: реализуйте HTTP клиент *)
  failwith "TODO: Implement HTTP downloader"

(** Скачать несколько URL конкурентно *)
let fetch_all ~sw ~net ~timeout (urls : string list) 
    : (string * (string, download_error) result) list =
  (* TODO: используйте Eio.Fiber.List.map *)
  failwith "TODO: Implement concurrent fetch"
```

**Задачи:**
- [ ] Установите `cohttp-eio`: `opam install cohttp-eio`
- [ ] Реализуйте `fetch` с timeout
- [ ] Реализуйте `fetch_all` для конкурентной загрузки
- [ ] Протестируйте с mock сервером

## 📝 Шаг 4: Хранилище (45 минут)

**Файл:** `lib/storage.ml`

```ocaml
type t = {
  mutable feeds : (string * Feed_parser.feed) list;  (* url, feed *)
  mutable all_posts : Feed_parser.post list;
}

let create () : t = { feeds = []; all_posts = [] }

let add_feed (storage : t) ~(url : string) (feed : Feed_parser.feed) 
    : (unit, string) result =
  (* TODO: добавить фид, проверить дубликаты *)
  failwith "TODO"

let get_feeds (storage : t) : (string * Feed_parser.feed) list =
  storage.feeds

let get_recent_posts (storage : t) ~(limit : int) : Feed_parser.post list =
  (* TODO: вернуть последние N постов *)
  failwith "TODO"
```

**Задачи:**
- [ ] Реализуйте все функции
- [ ] Добавьте дедупликацию постов по guid/link
- [ ] Сортируйте посты по pub_date
- [ ] Тесты для Storage

## 📝 Шаг 5: CLI интерфейс (90 минут)

**Файл:** `bin/main.ml`

```ocaml
open Cmdliner
open Rss_reader

let storage = Storage.create ()

(* Команда: add <url> *)
let add_cmd =
  let add url =
    Eio_main.run @@ fun env ->
    let net = Eio.Stdenv.net env in
    Eio.Switch.run @@ fun sw ->
    (* 1. Валидация *)
    let existing = Storage.get_feeds storage |> List.map fst in
    match Validator.validate_url url ~existing with
    | Error e ->
        Printf.eprintf "Ошибка: %s\n" (Validator.show_error e);
        exit 1
    | Ok url ->
        (* 2. Загрузка *)
        match Downloader.fetch ~sw ~net ~timeout:5.0 url with
        | Error _ -> Printf.eprintf "Не удалось загрузить фид\n"; exit 1
        | Ok xml ->
            (* 3. Парсинг *)
            match Feed_parser.parse xml with
            | Error e -> Printf.eprintf "Ошибка парсинга: %s\n" e; exit 1
            | Ok feed ->
                (* 4. Сохранение *)
                let _ = Storage.add_feed storage ~url feed in
                Printf.printf "Фид добавлен: %s\n" feed.title
  in
  let url_arg = Arg.(required & pos 0 (some string) None & info []) in
  Cmd.v (Cmd.info "add" ~doc:"Добавить RSS фид") Term.(const add $ url_arg)

(* TODO: реализуйте остальные команды *)

let () =
  let doc = "RSS Reader — консольный RSS агрегатор" in
  let default_cmd = Cmd.group (Cmd.info "rss-reader" ~doc) [add_cmd] in
  exit (Cmd.eval default_cmd)
```

**Задачи:**
- [ ] Реализуйте команду `list`
- [ ] Реализуйте команду `posts`
- [ ] Реализуйте команду `update`
- [ ] Добавьте цветной вывод
- [ ] Сохраняйте storage в файл

## 🎉 Проверка

```bash
# Тесты
cd exercises/project_rss_reader
dune test

# Запуск
dune exec rss-reader add "https://news.ycombinator.com/rss"
dune exec rss-reader list
dune exec rss-reader posts
```

## 📚 Дополнительные улучшения

- [ ] Персистентность: SQLite вместо памяти
- [ ] Web UI: Dream сервер
- [ ] Уведомления при новых постах
- [ ] Поиск по ключевым словам
- [ ] OPML импорт/экспорт

---

**Примечание:** Этот проект объединяет знания из глав 8, 12, 14, 15 и является отличной практикой для реальных приложений на OCaml!
