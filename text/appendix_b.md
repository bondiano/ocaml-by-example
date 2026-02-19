# Промисы и Lwt

## Цели главы

В этой главе мы изучим **Lwt** --- библиотеку конкурентности на основе промисов, и сравним её с Eio из главы 12:

- **Промисы** (`'a Lwt.t`) --- отложенные вычисления, которые завершатся в будущем.
- **Монадический стиль** --- `bind`, `>>=`, `let*` для цепочек асинхронных операций.
- **Конкурентные примитивы** --- `Lwt.both`, `Lwt.all`, `Lwt.pick`, `Lwt.choose`.
- **Lwt_io и Lwt_unix** --- асинхронный ввод-вывод и системные вызовы.
- **Lwt_stream** --- асинхронные потоки данных.
- **Сравнение Eio и Lwt** --- когда использовать какую библиотеку.

## Подготовка проекта

Код этой главы находится в `exercises/appendix_b`. Для работы с Lwt нужно установить библиотеку:

```text
$ opam install lwt
$ cd exercises/appendix_b
$ dune build
```

В файле `dune` проекта укажите зависимости:

```text
(library
 (name chapter19)
 (libraries lwt lwt.unix))
```

Пакет `lwt.unix` предоставляет привязки к системным вызовам: работу с файлами, сетью, таймерами и процессами.

## Зачем Lwt, если есть Eio?

В главе 12 мы изучили Eio --- библиотеку прямого стиля, основанную на effect handlers OCaml 5. Eio лучше спроектирована, но зачем тогда изучать Lwt?

Ответ --- **экосистема**. Lwt существует с 2008 года и стала основой огромного количества OCaml-проектов:

- **Dream** --- самый популярный веб-фреймворк OCaml.
- **Cohttp** --- HTTP-библиотека.
- **Irmin** --- распределённая база данных (Git-like).
- **Tezos** --- блокчейн-платформа.

Eio --- будущее конкурентности в OCaml, но Lwt --- настоящее экосистемы. Чтобы использовать Dream или Cohttp, нужно понимать Lwt.

```admonish tip title="Для Python/TS-разработчиков"
Lwt --- это аналог `asyncio` в Python или `Promise` в TypeScript/JavaScript. Тип `'a Lwt.t` --- это промис, как `Promise<T>` в TypeScript. Операция `let*` (bind) --- аналог `await`. Но есть важное отличие: в Python/TypeScript `async/await` --- специальный синтаксис, встроенный в язык. В OCaml Lwt --- это обычная библиотека, а `let*` --- пользовательский оператор (binding operator). Это значит, что вы можете создать свою «версию async» без изменения языка.
```

## Промисы: отложенные вычисления

Центральный тип Lwt --- `'a Lwt.t`. Это **промис**: значение типа `'a`, которое, возможно, ещё не вычислено. Промис может быть в одном из трёх состояний: **resolved** (готов), **pending** (ожидает) или **rejected** (ошибка).

### Создание промисов

```ocaml
(* Lwt.return : 'a -> 'a Lwt.t --- уже завершённый промис *)
let x : int Lwt.t = Lwt.return 42

(* Lwt.fail : exn -> 'a Lwt.t --- промис с ошибкой *)
let err : int Lwt.t = Lwt.fail (Failure "что-то пошло не так")
```

### Привязка: `Lwt.bind` и `>>=`

```ocaml
(* Lwt.bind : 'a Lwt.t -> ('a -> 'b Lwt.t) -> 'b Lwt.t *)
let y : string Lwt.t =
  Lwt.bind x (fun n -> Lwt.return (string_of_int n))
```

`Lwt.bind p f` --- когда промис `p` завершится со значением `v`, вызвать `f v`. Если `p` завершился ошибкой --- `f` не вызывается, ошибка пробрасывается дальше.

Оператор `>>=` --- инфиксный синоним `Lwt.bind`:

```ocaml
open Lwt.Infix

let z : int Lwt.t = x >>= fun n -> Lwt.return (n + 1)

(* Цепочка вычислений *)
let pipeline =
  Lwt.return "42"
  >>= fun s -> Lwt.return (int_of_string s)
  >>= fun n -> Lwt.return (n * 2)
  >>= fun n -> Lwt.return (string_of_int n)
(* pipeline : string Lwt.t, результат --- "84" *)
```

### Отображение: `Lwt.map` и `>|=`

```ocaml
(* Lwt.map : ('a -> 'b) -> 'a Lwt.t -> 'b Lwt.t *)
let w : string Lwt.t = Lwt.map string_of_int x

(* >|= --- инфиксный map *)
let w2 = x >|= fun n -> string_of_int n
let doubled = x >|= fun n -> n * 2
```

Разница: в `>>=` функция возвращает `'b Lwt.t`, а в `>|=` --- просто `'b`. Используйте `>|=` для чистых преобразований.

## Let-операторы

Цепочки `>>=` быстро становятся нечитаемыми. **Let-операторы**, знакомые из главы 8, делают код линейным:

```ocaml
open Lwt.Syntax

(* let* = Lwt.bind *)
let example1 () =
  let* a = Lwt.return 10 in
  let* b = Lwt.return 20 in
  Lwt.return (a + b)

(* let+ = Lwt.map --- для последнего шага *)
let example2 () =
  let+ n = Lwt.return 42 in
  n * 2
(* example2 () : int Lwt.t, результат --- 84 *)

(* and* = Lwt.both --- конкурентное выполнение *)
let example3 () =
  let* a = Lwt.return 10
  and* b = Lwt.return 20 in
  Lwt.return (a + b)
```

Обратите внимание на `and*`: в отличие от последовательного `let*`, конструкция `let* ... and* ...` запускает оба вычисления **конкурентно**.

Let-операторы --- рекомендуемый современный стиль. Они делают код похожим на обычный последовательный, что упрощает чтение и отладку.

```admonish tip title="Для Python/TS-разработчиков"
`let*` в Lwt --- это прямой аналог `await` в Python/TypeScript. Сравните:
- **TypeScript:** `const data = await fetch(url);`
- **Python:** `data = await fetch(url)`
- **OCaml Lwt:** `let* data = fetch url in`

А `Lwt.both` --- аналог `Promise.all([p1, p2])` в TypeScript или `asyncio.gather(t1, t2)` в Python. `Lwt.pick` --- аналог `Promise.race()`. Концепции идентичны, различается только синтаксис.
```

## Запуск Lwt

Для выполнения промисов нужен **event loop**. Функция `Lwt_main.run` запускает его и блокируется до завершения:

```ocaml
let () =
  Lwt_main.run (
    let open Lwt.Syntax in
    let* () = Lwt_io.printl "Привет из Lwt!" in
    let* () = Lwt_io.printl "Event loop запущен." in
    Lwt.return ()
  )
```

`Lwt_main.run` вызывается ровно один раз, на верхнем уровне программы. В отличие от Eio, где `Eio_main.run` передаёт окружение `env`, в Lwt модули `Lwt_io` и `Lwt_unix` доступны глобально --- удобнее для старта, но хуже для тестирования.

## Конкурентные примитивы

### `Lwt.both`

Запустить два промиса конкурентно и дождаться обоих:

```ocaml
let* (a, b) = Lwt.both
  (Lwt_unix.sleep 1.0 >|= fun () -> "результат A")
  (Lwt_unix.sleep 1.5 >|= fun () -> "результат B")
(* Общее время --- ~1.5 секунды, а не 2.5 *)
```

### `Lwt.all`

Запустить список промисов конкурентно и дождаться всех:

```ocaml
let* results = Lwt.all [task1; task2; task3]
(* results : 'a list --- в том же порядке *)
```

### `Lwt.pick`

Вернуть результат первого завершившегося и **отменить** остальные:

```ocaml
let with_timeout seconds task =
  Lwt.pick [
    (task >|= fun r -> Some r);
    (Lwt_unix.sleep seconds >|= fun () -> None);
  ]
```

Отменённые промисы получают исключение `Lwt.Canceled`.

### `Lwt.choose`

Как `Lwt.pick`, но **не отменяет** остальные промисы. Используйте, когда побочные эффекты остальных важны.

### Сводная таблица

| Функция | Ожидает | Отмена остальных |
|---------|---------|------------------|
| `Lwt.both` | Оба | Нет |
| `Lwt.all` | Все | Нет |
| `Lwt.pick` | Первый | Да |
| `Lwt.choose` | Первый | Нет |

## Lwt_io

Модуль `Lwt_io` предоставляет асинхронный буферизированный ввод-вывод:

```ocaml
open Lwt.Syntax

(* Вывод *)
let* () = Lwt_io.printl "с переводом строки" in
let* () = Lwt_io.printlf "форматированный: %d + %d = %d" 2 3 5 in

(* Ввод *)
let* line = Lwt_io.read_line Lwt_io.stdin in
Lwt_io.printlf "Вы ввели: %s" line
```

### Работа с файлами

```ocaml
(* Чтение файла целиком *)
let read_file path =
  Lwt_io.with_file ~mode:Input path (fun ic -> Lwt_io.read ic)

(* Запись в файл *)
let write_file path content =
  Lwt_io.with_file ~mode:Output path (fun oc -> Lwt_io.write oc content)

(* Построчное чтение *)
let read_lines path =
  Lwt_io.with_file ~mode:Input path (fun ic ->
    let rec loop acc =
      Lwt.catch
        (fun () ->
          let* line = Lwt_io.read_line ic in
          loop (line :: acc))
        (function
          | End_of_file -> Lwt.return (List.rev acc)
          | exn -> Lwt.fail exn)
    in
    loop []
  )
```

`Lwt_io.with_file` автоматически закрывает файл после завершения, даже при ошибках.

## Lwt_unix

Модуль `Lwt_unix` предоставляет асинхронные обёртки над системными вызовами:

```ocaml
(* Таймер --- уступает управление event loop *)
let* () = Lwt_unix.sleep 1.0 in
Lwt_io.printl "Прошла секунда!"

(* Запуск внешней команды *)
let* status = Lwt_unix.system "echo hello" in
match status with
| Unix.WEXITED 0 -> Lwt.return_ok ()
| Unix.WEXITED n -> Lwt.return_error (Printf.sprintf "exit code: %d" n)
| _ -> Lwt.return_error "сигнал"
```

**Важно:** `Unix.sleep` блокирует весь поток (и event loop), а `Lwt_unix.sleep` уступает управление, позволяя другим промисам выполняться. Никогда не используйте блокирующие вызовы внутри Lwt.

## Lwt_stream

`Lwt_stream` --- асинхронные потоки данных с поддержкой конкурентности:

```ocaml
(* Создание из push-функции *)
let stream, push = Lwt_stream.create ()
(* push : 'a option -> unit *)
(* Some x --- отправить значение, None --- закрыть поток *)

let () =
  push (Some 1);
  push (Some 2);
  push (Some 3);
  push None
```

### Потребление и преобразование

```ocaml
open Lwt.Syntax

let* items = Lwt_stream.to_list stream        (* все элементы *)
let* sum = Lwt_stream.fold ( + ) stream 0     (* свёртка *)
let* () = Lwt_stream.iter_s                    (* итерация с Lwt *)
  (fun x -> Lwt_io.printlf "Элемент: %d" x) stream

(* Преобразование *)
let doubled = Lwt_stream.map (fun x -> x * 2) stream
let evens = Lwt_stream.filter (fun x -> x mod 2 = 0) stream
```

### Паттерн Producer-Consumer

```ocaml
let producer_consumer () =
  let open Lwt.Syntax in
  let stream, push = Lwt_stream.create () in
  let producer =
    let* () = Lwt_list.iter_s (fun i ->
      let* () = Lwt_unix.sleep 0.1 in
      push (Some i); Lwt.return ()
    ) [1; 2; 3; 4; 5] in
    push None; Lwt.return ()
  in
  let consumer = Lwt_stream.fold ( + ) stream 0 in
  let* ((), sum) = Lwt.both producer consumer in
  Lwt_io.printlf "Сумма: %d" sum
```

## Сравнение Eio и Lwt

### Таблица различий

| Аспект | Eio | Lwt |
|--------|-----|-----|
| Стиль | Прямой (direct-style) | Монадический (promise) |
| Синтаксис | Обычный OCaml-код | `let*`, `>>=`, `>|=` |
| Конкурентность | `Fiber.both`, `Fiber.all` | `Lwt.both`, `Lwt.all` |
| Отмена | Структурированная (Switch) | `Lwt.cancel` (неструктурированная) |
| Параллелизм | Домены (многоядерность) | Нет (один поток) |
| Производительность | Выше (без аллокаций промисов) | Ниже (каждая операция аллоцирует) |
| Экосистема | Растущая | Зрелая (Dream, Cohttp, Irmin) |

### Код бок о бок

Конкурентное чтение двух файлов:

```ocaml
(* === Eio === *)
let read_both_eio env =
  let fs = Eio.Stdenv.fs env in
  let (a, b) = Eio.Fiber.pair
    (fun () -> Eio.Path.(load (fs / "a.txt")))
    (fun () -> Eio.Path.(load (fs / "b.txt")))
  in
  a ^ "\n" ^ b

(* === Lwt === *)
let read_both_lwt () =
  let open Lwt.Syntax in
  let read p = Lwt_io.with_file ~mode:Input p Lwt_io.read in
  let* (a, b) = Lwt.both (read "a.txt") (read "b.txt") in
  Lwt.return (a ^ "\n" ^ b)
```

В Eio код выглядит как обычный синхронный, а в Lwt каждая операция обёрнута в промис.

### Когда что выбирать

Используйте **Lwt**, когда работаете с Dream, Cohttp или существующей Lwt-кодовой базой, либо нужна поддержка OCaml < 5.

Используйте **Eio**, когда начинаете новый проект на OCaml 5+, нужен параллелизм или структурированная конкурентность.

Библиотека `lwt_eio` позволяет запускать Lwt-промисы внутри Eio и наоборот, упрощая постепенную миграцию.

```admonish info title="Real World OCaml"
Подробнее о конкурентном программировании в OCaml --- в главе [Concurrent Programming with Async](https://dev.realworldocaml.org/concurrent-programming.html) книги Real World OCaml. Там рассматривается Async (библиотека Jane Street), которая концептуально похожа на Lwt, но с другим API.
```

## Проект: конкурентный обработчик

Модуль `lib/concurrent_processor.ml` демонстрирует конкурентную обработку задач с ограничением параллелизма:

```ocaml
let process_with_limit ~max_concurrent tasks =
  let open Lwt.Syntax in
  let sem = Lwt_mutex.create () in
  let count = ref 0 in
  let wait_slot () =
    let rec try_acquire () =
      if !count < max_concurrent then begin
        incr count; Lwt.return ()
      end else
        Lwt.pause () >>= fun () -> try_acquire ()
    in
    Lwt_mutex.with_lock sem try_acquire
  in
  let release_slot () =
    Lwt_mutex.with_lock sem (fun () -> decr count; Lwt.return ())
  in
  Lwt_list.map_p (fun task ->
    let* () = wait_slot () in
    Lwt.finalize (fun () -> task ()) release_slot
  ) tasks
```

Этот паттерн используется для ограничения числа одновременных HTTP-запросов, обращений к базе данных или файловых операций.

## Продвинутые паттерны Lwt

Рассмотрим несколько продвинутых паттернов, которые часто встречаются в реальных Lwt-приложениях.

### `Lwt_switch` --- управление ресурсами

`Lwt_switch` предоставляет RAII-подобный механизм для автоматического освобождения ресурсов при выходе из scope:

```ocaml
let with_resource () =
  Lwt_switch.with_switch @@ fun switch ->
  let* conn = connect ~switch uri in
  (* conn автоматически закрывается при выходе из scope *)
  use conn
```

При создании ресурса (соединения, файла, подписки) вы регистрируете его в `switch`. Когда `Lwt_switch.with_switch` завершается (нормально или с ошибкой), все зарегистрированные ресурсы освобождаются в обратном порядке.

### TCP client/server

Lwt предоставляет модуль `Lwt_io` для работы с TCP-соединениями. Вот пример TCP-клиента:

```ocaml
(* TCP-клиент *)
let tcp_client host port =
  let open Lwt.Syntax in
  let addr = Unix.(ADDR_INET (inet_addr_of_string host, port)) in
  Lwt_io.with_connection addr (fun (ic, oc) ->
    let* () = Lwt_io.write_line oc "Hello" in
    Lwt_io.read_line ic)
```

`Lwt_io.with_connection` устанавливает TCP-соединение и передаёт пару каналов `(ic, oc)` --- input channel и output channel. Соединение автоматически закрывается при выходе.

### Timeout через `Lwt.pick` (race pattern)

Распространённый паттерн --- ограничение времени выполнения операции:

```ocaml
let with_timeout seconds task =
  Lwt.pick [
    task;
    (let* () = Lwt_unix.sleep seconds in
     Lwt.fail_with "timeout");
  ]
```

`Lwt.pick` запускает оба промиса конкурентно. Если `task` завершается первой --- возвращает её результат. Если первым завершается таймер --- бросает исключение `Failure "timeout"`, а `task` отменяется.

### Never-promise

Промис, который никогда не разрешится:

```ocaml
let never : _ Lwt.t = fst (Lwt.wait ())
(* Полезно для серверов: Lwt_main.run never *)
```

`Lwt.wait ()` возвращает пару `(promise, resolver)`. Если не использовать `resolver`, промис остаётся в состоянии `pending` навсегда. Это полезно для серверов, которые должны работать бесконечно: `Lwt_main.run never` запускает event loop и никогда не возвращается.

### Direct-style (Lwt 6+ с OCaml 5)

С появлением OCaml 5 и effect handlers, Lwt движется к прямому стилю. В экспериментальных версиях Lwt 6 появляется поддержка `spawn`/`await`:

```ocaml
(* Будущее Lwt: direct-style через spawn/await *)
(* spawn @@ fun () ->
     let line = await @@ Lwt_io.read_line Lwt_io.stdin in
     await @@ Lwt_io.write_line Lwt_io.stdout line *)
```

Пока что это экспериментальная фича в Lwt 6. Для нового кода без привязки к Lwt-экосистеме лучше использовать Eio (глава 12). Но для постепенной миграции существующих Lwt-проектов direct-style API может стать мостом между двумя мирами.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

Все упражнения работают внутри `Lwt_main.run`. Тесты оборачивают ваши функции в Lwt-окружение.

1. **(Лёгкое)** Реализуйте функцию `sequential_map`, которая применяет асинхронную функцию к каждому элементу списка **последовательно** и возвращает список результатов.

    ```ocaml
    val sequential_map : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t
    ```

    *Подсказка:* используйте `List.fold_left` с `Lwt.bind`, накапливая результаты в обратном порядке, а затем `List.rev`.

2. **(Среднее)** Реализуйте функцию `concurrent_map`, которая применяет асинхронную функцию к каждому элементу списка **конкурентно** и возвращает список результатов в том же порядке.

    ```ocaml
    val concurrent_map : ('a -> 'b Lwt.t) -> 'a list -> 'b list Lwt.t
    ```

    *Подсказка:* используйте `List.map` для создания списка промисов, а затем `Lwt.all`.

3. **(Среднее)** Реализуйте функцию `timeout`, которая оборачивает промис таймаутом. Если промис не завершается за указанное время --- возвращает `None`.

    ```ocaml
    val timeout : float -> 'a Lwt.t -> 'a option Lwt.t
    ```

    *Подсказка:* используйте `Lwt.pick` с двумя промисами --- основным и таймером.

4. **(Сложное)** Реализуйте функцию `rate_limit`, которая запускает список асинхронных задач, но не более `n` одновременно. Когда одна задача завершается --- запускается следующая.

    ```ocaml
    val rate_limit : int -> (unit -> 'a Lwt.t) list -> 'a list Lwt.t
    ```

    *Подсказка:* реализуйте семафор через `Lwt_mutex` и счётчик. Запустите все задачи через `Lwt_list.map_p`, но каждая ожидает свободного слота перед выполнением.

## Заключение

В этой главе мы:

- Изучили промисы `'a Lwt.t` --- основу конкурентности в Lwt.
- Освоили монадический стиль: `>>=`, `>|=`, `let*`, `let+`, `and*`.
- Познакомились с конкурентными примитивами: `Lwt.both`, `Lwt.all`, `Lwt.pick`, `Lwt.choose`.
- Научились работать с асинхронным I/O через `Lwt_io`, `Lwt_unix` и `Lwt_stream`.
- Детально сравнили Eio и Lwt --- их сильные стороны и области применения.

Lwt --- зрелая и проверенная библиотека, на которой построена значительная часть OCaml-экосистемы. Понимание Lwt открывает доступ к Dream, Cohttp и десяткам других библиотек.

Веб-разработка с Dream рассматривается в главе 18. Dream построен поверх Lwt, поэтому знание этого приложения поможет вам при работе с Dream.
