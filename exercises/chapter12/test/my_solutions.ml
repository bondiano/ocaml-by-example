(** Здесь вы можете писать свои решения упражнений. *)

(* ===== Основы Eio ===== *)

(* Лёгкое *)
(** Упражнение 1: parallel_fib — параллельное вычисление чисел Фибоначчи.

    Вычислить два числа Фибоначчи параллельно и вернуть их сумму.

    Используйте Eio.Fiber.both для параллельного запуска двух вычислений.

    Примеры:
    {[
      parallel_fib 10 15 = fib(10) + fib(15)
      (* Вычисления выполняются параллельно *)
    ]}

    Подсказки:
    1. Напишите функцию fib: int -> int (рекурсивная)
    2. Eio.Fiber.both (fun () -> fib n) (fun () -> fib m)
    3. Eio.Fiber.both возвращает пару: (a, b)
    4. Сложите результаты: a + b

    Связанные темы: Eio.Fiber, parallel computation, structured concurrency
    Время: ~8 минут *)
let parallel_fib (_n : int) (_m : int) : int =
  failwith "todo"

(* ===== Конкурентные операции над коллекциями ===== *)

(* Среднее *)
(** Упражнение 2: concurrent_map — конкурентное применение функции к списку.

    Применить функцию к каждому элементу списка конкурентно.

    Используйте Eio.Fiber.List.map или создайте fiber для каждого элемента.

    Примеры:
    {[
      concurrent_map (fun x -> x * 2) [1; 2; 3] = [2; 4; 6]
      (* Каждое применение выполняется в отдельном fiber *)
    ]}

    Подсказки:
    1. Используйте Eio.Fiber.List.map f lst
    2. Eio.Fiber.List.map автоматически создаёт fiber для каждого элемента
    3. Результаты собираются в том же порядке

    Альтернативный подход (ручной):
    1. List.map (fun x -> fun () -> f x) lst — создать thunks
    2. List.map (Eio.Fiber.fork ...) — запустить все fibers
    3. List.map Eio.Fiber.await — собрать результаты

    Связанные темы: Concurrent map, fibers, parallel processing
    Время: ~15 минут *)
let concurrent_map : ('a -> 'b) -> 'a list -> 'b list =
  fun _f _lst -> failwith "todo"

(* ===== Producer-Consumer ===== *)

(* Среднее *)
(** Упражнение 3: produce_consume — producer-consumer с суммированием.

    Создать producer, который производит числа от 1 до n,
    и consumer, который их суммирует.

    Используйте Eio.Stream для передачи данных между fibers.

    Алгоритм:
    1. Producer: добавить числа 1..n в stream, затем закрыть
    2. Consumer: читать из stream и накапливать сумму
    3. Запустить оба fiber параллельно с Eio.Fiber.both

    Примеры:
    {[
      produce_consume 10 = 55  (* 1+2+3+...+10 *)
      produce_consume 5 = 15   (* 1+2+3+4+5 *)
    ]}

    Подсказки:
    1. Eio.Stream.create buffer_size для создания stream
    2. Eio.Stream.add stream value — добавить в stream
    3. Eio.Stream.take stream — прочитать (блокируется если пусто)
    4. Eio.Stream.close stream — закрыть (take вернёт исключение End_of_stream)
    5. Producer: for i = 1 to n do Eio.Stream.add stream i done
    6. Consumer: try/with End_of_stream для завершения
    7. Eio.Fiber.both для запуска обоих

    Связанные темы: Producer-consumer, Eio.Stream, communication patterns
    Время: ~20 минут *)
let produce_consume (_n : int) : int =
  failwith "todo"

(* ===== Гонка и таймауты ===== *)

(* Среднее *)
(** Упражнение 4: race — результат первой завершившейся задачи.

    Запустить все задачи параллельно и вернуть результат первой завершившейся.
    Остальные задачи отменяются автоматически.

    Используйте Eio.Fiber.first для выбора первого результата.

    Примеры:
    {[
      race [
        (fun () -> Unix.sleep 2; "slow");
        (fun () -> "fast");
        (fun () -> Unix.sleep 1; "medium")
      ] = "fast"
    ]}

    Подсказки:
    1. Eio.Fiber.first для гонки двух задач
    2. Для списка задач: List.fold_left
    3. Или используйте Eio.Fiber.any (если доступно)
    4. Pattern:
       match tasks with
       | [] -> failwith "no tasks"
       | t :: ts -> List.fold_left (fun acc task ->
           fun () -> Eio.Fiber.first acc task) t ts

    Связанные темы: Racing, cancellation, timeouts
    Время: ~12 минут *)
let race (_tasks : (unit -> 'a) list) : 'a =
  failwith "todo"

(* ===== Сетевое программирование ===== *)

(* Сложное *)
(** Упражнение 5: uppercase_echo_server — TCP echo сервер.

    Создать TCP сервер, который:
    1. Принимает подключения на заданном порту
    2. Читает строки от клиента
    3. Преобразует в uppercase
    4. Отправляет обратно клиенту

    Сервер должен обрабатывать множественные подключения конкурентно.

    Структура:
    {[
      let uppercase_echo_server ~net ~port =
        Eio.Switch.run @@ fun sw ->
        let socket = Eio.Net.listen net ~sw ~reuse_addr:true
          ~backlog:5 (`Tcp (Eio.Net.Ipaddr.V4.loopback, port)) in
        Eio.Net.run_server socket (fun flow _addr ->
          (* обработка клиента *)
        )
    ]}

    Обработка клиента:
    1. Читать строки из flow (Eio.Buf_read.of_flow)
    2. Преобразовать в uppercase: String.uppercase_ascii
    3. Записать обратно (Eio.Buf_write.with_flow)
    4. Закрыть соединение

    Подсказки:
    1. Eio.Net.listen для создания серверного сокета
    2. Eio.Net.run_server запускает обработчик для каждого клиента
    3. Каждый клиент обрабатывается в отдельном fiber
    4. Eio.Buf_read.lines для чтения строк
    5. Eio.Buf_write.string для записи
    6. Обработка исключений для отключения клиента

    Связанные темы: TCP servers, concurrent connections, Eio.Net
    Время: ~35 минут *)
let uppercase_echo_server ~net ~port : unit =
  ignore (net, port);
  failwith "todo"

(* ===== Rate limiting ===== *)

(* Среднее *)
(** Упражнение 6: rate_limit — ограничение частоты вызовов.

    Применить функцию к каждому элементу списка с задержкой между вызовами.

    Параметры:
    - clock: Eio.Stdenv.clock для доступа к времени
    - f: функция для применения
    - items: список элементов
    - delay: задержка в секундах между вызовами

    Примеры:
    {[
      rate_limit ~clock (fun x -> x * 2) [1; 2; 3] 0.5
      (* Вызывает f 1, ждёт 0.5 сек, f 2, ждёт 0.5 сек, f 3 *)
      (* Возвращает [2; 4; 6] *)
    ]}

    Подсказки:
    1. List.map с Eio.Time.sleep между итерациями
    2. Не нужно ждать после последнего элемента
    3. Pattern:
       List.mapi (fun i x ->
         if i > 0 then Eio.Time.sleep clock delay;
         f x
       ) items

    Связанные темы: Rate limiting, Eio.Time, throttling
    Время: ~15 минут *)
let rate_limit ~clock _f _items _delay =
  ignore clock;
  failwith "todo"

(* ===== Worker Pools ===== *)

(* Сложное *)
(** Упражнение 7: worker_pool — пул воркеров фиксированного размера.

    Создать пул из n_workers воркеров для обработки списка задач.

    Алгоритм:
    1. Создать Eio.Stream для задач
    2. Запустить n_workers воркеров, каждый:
       - Читает задачи из stream
       - Выполняет их
       - Добавляет результаты в другой stream
    3. Producer добавляет все задачи в stream
    4. Собрать результаты

    Структура:
    {[
      let worker_pool n_workers tasks =
        Eio.Switch.run @@ fun sw ->
        let task_stream = Eio.Stream.create n_workers in
        let result_stream = Eio.Stream.create n_workers in

        (* Запустить воркеры *)
        for _ = 1 to n_workers do
          Eio.Fiber.fork ~sw (fun () ->
            (* воркер читает из task_stream и пишет в result_stream *)
          )
        done;

        (* Producer *)
        List.iter (fun task -> Eio.Stream.add task_stream task) tasks;
        Eio.Stream.close task_stream;

        (* Собрать результаты *)
        ...
    ]}

    Примеры:
    {[
      worker_pool 3 [
        (fun () -> 1 + 1);
        (fun () -> 2 + 2);
        (fun () -> 3 + 3)
      ] = [2; 4; 6]
      (* 3 воркера обрабатывают задачи параллельно *)
    ]}

    Подсказки:
    1. Eio.Stream для очереди задач и результатов
    2. Eio.Fiber.fork для запуска воркеров
    3. Воркер: while true с Eio.Stream.take
    4. Обработка End_of_stream для завершения воркера
    5. Счётчик для отслеживания завершённых задач

    Связанные темы: Worker pools, task queues, load balancing
    Время: ~30 минут *)
let worker_pool _n_workers _tasks =
  failwith "todo"

(* ===== Параллельная обработка ===== *)

(* Среднее *)
(** Упражнение 8: parallel_process — параллельная обработка файлов.

    Применить функцию к списку строк (имитация файлов) конкурентно
    и вернуть сумму результатов.

    Параметры:
    - f: функция обработки string -> int
    - files: список строк (имён файлов)

    Примеры:
    {[
      parallel_process String.length ["hello"; "world"; "ocaml"]
        = 5 + 5 + 5 = 15
    ]}

    Подсказки:
    1. Используйте Eio.Fiber.List.map для параллельной обработки
    2. List.fold_left (+) 0 для суммирования
    3. Или используйте конкурентный fold

    Связанные темы: Parallel map-reduce, aggregation
    Время: ~12 минут *)
let parallel_process _f _files =
  failwith "todo"
