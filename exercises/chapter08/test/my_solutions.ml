(** Здесь вы можете писать свои решения упражнений. *)

open Chapter08.Validation

(* ===== Базовая валидация ===== *)

(* Среднее *)
(** Упражнение 1: validate_phone — валидация номера телефона.

    Проверить что номер телефона валиден:
    - Формат: (XXX) XXX-XXXX где X — цифра
    - Или: XXX-XXX-XXXX
    - Или: 10 цифр подряд

    Возвращать:
    - Ok normalized_phone (формат: "XXXXXXXXXX")
    - Error [список ошибок]

    Примеры:
    {[
      validate_phone "(123) 456-7890" = Ok "1234567890"
      validate_phone "123-456-7890" = Ok "1234567890"
      validate_phone "1234567890" = Ok "1234567890"
      validate_phone "123" = Error ["недостаточно цифр"]
      validate_phone "abc" = Error ["телефон должен содержать только цифры"]
    ]}

    Подсказки:
    1. String.filter_map для извлечения только цифр
    2. Проверьте длину: должно быть ровно 10 цифр
    3. Char.code c >= Char.code '0' && c <= Char.code '9' для проверки цифры
    4. Можно использовать Str.regexp если хотите

    Связанные темы: Result type, string processing, validation
    Время: ~12 минут *)
let validate_phone (_phone : string) : (string, string list) result =
  failwith "todo"

(* Среднее *)
(** Упражнение 2: validate_person — валидация всех полей person.

    Проверить все поля записи person:
    - first: не пустое, только буквы
    - last: не пустое, только буквы
    - street: не пустое
    - city: не пустое, только буквы
    - state: ровно 2 заглавные буквы (например, "CA", "NY")

    Тип person определён в lib/validation.ml:
    {[
      type person = {
        first : string;
        last : string;
        address : address;
      }
      and address = {
        street : string;
        city : string;
        state : string;
      }
    ]}

    Если есть ошибки — вернуть Error со списком всех ошибок.
    Если всё валидно — вернуть Ok person.

    Примеры:
    {[
      validate_person "John" "Doe" "123 Main St" "Boston" "MA"
        = Ok {first = "John"; last = "Doe"; address = {...}}

      validate_person "" "Doe" "123 Main St" "Boston" "MA"
        = Error ["first name cannot be empty"]

      validate_person "John" "123" "123 Main St" "Boston" "MASS"
        = Error ["last name must contain only letters"; "state must be 2 letters"]
    ]}

    Подсказки:
    1. Создайте вспомогательные функции для каждого поля
    2. Используйте Result.bind или let* для комбинирования
    3. Либо соберите все ошибки сразу (applicative style)
    4. String.for_all для проверки "все символы — буквы"

    Связанные темы: Applicative validation, error accumulation, records
    Время: ~20 минут *)
let validate_person (_first : string) (_last : string)
    (_street : string) (_city : string) (_state : string)
    : (person, string list) result =
  failwith "todo"

(* ===== Traverse и конверсии ===== *)

(* Сложное *)
(** Упражнение 3: traverse_result — applicative traversal для Result.

    "Перевернуть" типы: из list of results в result of list.

    Семантика:
    - Если все Ok — вернуть Ok [список значений]
    - Если хотя бы один Error — вернуть Error [все ошибки]

    Это обобщённая версия: функция f возвращает Result.

    Примеры:
    {[
      let parse_int s = try Ok (int_of_string s) with _ -> Error ["not an int"]

      traverse_result parse_int ["1"; "2"; "3"]
        = Ok [1; 2; 3]

      traverse_result parse_int ["1"; "x"; "3"; "y"]
        = Error ["not an int"; "not an int"]  (* все ошибки собраны *)
    ]}

    Подсказки:
    1. Используйте List.fold_left или List.fold_right
    2. Накапливайте значения и ошибки отдельно
    3. Паттерн: match f x with Ok v -> ... | Error e -> ...
    4. Для аккумуляции ошибок: errors @ new_errors
    5. В конце: if errors = [] then Ok values else Error errors

    Связанные темы: Traversable, applicative functors, error accumulation
    Время: ~30 минут *)
let traverse_result : ('a -> ('b, 'e) result) -> 'a list -> ('b list, 'e list) result =
  fun _f _lst -> failwith "todo"

(* Лёгкое *)
(** Упражнение 4: option_to_result — конвертировать Option в Result.

    Превратить None в Error с заданным сообщением.

    Примеры:
    {[
      option_to_result ~error:"not found" (Some 42) = Ok 42
      option_to_result ~error:"not found" None = Error "not found"
    ]}

    Подсказка: простой pattern matching на Some/None
    Время: ~5 минут *)
let option_to_result ~error:(_error : 'e) (_opt : 'a option) : ('a, 'e) result =
  failwith "todo"

(* Лёгкое *)
(** Упражнение 5: result_to_option — конвертировать Result в Option.

    Отбросить информацию об ошибке, превратить Error в None.

    Примеры:
    {[
      result_to_option (Ok 42) = Some 42
      result_to_option (Error "oops") = None
    ]}

    Подсказка: match на Ok/Error
    Время: ~5 минут *)
let result_to_option (_r : ('a, 'e) result) : 'a option =
  failwith "todo"

(* ===== Алгоритмы валидации ===== *)

(* Среднее *)
(** Упражнение 6: ISBN Verifier — проверка ISBN-10.

    ISBN-10 состоит из 9 цифр + контрольная цифра (может быть X = 10).

    Алгоритм проверки:
    1. Извлечь 10 символов (игнорируя дефисы)
    2. Контрольная сумма: (d1×10 + d2×9 + ... + d10×1) mod 11 = 0
    3. X в последней позиции = 10

    Примеры:
    {[
      isbn_verifier "3-598-21508-8" = true   (* валидный ISBN *)
      isbn_verifier "3-598-21508-9" = false  (* неверная контрольная сумма *)
      isbn_verifier "3-598-2150X-8" = false  (* X не в конце *)
      isbn_verifier "359821508X" = true      (* X = 10, валидный *)
      isbn_verifier "123" = false            (* слишком короткий *)
    ]}

    Подсказки:
    1. Удалите дефисы: String.filter (fun c -> c <> '-')
    2. Проверьте длину = 10
    3. Последний символ может быть 'X', остальные — цифры
    4. Посчитайте взвешенную сумму: List.fold_left2
    5. Веса: [10; 9; 8; 7; 6; 5; 4; 3; 2; 1]

    Связанные темы: String processing, checksum algorithms, validation
    Время: ~20 минут *)
let isbn_verifier (_isbn : string) : bool = failwith "todo"

(* Среднее *)
(** Упражнение 7: Luhn algorithm — алгоритм Луна.

    Используется для валидации номеров кредитных карт.

    Алгоритм:
    1. Удалить пробелы
    2. Проверить: минимум 2 цифры, только цифры
    3. Справа налево:
       - Каждую вторую цифру умножить на 2
       - Если результат > 9, вычесть 9 (или сложить цифры)
    4. Сумма всех цифр должна делиться на 10

    Примеры:
    {[
      luhn "4539 3195 0343 6467" = true   (* валидная карта Visa *)
      luhn "8273 1232 7352 0569" = false  (* неверная контрольная сумма *)
      luhn "1" = false                    (* слишком короткий *)
      luhn "0000 0000 0000 0000" = true   (* всё нули — валидно *)
      luhn "059a" = false                 (* не только цифры *)
    ]}

    Подсказки:
    1. String.filter (fun c -> c <> ' ') для удаления пробелов
    2. String.length >= 2 для проверки длины
    3. List.filteri для обработки каждой второй цифры
    4. Для удвоенной цифры: if d * 2 > 9 then d * 2 - 9 else d * 2
    5. List.fold_left (+) 0 для суммы
    6. sum mod 10 = 0

    Связанные темы: Checksum algorithms, string processing
    Время: ~18 минут *)
let luhn (_number : string) : bool = failwith "todo"

(* ===== Полиморфные варианты ===== *)

(* Среднее *)
(** Упражнение 8: validate_email — валидация email с полиморфными вариантами.

    Проверить email адрес и вернуть специфичные ошибки.

    Правила:
    - Не пустой
    - Содержит '@'
    - Часть после @ (домен) не пустая
    - Домен должен содержать '.' (например, example.com)

    Типы ошибок (полиморфные варианты):
    - `EmptyEmail: пустая строка
    - `NoAtSign: нет символа @
    - `InvalidDomain of string: неверный домен (передать домен в конструкторе)

    Примеры:
    {[
      validate_email "user@example.com" = Ok "user@example.com"
      validate_email "" = Error `EmptyEmail
      validate_email "userexample.com" = Error `NoAtSign
      validate_email "user@" = Error (`InvalidDomain "")
      validate_email "user@example" = Error (`InvalidDomain "example")
    ]}

    Подсказки:
    1. String.trim для удаления пробелов
    2. String.index_opt для поиска '@'
    3. String.sub для извлечения домена
    4. String.contains для проверки '.' в домене
    5. Используйте полиморфные варианты: `EmptyEmail, `NoAtSign, `InvalidDomain _

    Связанные темы: Polymorphic variants, extensible errors, validation
    Время: ~15 минут *)
let validate_email (_email : string)
    : (string, [> `EmptyEmail | `NoAtSign | `InvalidDomain of string]) result =
  failwith "todo"
