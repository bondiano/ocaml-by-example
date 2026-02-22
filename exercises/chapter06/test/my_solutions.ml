(** Здесь вы можете писать свои решения упражнений. *)

open Chapter06.Path

(* ===== Работа с рекурсивными структурами данных ===== *)

(* Среднее *)
(** Упражнение: All Files — извлечь все файлы из дерева.

    Дано: дерево файловой системы (path).
    Найти: список всех файлов (не директорий).

    Типы определены в lib/path.ml:
    {[
      type path = File of string | Directory of string * path list
    ]}

    Подсказки:
    1. Используйте all_paths для получения всех путей
    2. Фильтруйте через is_directory
    3. Композиция: all_paths p |> List.filter (fun p -> not (is_directory p))

    Время: ~12 минут *)
let all_files (_p : path) : path list =
  failwith "todo"

(* Среднее *)
(** Упражнение: Largest File — найти файл с наибольшим размером.

    Дано: дерево файловой системы.
    Найти: файл с максимальным размером и сам размер.
    Вернуть: None если нет файлов.

    Подсказки:
    1. Получите все файлы через all_files
    2. Используйте List.filter_map с file_size
    3. List.fold_left для поиска максимума
    4. Обработайте пустой список → None

    Время: ~18 минут *)
let largest_file (_p : path) : (path * int) option =
  failwith "todo"

(* Среднее *)
(** Упражнение: Where Is — найти директорию содержащую файл.

    Дано: дерево и имя файла.
    Найти: директорию, которая непосредственно содержит файл с таким именем.

    Пример:
    {[
      Directory ("root", [
        File "a.txt";
        Directory ("sub", [File "b.txt"])
      ])

      where_is tree "b.txt" = Some (Directory ("sub", [...]))
    ]}

    Подсказки:
    1. Рекурсивная функция
    2. Проверьте детей текущей директории
    3. Если нет — рекурсивно ищите в поддиректориях
    4. List.find_map для поиска в детях

    Время: ~20 минут *)
let where_is (_p : path) (_name : string) : path option =
  failwith "todo"

(* Среднее *)
(** Упражнение: Total Size — суммарный размер всех файлов.

    Дано: дерево файловой системы.
    Найти: сумму размеров всех файлов.

    Подсказки:
    1. all_files для получения всех файлов
    2. List.filter_map file_size для получения размеров
    3. List.fold_left ( + ) 0 для суммирования
    4. Pipe operator |> для композиции

    Время: ~10 минут *)
let total_size (_p : path) : int =
  failwith "todo"

(* ===== Последовательности (Seq) ===== *)

(* Среднее *)
(** Упражнение: Fibonacci Sequence — бесконечная последовательность Фибоначчи.

    Реализуйте бесконечную ленивую последовательность чисел Фибоначчи:
    0, 1, 1, 2, 3, 5, 8, 13, 21, ...

    Примеры использования:
    {[
      Seq.take 5 fibs |> List.of_seq = [0; 1; 1; 2; 3]
    ]}

    Подсказки:
    1. Используйте Seq.unfold
    2. Состояние: (a, b) — текущее и следующее число
    3. unfold (fun (a, b) -> Some (a, (b, a+b))) (0, 1)

    Связанные темы: ленивые вычисления, unfold pattern
    Время: ~15 минут *)
let fibs : int Seq.t =
  fun () -> failwith "todo"

(* ===== Строковые алгоритмы ===== *)

(* Лёгкое *)
(** Упражнение: Pangram — проверка наличия всех букв алфавита.

    Pangram — предложение, содержащее все буквы алфавита хотя бы раз.
    Пример: "The quick brown fox jumps over the lazy dog"

    Примеры:
    {[
      is_pangram "abcdefghijklmnopqrstuvwxyz" = true
      is_pangram "hello world" = false
    ]}

    Подсказки:
    1. String.lowercase_ascii для нормализации
    2. String.contains для проверки наличия буквы
    3. Проверьте все буквы от 'a' до 'z'
    4. Можно использовать рекурсию или List.for_all

    Время: ~10 минут *)
let is_pangram (_sentence : string) : bool = failwith "todo"

(* Лёгкое *)
(** Упражнение: Isogram — проверка уникальности букв.

    Isogram — слово где все буквы уникальны (каждая встречается максимум 1 раз).

    Примеры:
    {[
      is_isogram "lumberjacks" = true
      is_isogram "background" = false  (* 'a' встречается дважды *)
      is_isogram "six-year-old" = true  (* дефисы игнорируются *)
    ]}

    Подсказки:
    1. Отфильтруйте только буквы (игнорируйте дефисы, пробелы)
    2. String.to_seq для преобразования в последовательность
    3. List.sort_uniq для получения уникальных
    4. Сравните длины: уникальных = всех букв

    Время: ~12 минут *)
let is_isogram (_word : string) : bool = failwith "todo"

(* Среднее *)
(** Упражнение: Anagram — найти анаграммы.

    Анаграмма — слова с одинаковым набором букв.
    Найти все слова из candidates, которые являются анаграммами word.

    Правила:
    - Регистронезависимо
    - Слово не является анаграммой самого себя

    Примеры:
    {[
      anagrams "listen" ["enlists"; "google"; "inlets"; "banana"]
        = ["inlets"]
    ]}

    Подсказки:
    1. Напишите функцию sort_word для сортировки букв
    2. String.lowercase_ascii + String.to_seq + List.sort
    3. Фильтруйте candidates: отсортированные буквы совпадают
    4. Исключите само слово (lowercase сравнение)

    Время: ~18 минут *)
let anagrams (_word : string) (_candidates : string list) : string list = failwith "todo"

(* Лёгкое *)
(** Упражнение: Reverse String — развернуть строку.

    Примеры:
    {[
      reverse_string "hello" = "olleh"
      reverse_string "OCaml" = "lmaCO"
    ]}

    Подсказка: String.init len (fun i -> s.[len - 1 - i])
    Время: ~5 минут *)
let reverse_string (_s : string) : string = failwith "todo"

(* Среднее *)
(** Упражнение: Nucleotide Count — подсчёт нуклеотидов в ДНК.

    Дано: строка ДНК (содержит A, C, G, T).
    Вернуть: список пар (нуклеотид, количество) отсортированный по нуклеотиду.

    Примеры:
    {[
      nucleotide_count "GATTACA" =
        [('A', 3); ('C', 1); ('G', 1); ('T', 2)]
    ]}

    Подсказки:
    1. Hashtbl для подсчёта
    2. Инициализируйте счётчики для A, C, G, T
    3. String.iter для прохода по строке
    4. Hashtbl.fold для сбора результатов
    5. List.sort для сортировки

    Время: ~15 минут *)
let nucleotide_count (_dna : string) : (char * int) list = failwith "todo"

(* Среднее *)
(** Упражнение: Hamming Distance — расстояние Хэмминга.

    Расстояние Хэмминга — количество позиций где символы различаются.

    Примеры:
    {[
      hamming_distance "GAGCCTACTAACGGGAT" "CATCGTAATGACGGCCT" = Ok 7
      hamming_distance "AAA" "AA" = Error "строки разной длины"
    ]}

    Подсказки:
    1. Валидация: String.length s1 = String.length s2
    2. Если разные длины → Error
    3. Используйте цикл или Seq.zip + Seq.filter
    4. Подсчитайте позиции где s1.[i] <> s2.[i]

    Время: ~12 минут *)
let hamming_distance (_s1 : string) (_s2 : string) : (int, string) result = failwith "todo"

(* Сложное *)
(** Упражнение: Run-Length Encoding — сжатие повторов.

    RLE сжимает последовательные повторы символов.

    Примеры:
    {[
      rle_encode "WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWWWWWWWWWWWWWWWWWWWWWWB"
        = "12WB12W3B24WB"

      rle_decode "12WB12W3B24WB"
        = "WWWWWWWWWWWWBWWWWWWWWWWWWBBBWWWWWWWWWWWWWWWWWWWWWWWWB"
    ]}

    Подсказки для encode:
    1. Группируйте последовательные одинаковые символы
    2. Для каждой группы: если длина > 1 → "NX", иначе → "X"
    3. Используйте fold с accumulator (текущий символ, счётчик)

    Подсказки для decode:
    1. Парсите число (если есть) + следующий символ
    2. Повторите символ N раз
    3. String.make count char для повторения

    Связанные темы: state machines, парсинг
    Время: ~40 минут (обе функции) *)
let rle_encode (_s : string) : string = failwith "todo"
let rle_decode (_s : string) : string = failwith "todo"

(* ===== Высокоуровневые абстракции ===== *)

(* Сложное *)
(** Упражнение: Traverse Option — applicative traversal для Option.

    "Перевернуть" типы: из list of options в option of list.
    Применить функцию f ко всем элементам, прервать при первом None.

    Примеры:
    {[
      traverse_option (fun x -> Some (x + 1)) [1; 2; 3]
        = Some [2; 3; 4]

      traverse_option (fun x -> if x > 0 then Some x else None) [1; -2; 3]
        = None
    ]}

    Подсказки:
    1. List.fold_left с accumulator типа 'b list option
    2. Pattern match: (Some acc, Some y) -> Some (y :: acc)
    3. Любой None → сразу None
    4. Не забудьте reverse результат!

    Связанные темы: Applicative functors, Traversable
    Время: ~25 минут *)
let traverse_option (_f : 'a -> 'b option) (_lst : 'a list) : 'b list option =
  failwith "todo"

(* Сложное *)
(** Упражнение: Traverse Result — applicative traversal для Result.

    Аналогично traverse_option, но с Result.
    Прервать при первой ошибке.

    Примеры:
    {[
      let parse_int s = try Ok (int_of_string s) with _ -> Error "not int" in
      traverse_result parse_int ["1"; "2"; "3"] = Ok [1; 2; 3]
      traverse_result parse_int ["1"; "x"; "3"] = Error "not int"
    ]}

    Подсказки:
    1. Аналогично traverse_option
    2. Pattern match: (Ok acc, Ok y) -> Ok (y :: acc)
    3. Любой Error → сразу Error (первая ошибка!)
    4. reverse результат

    Время: ~25 минут *)
let traverse_result (_f : 'a -> ('b, 'e) result) (_lst : 'a list) : ('b list, 'e) result =
  failwith "todo"

(* ===== Реализация List operations с нуля ===== *)

(* Среднее *)
(** Упражнение: List Ops — реализуйте операции над списками БЕЗ List.*.

    Цель: понять как работают list functions изнутри.
    Правило: НЕ используйте функции из модуля List!

    Реализуйте 8 функций:
    1. length — длина списка
    2. reverse — развернуть список
    3. map — применить функцию к каждому элементу
    4. filter — отфильтровать по предикату
    5. fold_left — свёртка слева направо
    6. fold_right — свёртка справа налево
    7. append — конкатенация двух списков
    8. concat — конкатенация списка списков

    Подсказки:
    - Используйте pattern matching и рекурсию
    - length: считайте 1 + length tail
    - reverse: используйте accumulator
    - fold_left: хвостовая рекурсия
    - fold_right: НЕ хвостовая (или через reverse + fold_left)
    - append: [1;2] @ [3;4] = [1;2;3;4]

    Время: ~40 минут на все 8 функций *)
module List_ops = struct
  let length (_lst : 'a list) : int = failwith "todo"
  let reverse (_lst : 'a list) : 'a list = failwith "todo"
  let map (_f : 'a -> 'b) (_lst : 'a list) : 'b list = failwith "todo"
  let filter (_f : 'a -> bool) (_lst : 'a list) : 'a list = failwith "todo"
  let fold_left (_f : 'b -> 'a -> 'b) (_init : 'b) (_lst : 'a list) : 'b = failwith "todo"
  let fold_right (_f : 'a -> 'b -> 'b) (_lst : 'a list) (_init : 'b) : 'b = failwith "todo"
  let append (_xs : 'a list) (_ys : 'a list) : 'a list = failwith "todo"
  let concat (_lists : 'a list list) : 'a list = failwith "todo"
end

(* ===== Продвинутая работа с Seq ===== *)

(* Сложное *)
(** Упражнение: Windowed Pairs — пары соседних элементов последовательности.

    Из последовательности [1; 2; 3; 4] сделать [(1,2); (2,3); (3,4)].

    Примеры:
    {[
      let seq = List.to_seq [1; 2; 3; 4] in
      windowed_pairs seq |> List.of_seq = [(1,2); (2,3); (3,4)]
    ]}

    Подсказки:
    1. Используйте Seq.unfold или ручной Seq
    2. Храните состояние: предыдущий элемент
    3. Первый элемент — запомнить, не возвращать пару
    4. Следующие элементы — вернуть (prev, curr)

    Связанные темы: Lazy evaluation, sliding window
    Время: ~20 минут *)
let windowed_pairs (_seq : 'a Seq.t) : ('a * 'a) Seq.t =
  fun () -> failwith "todo"

(* Сложное *)
(** Упражнение: Cartesian Product — декартово произведение последовательностей.

    Все пары (a, b) где a из s1, b из s2.

    Примеры:
    {[
      let s1 = List.to_seq [1; 2] in
      let s2 = List.to_seq ['a'; 'b'] in
      cartesian s1 s2 |> List.of_seq =
        [(1,'a'); (1,'b'); (2,'a'); (2,'b')]
    ]}

    Подсказки:
    1. Для каждого элемента из s1 сгенерировать пары со всеми из s2
    2. Используйте Seq.flat_map
    3. Seq.product в stdlib (OCaml 4.14+) делает это автоматически
    4. Но реализуйте сами для обучения!

    Связанные темы: Nested iteration, flat_map
    Время: ~25 минут *)
let cartesian (_s1 : 'a Seq.t) (_s2 : 'b Seq.t) : ('a * 'b) Seq.t =
  fun () -> failwith "todo"
