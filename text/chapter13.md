# Обработчики эффектов

## Цели главы

Эта глава об **обработчиках эффектов** (effect handlers) — возможности OCaml 5, которая позволяет описывать побочные эффекты как значения и интерпретировать их произвольным образом.

Темы главы:

- **Алгебраические эффекты** — что это и зачем.
- **Объявление эффектов** — расширяемый тип `Effect.t`.
- **Выполнение эффектов** — `Effect.perform`.
- **Глубокие обработчики** — `Effect.Deep.try_with` и `Effect.Deep.match_with`.
- **Продолжения** — `Effect.Deep.continue`.
- **Поверхностные обработчики** — `Effect.Shallow`.
- **Композиция обработчиков** — вложенные `try_with`.
- **Сравнение** с трансформерами монад из Haskell.
- **Проект**: интерпретатор с логированием и состоянием.

## Подготовка проекта

Код этой главы находится в `exercises/chapter13`. Обработчики эффектов встроены в стандартную библиотеку OCaml 5, дополнительные пакеты не нужны:

```text
$ cd exercises/chapter13
$ dune build
```

## Что такое алгебраические эффекты

Представьте, что вы хотите написать функцию, которая использует состояние (чтение и запись переменной). В императивных языках вы просто используете мутабельную переменную. В чисто функциональных — монаду State. Но что, если бы вы могли:

1. **Описать** эффект — «я хочу прочитать состояние» или «я хочу записать новое значение».
2. **Выполнить** эффект в коде, не зная, как он будет обработан.
3. **Интерпретировать** эффект на уровне вызывающего кода — решить, хранить ли состояние в `ref`, в файле или в базе данных.

Именно это и дают **алгебраические эффекты**. Эффект — это операция, объявленная программистом, но не имеющая встроенной реализации. Реализацию предоставляет **обработчик** (handler), оборачивающий вычисление.

Алгебраические эффекты можно рассматривать как обобщение исключений: исключение прерывает вычисление, а эффект **приостанавливает** его, позволяя обработчику передать значение обратно и **возобновить** выполнение.

## Объявление эффектов

В OCaml 5 эффекты объявляются через расширяемый тип `Effect.t`:

```ocaml
type _ Effect.t += Get : int Effect.t
type _ Effect.t += Set : int -> unit Effect.t
```

Здесь мы объявили два эффекта:

- `Get` — запрос текущего значения состояния (возвращает `int`).
- `Set v` — установка нового значения (возвращает `unit`).

Тип `'a Effect.t` параметризован типом возвращаемого значения: `Get` возвращает `int`, а `Set` возвращает `unit`.

Синтаксис `+=` означает, что мы **расширяем** существующий тип — можно добавлять новые эффекты в разных модулях.

## Выполнение эффектов

Для выполнения эффекта используется `Effect.perform`:

```ocaml
let state_example () =
  let x = Effect.perform Get in
  Effect.perform (Set (x + 10));
  let y = Effect.perform Get in
  x + y
```

Эта функция:

1. Читает текущее состояние в `x`.
2. Устанавливает новое значение `x + 10`.
3. Читает обновлённое состояние в `y`.
4. Возвращает `x + y`.

Обратите внимание: в этом коде **нет** ни `ref`, ни монад, ни аргументов для передачи состояния. Код выглядит как обычные вызовы функций. Но если вызвать `state_example ()` без обработчика, мы получим исключение `Unhandled`.

````admonish tip title="Для Python/TypeScript-разработчиков"
`Effect.perform` можно сравнить с `yield` в генераторах Python и TypeScript, но с важным отличием — эффект возвращает значение обратно:

```python
# Python: генератор "приостанавливает" выполнение
def state_example():
    x = yield "get"          # приостановка, получаем значение
    yield ("set", x + 10)    # приостановка
    y = yield "get"           # приостановка, получаем значение
    return x + y
```

В генераторе `yield` приостанавливает функцию и передаёт значение вызывающему коду, который может «вернуть» ответ через `.send()`. В OCaml `perform` работает аналогично, но:
- Нет специального синтаксиса — обычные вызовы функций.
- Обработчик определяет семантику, а не вызывающий код напрямую.
- Несколько эффектов компонуются автоматически (нет проблемы «один yield на всё»).
````

## Глубокие обработчики: `try_with`

Простейший способ обработать эффекты — `Effect.Deep.try_with`:

```ocaml
let run_state (init : int) (f : unit -> 'a) : 'a =
  let state = ref init in
  Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Get -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            Effect.Deep.continue k !state)
        | Set v -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            state := v;
            Effect.Deep.continue k ())
        | _ -> None }
```

Разберём по частям:

- `Effect.Deep.try_with f ()` — вызывает `f ()` и перехватывает эффекты.
- `{ effc = ... }` — запись-обработчик с одним полем `effc`.
- `effc` получает эффект и возвращает `Some handler` если знает, как его обработать, или `None`, чтобы передать вверх по стеку.
- `fun (type a) (eff : a Effect.t)` — локально-абстрактный тип, необходимый для GADT-паттерн-матчинга.
- `Effect.Deep.continue k value` — возобновляет приостановленное вычисление, передавая `value` как результат `perform`.

Проверим:

```ocaml
let () =
  let result = run_state 5 state_example in
  Printf.printf "Результат: %d\n" result
  (* Результат: 20 *)
  (* 5 + (5 + 10) = 20 *)
```

### Как это работает

1. `state_example` вызывает `perform Get`.
2. Вычисление приостанавливается, управление передаётся обработчику.
3. Обработчик видит `Get`, читает `!state` (= 5) и вызывает `continue k 5`.
4. Вычисление возобновляется: `x = 5`.
5. `perform (Set 15)` — обработчик записывает `state := 15` и вызывает `continue k ()`.
6. `perform Get` — обработчик возвращает `!state` (= 15), `y = 15`.
7. Результат: `5 + 15 = 20`.

## Глубокие обработчики: `match_with`

`Effect.Deep.match_with` — более полная форма обработчика, позволяющая перехватывать не только эффекты, но и нормальное завершение и исключения:

```ocaml
type _ Effect.t += Fail : string -> 'a Effect.t

let run_fail (f : unit -> 'a) : ('a, string) result =
  Effect.Deep.match_with f ()
    { retc = (fun x -> Ok x);
      exnc = (fun e -> raise e);
      effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Fail msg -> Some (fun (_k : (a, _) Effect.Deep.continuation) ->
            Error msg)
        | _ -> None }
```

Три поля:

- `retc` — вызывается при нормальном возвращении значения из `f`.
- `exnc` — вызывается при выбросе исключения.
- `effc` — вызывается при выполнении эффекта (как в `try_with`).

Обратите внимание: в обработчике `Fail` мы **не вызываем** `continue k`. Это означает, что вычисление прерывается — продолжение отбрасывается. Это безопасно и корректно: если продолжение не используется, оно просто собирается сборщиком мусора.

### Разница между `try_with` и `match_with`

| | `try_with` | `match_with` |
|---|---|---|
| Нормальное значение | Возвращается as-is | Передаётся в `retc` |
| Исключение | Пробрасывается | Передаётся в `exnc` |
| Эффект | Обрабатывается `effc` | Обрабатывается `effc` |

Используйте `try_with`, когда вам нужно только перехватить эффекты. Используйте `match_with`, когда нужно трансформировать результат (например, обернуть в `Result`).

## Продолжения подробнее

Продолжение (continuation) `k` — это «оставшаяся часть вычисления» после точки `perform`. Это первоклассное значение, которое можно:

- **Возобновить один раз** с помощью `Effect.Deep.continue k value`.
- **Прервать** с помощью `Effect.Deep.discontinue k exn` (бросить исключение в точке `perform`).
- **Не использовать** вовсе (как в примере с `Fail`).

Важное ограничение: продолжение глубокого обработчика можно использовать **только один раз** (one-shot). Попытка вызвать `continue` дважды приведёт к исключению `Continuation_already_resumed`.

```ocaml
(* discontinue — прервать вычисление с исключением *)
| Fail msg -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
    Effect.Deep.discontinue k (Failure msg))
```

`discontinue k exn` — альтернатива неиспользованию продолжения: вместо того чтобы молча отбросить `k`, мы «вбрасываем» исключение обратно в точку `perform`. Это позволяет вызывающему коду перехватить ошибку через стандартный `try ... with`.

## Эффект Log: накопление сообщений

Создадим эффект для логирования:

```ocaml
type _ Effect.t += Log : string -> unit Effect.t

let run_log (f : unit -> 'a) : 'a * string list =
  let logs = ref [] in
  let result = Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Log msg -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            logs := msg :: !logs;
            Effect.Deep.continue k ())
        | _ -> None }
  in
  (result, List.rev !logs)
```

Использование:

```ocaml
let log_example () =
  Effect.perform (Log "start");
  let result = 2 + 3 in
  Effect.perform (Log (Printf.sprintf "result = %d" result));
  Effect.perform (Log "done");
  result

let () =
  let (value, logs) = run_log log_example in
  Printf.printf "Значение: %d\n" value;
  List.iter (Printf.printf "  Лог: %s\n") logs
  (* Значение: 5
     Лог: start
     Лог: result = 5
     Лог: done *)
```

Функция `log_example` не знает, куда пишутся логи — в список, в файл, в `/dev/null`. Это решает обработчик.

````admonish tip title="Для Python/TypeScript-разработчиков"
Эффект `Log` — аналог **dependency injection** для логирования. В Python и TypeScript для этого обычно используют модуль `logging` или передают логгер как аргумент:

```python
# Python: DI через аргумент
def process(data, logger=print):
    logger("начинаем обработку")
    result = compute(data)
    logger(f"результат: {result}")
    return result

# Тестирование: подставляем мок-логгер
logs = []
process(data, logger=logs.append)
```

В OCaml эффекты позволяют добиться того же **без** передачи логгера через все аргументы. Функция просто вызывает `perform (Log msg)`, а обработчик на верхнем уровне решает, куда писать. Это устраняет проблему «пробрасывания зависимостей через весь стек вызовов» (prop drilling).
````

## Композиция обработчиков

Одно из главных преимуществ эффектов — обработчики легко **компонуются** через вложенность:

```ocaml
let combined_example () =
  Effect.perform (Log "начинаем");
  let x = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "текущее значение: %d" x));
  Effect.perform (Set (x * 2));
  let y = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "новое значение: %d" y));
  y

let () =
  let (result, logs) = run_log (fun () ->
    run_state 7 combined_example
  ) in
  Printf.printf "Результат: %d\n" result;
  List.iter (Printf.printf "  %s\n") logs
  (* Результат: 14
     начинаем
     текущее значение: 7
     новое значение: 14 *)
```

Здесь `run_state` обрабатывает `Get`/`Set`, а `run_log` обрабатывает `Log`. Порядок вложенности определяет, какой обработчик перехватывает какие эффекты: внутренний (`run_state`) видит эффекты первым, но пропускает `Log` наверх через `_ -> None`.

### Порядок вложенности

Обработчики работают как стек. Когда эффект не обработан (`None`), он передаётся следующему обработчику вверх по стеку:

```
run_log        <-- обрабатывает Log, пропускает остальное
  run_state    <-- обрабатывает Get/Set, пропускает остальное
    f ()       <-- выполняет perform Get, Set, Log
```

Если поменять порядок, всё будет работать так же, потому что каждый обработчик реагирует только на «свои» эффекты.

## Поверхностные обработчики

OCaml предоставляет два вида обработчиков:

- **Глубокие** (`Effect.Deep`) — обработчик автоматически переустанавливается после каждого `continue`. Это значит, что один вызов `try_with` обработает **все** вхождения эффекта.
- **Поверхностные** (`Effect.Shallow`) — обработчик срабатывает **один раз**. После `continue` нужно явно указать следующий обработчик.

```ocaml
let run_state_shallow (init : int) (f : unit -> 'a) : 'a =
  let state = ref init in
  let fiber = Effect.Shallow.fiber f in
  let rec handler = {
    Effect.Shallow.retc = Fun.id;
    exnc = raise;
    effc = fun (type a) (eff : a Effect.t) ->
      match eff with
      | Get -> Some (fun (k : (a, _) Effect.Shallow.continuation) ->
          Effect.Shallow.continue_with k !state handler)
      | Set v -> Some (fun (k : (a, _) Effect.Shallow.continuation) ->
          state := v;
          Effect.Shallow.continue_with k () handler)
      | _ -> None
  } in
  Effect.Shallow.continue_with fiber () handler
```

Ключевое отличие от глубокого обработчика: в каждом `continue_with` нужно явно передать `handler` снова, иначе следующий эффект окажется необработанным. Именно поэтому `handler` объявлен через `let rec` — запись ссылается на саму себя внутри `continue_with`.

На практике поверхностные обработчики нужны реже. Они полезны, когда:

- Нужно менять поведение обработчика между вызовами.
- Реализуется корутина или генератор, где каждый `yield` требует другой логики.

В большинстве случаев используйте **глубокие** обработчики — они проще и удобнее.

## Сравнение с трансформерами монад (Haskell)

Если вы знакомы с Haskell, сравним подходы:

### Haskell: трансформеры монад

```haskell
-- Haskell
type App a = StateT Int (WriterT [String] IO) a

example :: App Int
example = do
  tell ["начинаем"]
  x <- get
  tell ["текущее значение: " ++ show x]
  put (x * 2)
  y <- get
  tell ["новое значение: " ++ show y]
  return y
```

### OCaml: обработчики эффектов

```ocaml
(* OCaml *)
let example () =
  Effect.perform (Log "начинаем");
  let x = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "текущее значение: %d" x));
  Effect.perform (Set (x * 2));
  let y = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "новое значение: %d" y));
  y
```

| Аспект | Трансформеры монад | Обработчики эффектов |
|--------|-------------------|---------------------|
| Синтаксис | `do`-нотация, `lift` | Обычный код + `perform` |
| Композиция | Стек трансформеров, порядок важен | Вложенные обработчики |
| Производительность | Накладные расходы от boxing | Оптимизировано в рантайме |
| Типобезопасность | Полная (тип монады отражает эффекты) | Частичная (необработанный эффект — рантайм-ошибка) |
| Расширяемость | Новый эффект = новый трансформер + `lift` | Новый эффект = новый конструктор |

Главное преимущество обработчиков эффектов — **отсутствие `lift`**. В Haskell при добавлении нового трансформера в стек нужно обновлять все вызовы. В OCaml каждый эффект независим.

Главный недостаток — **отсутствие статической проверки**: компилятор не предупредит, если вы забыли обработать эффект. Вы узнаете об этом только в рантайме.

```admonish note title="Сравнение с Haskell"
В Haskell стек трансформеров монад фиксируется в типе: `StateT Int (WriterT [String] IO) a`. Компилятор **видит** все эффекты и не позволит забыть `runStateT` или `runWriterT`. В OCaml `Effect.perform Get` компилируется без обработчика — ошибка обнаружится только в рантайме.

Библиотеки алгебраических эффектов для Haskell (Polysemy, Effectful, Cleff) пытаются совместить оба подхода — удобство эффектов с типовой проверкой. В OCaml пока нет встроенной системы типов для эффектов, хотя это обсуждается в сообществе.
```

## Когда использовать обработчики эффектов

Используйте эффекты, когда:

- Нужно **инжектировать зависимости** — функция выполняет `perform`, а обработчик решает, как реализовать операцию (реальная БД vs мок в тестах).
- Нужна **интерпретация вычислений** — один и тот же код можно запустить с разными обработчиками (логирование в файл vs в память).
- Реализуете **конкурентность** — Eio использует эффекты для файберов.

Не используйте эффекты, когда:

- Достаточно **простого аргумента** — передать функцию-логгер проще, чем объявлять эффект.
- Нужна **статическая гарантия** обработки — `Result` и `Option` проверяются компилятором, эффекты — нет.
- Код должен быть **совместим** со старыми версиями OCaml (< 5.0).

## Генераторы через эффекты

Эффекты позволяют реализовать **генераторы** (аналог `yield` в Python) — функции, которые приостанавливают выполнение и возвращают промежуточные значения.

### Эффект Yield

```ocaml
type _ Effect.t += Yield : 'a -> unit Effect.t

let yield v = Effect.perform (Yield v)
```

### Обработчик генератора

Обработчик собирает все значения, переданные через `Yield`, в список:

```ocaml
let run_generator (f : unit -> unit) : 'a list =
  let results = ref [] in
  Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Yield v -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            results := (Obj.magic v) :: !results;
            Effect.Deep.continue k ())
        | _ -> None };
  List.rev !results
```

`Obj.magic` здесь используется для обхода системы типов — в реальном коде лучше использовать экзистенциальные типы или GADT.

### Пример: генератор диапазона

```ocaml
let range n =
  for i = 1 to n do
    yield i
  done

let () =
  let values = run_generator (fun () -> range 5) in
  List.iter (Printf.printf "%d ") values
  (* Выведет: 1 2 3 4 5 *)
```

Функция `range` приостанавливает выполнение на каждом `yield`, обработчик собирает значения и возобновляет продолжение.

### Связь с `Seq`

Генераторы через эффекты можно превратить в ленивые последовательности:

```ocaml
let to_seq (gen : unit -> unit) : int Seq.t =
  let state = ref (Some (fun () -> gen ())) in
  fun () ->
    match !state with
    | None -> Seq.Nil
    | Some f ->
        try
          Effect.Deep.try_with f ()
            { effc = fun (type a) (eff : a Effect.t) ->
                match eff with
                | Yield v -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
                    state := Some (fun () -> Effect.Deep.continue k ());
                    raise (Obj.magic v))
                | _ -> None };
          state := None;
          Seq.Nil
        with v -> Seq.Cons (Obj.magic v, to_seq (fun () -> ()))
```

Это показывает, как эффекты могут служить основой для реализации ленивых вычислений.

```admonish tip title="Для Python-разработчиков"
Эффект `Yield` — прямой аналог `yield` в Python:

\`\`\`python
def range_gen(n):
    for i in range(1, n + 1):
        yield i

list(range_gen(5))  # [1, 2, 3, 4, 5]
\`\`\`

В Python генераторы встроены в язык, в OCaml их можно реализовать через эффекты.
```

## Кооперативный планировщик

Эффекты позволяют реализовать **кооперативную многозадачность** — основу библиотек вроде Eio. Рассмотрим простой планировщик задач.

### Эффект Fork и Yield

```ocaml
type _ Effect.t += Fork : (unit -> unit) -> unit Effect.t
type _ Effect.t += Yield_sched : unit Effect.t

let fork f = Effect.perform (Fork f)
let yield () = Effect.perform Yield_sched
```

- `Fork f` — запустить новую задачу `f` конкурентно.
- `Yield_sched` — уступить процессор другой задаче.

### Планировщик с очередью задач

```ocaml
let run_scheduler (main : unit -> unit) : unit =
  let queue = Queue.create () in
  let enqueue task = Queue.add task queue in
  let dequeue () =
    if Queue.is_empty queue then None
    else Some (Queue.take queue)
  in

  let rec schedule () =
    match dequeue () with
    | None -> ()
    | Some task ->
        Effect.Deep.try_with task ()
          { effc = fun (type a) (eff : a Effect.t) ->
              match eff with
              | Fork f -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
                  enqueue (fun () -> Effect.Deep.continue k ());
                  enqueue f;
                  schedule ())
              | Yield_sched -> Some (fun k ->
                  enqueue (fun () -> Effect.Deep.continue k ());
                  schedule ())
              | _ -> None };
        schedule ()
  in
  enqueue main;
  schedule ()
```

Планировщик:
1. Хранит очередь задач (`Queue`).
2. При `Fork f` добавляет текущую задачу и `f` в очередь, продолжает выполнение.
3. При `Yield_sched` добавляет текущую задачу в конец очереди и переключается на следующую.

### Пример: конкурентные задачи

```ocaml
let task name n =
  for i = 1 to n do
    Printf.printf "%s: %d\n" name i;
    yield ()
  done

let () =
  run_scheduler (fun () ->
    fork (fun () -> task "A" 3);
    fork (fun () -> task "B" 3);
    task "Main" 2)
  (* Выведет (порядок зависит от планировщика):
     Main: 1
     A: 1
     B: 1
     Main: 2
     A: 2
     B: 2
     A: 3
     B: 3 *)
```

Каждая задача уступает процессор через `yield ()`, позволяя другим задачам выполняться.

```admonish note title="Как Eio использует эффекты"
Eio внутри использует похожий механизм: каждый файбер — это продолжение, приостановленное на I/O-операции. Когда файбер вызывает `Eio.Fiber.yield`, планировщик переключается на другой файбер. Когда I/O завершается, продолжение возобновляется. Этот простой планировщик демонстрирует основную идею.
```

## Проект: мини-интерпретатор с эффектами

Объединим все идеи в проекте — простом интерпретаторе выражений, использующем состояние и логирование через эффекты.

Модуль `lib/effects.ml` содержит:

### Эффект State

```ocaml
type _ Effect.t += Get : int Effect.t
type _ Effect.t += Set : int -> unit Effect.t

let run_state (init : int) (f : unit -> 'a) : 'a =
  let state = ref init in
  Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Get -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            Effect.Deep.continue k !state)
        | Set v -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            state := v;
            Effect.Deep.continue k ())
        | _ -> None }
```

### Эффект Log

```ocaml
type _ Effect.t += Log : string -> unit Effect.t

let run_log (f : unit -> 'a) : 'a * string list =
  let logs = ref [] in
  let result = Effect.Deep.try_with f ()
    { effc = fun (type a) (eff : a Effect.t) ->
        match eff with
        | Log msg -> Some (fun (k : (a, _) Effect.Deep.continuation) ->
            logs := msg :: !logs;
            Effect.Deep.continue k ())
        | _ -> None }
  in
  (result, List.rev !logs)
```

### Примеры использования

```ocaml
let state_example () =
  let x = Effect.perform Get in
  Effect.perform (Set (x + 10));
  let y = Effect.perform Get in
  x + y

let log_example () =
  Effect.perform (Log "start");
  let result = 2 + 3 in
  Effect.perform (Log (Printf.sprintf "result = %d" result));
  Effect.perform (Log "done");
  result

let combined_example () =
  Effect.perform (Log "начинаем");
  let x = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "текущее значение: %d" x));
  Effect.perform (Set (x * 2));
  let y = Effect.perform Get in
  Effect.perform (Log (Printf.sprintf "новое значение: %d" y));
  y
```

Запуск:

```ocaml
(* State: начальное значение 5 *)
let () =
  let result = run_state 5 state_example in
  Printf.printf "state_example: %d\n" result
  (* state_example: 20 *)

(* Log: накопление сообщений *)
let () =
  let (value, logs) = run_log log_example in
  Printf.printf "log_example: %d, logs: [%s]\n"
    value (String.concat "; " logs)
  (* log_example: 5, logs: [start; result = 5; done] *)

(* Композиция State + Log *)
let () =
  let (result, logs) = run_log (fun () ->
    run_state 7 combined_example
  ) in
  Printf.printf "combined: %d, logs: [%s]\n"
    result (String.concat "; " logs)
  (* combined: 14, logs: [начинаем; текущее значение: 7; новое значение: 14] *)
```

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Среднее)** Реализуйте эффект `Emit` для испускания целых чисел. Напишите обработчик `run_emit`, который собирает все испущенные значения в список.

    ```ocaml
    type _ Effect.t += Emit : int -> unit Effect.t

    val run_emit : (unit -> 'a) -> 'a * int list
    ```

    *Подсказка:* по аналогии с `run_log`, но собирайте `int` вместо `string`.

2. **(Среднее)** Реализуйте эффект `Ask` для чтения из окружения (паттерн Reader). Напишите обработчик `run_reader`, который передаёт строку-окружение при каждом `Ask`.

    ```ocaml
    type _ Effect.t += Ask : string Effect.t

    val run_reader : string -> (unit -> 'a) -> 'a
    ```

    *Подсказка:* по аналогии с `Get`, но значение никогда не меняется.

3. **(Сложное)** Реализуйте функцию `count_and_emit`, которая использует одновременно эффекты `State` (из библиотеки) и `Emit` (из упражнения 1). Функция должна для каждого `i` от 1 до `n` прибавить `i` к состоянию и испустить новое значение.

    ```ocaml
    val count_and_emit : int -> unit
    ```

    При начальном состоянии 0 и `n = 3`:
    - `i=1`: состояние = 0+1 = 1, emit 1
    - `i=2`: состояние = 1+2 = 3, emit 3
    - `i=3`: состояние = 3+3 = 6, emit 6
    - Результат: `[1; 3; 6]`

4. **(Сложное)** Реализуйте эффект `Fail` для обработки ошибок. Напишите обработчик `run_fail`, который возвращает `Ok value` при нормальном завершении и `Error msg` при выполнении `Fail msg`.

    ```ocaml
    type _ Effect.t += Fail : string -> 'a Effect.t

    val run_fail : (unit -> 'a) -> ('a, string) result
    ```

    *Подсказка:* используйте `Effect.Deep.match_with` с `retc`, `exnc` и `effc`. В обработчике `Fail` **не вызывайте** `continue` — просто верните `Error msg`.

5. **(Сложное)** Реализуйте генератор, который испускает квадраты чисел от 1 до n. Используйте эффект `Yield` и обработчик `run_generator`.

    ```ocaml
    type _ Effect.t += Yield : int -> unit Effect.t

    val squares : int -> int list
    ```

    `squares 5` должна вернуть `[1; 4; 9; 16; 25]`.

    *Подсказка:* внутри `squares` используйте цикл `for`, вызывая `Effect.perform (Yield (i * i))` на каждой итерации. Обработчик собирает значения в список.

6. **(Сложное)** Реализуйте паттерн `async/await` через эффекты. Определите эффект `Async` для запуска асинхронных операций и обработчик `run_async`, который собирает все результаты.

    ```ocaml
    type _ Effect.t += Async : (unit -> 'a) -> 'a Effect.t

    val run_async : (unit -> 'a) -> 'a
    ```

    Пример: `run_async (fun () -> let x = perform (Async (fun () -> 10)) in x + 5)` возвращает `15`.

    *Подсказка:* используйте `Effect.Deep.try_with`. При `Async f` выполните `f ()` и передайте результат в продолжение через `continue`.

## Заключение

В этой главе:

- **Алгебраические эффекты** — операция объявляется программистом, реализация предоставляется обработчиком. Эффект приостанавливает вычисление; обработчик его возобновляет.
- **`Effect.perform`** — выполнить эффект. Код выглядит как обычные вызовы функций — нет `do`-нотации, нет `lift`.
- **`try_with`** — перехватить эффекты. **`match_with`** — перехватить эффекты и трансформировать результат (например, обернуть в `Result`).
- **Продолжения** — первоклассные значения. Глубокое продолжение можно использовать только один раз.
- **Композиция** — обработчики вкладываются друг в друга. Каждый перехватывает только «свои» эффекты, остальные пропускает наверх.
- Эффекты State и Log реализованы и скомпонованы без `lift`.
- Главный недостаток по сравнению с трансформерами монад Haskell — отсутствие статической проверки. Необработанный эффект обнаруживается только в рантайме.

```admonish info title="Подробнее"
Официальное руководство по effect handlers в OCaml 5: [OCaml Manual, глава «Effect Handlers»](https://v2.ocaml.org/manual/effects.html). Также рекомендуется туториал [«Effect Handlers in OCaml 5»](https://github.com/ocaml-multicore/ocaml5-tutorial) от команды OCaml Multicore.
```

В следующей главе — FFI: взаимодействие OCaml с C и работа с JSON.
