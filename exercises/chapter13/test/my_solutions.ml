(** Здесь вы можете писать свои решения упражнений. *)

(* ===== Базовые эффекты ===== *)

(* Среднее *)
(** Упражнение 1: run_emit — эффект для испускания значений.

    Реализовать эффект Emit, который позволяет "испускать" значения
    во время вычисления и собирать их в список.

    Эффект:
    {[
      type _ Effect.t += Emit : int -> unit Effect.t
    ]}

    Использование:
    {[
      let computation () =
        Effect.perform (Emit 1);
        Effect.perform (Emit 2);
        Effect.perform (Emit 3);
        42

      run_emit computation = (42, [1; 2; 3])
    ]}

    Обработчик должен:
    1. Перехватывать Emit и накапливать значения в список
    2. Продолжать вычисление после каждого Emit
    3. Вернуть итоговое значение и список испущенных значений

    Подсказки:
    1. Используйте Effect.Deep.match_with
    2. Структура обработчика:
       {[
         Effect.Deep.match_with f ()
         {
           retc = (fun v -> (v, []));
           exnc = raise;
           effc = (fun (type a) (eff : a Effect.t) ->
             match eff with
             | Emit n -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
                 let (result, emitted) = Effect.Deep.continue k () in
                 (result, n :: emitted))
             | _ -> None
           )
         }
       ]}
    3. retc — обработка возвращаемого значения
    4. effc — обработка эффектов
    5. Effect.Deep.continue k v — продолжить с значением v

    Связанные темы: Effect handlers, continuations, state accumulation
    Время: ~18 минут *)
type _ Effect.t += Emit : int -> unit Effect.t

let run_emit (f : unit -> 'a) : 'a * int list =
  ignore f;
  failwith "todo"

(* ===== Reader эффект ===== *)

(* Среднее *)
(** Упражнение 2: run_reader — эффект для чтения из окружения.

    Реализовать эффект Ask, который позволяет читать значение из окружения.

    Эффект:
    {[
      type _ Effect.t += Ask : string Effect.t
    ]}

    Использование:
    {[
      let computation () =
        let name = Effect.perform Ask in
        "Hello, " ^ name

      run_reader "Alice" computation = "Hello, Alice"
      run_reader "Bob" computation = "Hello, Bob"
    ]}

    Обработчик должен:
    1. Перехватывать Ask
    2. Продолжать вычисление, передавая значение env

    Подсказки:
    1. Effect.Deep.match_with с окружением env
    2. При Ask: Effect.Deep.continue k env
    3. Структура:
       {[
         Effect.Deep.match_with f ()
         {
           retc = (fun v -> v);
           exnc = raise;
           effc = (fun (type a) (eff : a Effect.t) ->
             match eff with
             | Ask -> Some (fun k -> Effect.Deep.continue k env)
             | _ -> None
           )
         }
       ]}

    Связанные темы: Reader monad, environment passing, effect handlers
    Время: ~15 минут *)
type _ Effect.t += Ask : string Effect.t

let run_reader (env : string) (f : unit -> 'a) : 'a =
  ignore (env, f);
  failwith "todo"

(* ===== Композиция эффектов ===== *)

(* Сложное *)
(** Упражнение 3: count_and_emit — композиция State + Emit.

    Использовать два эффекта одновременно:
    - State эффект (Get/Set) для счётчика
    - Emit эффект для испускания промежуточных значений

    Функция должна:
    1. Считать от 0 до n
    2. На каждом шаге испускать текущее значение счётчика (Emit)
    3. Использовать State для хранения счётчика

    Предполагается, что эффекты State и Emit уже определены
    в библиотеке (Chapter13.State).

    Примеры:
    {[
      (* Предположим run_state_emit запускает оба обработчика *)
      run_state_emit (fun () -> count_and_emit 3)
        = ((), [0; 1; 2; 3])  (* final state и список испущенных *)
    ]}

    Подсказки:
    1. Используйте Effect.perform для вызова эффектов
    2. Get для чтения состояния
    3. Set для обновления состояния
    4. Emit для испускания значений
    5. Цикл: for i = 0 to n или рекурсия
    6. Pattern:
       {[
         let rec loop () =
           let current = Effect.perform Get in
           if current <= n then begin
             Effect.perform (Emit current);
             Effect.perform (Set (current + 1));
             loop ()
           end
         in loop ()
       ]}

    Связанные темы: Effect composition, multiple handlers, state management
    Время: ~25 минут *)
let count_and_emit (n : int) : unit =
  ignore n;
  failwith "todo"

(* ===== Обработка ошибок ===== *)

(* Среднее *)
(** Упражнение 4: run_fail — эффект для обработки ошибок.

    Реализовать эффект Fail, который позволяет "провалить" вычисление
    с сообщением об ошибке.

    Эффект:
    {[
      type _ Effect.t += Fail : string -> 'a Effect.t
    ]}

    Обработчик должен преобразовать в Result type.

    Использование:
    {[
      let computation () =
        if false then Effect.perform (Fail "error")
        else 42

      run_fail computation = Ok 42

      let bad_computation () =
        Effect.perform (Fail "something went wrong")

      run_fail bad_computation = Error "something went wrong"
    ]}

    Подсказки:
    1. Effect.Deep.match_with
    2. retc: fun v -> Ok v
    3. Обработка Fail: fun k -> Error msg (не продолжаем!)
    4. Не вызываем Effect.Deep.continue при ошибке
    5. Структура:
       {[
         Effect.Deep.match_with f ()
         {
           retc = (fun v -> Ok v);
           exnc = (fun e -> Error (Printexc.to_string e));
           effc = (fun (type a) (eff : a Effect.t) ->
             match eff with
             | Fail msg -> Some (fun _k -> Error msg)
             | _ -> None
           )
         }
       ]}

    Связанные темы: Error handling, exceptions as effects, Result type
    Время: ~15 минут *)
type _ Effect.t += Fail : string -> 'a Effect.t

let run_fail (f : unit -> 'a) : ('a, string) result =
  ignore f;
  failwith "todo"

(* ===== Генераторы ===== *)

(* Среднее *)
(** Упражнение 5: squares — генератор квадратов чисел.

    Реализовать генератор, который испускает квадраты чисел от 1 до n.

    Эффект:
    {[
      type _ Effect.t += Yield : int -> unit Effect.t
    ]}

    Обработчик собирает все Yield'нутые значения в список.

    Использование:
    {[
      let generator n =
        for i = 1 to n do
          Effect.perform (Yield (i * i))
        done

      squares 5 = [1; 4; 9; 16; 25]
    ]}

    Подсказки:
    1. Аналогично run_emit
    2. При Yield: накапливаем значения в список
    3. Effect.Deep.continue k () для продолжения
    4. retc: fun () -> []
    5. Структура:
       {[
         let rec loop f =
           Effect.Deep.match_with f ()
           {
             retc = (fun () -> []);
             exnc = raise;
             effc = (fun (type a) (eff : a Effect.t) ->
               match eff with
               | Yield n -> Some (fun k ->
                   n :: Effect.Deep.continue k ())
               | _ -> None
             )
           }
       ]}

    Связанные темы: Generators, yield, iterators, coroutines
    Время: ~18 минут *)
type _ Effect.t += Yield : int -> unit Effect.t

let squares (_n : int) : int list =
  failwith "todo"

(* ===== Async/Await ===== *)

(* Сложное *)
(** Упражнение 6: run_async — имитация async/await через эффекты.

    Реализовать эффект Async, который позволяет запускать вычисления "асинхронно".

    Эффект:
    {[
      type _ Effect.t += Async : (unit -> 'a) -> 'a Effect.t
    ]}

    Обработчик должен:
    1. Запускать "асинхронное" вычисление немедленно
    2. Продолжать основное вычисление с результатом

    Это упрощённая имитация — реальный async требует scheduler.

    Использование:
    {[
      let computation () =
        let x = Effect.perform (Async (fun () -> 21)) in
        let y = Effect.perform (Async (fun () -> 21)) in
        x + y

      run_async computation = 42
    ]}

    Подсказки:
    1. При Async task: выполнить task (), получить результат
    2. Effect.Deep.continue k result
    3. В реальности нужен event loop, но здесь просто выполняем синхронно
    4. Структура:
       {[
         Effect.Deep.match_with f ()
         {
           retc = (fun v -> v);
           exnc = raise;
           effc = (fun (type a) (eff : a Effect.t) ->
             match eff with
             | Async task -> Some (fun k ->
                 let result = task () in
                 Effect.Deep.continue k result)
             | _ -> None
           )
         }
       ]}

    Связанные темы: Async/await, promises, concurrency primitives
    Время: ~30 минут *)
type _ Effect.t += Async : (unit -> 'a) -> 'a Effect.t

let run_async (f : unit -> 'a) : 'a =
  ignore f;
  failwith "todo"
