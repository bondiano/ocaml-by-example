(** Здесь вы можете писать свои решения упражнений. *)

(* ===== Smart Constructors ===== *)

(* Лёгкое *)
(** Упражнение 1: PositiveInt — smart constructor для положительных чисел.

    Создать абстрактный тип для строго положительных целых чисел.

    Инвариант: значение всегда > 0

    Операции:
    - make n: создать, возвращает Error если n <= 0
    - value: извлечь значение
    - add: сложить два положительных числа
    - to_string: преобразовать в строку

    Примеры:
    {[
      PositiveInt.make 5 = Ok pos_5
      PositiveInt.make 0 = Error "число должно быть положительным"
      PositiveInt.make (-3) = Error "число должно быть положительным"

      let x = Result.get_ok (PositiveInt.make 3)
      let y = Result.get_ok (PositiveInt.make 4)
      PositiveInt.value (PositiveInt.add x y) = 7
    ]}

    Подсказки:
    1. type t = int — внутреннее представление скрыто сигнатурой
    2. make: if n > 0 then Ok n else Error "..."
    3. add: просто a + b (инвариант гарантирует положительность)
    4. string_of_int для to_string

    Связанные темы: Smart constructors, type safety, invariants
    Время: ~10 минут *)
module PositiveInt : sig
  type t
  val make : int -> (t, string) result
  val value : t -> int
  val add : t -> t -> t
  val to_string : t -> string
end = struct
  type t = int
  let make _n = failwith "todo"
  let value _t = failwith "todo"
  let add _a _b = failwith "todo"
  let to_string _t = failwith "todo"
end

(* Среднее *)
(** Упражнение 2: Email — smart constructor для email-адресов.

    Создать тип для валидных email адресов.

    Правила валидации:
    - Не пустая строка → Error "email не может быть пустым"
    - Содержит '@' → Error "email должен содержать @"
    - Домен (после @) содержит '.' → Error "некорректный домен"

    Примеры:
    {[
      Email.make "user@example.com" = Ok email
      Email.make "" = Error "email не может быть пустым"
      Email.make "user.example.com" = Error "email должен содержать @"
      Email.make "user@example" = Error "некорректный домен"
    ]}

    Подсказки:
    1. String.trim для удаления пробелов
    2. String.contains s '@' для проверки наличия
    3. String.index_opt s '@' для поиска позиции
    4. String.sub для извлечения домена
    5. Проверяйте условия последовательно

    Связанные темы: Smart constructors, string validation, Result type
    Время: ~12 минут *)
module Email : sig
  type t
  val make : string -> (t, string) result
  val to_string : t -> string
end = struct
  type t = string
  let make _s = failwith "todo"
  let to_string _t = failwith "todo"
end

(* Среднее *)
(** Упражнение 3: NonEmptyList — список с гарантией непустоты.

    Создать тип списка, который гарантированно содержит хотя бы один элемент.

    Внутреннее представление: type 'a t = 'a * 'a list

    Преимущества:
    - head никогда не падает
    - tail всегда определён (может быть пустым)
    - Компилятор гарантирует инвариант

    Операции:
    - make: создать из списка (Error если пустой)
    - singleton: создать из одного элемента
    - head: первый элемент (всегда есть)
    - tail: остальные элементы (может быть [])
    - to_list: преобразовать в обычный список
    - length: длина (всегда >= 1)
    - map: применить функцию к каждому элементу

    Примеры:
    {[
      NonEmptyList.make [1; 2; 3] = Ok nel
      NonEmptyList.make [] = Error "список не может быть пустым"

      let nel = NonEmptyList.singleton 42
      NonEmptyList.head nel = 42
      NonEmptyList.tail nel = []

      let nel2 = Result.get_ok (NonEmptyList.make [1; 2; 3])
      NonEmptyList.head nel2 = 1
      NonEmptyList.tail nel2 = [2; 3]
      NonEmptyList.length nel2 = 3
    ]}

    Подсказки:
    1. make: match lst with [] -> Error | x :: xs -> Ok (x, xs)
    2. singleton x = (x, [])
    3. head (x, _) = x
    4. tail (_, xs) = xs
    5. to_list (x, xs) = x :: xs
    6. map f (x, xs) = (f x, List.map f xs)

    Связанные темы: Type-level guarantees, phantom types, smart constructors
    Время: ~20 минут *)
module NonEmptyList : sig
  type 'a t
  val make : 'a list -> ('a t, string) result
  val singleton : 'a -> 'a t
  val head : 'a t -> 'a
  val tail : 'a t -> 'a list
  val to_list : 'a t -> 'a list
  val length : 'a t -> int
  val map : ('a -> 'b) -> 'a t -> 'b t
end = struct
  type 'a t = 'a * 'a list
  let make _lst = failwith "todo"
  let singleton _x = failwith "todo"
  let head (_x, _xs) = failwith "todo"
  let tail (_x, _xs) = failwith "todo"
  let to_list (_x, _xs) = failwith "todo"
  let length (_x, _xs) = failwith "todo"
  let map _f (_x, _xs) = failwith "todo"
end

(* ===== Phantom Types ===== *)

(* Среднее *)
(** Упражнение 4: TrafficLight — светофор как конечный автомат.

    Реализовать светофор используя phantom types для обеспечения
    корректного порядка переключения состояний на уровне типов.

    Phantom types (типы-призраки):
    - type red / type yellow / type green — нет значений, только типы
    - type 'state light — параметр 'state указывает текущее состояние
    - Функции переходов типизированы: red light -> green light

    Правильный порядок:
    Red → Green → Yellow → Red → ...

    Попытка нарушить порядок (например, Red → Yellow) приведёт к ошибке компиляции.

    Операции:
    - start: начальное состояние (red light)
    - red_to_green: Red → Green
    - green_to_yellow: Green → Yellow
    - yellow_to_red: Yellow → Red
    - show: показать цвет (работает для любого состояния)

    Примеры:
    {[
      let light = TrafficLight.start
      TrafficLight.show light = "Red"

      let light = TrafficLight.red_to_green light
      TrafficLight.show light = "Green"

      let light = TrafficLight.green_to_yellow light
      TrafficLight.show light = "Yellow"

      let light = TrafficLight.yellow_to_red light
      TrafficLight.show light = "Red"

      (* Ошибка компиляции: *)
      (* TrafficLight.green_to_yellow TrafficLight.start *)
    ]}

    Подсказки:
    1. type red, yellow, green — пустые типы (phantom)
    2. type 'state light = { color : string }
    3. start = { color = "Red" } : red light
    4. Переходы просто меняют строку, но типы разные:
       red_to_green _ = { color = "Green" }
    5. show работает для любого 'state: show l = l.color

    Связанные темы: Phantom types, type-safe state machines, compile-time guarantees
    Время: ~18 минут *)
module TrafficLight : sig
  type red
  type yellow
  type green

  type 'state light

  val start : red light
  val red_to_green : red light -> green light
  val green_to_yellow : green light -> yellow light
  val yellow_to_red : yellow light -> red light
  val show : 'state light -> string
end = struct
  type red
  type yellow
  type green

  type 'state light = { color : string }

  let start = failwith "todo"
  let red_to_green _l = failwith "todo"
  let green_to_yellow _l = failwith "todo"
  let yellow_to_red _l = failwith "todo"
  let show _l = failwith "todo"
end

(* ===== Applicative Validation ===== *)

(* Сложное *)
(** Упражнение 5: Form — строитель формы с аккумуляцией ошибок.

    Создать систему валидации форм в applicative стиле,
    которая накапливает все ошибки вместо остановки на первой.

    Тип:
    {[
      type 'a validated = ('a, (string * string) list) result
      (* Ok значение | Error [(имя_поля, ошибка); ...] *)
    ]}

    Операции:
    - field name raw_value parser: валидировать одно поле
    - map2: комбинировать два поля (накапливая ошибки)
    - map3: комбинировать три поля
    - run: вернуть итоговый результат

    Ключевая идея:
    - При комбинировании (Ok, Ok) → Ok (применить функцию)
    - При комбинировании с Error → накопить все ошибки

    Примеры:
    {[
      (* Парсер для positive int *)
      let parse_positive s =
        match int_of_string_opt s with
        | Some n when n > 0 -> Ok n
        | _ -> Error "должно быть положительное число"

      (* Валидация одного поля *)
      let age_field = Form.field "age" "25" parse_positive
      Form.run age_field = Ok 25

      let bad_age = Form.field "age" "abc" parse_positive
      Form.run bad_age = Error [("age", "должно быть положительное число")]

      (* Комбинирование нескольких полей *)
      type person = { name : string; age : int }

      let person_form =
        Form.map2
          (fun name age -> { name; age })
          (Form.field "name" "Alice" (fun s -> if s <> "" then Ok s else Error "не должно быть пустым"))
          (Form.field "age" "25" parse_positive)

      Form.run person_form = Ok { name = "Alice"; age = 25 }

      (* Несколько ошибок накапливаются *)
      let bad_form =
        Form.map2
          (fun name age -> { name; age })
          (Form.field "name" "" (fun s -> if s <> "" then Ok s else Error "пустое"))
          (Form.field "age" "-5" parse_positive)

      Form.run bad_form = Error [("name", "пустое"); ("age", "должно быть положительное число")]
    ]}

    Подсказки:
    1. field: применить parser, обернуть ошибку с именем поля
       match parser raw with
       | Ok v -> Ok v
       | Error e -> Error [(name, e)]
    2. map2: комбинировать результаты
       match a, b with
       | Ok va, Ok vb -> Ok (f va vb)
       | Error ea, Error eb -> Error (ea @ eb)
       | Error e, _ | _, Error e -> Error e
    3. map3: аналогично map2, но для трёх значений
    4. run v = v (просто вернуть)

    Связанные темы: Applicative functors, error accumulation, form validation
    Время: ~35 минут *)
