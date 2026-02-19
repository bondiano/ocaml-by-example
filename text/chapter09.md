# Мутабельное состояние и прямые эффекты

## Цели главы

В этой главе — работа с **побочными эффектами** в OCaml. В отличие от Haskell, OCaml не требует монады `IO`: любая функция может выполнять эффекты.

В главе:

- Ссылки (`ref`) — мутабельные ячейки.
- Мутабельные записи — поля с `mutable`.
- Массивы — мутабельные коллекции.
- Ввод-вывод — `Printf`, `print_endline`, `input_line`.
- Работа с файлами — `In_channel`, `Out_channel`.
- Форматирование строк — `Printf.sprintf`, `Format`.
- Тип `unit` — индикатор побочных эффектов.
- Сравнение подхода OCaml с монадой `IO` Haskell.

## Подготовка проекта

Код этой главы находится в `exercises/chapter09`. Соберите проект:

```text
$ cd exercises/chapter09
$ dune build
```

## Побочные эффекты в OCaml

В Haskell побочные эффекты изолированы типом `IO`:

```haskell
-- Haskell: эффекты видны в типе
main :: IO ()
main = putStrLn "Hello"
```

В OCaml любая функция может выполнять побочные эффекты — печатать, читать файлы, изменять состояние. Это часть философии языка: OCaml — **практичный** функциональный язык, который не запрещает побочные эффекты, а поощряет их осознанное использование.

```ocaml
(* OCaml: эффекты не видны в типе *)
let main () = print_endline "Hello"
(* val main : unit -> unit *)
```

Тип `unit -> unit` подсказывает, что функция вызывается ради побочных эффектов (возвращает `()`), но компилятор это не проверяет.

### Плюсы и минусы прямого стиля

| Аспект | OCaml (прямые эффекты) | Haskell (IO-монада) |
|--------|----------------------|---------------------|
| Простота | Нет обёрток, привычный стиль | Требует монадических комбинаторов |
| Типобезопасность | Эффекты не видны в типах | Эффекты отражены в типах |
| Отладка | Можно вставить `print` где угодно | Нужно поднять в IO |
| Рефакторинг | Сложнее отследить эффекты | Компилятор покажет все эффекты |
| Тестирование | Нужна дисциплина | Чистые функции легко тестировать |

Хорошая практика OCaml: **разделяйте чистые вычисления и побочные эффекты** самостоятельно, даже без помощи компилятора. Пишите чистые функции, а эффекты выполняйте на верхнем уровне.

## Ссылки (`ref`)

Ссылка (reference) — мутабельная ячейка, содержащая одно значение:

```text
# let counter = ref 0;;
val counter : int ref = {contents = 0}

# !counter;;
- : int = 0

# counter := !counter + 1;;
- : unit = ()

# !counter;;
- : int = 1
```

Три операции:

- `ref v` — создать ссылку с начальным значением `v`.
- `!r` — разыменование (чтение значения).
- `r := v` — присвоение (запись значения).

### Тип `ref`

`ref` — это просто запись с мутабельным полем:

```ocaml
type 'a ref = { mutable contents : 'a }
```

`ref 0` эквивалентно `{ contents = 0 }`. Оператор `!` — это `fun r -> r.contents`. Оператор `:=` — это `fun r v -> r.contents <- v`.

### Ссылки в функциях

```ocaml
let make_counter () =
  let n = ref 0 in
  let increment () = n := !n + 1; !n in
  let get () = !n in
  (increment, get)
```

```text
# let (incr, get) = make_counter ();;
# incr ();;
- : int = 1
# incr ();;
- : int = 2
# get ();;
- : int = 2
```

Замыкание (closure) `increment` захватывает ссылку `n`. Каждый вызов `make_counter ()` создаёт новый независимый счётчик.

```admonish tip title="Для Python/TypeScript-разработчиков"
В Python **все** переменные мутабельны по умолчанию — вы просто пишете `x = 0` и затем `x = x + 1`. В TypeScript есть явное разделение: `let` (мутабельная) vs `const` (иммутабельная).

В OCaml подход противоположный: все привязки (`let`) иммутабельны по умолчанию. Чтобы получить мутабельную переменную, нужно **явно** создать ссылку через `ref`:

| | Python | TypeScript | OCaml |
|---|---|---|---|
| Объявление | `x = 0` | `let x = 0` | `let x = ref 0` |
| Чтение | `x` | `x` | `!x` |
| Запись | `x = 1` | `x = 1` | `x := 1` |

Операторы `!` (разыменование) и `:=` (присвоение) — синтаксический «налог» за мутабельность. Это сделано намеренно: мутабельный код должен быть **заметен** при чтении.
```

### Ссылки vs иммутабельные значения

Используйте ссылки **только когда мутабельность действительно нужна**:

- Счётчики, кэши, аккумуляторы.
- Циклы (хотя рекурсия обычно предпочтительнее).
- Взаимодействие с мутабельными API.

Для большинства задач иммутабельные значения и рекурсия лучше — они проще для понимания и тестирования.

## Мутабельные записи

В главе 4 мы видели записи с `mutable`-полями. Теперь рассмотрим их подробнее:

```ocaml
type account = {
  owner : string;
  mutable balance : float;
}
```

```text
# let acc = { owner = "Иван"; balance = 1000.0 };;
# acc.balance;;
- : float = 1000.
# acc.balance <- acc.balance -. 100.0;;
- : unit = ()
# acc.balance;;
- : float = 900.
```

Оператор `<-` изменяет мутабельное поле «на месте». Неизменяемые поля (`owner`) нельзя менять.

### Пример: простой стек

```ocaml
type 'a stack = {
  mutable items : 'a list;
  mutable size : int;
}

let create_stack () = { items = []; size = 0 }

let push x s =
  s.items <- x :: s.items;
  s.size <- s.size + 1

let pop s =
  match s.items with
  | [] -> None
  | x :: rest ->
    s.items <- rest;
    s.size <- s.size - 1;
    Some x
```

`push` добавляет элемент в голову списка — операция O(1). `pop` возвращает `None` для пустого стека или `Some x` с верхним элементом, одновременно обновляя `items` и `size`. Поля `items` и `size` синхронизируются вручную — при добавлении/удалении оба изменяются вместе.

## Массивы

Массивы в OCaml — мутабельные коллекции с доступом по индексу за O(1):

```text
# let a = [| 1; 2; 3; 4; 5 |];;
val a : int array = [|1; 2; 3; 4; 5|]

# a.(0);;
- : int = 1

# a.(2) <- 99;;
- : unit = ()

# a;;
- : int array = [|1; 2; 99; 4; 5|]
```

Синтаксис: `[| ... |]` — литерал массива. `a.(i)` — доступ по индексу. `a.(i) <- v` — запись по индексу.

### Создание массивов

```text
# Array.make 5 0;;
- : int array = [|0; 0; 0; 0; 0|]

# Array.init 5 (fun i -> i * i);;
- : int array = [|0; 1; 4; 9; 16|]

# Array.of_list [1; 2; 3];;
- : int array = [|1; 2; 3|]

# Array.to_list [| 1; 2; 3 |];;
- : int list = [1; 2; 3]
```

### Когда массивы vs списки

| Операция | Список | Массив |
|----------|--------|--------|
| Доступ по индексу | O(n) | O(1) |
| Добавление в начало | O(1) | O(n) |
| Конкатенация | O(n) | O(n) |
| Сопоставление с образцом | Да | Нет |
| Мутабельность | Нет | Да |

Списки лучше для последовательной обработки (map, filter, fold). Массивы — для случайного доступа и численных вычислений.

```admonish tip title="Для Python/TypeScript-разработчиков"
В Python список (`list`) — это на самом деле динамический массив (аналог `ArrayList` в Java). В TypeScript `Array<T>` — тоже динамический массив. Оба мутабельны и поддерживают доступ по индексу за O(1).

В OCaml `list` и `array` — **разные** структуры данных:

- `list` — односвязный иммутабельный список (как linked list). Доступ по индексу — O(n), но добавление в начало — O(1).
- `array` — мутабельный массив фиксированного размера с доступом O(1).

Если вы привыкли к `list.append()` в Python, помните: в OCaml списки не растут на месте. Вместо этого используйте `x :: xs` (добавление в начало) или `Array` для мутабельной коллекции.
```

## Циклы

OCaml поддерживает традиционные циклы — `for` и `while`:

### Цикл `for`

```ocaml
let print_range a b =
  for i = a to b do
    Printf.printf "%d " i
  done;
  print_newline ()
```

```text
# print_range 1 5;;
1 2 3 4 5
```

Обратный цикл — с `downto`:

```ocaml
let countdown n =
  for i = n downto 1 do
    Printf.printf "%d... " i
  done;
  print_endline "Пуск!"
```

### Цикл `while`

```ocaml
let find_first_negative arr =
  let i = ref 0 in
  let len = Array.length arr in
  while !i < len && arr.(!i) >= 0 do
    i := !i + 1
  done;
  if !i < len then Some !i else None
```

Функция возвращает индекс первого отрицательного элемента в `Some`, или `None` если все элементы неотрицательны. Цикл завершается либо при выходе за границы массива, либо при обнаружении отрицательного числа — после цикла проверяем, дошли ли мы до конца или остановились на нужном элементе. Циклы в OCaml возвращают `unit`. Они полезны при работе с массивами и мутабельным состоянием, но для обработки списков предпочитайте `List.map`, `List.fold_left` и рекурсию.

## Вывод: `print` и `Printf`

### Простой вывод

```text
# print_string "hello";;
hello- : unit = ()

# print_endline "hello";;
hello
- : unit = ()

# print_int 42;;
42- : unit = ()

# print_float 3.14;;
3.14- : unit = ()

# print_newline ();;

- : unit = ()
```

### `Printf.printf` — форматированный вывод

`Printf.printf` — аналог `printf` из C, но **типобезопасный**:

```text
# Printf.printf "Имя: %s, Возраст: %d\n" "Иван" 25;;
Имя: Иван, Возраст: 25
- : unit = ()

# Printf.printf "Pi = %.4f\n" 3.14159;;
Pi = 3.1416
- : unit = ()
```

Спецификаторы формата:

| Спецификатор | Тип | Пример |
|-------------|-----|--------|
| `%d` | `int` | `42` |
| `%f` | `float` | `3.14` |
| `%s` | `string` | `"hello"` |
| `%b` | `bool` | `true` |
| `%c` | `char` | `'a'` |
| `%a` | custom printer | — |
| `%%` | literal `%` | `%` |

В OCaml форматная строка — не обычная строка, а специальный тип `('a, 'b, 'c) format`. Компилятор проверяет соответствие типов на этапе компиляции:

```text
# Printf.printf "%d" "hello";;
Error: This expression has type string but an expression of type int was expected
```

### `Printf.sprintf` — форматирование в строку

```text
# Printf.sprintf "Имя: %s, Возраст: %d" "Иван" 25;;
- : string = "Имя: Иван, Возраст: 25"

# Printf.sprintf "%.2f%%" 99.5;;
- : string = "99.50%"
```

`sprintf` работает как `printf`, но возвращает строку вместо вывода на экран. Это удобно для формирования сообщений.

## Ввод: `input_line` и `read_line`

```text
# let name = read_line ();;
(пользователь вводит: Иван)
val name : string = "Иван"
```

`read_line ()` читает строку из стандартного ввода. `input_line ic` читает строку из произвольного канала ввода.

## Работа с файлами

### Чтение файла

```ocaml
let read_file path =
  In_channel.with_open_text path In_channel.input_all
```

`In_channel.with_open_text` открывает файл, передаёт канал в функцию и **гарантирует закрытие** файла, даже при исключении. Это аналог `with` в Python или `bracket` в Haskell.

```admonish tip title="Для Python/TypeScript-разработчиков"
Паттерн `In_channel.with_open_text path f` — прямой аналог контекстного менеджера `with` в Python:

```python
# Python
with open("file.txt") as f:
    content = f.read()

# TypeScript (Node.js) — нет встроенного аналога,
# нужно try/finally или fs.readFileSync
```

В OCaml нет `with`-синтаксиса, но функции `with_open_*` выполняют ту же роль — гарантируют закрытие ресурса при любом исходе вычисления. Это паттерн «bracket» (открыть-использовать-закрыть).
```

Построчное чтение:

```ocaml
let read_lines path =
  In_channel.with_open_text path (fun ic ->
    let rec loop acc =
      match In_channel.input_line ic with
      | Some line -> loop (line :: acc)
      | None -> List.rev acc
    in
    loop [])
```

Функция использует паттерн «аккумулятор»: строки добавляются в начало списка (быстрая операция), а в конце список переворачивается через `List.rev`, чтобы восстановить исходный порядок строк. `In_channel.input_line` возвращает `None` при достижении конца файла.

### Запись в файл

```ocaml
let write_file path content =
  Out_channel.with_open_text path (fun oc ->
    Out_channel.output_string oc content)

let write_lines path lines =
  Out_channel.with_open_text path (fun oc ->
    List.iter (fun line ->
      Out_channel.output_string oc (line ^ "\n")
    ) lines)
```

### Добавление в файл

```ocaml
let append_to_file path content =
  Out_channel.with_open_gen
    [Open_append; Open_creat; Open_text] 0o644 path
    (fun oc -> Out_channel.output_string oc content)
```

`with_open_gen` позволяет указать флаги открытия: `Open_append` — добавление, `Open_creat` — создание если не существует. `0o644` — права доступа в восьмеричной записи (чтение и запись для владельца, только чтение для остальных); используется только при создании файла.

## Последовательное выполнение: `;`

Точка с запятой `;` — оператор последовательного выполнения. Он вычисляет левое выражение, отбрасывает результат и вычисляет правое:

```ocaml
let greet name =
  print_string "Привет, ";
  print_string name;
  print_endline "!"
```

Компилятор предупредит, если результат перед `;` не `unit`:

```text
# 1 + 2; print_endline "ok";;
Warning 10: this expression should have type unit.
```

Если вы намеренно отбрасываете значение, используйте `ignore`:

```ocaml
let _ = ignore (1 + 2); print_endline "ok"
```

## Проект: менеджер записей

Модуль `lib/records.ml` демонстрирует работу с мутабельным состоянием на примере простого хранилища записей.

### Тип данных

```ocaml
type record = {
  id : int;
  name : string;
  value : string;
}

type store = {
  mutable entries : record list;
  mutable next_id : int;
}
```

### Операции

```ocaml
let create_store () =
  { entries = []; next_id = 1 }

let add_record store ~name ~value =
  let record = { id = store.next_id; name; value } in
  store.entries <- record :: store.entries;
  store.next_id <- store.next_id + 1;
  record

let find_record store id =
  List.find_opt (fun r -> r.id = id) store.entries

let remove_record store id =
  store.entries <- List.filter (fun r -> r.id <> id) store.entries

let all_records store =
  List.rev store.entries
```

`add_record` создаёт запись с текущим `next_id`, добавляет её в начало списка (через `::`) и увеличивает счётчик. `all_records` переворачивает список, чтобы вернуть записи в порядке добавления — ведь самые новые записи находятся в начале `store.entries`.

## Functional Core, Imperative Shell

### Идея паттерна

В OCaml побочные эффекты не отражаются в типах, поэтому разделение чистого и мутабельного кода — ответственность программиста. Паттерн **Functional Core, Imperative Shell** (FC/IS) помогает структурировать код:

- **Functional Core** — чистые функции без побочных эффектов. Вся бизнес-логика, валидация, преобразования данных. Легко тестировать, легко рассуждать.
- **Imperative Shell** — тонкая оболочка, управляющая состоянием и выполняющая эффекты (IO, мутация). Делегирует логику Functional Core.

### Проблема: смешение логики и мутации

В нашем менеджере записей логика и мутация переплетены. `add_record` одновременно **создаёт** запись и **мутирует** хранилище:

```ocaml
let add_record store ~name ~value =
  let record = { id = store.next_id; name; value } in
  store.entries <- record :: store.entries;    (* мутация! *)
  store.next_id <- store.next_id + 1;         (* мутация! *)
  record
```

Тестировать такую функцию сложнее — нужно создавать мутабельный `store` для каждого теста.

### Рефакторинг: разделение на Pure и Shell

**Pure** — чистые функции, работающие с иммутабельными данными:

```ocaml
module Pure = struct
  let make_record ~id ~name ~value = { id; name; value }

  let find entries id =
    List.find_opt (fun r -> r.id = id) entries

  let remove entries id =
    List.filter (fun r -> r.id <> id) entries

  let all entries = List.rev entries
end
```

**Shell** — мутабельная оболочка, делегирующая логику Pure:

```ocaml
module Shell = struct
  let add store ~name ~value =
    let record = Pure.make_record ~id:store.next_id ~name ~value in
    store.entries <- record :: store.entries;
    store.next_id <- store.next_id + 1;
    record

  let find store id = Pure.find store.entries id
  let remove store id = store.entries <- Pure.remove store.entries id
  let all store = Pure.all store.entries
end
```

### Преимущества

- **Тестируемость**: функции `Pure` можно тестировать без мутабельного состояния — передаёте иммутабельный список, получаете результат.
- **Читаемость**: из сигнатур ясно, где происходят эффекты (функции `Shell` принимают `store`), а где чистая логика.
- **Повторное использование**: `Pure.find` и `Pure.remove` работают с любым `record list`, не только с `store.entries`.

### Когда применять

FC/IS особенно полезен, когда:

- Бизнес-логика сложна и нуждается в тестах.
- Код смешивает вычисления и побочные эффекты.
- Несколько потребителей одной и той же логики (CLI, веб-сервер, тесты).

Для простых случаев (счётчик на `ref`) разделение избыточно. Применяйте по мере роста сложности.

```admonish info title="Подробнее"
Детальное описание мутабельного состояния, массивов и императивного программирования: [Real World OCaml, глава «Imperative Programming»](https://dev.realworldocaml.org/imperative-programming.html).
```

## Сборщик мусора и управление памятью

OCaml использует автоматическое управление памятью — сборщик мусора (GC) освобождает объекты, которые больше не используются. Понимание работы GC помогает писать эффективный код и управлять ресурсами.

### Generational GC

Сборщик мусора OCaml — **поколенческий** (generational). Он разделяет память на два поколения:

- **Minor heap** (малая куча) — маленькая область (~256KB по умолчанию). Все новые объекты создаются здесь. Сборка мусора в minor heap выполняется **очень быстро** с помощью алгоритма copying GC — живые объекты копируются, а всё остальное освобождается разом.

- **Major heap** (большая куча) — большая область для **долгоживущих** объектов. Используется алгоритм mark-and-sweep: сначала помечаются живые объекты, затем неотмеченные освобождаются. Сборка выполняется инкрементально, чтобы не останавливать программу надолго.

Типичное соотношение: на каждую major-сборку приходится ~100 minor-сборок. Объекты, пережившие minor-сборку, **переносятся** (promote) в major heap, где живут дольше.

Такая схема работает хорошо благодаря **гипотезе поколений**: большинство объектов живут очень недолго. Функциональный код создаёт множество временных значений — minor heap собирает их быстро и дёшево.

### Модуль `Gc`

Модуль `Gc` позволяет получать статистику и настраивать параметры сборщика:

```ocaml
let stats = Gc.stat () in
Printf.printf "Minor collections: %d\n" stats.minor_collections;
Printf.printf "Major collections: %d\n" stats.major_collections;
Printf.printf "Minor heap size: %d words\n" stats.heap_words;

(* Включение подробного вывода GC *)
Gc.set { (Gc.get ()) with Gc.verbose = 0x01 }
```

`Gc.stat ()` возвращает запись типа `Gc.stat` с информацией о количестве сборок, размерах куч и другими метриками. `Gc.get ()` возвращает текущие настройки, а `Gc.set` позволяет их изменить — например, включить подробный вывод отладочной информации.

### Finalisers

Финализеры — функции, которые вызываются перед тем, как GC соберёт объект. Они полезны для освобождения внешних ресурсов (файловых дескрипторов, сетевых соединений):

```ocaml
let register_resource resource =
  Gc.finalise (fun r -> cleanup r) resource

(* ВАЖНО: OCaml НЕ гарантирует запуск finalisers при exit *)
let () = at_exit Gc.full_major
```

Важные предупреждения:

- **Финализеры не вызываются при `exit`** — если программа завершается, GC не обязан собрать все объекты. Используйте `at_exit Gc.full_major`, чтобы форсировать полную сборку при завершении.
- **Финализер не должен бросать исключения** — исключение из финализера приведёт к непредсказуемому поведению.
- **Не привязывайте финализер к значению, которое он замыкает** — если финализер ссылается на тот же объект, к которому привязан, объект никогда не будет собран (циклическая ссылка).

### Weak references

Слабые ссылки (weak references) позволяют GC собирать значение, **даже если ссылка на него существует**. Это полезно для кешей — если памяти достаточно, значение остаётся в кеше; если GC нуждается в памяти, кеш очищается автоматически:

```ocaml
let cache = Weak.create 100

let get_or_compute n compute =
  match Weak.get cache n with
  | Some value -> value
  | None ->
    let value = compute () in
    Weak.set cache n (Some value);
    value
```

`Weak.create n` создаёт массив из `n` слабых ссылок. `Weak.get` возвращает `Some value`, если значение ещё не собрано, или `None`, если GC его уже освободил. `Weak.set` устанавливает значение в слот.

Слабые ссылки — инструмент для ситуаций, когда вы хотите сохранить значение «если возможно», но не хотите мешать GC освобождать память. Типичный пример — кеш вычислений, который автоматически уменьшается при нехватке памяти.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Лёгкое)** Реализуйте модуль `Counter` — счётчик на основе `ref`.

    ```ocaml
    val counter_create : int -> int ref
    val counter_increment : int ref -> unit
    val counter_decrement : int ref -> unit
    val counter_reset : int ref -> unit
    val counter_value : int ref -> int
    ```

    `counter_create 0` создаёт счётчик с начальным значением 0. `counter_increment` увеличивает на 1, `counter_decrement` уменьшает, `counter_reset` сбрасывает в 0.

2. **(Среднее)** Реализуйте модуль `Logger` — простой логгер, который накапливает сообщения в буфере.

    ```ocaml
    type logger
    val logger_create : unit -> logger
    val logger_log : logger -> string -> unit
    val logger_messages : logger -> string list
    val logger_clear : logger -> unit
    val logger_count : logger -> int
    ```

    *Подсказка:* используйте `ref` со списком строк. `logger_messages` должна возвращать сообщения в порядке добавления.

3. **(Среднее)** Реализуйте функцию `format_table`, которая форматирует список записей в текстовую таблицу.

    ```ocaml
    val format_table : (string * string) list -> string
    ```

    Например, `format_table [("Имя", "Иван"); ("Город", "Москва")]` должна вернуть:

    ```
    Имя   | Иван
    Город | Москва
    ```

    *Подсказка:* используйте `Printf.sprintf` и вычислите максимальную длину ключа для выравнивания.

4. **(Среднее)** Реализуйте функцию `array_sum_imperative`, которая вычисляет сумму элементов массива с помощью цикла `for` и ссылки-аккумулятора.

    ```ocaml
    val array_sum_imperative : int array -> int
    ```

    *Подсказка:* используйте `ref` для аккумулятора и `for i = 0 to Array.length arr - 1`.

5. **(Среднее)** Robot Name — генерация уникальных имён роботов формата AA000 (две буквы + три цифры). Каждый вызов `create` должен давать уникальное имя.

    ```ocaml
    module Robot : sig
      type t
      val create : unit -> t
      val name : t -> string
      val reset : t -> t
    end
    ```

    `create ()` создаёт робота с уникальным именем. `name` возвращает имя. `reset` создаёт нового робота с новым уникальным именем.

6. **(Среднее)** LRU-кеш — реализовать кеш с ограниченной ёмкостью. При переполнении вытесняется наименее использованный элемент.

    ```ocaml
    module LRU : sig
      type ('k, 'v) t
      val create : int -> ('k, 'v) t
      val get : ('k, 'v) t -> 'k -> 'v option
      val put : ('k, 'v) t -> 'k -> 'v -> unit
      val size : ('k, 'v) t -> int
    end
    ```

    `create n` создаёт кеш ёмкостью `n`. `put` добавляет элемент (вытесняя старейший при переполнении). `get` возвращает значение и делает элемент «недавно использованным».

7. **(Среднее)** Отрефакторьте Logger (упражнение 2) в стиле Functional Core / Imperative Shell. Создайте модуль `LoggerPure` с чистыми функциями, работающими со списком строк, и модуль `LoggerShell`, управляющий мутабельным состоянием.

    ```ocaml
    module LoggerPure : sig
      val add : string list -> string -> string list
      val count : string list -> int
      val messages : string list -> string list
    end

    module LoggerShell : sig
      type t
      val create : unit -> t
      val log : t -> string -> unit
      val messages : t -> string list
      val count : t -> int
      val clear : t -> unit
    end
    ```

    *Подсказка:* `LoggerPure` работает с `string list` напрямую. `LoggerShell` хранит `string list ref` и делегирует логику `LoggerPure`.

8. **(Сложное)** Bowling — подсчёт очков в боулинге. Реализуйте модуль с мутабельным состоянием игры.

    ```ocaml
    module Bowling : sig
      type t
      val create : unit -> t
      val roll : t -> int -> (unit, string) result
      val score : t -> int
    end
    ```

    Правила:
    - Игра состоит из 10 фреймов.
    - В каждом фрейме 2 броска (если не страйк).
    - **Spare** (сбиты все 10 кеглей за 2 броска): 10 + следующий бросок.
    - **Strike** (сбиты все 10 за 1 бросок): 10 + два следующих броска.
    - 10-й фрейм: бонусные броски при spare/strike.
    - Perfect game (12 страйков) = 300 очков.

    *Подсказка:* храните все броски в списке, а `score` вычисляйте проходом по фреймам.

## Заключение

В этой главе:

- Ссылки (`ref`) — мутабельные ячейки OCaml.
- Мутабельные записи и массивы.
- Ввод-вывод: `Printf.printf`, `Printf.sprintf`, `In_channel`, `Out_channel`.
- Безопасная работа с файлами через `with_open_text`.
- Циклы `for` и `while`.
- Паттерн Functional Core / Imperative Shell: бизнес-логика отделена от эффектов.

Следующая глава — проектирование через типы: умные конструкторы, кодирование состояний в типах и паттерн «Parse, Don't Validate».
