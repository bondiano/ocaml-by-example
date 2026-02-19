# Конкурентность с Eio

## Цели главы

Эта глава о конкурентном и параллельном программировании в OCaml 5 с библиотекой **Eio** — прямой стиль (direct-style) вместо промисов и колбэков.

Темы главы:

- **Домены** (domains) — настоящий параллелизм на нескольких ядрах.
- **Файберы** (fibers) — легковесная конкурентность внутри домена.
- **Eio** — библиотека прямого стиля для конкурентного ввода-вывода.
- **Структурированная конкурентность** — все задачи завершаются до выхода из scope.
- **Каналы** (`Eio.Stream`) — безопасная коммуникация между файберами.
- **Таймауты** и отмена операций.
- Сравнение с Lwt и Async.

## Подготовка проекта

Код этой главы находится в `exercises/chapter12`. Этой главе нужны дополнительные библиотеки:

```text
$ opam install eio eio_main
$ cd exercises/chapter12
$ dune build
```

## OCaml 5 и многоядерность

OCaml 5 — историческое обновление языка, добавившее поддержку параллелизма. До OCaml 5 существовал глобальный мьютекс (GIL), не позволявший выполнять OCaml-код на нескольких ядрах одновременно.

OCaml 5 предлагает два уровня конкурентности:

1. **Домены** (domains) — потоки уровня ОС для настоящего параллелизма.
2. **Effect handlers** — механизм для реализации легковесной конкурентности (файберов).

## Домены

Домен (domain) — единица параллелизма. Каждый домен выполняется на отдельном ядре процессора:

```ocaml
let () =
  let d = Domain.spawn (fun () ->
    Printf.printf "Домен: %d\n" (Domain.self () :> int)
  ) in
  Printf.printf "Основной домен\n";
  Domain.join d
```

`Domain.spawn f` запускает функцию `f` в новом домене. `Domain.join d` ожидает завершения домена и возвращает результат. Выражение `(Domain.self () :> int)` — явное приведение типа (coercion): `Domain.self ()` возвращает непрозрачный тип `Domain.id`, а `:> int` преобразует его в `int` для вывода.

### Параллельное вычисление

```ocaml
let parallel_sum arr =
  let n = Array.length arr in
  let mid = n / 2 in
  let d = Domain.spawn (fun () ->
    let sum = ref 0 in
    for i = 0 to mid - 1 do sum := !sum + arr.(i) done;
    !sum
  ) in
  let sum2 = ref 0 in
  for i = mid to n - 1 do sum2 := !sum2 + arr.(i) done;
  Domain.join d + !sum2
```

Массив делится пополам, каждая половина суммируется в своём домене параллельно.

### Ограничения доменов

- Доменов должно быть **мало** (по числу ядер). Создание домена — дорогая операция.
- Для тысяч конкурентных задач используйте **файберы**.

```admonish tip title="Для Python/TypeScript-разработчиков"
Домены в OCaml 5 — это аналог **настоящих потоков** (не `threading` в Python, который ограничен GIL). Ближайшая аналогия:

| | Python | Go | OCaml 5 |
|---|---|---|---|
| Настоящий параллелизм | `multiprocessing` | горутины + GOMAXPROCS | домены |
| Ограничение | Отдельные процессы, IPC | Тысячи горутин, но 1 рантайм | Мало доменов (по числу ядер) |
| Легковесная конкурентность | `asyncio` | горутины | файберы (Eio) |

До OCaml 5 ситуация была как в Python: глобальный мьютекс (GIL/GIL аналог) не позволял параллелить OCaml-код. Теперь домены снимают это ограничение, но их должно быть мало — для массовой конкурентности используйте файберы.
```

## Eio: конкурентность прямого стиля

**Eio** — библиотека для конкурентного ввода-вывода, использующая effect handlers OCaml 5. Её главное преимущество — **прямой стиль**: код выглядит как обычный последовательный, без промисов, монад или колбэков.

### Сравнение подходов

```ocaml
(* Lwt (промисы, старый стиль) *)
let fetch_lwt url =
  let open Lwt.Syntax in
  let* response = Http.get url in
  let* body = Http.read_body response in
  Lwt.return (String.length body)

(* Eio (прямой стиль, новый стиль) *)
let fetch_eio url =
  let response = Http.get url in
  let body = Http.read_body response in
  String.length body
```

В Eio нет `let*`, `>>=`, `Lwt.return` — код читается как обычный последовательный код, но при этом файберы корректно переключаются при ожидании I/O.

```admonish tip title="Для Python/TypeScript-разработчиков"
Eio — это ответ OCaml на проблему «цветных функций» (colored functions). В Python `asyncio` и TypeScript `async/await` создают разделение на «обычные» и «асинхронные» функции:

```python
# Python: async "заражает" весь стек вызовов
async def fetch(url):
    response = await aiohttp.get(url)  # async!
    return response.text

# Нельзя вызвать из обычной функции без await
```

В Eio такого разделения нет. Конкурентный код выглядит точно так же, как синхронный — нет `async`, `await`, `>>=`. Файберы переключаются автоматически при I/O-операциях. Это стало возможным благодаря effect handlers в OCaml 5.
```

### Запуск Eio

Любая Eio-программа начинается с `Eio_main.run`:

```ocaml
let () =
  Eio_main.run @@ fun env ->
  let stdout = Eio.Stdenv.stdout env in
  Eio.Flow.copy_string "Привет, Eio!\n" stdout
```

`@@` — оператор применения функции справа налево: `f @@ x` эквивалентно `f x`, но позволяет обойтись без скобок вокруг длинного аргумента. Здесь `Eio_main.run @@ fun env -> ...` читается как «запусти event loop и передай `env` в лямбду».

`Eio_main.run` инициализирует event loop и передаёт `env` — окружение с доступом к файловой системе, сети, стандартному вводу-выводу и часам.

### Окружение `env`

| Функция | Описание |
|---------|----------|
| `Eio.Stdenv.stdout env` | Стандартный вывод |
| `Eio.Stdenv.stdin env` | Стандартный ввод |
| `Eio.Stdenv.stderr env` | Стандартный вывод ошибок |
| `Eio.Stdenv.clock env` | Часы (для таймаутов и sleep) |
| `Eio.Stdenv.fs env` | Файловая система |
| `Eio.Stdenv.net env` | Сетевой стек |

Передача `env` через аргументы вместо глобальных функций — это **dependency injection**: тесты могут подставить моковое окружение.

## Файберы

Файбер (fiber) — легковесный «зелёный поток», работающий внутри домена. В отличие от доменов, файберы дёшевы — можно запустить тысячи.

### `Eio.Fiber.both`

`Eio.Fiber.both` запускает две функции конкурентно и ждёт завершения обеих:

```ocaml
let () =
  Eio_main.run @@ fun _env ->
  Eio.Fiber.both
    (fun () -> traceln "Файбер A: начал"; traceln "Файбер A: закончил")
    (fun () -> traceln "Файбер B: начал"; traceln "Файбер B: закончил")
```

`traceln` — отладочный вывод Eio (потокобезопасный, в отличие от `Printf.printf`). `Fiber.both` возвращается только тогда, когда **оба** файбера завершились; порядок сообщений может варьироваться в зависимости от планировщика.

### `Eio.Fiber.all` и `Eio.Fiber.any`

```ocaml
(* Запустить все задачи конкурентно, дождаться завершения всех *)
Eio.Fiber.all [
  (fun () -> task1 ());
  (fun () -> task2 ());
  (fun () -> task3 ());
]

(* Запустить все, вернуть результат первой завершившейся *)
Eio.Fiber.any [
  (fun () -> task1 ());
  (fun () -> task2 ());
]
```

`Fiber.all` ждёт **все** задачи. `Fiber.any` возвращает результат **первой** завершившейся и отменяет остальные.

### `Eio.Fiber.fork`

Для запуска файбера в фоне используется `Fiber.fork` внутри `Switch`:

```ocaml
let () =
  Eio_main.run @@ fun _env ->
  Eio.Switch.run @@ fun sw ->
  Eio.Fiber.fork ~sw (fun () ->
    traceln "Фоновый файбер"
  );
  traceln "Основной файбер"
```

`Fiber.fork ~sw` требует явно передать `sw` (switch) — это принудительная привязка жизненного цикла файбера к лексической области видимости `Switch.run`. Без `sw` скомпилировать вызов невозможно, что исключает «забытые» фоновые задачи.

## Структурированная конкурентность

**Switch** — ключевая абстракция Eio для управления временем жизни файберов:

```ocaml
Eio.Switch.run @@ fun sw ->
  Eio.Fiber.fork ~sw (fun () -> task1 ());
  Eio.Fiber.fork ~sw (fun () -> task2 ());
  (* Switch.run не вернётся, пока оба файбера не завершатся *)
```

Правила:

1. Все файберы, созданные внутри `Switch.run`, **должны завершиться** до выхода.
2. Если один файбер бросает исключение — остальные **отменяются**.
3. Нельзя «забыть» файбер — нет утечек горутин/промисов.

Это называется **структурированная конкурентность** — время жизни конкурентных задач привязано к лексической области видимости.

```admonish tip title="Для Python/TypeScript-разработчиков"
Структурированная конкурентность в Eio — аналог `TaskGroup` из Python 3.11+ и `Promise.all` с контролем жизненного цикла:

```python
# Python 3.11+ — структурированная конкурентность
async with asyncio.TaskGroup() as tg:
    tg.create_task(task1())
    tg.create_task(task2())
# Все задачи гарантированно завершены здесь
```

В Eio `Switch.run` играет ту же роль, что `TaskGroup`. Без `Switch` невозможно запустить фоновый файбер — это предотвращает «забытые» задачи и утечки горутин/промисов, с которыми часто сталкиваются в Go и Node.js.
```

## Каналы: `Eio.Stream`

`Eio.Stream` — потокобезопасная очередь для коммуникации между файберами:

```ocaml
let () =
  Eio_main.run @@ fun _env ->
  let stream = Eio.Stream.create 10 in  (* буфер на 10 элементов *)
  Eio.Fiber.both
    (fun () ->
      for i = 1 to 5 do
        Eio.Stream.add stream i;
        traceln "Отправил: %d" i
      done)
    (fun () ->
      for _ = 1 to 5 do
        let v = Eio.Stream.take stream in
        traceln "Получил: %d" v
      done)
```

- `Eio.Stream.create n` — создать канал с буфером размера `n`. Если `n = 0` — синхронный канал (отправитель блокируется до получения).
- `Eio.Stream.add stream v` — отправить значение (блокируется, если буфер полон).
- `Eio.Stream.take stream` — получить значение (блокируется, если буфер пуст).

В примере выше оба файбера выполняются конкурентно: если буфер заполнен, первый приостанавливается до тех пор, пока второй не прочитает элемент, — явных мьютексов или семафоров не нужно.

### Паттерн Producer-Consumer

```ocaml
let producer stream n =
  for i = 1 to n do
    Eio.Stream.add stream (Some i)
  done;
  Eio.Stream.add stream None  (* сигнал завершения *)

let consumer stream =
  let rec loop acc =
    match Eio.Stream.take stream with
    | None -> List.rev acc
    | Some v -> loop (v :: acc)
  in
  loop []
```

Producer посылает числа обёрнутыми в `Some`, а в конце отправляет `None` как сигнал завершения. Consumer читает поток в цикле: при `Some v` накапливает значение, при `None` — возвращает накопленный список. Это идиоматичный способ «закрыть» канал без дополнительных флагов.

## Таймауты и отмена

### `Eio.Time.sleep`

```ocaml
let () =
  Eio_main.run @@ fun env ->
  let clock = Eio.Stdenv.clock env in
  traceln "Начало";
  Eio.Time.sleep clock 1.0;
  traceln "Прошла 1 секунда"
```

### Таймаут с `Fiber.any`

```ocaml
let with_timeout clock seconds f =
  Eio.Fiber.any [
    (fun () -> Some (f ()));
    (fun () -> Eio.Time.sleep clock seconds; None);
  ]
```

Если `f` завершается за `seconds` секунд — возвращает `Some result`. Иначе — `None`, а `f` отменяется.

## Сравнение Eio с Lwt и Async

| Аспект | Lwt | Async | Eio |
|--------|-----|-------|-----|
| Стиль | Монадический (`>>=`) | Монадический (`>>=`) | Прямой |
| Параллелизм | Нет (1 ядро) | Нет (1 ядро) | Да (домены) |
| Механизм | Промисы | Deferred | Effect handlers |
| Структурированность | Нет | Нет | Да (Switch) |
| Зрелость | Высокая | Высокая | Растущая |

Eio — будущее конкурентности в OCaml. Lwt и Async остаются для обратной совместимости.

### Сравнение кода: Lwt vs Eio

Рассмотрим одну и ту же задачу — конкурентно загрузить данные с двух URL — в Lwt и Eio.

**Lwt (монадический стиль):**

```ocaml
open Lwt.Syntax

let fetch_both url1 url2 =
  let* resp1 = Cohttp_lwt_unix.Client.get (Uri.of_string url1) in
  let* resp2 = Cohttp_lwt_unix.Client.get (Uri.of_string url2) in
  let* body1 = Cohttp_lwt.Body.to_string (snd resp1) in
  let* body2 = Cohttp_lwt.Body.to_string (snd resp2) in
  Lwt.return (body1, body2)

let () =
  Lwt_main.run (fetch_both "http://example.com" "http://ocaml.org")
```

Обратите внимание:
- `let*` — синтаксический сахар для `Lwt.bind`. Без него код превращается в callback hell.
- Операции выполняются **последовательно** — сначала `url1`, затем `url2`. Для параллельного выполнения нужен `Lwt.both`.
- Функции возвращают промисы (`'a Lwt.t`), которые нужно явно разворачивать через `let*`.

**Lwt (параллельный вариант):**

```ocaml
let fetch_both_parallel url1 url2 =
  let p1 = Cohttp_lwt_unix.Client.get (Uri.of_string url1) in
  let p2 = Cohttp_lwt_unix.Client.get (Uri.of_string url2) in
  let* (resp1, resp2) = Lwt.both p1 p2 in
  let* body1 = Cohttp_lwt.Body.to_string (snd resp1) in
  let* body2 = Cohttp_lwt.Body.to_string (snd resp2) in
  Lwt.return (body1, body2)
```

Параллелизм требует явного `Lwt.both` — забыли его использовать, и код становится последовательным.

**Eio (прямой стиль):**

```ocaml
let fetch_both ~net url1 url2 =
  Eio.Fiber.both
    (fun () ->
      let resp = http_get ~net url1 in
      resp)
    (fun () ->
      let resp = http_get ~net url2 in
      resp)

let () =
  Eio_main.run @@ fun env ->
  let net = Eio.Stdenv.net env in
  fetch_both ~net "http://example.com" "http://ocaml.org"
```

Преимущества:
- Нет `let*` — код выглядит как обычный императивный стиль.
- Параллелизм явный через `Fiber.both` — нельзя случайно сделать код последовательным.
- Структурированность: оба запроса завершатся до выхода из `Fiber.both`, даже если один упадёт с ошибкой.

```admonish info title="Подробнее"
Подробное описание конкурентного программирования в OCaml: [Real World OCaml, глава «Concurrent Programming with Async»](https://dev.realworldocaml.org/concurrent-programming.html). Хотя глава описывает библиотеку Async, базовые концепции (промисы, event loop, конкурентный I/O) применимы и к Eio.
```

## Проект: конкурентные вычисления

Модуль `lib/concurrent.ml` демонстрирует базовые паттерны конкурентности с Eio.

### Параллельный map

```ocaml
let parallel_map f lst =
  Eio.Fiber.List.map f lst
```

`Eio.Fiber.List.map` выполняет `f` для каждого элемента конкурентно (в отдельных файберах) и собирает результаты в том же порядке.

### Параллельная свёртка

```ocaml
let parallel_sum lst =
  let results = Eio.Fiber.List.map (fun x -> x) lst in
  List.fold_left ( + ) 0 results
```

Здесь `Fiber.List.map (fun x -> x) lst` — намеренно тривиальный пример: функция-идентичность показывает структуру паттерна, но в реальном коде на её месте стоит вычислительно тяжёлая операция (например, чтение из сети). После сбора результатов стандартный `fold_left` суммирует список последовательно.

## Buf_read и сетевое взаимодействие

До сих пор мы работали с файберами, каналами и таймаутами. Но Eio также предоставляет удобные средства для **буферизованного чтения** данных из потоков и **сетевого взаимодействия**.

### Buf_read — буферизованное чтение

`Eio.Buf_read` оборачивает поток (`flow`) в буфер и позволяет читать данные построчно, побайтово или по произвольным разделителям. Это аналог `Buffered_reader` в других языках:

```ocaml
let read_http_status flow =
  let buf = Eio.Buf_read.of_flow flow ~max_size:4096 in
  let status_line = Eio.Buf_read.line buf in
  status_line
```

`Eio.Buf_read.of_flow flow ~max_size:n` создаёт буферизованный читатель с ограничением буфера в `n` байт. `Eio.Buf_read.line buf` читает одну строку (до `\n`).

Основные функции `Buf_read`:

| Функция | Описание |
|---------|----------|
| `Eio.Buf_read.line buf` | Прочитать строку до `\n` |
| `Eio.Buf_read.take n buf` | Прочитать ровно `n` байт |
| `Eio.Buf_read.at_end_of_input buf` | Проверить, достигнут ли конец потока |
| `Eio.Buf_read.any_char buf` | Прочитать один символ |

### Custom-парсеры для бинарных протоколов

`Buf_read` позволяет создавать собственные комбинаторы для чтения бинарных данных. Например, целые числа разной ширины:

```ocaml
module R = struct
  include Eio.Buf_read
  let int8 = map (Fun.flip String.get_int8 0) (take 1)
  let int16_be = map (Fun.flip String.get_int16_be 0) (take 2)
end
```

Здесь `take n` читает `n` байт как строку, а `map f parser` применяет функцию `f` к результату парсера. `Fun.flip String.get_int8 0` переставляет аргументы функции `String.get_int8 s pos` так, чтобы передать `pos = 0` заранее и получить функцию `string -> int`. Такой подход удобен для реализации бинарных протоколов (например, чтение заголовков пакетов).

### Networking — сетевое взаимодействие

Eio предоставляет модуль `Eio.Net` для работы с TCP/UDP. Сетевой стек доступен через `Eio.Stdenv.net env`.

#### TCP-клиент

```ocaml
let tcp_client ~net ~host ~port =
  let addr = `Tcp (Eio.Net.Ipaddr.V4.loopback, port) in
  Eio.Net.connect net addr |> fun flow ->
  let buf = Eio.Buf_read.of_flow flow ~max_size:4096 in
  Eio.Flow.copy_string "GET / HTTP/1.0\r\n\r\n" flow;
  Eio.Buf_read.line buf
```

Разберём по шагам:

1. `Eio.Net.connect net addr` — устанавливает TCP-соединение и возвращает `flow`.
2. `Eio.Flow.copy_string ... flow` — отправляет данные в поток.
3. `Eio.Buf_read.of_flow flow` — оборачивает поток для буферизованного чтения.
4. `Eio.Buf_read.line buf` — читает строку ответа.

#### Адреса

Eio поддерживает несколько видов адресов:

- `` `Tcp (ip, port) `` — TCP-соединение.
- `Eio.Net.Ipaddr.V4.loopback` — `127.0.0.1`.
- `Eio.Net.Ipaddr.V6.loopback` — `::1`.

Обратите внимание: `net` передаётся как аргумент (dependency injection), что позволяет подставить мок-сеть в тестах.

#### TCP echo-сервер

Простой TCP-сервер, который отправляет обратно всё, что получает:

```ocaml
let echo_server ~net ~port =
  let addr = `Tcp (Eio.Net.Ipaddr.V4.any, port) in
  Eio.Net.listen net addr ~backlog:10 ~reuse_addr:true
    (fun flow _addr ->
      try
        let buf = Eio.Buf_read.of_flow flow ~max_size:4096 in
        while true do
          let line = Eio.Buf_read.line buf in
          Eio.Flow.copy_string (line ^ "\n") flow
        done
      with End_of_file ->
        traceln "Клиент отключился")
```

Разберём по шагам:

1. `Eio.Net.listen net addr ~backlog:10` — начать слушать входящие соединения на `addr`. `backlog` — размер очереди ожидающих подключений.
2. `reuse_addr:true` — позволяет перезапустить сервер сразу после остановки (без ожидания закрытия сокета ОС).
3. Для каждого подключения вызывается обработчик `(fun flow _addr -> ...)`. Каждый клиент обрабатывается в отдельном файбере автоматически.
4. `Eio.Buf_read.line buf` — читает строку до `\n`.
5. `Eio.Flow.copy_string (line ^ "\n") flow` — отправляет строку обратно клиенту.
6. `End_of_file` — клиент закрыл соединение.

**Запуск сервера:**

```ocaml
let () =
  Eio_main.run @@ fun env ->
  let net = Eio.Stdenv.net env in
  traceln "Сервер запущен на порту 8080";
  echo_server ~net ~port:8080
```

Сервер обрабатывает каждого клиента конкурентно: если приходит второй клиент, он не блокирует первого.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

Все упражнения этой главы выполняются внутри `Eio_main.run`. Тесты оборачивают ваши функции в Eio-окружение.

1. **(Среднее)** Реализуйте функцию `parallel_fib`, которая вычисляет N-й и M-й числа Фибоначчи параллельно, используя `Eio.Fiber.both`, и возвращает их сумму.

    ```ocaml
    val parallel_fib : int -> int -> int
    ```

    *Подсказка:* напишите обычную функцию `fib n` и используйте `Eio.Fiber.both` с `ref` для сбора результатов.

2. **(Среднее)** Реализуйте функцию `concurrent_map`, которая применяет функцию к каждому элементу списка конкурентно, используя `Eio.Fiber.List.map`.

    ```ocaml
    val concurrent_map : ('a -> 'b) -> 'a list -> 'b list
    ```

3. **(Среднее)** Реализуйте паттерн producer-consumer: функцию `produce_consume`, где producer отправляет числа от 1 до n в `Eio.Stream`, а consumer суммирует их.

    ```ocaml
    val produce_consume : int -> int
    ```

    *Подсказка:* используйте `Eio.Stream.create`, `Eio.Fiber.both`, `Some`/`None` как сигнал завершения.

4. **(Среднее)** Реализуйте функцию `race`, которая запускает список функций конкурентно и возвращает результат первой завершившейся.

    ```ocaml
    val race : (unit -> 'a) list -> 'a
    ```

    *Подсказка:* используйте `Eio.Fiber.any`.

5. **(Сложное)** Реализуйте функцию `uppercase_echo_server`, которая запускает TCP-сервер на заданном порту, читает строки от клиентов и отправляет их обратно в верхнем регистре.

    ```ocaml
    val uppercase_echo_server : net:Eio.Net.t -> port:int -> unit
    ```

    *Подсказка:* используйте `Eio.Net.listen`, `Eio.Buf_read.line`, `String.uppercase_ascii` и `Eio.Flow.copy_string`. Обрабатывайте `End_of_file` для корректного закрытия соединения.

## Заключение

В этой главе:

- **Домены** — единица параллелизма OCaml 5. Один домен на ядро процессора.
- **Eio** — прямой стиль: нет `let*`, нет `>>=`, нет `async/await`. Файберы переключаются автоматически при I/O.
- **Switch** — структурированная конкурентность. Все файберы завершаются до выхода из блока. Утечки горутин невозможны.
- **Eio.Stream** — потокобезопасная очередь для коммуникации между файберами. Паттерн producer-consumer без явных мьютексов.
- **Таймауты** реализуются через `Fiber.any` со `sleep`.
- Eio — настоящее конкурентности в OCaml. Lwt и Async остаются для обратной совместимости.

В следующей главе — обработчики эффектов: одна из ключевых новинок OCaml 5.
