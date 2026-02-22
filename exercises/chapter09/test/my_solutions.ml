(** Здесь вы можете писать свои решения упражнений. *)

(* ===== Мутабельные ссылки ===== *)

(* Лёгкое *)
(** Упражнение 1: Counter — счётчик на ref.

    Реализуйте простой счётчик используя ref cell.

    Операции:
    - counter_create: создать счётчик с начальным значением
    - counter_increment: увеличить на 1
    - counter_decrement: уменьшить на 1
    - counter_reset: сбросить в 0
    - counter_value: получить текущее значение

    Примеры:
    {[
      let c = counter_create 5
      counter_increment c;
      counter_value c = 6

      counter_decrement c;
      counter_value c = 5

      counter_reset c;
      counter_value c = 0
    ]}

    Подсказки:
    1. ref создаёт мутабельную ссылку: let x = ref 42
    2. ! для чтения: !x
    3. := для записи: x := 10
    4. Инкремент: c := !c + 1

    Связанные темы: ref cells, императивное программирование, мутабельное состояние
    Время: ~10 минут *)
let counter_create (_init : int) : int ref =
  failwith "todo"

let counter_increment (_c : int ref) : unit =
  failwith "todo"

let counter_decrement (_c : int ref) : unit =
  failwith "todo"

let counter_reset (_c : int ref) : unit =
  failwith "todo"

let counter_value (_c : int ref) : int =
  failwith "todo"

(* ===== Мутабельные записи ===== *)

(* Лёгкое *)
(** Упражнение 2: Logger — логгер с мутабельным списком.

    Реализуйте простой логгер используя mutable record field.

    Тип:
    {[
      type logger = { mutable messages : string list }
    ]}

    Операции:
    - logger_create: создать пустой логгер
    - logger_log: добавить сообщение (в начало списка)
    - logger_messages: получить все сообщения
    - logger_clear: очистить все сообщения
    - logger_count: количество сообщений

    Примеры:
    {[
      let l = logger_create ()
      logger_log l "hello";
      logger_log l "world";
      logger_messages l = ["world"; "hello"]
      logger_count l = 2

      logger_clear l;
      logger_count l = 0
    ]}

    Подсказки:
    1. mutable поле модифицируется через <- : l.messages <- new_value
    2. Добавление в начало: msg :: l.messages
    3. List.length для подсчёта

    Связанные темы: mutable records, императивный стиль
    Время: ~12 минут *)
type logger = {
  mutable messages : string list;
}

let logger_create () : logger =
  failwith "todo"

let logger_log (_l : logger) (_msg : string) : unit =
  failwith "todo"

let logger_messages (_l : logger) : string list =
  failwith "todo"

let logger_clear (_l : logger) : unit =
  failwith "todo"

let logger_count (_l : logger) : int =
  failwith "todo"

(* ===== Строковое форматирование ===== *)

(* Среднее *)
(** Упражнение 3: format_table — форматирование таблицы.

    Отформатировать список пар (имя, значение) как таблицу с выравниванием.

    Требования:
    - Колонки разделены " | "
    - Первая колонка выровнена по левому краю
    - Вторая колонка выровнена по правому краю
    - Найти максимальную ширину каждой колонки

    Примеры:
    {[
      format_table [("Name", "Alice"); ("Age", "30")]
        = "Name | Alice\nAge  |    30"

      format_table [("City", "Boston"); ("State", "MA")]
        = "City  | Boston\nState |     MA"
    ]}

    Подсказки:
    1. List.fold_left для поиска максимальной длины
    2. String.length для длины строки
    3. Printf.sprintf "%-*s | %*s" width1 str1 width2 str2 для форматирования
    4. %-*s — выравнивание влево, %*s — выравнивание вправо
    5. String.concat "\n" для объединения строк

    Связанные темы: String formatting, Printf, alignment
    Время: ~15 минут *)
let format_table (_rows : (string * string) list) : string =
  failwith "todo"

(* ===== Циклы ===== *)

(* Лёгкое *)
(** Упражнение 4: array_sum_imperative — сумма массива через for.

    Посчитать сумму элементов массива используя императивный цикл for.

    Примеры:
    {[
      array_sum_imperative [|1; 2; 3; 4|] = 10
      array_sum_imperative [||] = 0
    ]}

    Подсказки:
    1. Используйте let sum = ref 0
    2. for i = 0 to Array.length arr - 1 do ... done
    3. arr.(i) для доступа к элементу
    4. sum := !sum + arr.(i)

    Связанные темы: for loops, ref cells, arrays
    Время: ~5 минут *)
let array_sum_imperative (_arr : int array) : int =
  failwith "todo"

(* ===== Глобальное состояние ===== *)

(* Среднее *)
(** Упражнение 5: Robot Name — уникальные имена роботов.

    Генерировать уникальные случайные имена для роботов.

    Формат имени: XX###, где X — заглавная буква, # — цифра
    Примеры: "AB123", "ZY987"

    Операции:
    - create: создать робота с уникальным именем
    - name: получить имя робота
    - reset: сгенерировать новое уникальное имя

    Глобальное состояние:
    - _used_names: Hashtbl для отслеживания использованных имён

    Примеры:
    {[
      let r1 = Robot.create ()
      let r2 = Robot.create ()
      (* Имена разные *)
      Robot.name r1 <> Robot.name r2

      let r3 = Robot.reset r1
      (* Новое имя отличается от старого *)
      Robot.name r3 <> Robot.name r1
    ]}

    Подсказки:
    1. Random.int для генерации случайных чисел
    2. Char.chr (Char.code 'A' + Random.int 26) для случайной буквы
    3. Printf.sprintf "%c%c%d%d%d" для форматирования
    4. Hashtbl.mem для проверки наличия
    5. Hashtbl.add для добавления
    6. Рекурсия для повтора при коллизии

    Связанные темы: Random, Hashtbl, global state, uniqueness
    Время: ~20 минут *)
module Robot = struct
  type t = { name : string }
  let _used_names : (string, unit) Hashtbl.t = Hashtbl.create 100

  let create () : t = failwith "todo"
  let name (_robot : t) : string = failwith "todo"
  let reset (_robot : t) : t = failwith "todo"
end

(* ===== Сложные структуры данных ===== *)

(* Сложное *)
(** Упражнение 6: LRU Cache — простой LRU кэш.

    Реализовать кэш с политикой вытеснения LRU (Least Recently Used).

    Структура:
    {[
      type ('k, 'v) t = {
        mutable entries : ('k * 'v) list;
        capacity : int;
      }
    ]}

    Операции:
    - create capacity: создать кэш с заданной вместимостью
    - get cache key: получить значение (перемещает в начало)
    - put cache key value: добавить/обновить (вытесняет старый если полный)
    - size: количество элементов

    Алгоритм LRU:
    - Недавно использованные элементы — в начале списка
    - При get: переместить элемент в начало
    - При put: если есть — обновить и переместить в начало
    - При put нового: если размер = capacity, удалить последний (самый старый)

    Примеры:
    {[
      let cache = LRU.create 2
      LRU.put cache "a" 1;
      LRU.put cache "b" 2;
      LRU.get cache "a" = Some 1  (* "a" теперь свежий *)

      LRU.put cache "c" 3;  (* вытеснит "b" *)
      LRU.get cache "b" = None
      LRU.get cache "a" = Some 1
      LRU.get cache "c" = Some 3
    ]}

    Подсказки:
    1. List.find_opt для поиска по ключу
    2. List.filter для удаления элемента
    3. Новый элемент добавляется в начало: (key, value) :: rest
    4. List.length для проверки размера
    5. Если размер > capacity: удалить последний через List.rev |> List.tl |> List.rev
       или лучше: List.take (capacity - 1)

    Связанные темы: LRU cache, mutable data structures, algorithms
    Время: ~35 минут *)
module LRU = struct
  type ('k, 'v) t = {
    mutable entries : ('k * 'v) list;
    capacity : int;
  }

  let create (_capacity : int) : ('k, 'v) t = failwith "todo"
  let get (_cache : ('k, 'v) t) (_key : 'k) : 'v option = failwith "todo"
  let put (_cache : ('k, 'v) t) (_key : 'k) (_value : 'v) : unit = failwith "todo"
  let size (_cache : ('k, 'v) t) : int = failwith "todo"
end

(* ===== Functional Core / Imperative Shell ===== *)

(* Среднее *)
(** Упражнение 7: Logger FC/IS — Functional Core + Imperative Shell.

    Реализовать логгер в стиле FC/IS:
    - LoggerPure: чистые функции, работающие со списком
    - LoggerShell: императивная оболочка с mutable state

    LoggerPure (Functional Core):
    - add: добавить сообщение в список (чистая функция)
    - count: подсчитать сообщения
    - messages: вернуть список

    LoggerShell (Imperative Shell):
    - create: создать логгер
    - log: добавить сообщение (использует LoggerPure.add)
    - messages/count/clear: методы с mutable state

    Примеры:
    {[
      (* Pure *)
      LoggerPure.add [] "hello" = ["hello"]
      LoggerPure.count ["a"; "b"] = 2

      (* Shell *)
      let l = LoggerShell.create ()
      LoggerShell.log l "test";
      LoggerShell.count l = 1
    ]}

    Подсказки:
    1. LoggerPure — все функции чистые, принимают и возвращают список
    2. LoggerShell.log вызывает LoggerPure.add: l.msgs <- LoggerPure.add l.msgs msg
    3. Разделение логики и побочных эффектов

    Связанные темы: Functional Core / Imperative Shell, architecture patterns
    Время: ~18 минут *)
module LoggerPure = struct
  let add (_msgs : string list) (_msg : string) : string list = failwith "todo"
  let count (_msgs : string list) : int = failwith "todo"
  let messages (_msgs : string list) : string list = failwith "todo"
end

module LoggerShell = struct
  type t = { mutable msgs : string list }
  let create () : t = failwith "todo"
  let log (_l : t) (_msg : string) : unit = failwith "todo"
  let messages (_l : t) : string list = failwith "todo"
  let count (_l : t) : int = failwith "todo"
  let clear (_l : t) : unit = failwith "todo"
end

(* ===== Конечные автоматы ===== *)

(* Сложное *)
(** Упражнение 8: Bowling — подсчёт очков в боулинге.

    Реализовать систему подсчёта очков для боулинга.

    Правила боулинга:
    - 10 фреймов
    - В каждом фрейме: до 2 бросков (или 1 если strike)
    - Strike: все 10 кеглей с первого броска
      Бонус: следующие 2 броска
    - Spare: все 10 кеглей за 2 броска
      Бонус: следующий 1 бросок
    - 10-й фрейм: если strike/spare — дополнительные броски

    Структура:
    {[
      type t = {
        mutable rolls : int list;  (* все броски *)
        mutable current_frame : int;
        mutable finished : bool;
      }
    ]}

    Операции:
    - create: создать новую игру
    - roll pins: записать бросок (валидация)
    - score: подсчитать общий счёт

    Валидация:
    - pins должен быть 0..10
    - Сумма двух бросков в фрейме <= 10
    - Нельзя бросать после окончания игры

    Примеры:
    {[
      let g = Bowling.create ()
      (* Все броски по 1 кегле *)
      for i = 1 to 20 do
        ignore (Bowling.roll g 1)
      done;
      Bowling.score g = 20

      (* Perfect game: 12 strikes *)
      let g2 = Bowling.create ()
      for i = 1 to 12 do
        ignore (Bowling.roll g2 10)
      done;
      Bowling.score g2 = 300
    ]}

    Подсказки:
    1. Храните все броски в списке
    2. roll: добавляет бросок, проверяет валидность
    3. score: проходит по фреймам, суммирует с бонусами
    4. Strike: if rolls.(i) = 10 then бонус = rolls.(i+1) + rolls.(i+2)
    5. Spare: if rolls.(i) + rolls.(i+1) = 10 then бонус = rolls.(i+2)
    6. 10-й фрейм — особая логика

    Связанные темы: State machines, game scoring, validation, complex rules
    Время: ~40 минут *)
module Bowling = struct
  type t = {
    mutable rolls : int list;
    mutable current_frame : int;
    mutable finished : bool;
  }

  let create () : t = failwith "todo"
  let roll (_game : t) (_pins : int) : (unit, string) result = failwith "todo"
  let score (_game : t) : int = failwith "todo"
end
