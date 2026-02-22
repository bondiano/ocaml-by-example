(** Здесь вы можете писать свои решения упражнений. *)

(* ===== Lwt map операции ===== *)

(* Среднее *)
(** Упражнение 1: sequential_map — последовательное применение async функции.

    Применить async функцию к каждому элементу списка последовательно
    (один за другим, ожидая завершения каждого).

    Аналог: List.map, но для async функций

    Примеры:
    {[
      let fetch url =
        Lwt_unix.sleep 0.1 >>= fun () ->
        Lwt.return (url ^ "_data")
      in

      sequential_map fetch ["url1"; "url2"; "url3"]
        (* выполняет fetch для каждого URL по очереди *)
        (* возвращает: ["url1_data"; "url2_data"; "url3_data"] *)
    ]}

    Подсказки:
    1. Используйте Lwt.bind (>>=) для последовательности:
       {[
         let rec seq_map f = function
           | [] -> Lwt.return []
           | x :: xs ->
               f x >>= fun y ->
               seq_map f xs >>= fun ys ->
               Lwt.return (y :: ys)
       ]}
    2. Или используйте List.fold_left с Lwt.bind:
       {[
         List.fold_left (fun acc_lwt x ->
           acc_lwt >>= fun acc ->
           f x >>= fun y ->
           Lwt.return (y :: acc)
         ) (Lwt.return []) lst
         >>= fun reversed -> Lwt.return (List.rev reversed)
       ]}
    3. Или Lwt_list.map_s (если разрешено использовать)

    Связанные темы: Lwt, sequential execution, async map
    Время: ~15 минут *)
let sequential_map (f : 'a -> 'b Lwt.t) (lst : 'a list) : 'b list Lwt.t =
  ignore f; ignore lst;
  failwith "todo"

(* Среднее *)
(** Упражнение 2: concurrent_map — параллельное применение async функции.

    Применить async функцию к каждому элементу списка конкурентно
    (запустить все задачи одновременно).

    Аналог: Eio.Fiber.List.map для Lwt

    Примеры:
    {[
      let fetch url =
        Lwt_unix.sleep (Random.float 1.0) >>= fun () ->
        Lwt.return (url ^ "_data")
      in

      concurrent_map fetch ["url1"; "url2"; "url3"]
        (* запускает все fetch одновременно *)
        (* ждёт завершения всех *)
        (* возвращает результаты в том же порядке *)
    ]}

    Подсказки:
    1. List.map для создания списка промисов:
       {[
         let promises = List.map f lst in
       ]}
    2. Lwt.all для ожидания всех промисов:
       {[
         Lwt.all promises
       ]}
    3. Или Lwt.join если не нужен порядок
    4. Lwt.all сохраняет порядок результатов

    Связанные темы: Lwt, concurrent execution, parallel map
    Время: ~12 минут *)
let concurrent_map (f : 'a -> 'b Lwt.t) (lst : 'a list) : 'b list Lwt.t =
  ignore f; ignore lst;
  failwith "todo"

(* ===== Управление выполнением ===== *)

(* Среднее *)
(** Упражнение 3: timeout — ограничение времени выполнения.

    Обернуть промис с таймаутом. Если промис не завершится за заданное время,
    вернуть None. Иначе вернуть Some результата.

    Примеры:
    {[
      let slow_task = Lwt_unix.sleep 5.0 >>= fun () -> Lwt.return 42 in

      timeout 1.0 slow_task  (* вернёт None через 1 секунду *)

      let fast_task = Lwt_unix.sleep 0.1 >>= fun () -> Lwt.return 42 in

      timeout 1.0 fast_task  (* вернёт Some 42 *)
    ]}

    Подсказки:
    1. Lwt.pick для гонки двух промисов:
       {[
         Lwt.pick [promise1; promise2]
       ]}
    2. Создать таймаут промис:
       {[
         let timeout_promise =
           Lwt_unix.sleep seconds >>= fun () -> Lwt.return None
       ]}
    3. Обернуть основной промис:
       {[
         let wrapped_promise =
           promise >>= fun result -> Lwt.return (Some result)
       ]}
    4. Lwt.pick [wrapped_promise; timeout_promise]
    5. Lwt.pick возвращает результат первого завершившегося промиса

    Связанные темы: Timeout, Lwt.pick, racing promises
    Время: ~15 минут *)
let timeout (seconds : float) (promise : 'a Lwt.t) : 'a option Lwt.t =
  ignore seconds; ignore promise;
  failwith "todo"

(* ===== Продвинутое управление ===== *)

(* Сложное *)
(** Упражнение 4: rate_limit — ограничение количества параллельных задач.

    Выполнить список задач, но не более n задач одновременно.

    Как работает:
    - Запускать не более n задач одновременно
    - Когда задача завершается, запускать следующую из очереди
    - Вернуть результаты всех задач в порядке

    Примеры:
    {[
      let tasks = [
        (fun () -> Lwt_unix.sleep 1.0 >>= fun () -> Lwt.return 1);
        (fun () -> Lwt_unix.sleep 1.0 >>= fun () -> Lwt.return 2);
        (fun () -> Lwt_unix.sleep 1.0 >>= fun () -> Lwt.return 3);
        (fun () -> Lwt_unix.sleep 1.0 >>= fun () -> Lwt.return 4);
      ]

      rate_limit 2 tasks
        (* Запускает первые 2 задачи *)
        (* Когда одна завершается, запускает следующую *)
        (* Не более 2 задач одновременно *)
        (* Возвращает [1; 2; 3; 4] *)
    ]}

    Подсказки:
    1. Используйте Lwt_pool для ограничения параллелизма:
       {[
         let pool = Lwt_pool.create n (fun () -> Lwt.return_unit) in
         Lwt_list.map_p (fun task ->
           Lwt_pool.use pool (fun () -> task ())
         ) tasks
       ]}
    2. Или реализуйте вручную через семафор:
       {[
         let semaphore = Lwt_mutex.create () in
         let active = ref 0 in
         (* логика управления активными задачами *)
       ]}
    3. Или через рекурсию с аккумулятором:
       - Поддерживать список активных задач (не более n)
       - Когда задача завершается, запускать следующую
    4. Lwt.choose для ожидания любой из активных задач
    5. Сохранить порядок результатов

    Связанные темы: Concurrency control, semaphore, task queue
    Время: ~30 минут *)
let rate_limit (n : int) (tasks : (unit -> 'a Lwt.t) list) : 'a list Lwt.t =
  ignore n; ignore tasks;
  failwith "todo"
