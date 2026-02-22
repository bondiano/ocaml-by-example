(** Здесь вы можете писать свои решения упражнений. *)

(* ====================================================================== *)
(*  JSON-упражнения (1–4)                                                  *)
(* ====================================================================== *)

(* ===== Ручная сериализация ===== *)

(* Лёгкое *)
(** Упражнение 1: product_to_json — преобразование record в JSON.

    Вручную создать JSON объект из записи product.

    Тип product:
    {[
      type product = {
        title    : string;
        price    : float;
        in_stock : bool;
      }
    ]}

    Должны получить JSON:
    {[
      {
        "title": "...",
        "price": ...,
        "in_stock": true/false
      }
    ]}

    Примеры:
    {[
      let p = { title = "Laptop"; price = 999.99; in_stock = true }
      product_to_json p = `Assoc [
        ("title", `String "Laptop");
        ("price", `Float 999.99);
        ("in_stock", `Bool true)
      ]
    ]}

    Подсказки:
    1. Yojson.Safe.t — это полиморфный вариант
    2. `Assoc [(key, value); ...] для объектов
    3. `String, `Float, `Bool для значений
    4. Структура:
       `Assoc [
         ("title", `String p.title);
         ("price", `Float p.price);
         ("in_stock", `Bool p.in_stock)
       ]

    Связанные темы: JSON serialization, Yojson, manual encoding
    Время: ~8 минут *)
type product = {
  title    : string;
  price    : float;
  in_stock : bool;
}

let product_to_json (_p : product) : Yojson.Safe.t =
  failwith "todo"

(* Среднее *)
(** Упражнение 2: product_of_json — парсинг JSON в record.

    Преобразовать JSON объект в record product с валидацией.

    Возможные ошибки:
    - Не объект (`Assoc)
    - Отсутствуют обязательные поля
    - Неверный тип значения

    Примеры:
    {[
      let json = `Assoc [
        ("title", `String "Laptop");
        ("price", `Float 999.99);
        ("in_stock", `Bool true)
      ]
      product_of_json json = Ok { title = "Laptop"; price = 999.99; in_stock = true }

      product_of_json (`String "invalid") = Error "expected object"
      product_of_json (`Assoc []) = Error "missing field: title"
    ]}

    Подсказки:
    1. Pattern match на `Assoc fields
    2. List.assoc_opt для поиска полей
    3. Валидация типов: match value with `String s -> ... | _ -> Error
    4. Структура:
       {[
         match json with
         | `Assoc fields ->
             (match List.assoc_opt "title" fields with
              | Some (`String title) -> ...
              | Some _ -> Error "title must be string"
              | None -> Error "missing field: title")
         | _ -> Error "expected object"
       ]}
    5. Можно использовать Result.bind или let* для композиции

    Связанные темы: JSON deserialization, validation, Result type
    Время: ~15 минут *)
let product_of_json (_json : Yojson.Safe.t) : (product, string) result =
  failwith "todo"

(* Лёгкое *)
(** Упражнение 3: extract_names — извлечь имена из JSON массива.

    Дан JSON массив объектов с полем "name", извлечь все имена.

    Примеры:
    {[
      let json = `List [
        `Assoc [("name", `String "Alice"); ("age", `Int 30)];
        `Assoc [("name", `String "Bob"); ("age", `Int 25)]
      ]
      extract_names json = ["Alice"; "Bob"]

      extract_names (`List []) = []
    ]}

    Подсказки:
    1. Pattern match на `List items
    2. List.filter_map для извлечения имён
    3. Для каждого item:
       match item with
       | `Assoc fields ->
           (match List.assoc_opt "name" fields with
            | Some (`String name) -> Some name
            | _ -> None)
       | _ -> None
    4. Если не `List, вернуть []

    Связанные темы: JSON traversal, pattern matching, List.filter_map
    Время: ~8 минут *)
let extract_names (_json : Yojson.Safe.t) : string list =
  failwith "todo"

(* Лёгкое *)
(** Упражнение 4: config с ppx_yojson_conv — автоматическая сериализация.

    Тип config уже аннотирован [@@deriving yojson].
    ppx_yojson_conv автоматически генерирует:
    - config_to_yojson : config -> Yojson.Safe.t
    - config_of_yojson : Yojson.Safe.t -> (config, string) result

    Ничего делать не нужно! Функции уже сгенерированы.

    Примеры использования:
    {[
      let c = { host = "localhost"; port = 8080; debug = true }
      let json = config_to_yojson c
      (* `Assoc [("host", `String "localhost"); ("port", `Int 8080); ("debug", `Bool true)] *)

      let c2 = config_of_yojson json
      (* Ok { host = "localhost"; port = 8080; debug = true } *)
    ]}

    Подсказка: это упражнение демонстрирует использование ppx_yojson_conv.
    Функции уже доступны автоматически благодаря [@@deriving yojson].

    Связанные темы: ppx, code generation, automatic serialization
    Время: ~5 минут (просто понимание) *)
type config = {
  host  : string;
  port  : int;
  debug : bool;
} [@@deriving yojson]

(* ====================================================================== *)
(*  FFI-упражнения (5–7)                                                   *)
(*                                                                         *)
(*  Откройте lib/stubs.c и прочитайте реализации C-функций перед           *)
(*  тем, как писать привязки. Каждый комментарий в stubs.c объясняет,      *)
(*  какие макросы и функции OCaml C API использованы.                      *)
(* ====================================================================== *)

(* ===== FFI: Простые привязки ===== *)

(* Лёгкое *)
(** Упражнение 5: count_char — привязка к C функции подсчёта символов.

    Прочитайте сигнатуру в lib/stubs.c:
    {[
      CAMLprim value caml_count_char(value str, value ch)
    ]}

    C-функция:
    - Принимает строку (String_val) и символ (Int_val)
    - Возвращает количество вхождений (Val_int)

    Задача: заменить let на external объявление.

    Формат external:
    {[
      external count_char : string -> char -> int = "caml_count_char"
    ]}

    Примеры:
    {[
      count_char "hello" 'l' = 2
      count_char "OCaml" 'a' = 1
      count_char "test" 'x' = 0
    ]}

    Подсказки:
    1. external name : тип = "имя_C_функции"
    2. Типы OCaml соответствуют:
       - string -> String_val в C
       - char -> Int_val в C (char хранится как int)
       - int возвращается как Val_int из C
    3. Имя C функции: "caml_count_char"

    Связанные темы: FFI, external declarations, C bindings
    Время: ~8 минут *)
let count_char (_s : string) (_c : char) : int =
  failwith "todo"
(* Замените строку выше на:
   external count_char : string -> char -> int = "caml_count_char" *)

(* Среднее *)
(** Упражнение 6: str_repeat — привязка к C с безопасной обёрткой.

    Прочитайте сигнатуру в lib/stubs.c:
    {[
      CAMLprim value caml_str_repeat(value str, value n)
    ]}

    C-функция:
    - Повторяет строку n раз
    - n <= 0 → возвращает пустую строку (обработано в C)

    Задача состоит из двух шагов:

    Шаг A: создать raw привязку
    {[
      external raw_str_repeat : string -> int -> string = "caml_str_repeat"
    ]}

    Шаг Б: создать безопасную обёртку str_repeat
    - Если n < 0, вернуть ""
    - Иначе вызвать raw_str_repeat

    Примеры:
    {[
      str_repeat "ab" 3 = "ababab"
      str_repeat "x" 0 = ""
      str_repeat "hello" (-5) = ""  (* безопасная обёртка *)
    ]}

    Подсказки:
    1. Шаг A: external raw_str_repeat : string -> int -> string = "caml_str_repeat"
    2. Шаг Б: if n < 0 then "" else raw_str_repeat s n
    3. Обёртка добавляет дополнительную валидацию

    Связанные темы: FFI, safe wrappers, input validation
    Время: ~12 минут *)
let raw_str_repeat (_s : string) (_n : int) : string =
  failwith "todo"
(* Шаг A: замените строку выше на:
   external raw_str_repeat : string -> int -> string = "caml_str_repeat" *)

let str_repeat (_s : string) (_n : int) : string =
  failwith "todo"

(* Среднее *)
(** Упражнение 7: sum_int_array + mean — FFI с вычислением среднего.

    Прочитайте сигнатуру в lib/stubs.c:
    {[
      CAMLprim value caml_sum_int_array(value arr)
    ]}

    C-функция:
    - Принимает массив целых чисел
    - Возвращает сумму элементов

    Задача состоит из двух шагов:

    Шаг A: создать FFI привязку
    {[
      external raw_sum_int_array : int array -> int = "caml_sum_int_array"
    ]}

    Шаг Б: реализовать mean : int array -> float option
    - Для пустого массива: None
    - Для непустого: Some (сумма / длина)

    Примеры:
    {[
      mean [|1; 2; 3; 4|] = Some 2.5
      mean [|10; 20|] = Some 15.0
      mean [||] = None
    ]}

    Подсказки:
    1. Шаг A: external raw_sum_int_array : int array -> int = "caml_sum_int_array"
    2. Шаг Б:
       - Array.length arr для получения длины
       - if Array.length arr = 0 then None
       - else Some (float_of_int (raw_sum_int_array arr) /. float_of_int (Array.length arr))
    3. Используйте float_of_int для преобразования в float
    4. Оператор /. для деления float

    Связанные темы: FFI, arrays, statistical computations
    Время: ~15 минут *)
let raw_sum_int_array (_arr : int array) : int =
  failwith "todo"
(* Шаг A: замените строку выше на:
   external raw_sum_int_array : int array -> int = "caml_sum_int_array" *)

let mean (_arr : int array) : float option =
  failwith "todo"
