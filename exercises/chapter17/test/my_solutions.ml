(** Здесь вы можете писать свои решения упражнений. *)

(* ===== Angstrom парсинг ===== *)

(* Среднее *)
(** Упражнение 1: int_list_parser — парсер списка целых чисел.

    Распарсить строку вида "[1, 2, 3]" в список [1; 2; 3].

    Формат:
    - Квадратные скобки [ ]
    - Числа разделены запятыми и опциональными пробелами
    - Может быть пустой список []

    Примеры:
    {[
      Angstrom.parse_string ~consume:All int_list_parser "[1, 2, 3]" = Ok [1; 2; 3]
      Angstrom.parse_string ~consume:All int_list_parser "[]" = Ok []
      Angstrom.parse_string ~consume:All int_list_parser "[42]" = Ok [42]
    ]}

    Подсказки:
    1. Angstrom.char '[' для начала
    2. Angstrom.sep_by для списка с разделителями:
       sep_by (char ',' *> skip_while (fun c -> c = ' ')) int_parser
    3. Angstrom.char ']' для конца
    4. Angstrom.int для парсинга чисел
    5. Комбинаторы:
       {[
         let* _ = char '[' in
         let* numbers = sep_by (char ',' *> skip_while ...) int in
         let* _ = char ']' in
         return numbers
       ]}

    Связанные темы: Angstrom, parser combinators, list parsing
    Время: ~15 минут *)
let int_list_parser : int list Angstrom.t =
  Angstrom.fail "todo"

(* Лёгкое *)
(** Упражнение 2: key_value_parser — парсер пар "key=value".

    Распарсить строку вида "name=John" в ("name", "John").

    Формат:
    - Ключ: буквы и цифры
    - Знак равенства =
    - Значение: любые символы до конца строки

    Примеры:
    {[
      Angstrom.parse_string ~consume:All key_value_parser "name=John" = Ok ("name", "John")
      Angstrom.parse_string ~consume:All key_value_parser "age=25" = Ok ("age", "25")
    ]}

    Подсказки:
    1. Angstrom.take_while1 для ключа:
       take_while1 (fun c -> Char.is_alphanum c)
    2. Angstrom.char '=' для разделителя
    3. Angstrom.take_till (fun c -> c = '\n') для значения
    4. Или просто take_while (fun _ -> true) для всех символов
    5. Комбинаторы:
       {[
         let* key = take_while1 Char.is_alphanum in
         let* _ = char '=' in
         let* value = take_while (fun _ -> true) in
         return (key, value)
       ]}

    Связанные темы: Angstrom, key-value parsing, simple combinators
    Время: ~10 минут *)
let key_value_parser : (string * string) Angstrom.t =
  Angstrom.fail "todo"

(* ===== GADT ===== *)

(* Среднее *)
(** Упражнение 3: eval_extended — GADT с оператором Not.

    Расширить evaluator для GADT выражений, добавив оператор Not.

    Тип extended_expr:
    {[
      type _ extended_expr =
        | Int : int -> int extended_expr
        | Bool : bool -> bool extended_expr
        | Add : int extended_expr * int extended_expr -> int extended_expr
        | Not : bool extended_expr -> bool extended_expr
        | Gt : int extended_expr * int extended_expr -> bool extended_expr
    ]}

    GADT гарантирует type safety на уровне типов:
    - Int _ : int extended_expr
    - Bool _ : bool extended_expr
    - Add всегда возвращает int
    - Not всегда возвращает bool

    Примеры:
    {[
      eval_extended (Int 42) = 42
      eval_extended (Bool true) = true
      eval_extended (Add (Int 2, Int 3)) = 5
      eval_extended (Not (Bool false)) = true
      eval_extended (Gt (Int 5, Int 3)) = true
    ]}

    Подсказки:
    1. Используйте type a. для полиморфной функции
    2. Pattern matching на GADT:
       {[
         let eval_extended : type a. a extended_expr -> a = function
           | Int n -> n
           | Bool b -> b
           | Add (a, b) -> eval_extended a + eval_extended b
           | Not a -> not (eval_extended a)
           | Gt (a, b) -> eval_extended a > eval_extended b
       ]}
    3. Компилятор гарантирует что типы совпадают

    Связанные темы: GADT, type safety, pattern matching
    Время: ~15 минут *)
type _ extended_expr =
  | Int : int -> int extended_expr
  | Bool : bool -> bool extended_expr
  | Add : int extended_expr * int extended_expr -> int extended_expr
  | Not : bool extended_expr -> bool extended_expr
  | Gt : int extended_expr * int extended_expr -> bool extended_expr

let eval_extended : type a. a extended_expr -> a = function
  | _ -> failwith "todo"

(* ===== Сложный парсинг ===== *)

(* Сложное *)
(** Упражнение 4: arith_parser — парсер арифметических выражений.

    Распарсить и вычислить выражение с операторами + и *.

    Правила приоритета:
    - * имеет больший приоритет чем +
    - Скобки переопределяют приоритет

    Примеры:
    {[
      Angstrom.parse_string ~consume:All arith_parser "2+3" = Ok 5
      Angstrom.parse_string ~consume:All arith_parser "2*3+4" = Ok 10  (* (2*3)+4 *)
      Angstrom.parse_string ~consume:All arith_parser "2+3*4" = Ok 14  (* 2+(3*4) *)
      Angstrom.parse_string ~consume:All arith_parser "(2+3)*4" = Ok 20
    ]}

    Подсказки:
    1. Используйте рекурсивные парсеры с fix:
       {[
         Angstrom.fix (fun expr ->
           (* определение парсера *)
         )
       ]}
    2. Грамматика:
       {[
         expr   ::= term ('+' term)*
         term   ::= factor ('*' factor)*
         factor ::= number | '(' expr ')'
       ]}
    3. chainl1 для левоассоциативных операторов
    4. Пример структуры:
       {[
         let number = Angstrom.int in
         let factor = ... in
         let term = chainl1 factor (char '*' *> return ( * )) in
         let expr = chainl1 term (char '+' *> return (+)) in
       ]}
    5. Не забудьте skip_whitespace между токенами

    Связанные темы: Recursive parsers, operator precedence, expression parsing
    Время: ~30 минут *)
let arith_parser : int Angstrom.t =
  Angstrom.fail "todo"

(* ===== Строковые алгоритмы ===== *)

(* Среднее *)
(** Упражнение 5: matching_brackets — проверка парности скобок.

    Проверить что все скобки (), [], {} правильно вложены и закрыты.

    Правила:
    - Каждая открывающая скобка должна иметь соответствующую закрывающую
    - Скобки должны быть правильно вложены
    - Игнорировать все символы кроме скобок

    Примеры:
    {[
      matching_brackets "()" = true
      matching_brackets "()[]" = true
      matching_brackets "({[]})" = true
      matching_brackets "([)]" = false  (* неправильное вложение *)
      matching_brackets "(((" = false  (* не закрыты *)
      matching_brackets "hello (world)" = true  (* игнорируем буквы *)
    ]}

    Подсказки:
    1. Используйте стек (list) для отслеживания открывающих скобок
    2. При открывающей скобке: добавить в стек
    3. При закрывающей скобке:
       - Проверить что стек не пуст
       - Проверить что верхняя скобка соответствует
       - Удалить из стека
    4. В конце стек должен быть пуст
    5. Структура:
       {[
         let rec check stack = function
           | [] -> stack = []
           | '(' :: rest -> check ('(' :: stack) rest
           | ')' :: rest ->
               (match stack with
                | '(' :: s -> check s rest
                | _ -> false)
           | _ :: rest -> check stack rest  (* игнорировать *)
       ]}

    Связанные темы: Stack-based algorithms, bracket matching, validation
    Время: ~15 минут *)
let matching_brackets (_s : string) : bool = failwith "todo"

(* Лёгкое *)
(** Упражнение 6: word_count — подсчёт частоты слов.

    Подсчитать сколько раз каждое слово встречается в строке.

    Правила:
    - Слова разделены пробелами и знаками препинания
    - Регистр не важен (case-insensitive)
    - Возвращать список пар (слово, количество)

    Примеры:
    {[
      word_count "hello world" = [("hello", 1); ("world", 1)]
      word_count "hello Hello HELLO" = [("hello", 3)]
      word_count "one, two, one!" = [("one", 2); ("two", 1)]
    ]}

    Подсказки:
    1. String.lowercase_ascii для приведения к нижнему регистру
    2. Str.split (Str.regexp "[^a-zA-Z]+") для разделения на слова
    3. Hashtbl для подсчёта частот:
       {[
         let freq = Hashtbl.create 16 in
         List.iter (fun word ->
           let count = Hashtbl.find_opt freq word |> Option.value ~default:0 in
           Hashtbl.replace freq word (count + 1)
         ) words;
         Hashtbl.to_seq freq |> List.of_seq
       ]}
    4. Или используйте List.fold_left с Map

    Связанные темы: String processing, frequency counting, Hashtbl
    Время: ~10 минут *)
let word_count (_s : string) : (string * int) list = failwith "todo"
