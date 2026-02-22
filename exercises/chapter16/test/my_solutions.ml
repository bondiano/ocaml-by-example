(** Здесь вы можете писать свои решения упражнений. *)
open Chapter16.Properties
[@@warning "-33"]

(* ===== Property-based тесты ===== *)

(* Лёгкое *)
(** Упражнение 1: prop_rev_involution — свойство reverse.

    Проверить что reverse дважды = identity:
    List.rev (List.rev lst) = lst

    Это называется "инволюция" — функция, обратная сама себе.

    Используйте QCheck для генерации случайных списков и проверки свойства.

    Структура теста:
    {[
      QCheck.Test.make
        ~name:"rev_involution"
        ~count:100
        QCheck.(list small_int)
        (fun lst -> List.rev (List.rev lst) = lst)
    ]}

    Примеры свойства:
    {[
      List.rev (List.rev [1; 2; 3]) = [1; 2; 3]  ✓
      List.rev (List.rev []) = []  ✓
    ]}

    Подсказки:
    1. QCheck.Test.make для создания теста
    2. QCheck.(list small_int) — генератор списков целых чисел
    3. Функция-предикат: fun lst -> ...
    4. Сравнение через =
    5. count:100 означает 100 тестовых случаев

    Связанные темы: Property-based testing, QCheck, invariants
    Время: ~8 минут *)
let prop_rev_involution =
  QCheck.Test.make ~name:"rev_involution" ~count:100
    QCheck.(list small_int)
    (fun _lst -> failwith "todo")

(* Лёгкое *)
(** Упражнение 2: prop_sort_sorted — свойство sort.

    Проверить что List.sort всегда возвращает отсортированный список.

    Свойство: результат List.sort должен быть упорядочен по возрастанию.

    Вспомогательная функция is_sorted:
    {[
      let rec is_sorted = function
        | [] | [_] -> true
        | x :: y :: rest -> x <= y && is_sorted (y :: rest)
    ]}

    Примеры:
    {[
      is_sorted [1; 2; 3] = true
      is_sorted [3; 1; 2] = false
      is_sorted [] = true
    ]}

    Подсказки:
    1. Сначала определить is_sorted
    2. QCheck.Test.make с list small_int
    3. Предикат: fun lst -> is_sorted (List.sort compare lst)
    4. List.sort compare для сортировки

    Связанные темы: Sorting properties, is_sorted predicate
    Время: ~10 минут *)
let prop_sort_sorted =
  QCheck.Test.make ~name:"sort_sorted" ~count:100
    QCheck.(list small_int)
    (fun _lst -> failwith "todo")

(* Среднее *)
(** Упражнение 3: prop_bst_membership — свойство BST.

    Проверить что все вставленные элементы в BST присутствуют в дереве.

    Свойство:
    - Вставить все элементы xs в дерево
    - Проверить что каждый элемент найден через mem

    Генератор:
    {[
      QCheck.(pair small_int (list small_int))
      (* (x, xs) где x — элемент для проверки, xs — список для вставки *)
    ]}

    Подсказки:
    1. Используйте BST из Chapter16.Properties (или реализуйте свой)
    2. List.fold_left для вставки всех элементов
    3. Проверить что x найден в дереве после вставки x :: xs
    4. Структура:
       {[
         fun (x, xs) ->
           let tree = List.fold_left (fun t v -> BST.insert v t) BST.empty (x :: xs) in
           BST.mem x tree
       ]}

    Связанные темы: BST properties, membership testing
    Время: ~15 минут *)
let prop_bst_membership =
  QCheck.Test.make ~name:"bst_membership" ~count:100
    QCheck.(pair small_int (list small_int))
    (fun (_x, _xs) -> failwith "todo")

(* Среднее *)
(** Упражнение 4: prop_codec_roundtrip — свойство кодека.

    Проверить что encode/decode — обратные операции (roundtrip).

    Свойство:
    decode (encode x) = x

    Используйте кодек из Chapter16.Properties:
    {[
      encode : int -> string -> string
      decode : string -> (int * string, string) result
    ]}

    Примеры:
    {[
      let encoded = encode 42 "data"
      decode encoded = Ok (42, "data")
    ]}

    Подсказки:
    1. Генератор: QCheck.(pair small_int (string_of_size (Gen.return 5)))
    2. Предикат:
       {[
         fun (n, s) ->
           let encoded = encode n s in
           match decode encoded with
           | Ok (n', s') -> n = n' && s = s'
           | Error _ -> false
       ]}
    3. Проверить что decode успешен И значения совпадают

    Связанные темы: Roundtrip properties, codecs, serialization
    Время: ~12 минут *)
let prop_codec_roundtrip =
  QCheck.Test.make ~name:"codec_roundtrip" ~count:100
    QCheck.(pair small_int (string_of_size (Gen.return 5)))
    (fun (_n, _s) -> failwith "todo")

(* ===== Реализации для тестирования ===== *)

(* Среднее *)
(** Упражнение 5: binary_search — бинарный поиск в отсортированном массиве.

    Найти индекс элемента target в отсортированном массиве.

    Алгоритм:
    1. Два указателя: left и right
    2. Середина: mid = (left + right) / 2
    3. Если arr.(mid) = target → Some mid
    4. Если arr.(mid) < target → ищем справа (left = mid + 1)
    5. Если arr.(mid) > target → ищем слева (right = mid - 1)
    6. Если left > right → None (не найдено)

    Примеры:
    {[
      binary_search [|1; 3; 5; 7; 9|] 5 = Some 2
      binary_search [|1; 3; 5; 7; 9|] 4 = None
      binary_search [||] 1 = None
    ]}

    Подсказки:
    1. Рекурсивная или итеративная реализация
    2. Рекурсивная:
       {[
         let rec search left right =
           if left > right then None
           else
             let mid = (left + right) / 2 in
             if arr.(mid) = target then Some mid
             else if arr.(mid) < target then search (mid + 1) right
             else search left (mid - 1)
       ]}
    3. Начальный вызов: search 0 (Array.length arr - 1)

    Связанные темы: Binary search, algorithms, recursion
    Время: ~18 минут *)
let binary_search (_arr : int array) (_target : int) : int option = failwith "todo"

(* ===== Binary Search Tree ===== *)

(* Лёгкое *)
(** Упражнение 6a: BST.insert — вставка в BST.

    Вставить элемент в бинарное дерево поиска.

    Структура BST:
    {[
      type 'a t =
        | Empty
        | Node of 'a t * 'a * 'a t
        (*        left   val  right *)
    ]}

    Инвариант BST:
    - Все элементы в левом поддереве < значения узла
    - Все элементы в правом поддереве > значения узла

    Примеры:
    {[
      BST.empty |> BST.insert 5 |> BST.insert 3 |> BST.insert 7
      (* Node (Node (Empty, 3, Empty), 5, Node (Empty, 7, Empty)) *)
    ]}

    Подсказки:
    1. Pattern match на дерево:
       {[
         match tree with
         | Empty -> Node (Empty, value, Empty)
         | Node (l, v, r) ->
             if value < v then Node (insert value l, v, r)
             else if value > v then Node (l, v, insert value r)
             else tree  (* уже есть *)
       ]}
    2. Рекурсивно вставлять в нужное поддерево

    Связанные темы: BST, recursive data structures
    Время: ~15 минут *)

(* Лёгкое *)
(** Упражнение 6b: BST.mem — поиск в BST.

    Проверить наличие элемента в дереве.

    Примеры:
    {[
      let tree = BST.empty |> BST.insert 5 |> BST.insert 3
      BST.mem 5 tree = true
      BST.mem 3 tree = true
      BST.mem 10 tree = false
    ]}

    Подсказки:
    1. Pattern match на дерево:
       {[
         match tree with
         | Empty -> false
         | Node (l, v, r) ->
             if value = v then true
             else if value < v then mem value l
             else mem value r
       ]}
    2. Используйте инвариант BST для эффективного поиска

    Связанные темы: BST search, binary search on trees
    Время: ~8 минут *)

(* Среднее *)
(** Упражнение 6c: BST.to_sorted_list — преобразование BST в отсортированный список.

    Выполнить in-order обход дерева (левое → корень → правое),
    что даёт отсортированный список.

    Примеры:
    {[
      let tree = BST.empty |> BST.insert 5 |> BST.insert 3 |> BST.insert 7
      BST.to_sorted_list tree = [3; 5; 7]
    ]}

    Подсказки:
    1. In-order обход:
       {[
         match tree with
         | Empty -> []
         | Node (l, v, r) ->
             to_sorted_list l @ [v] @ to_sorted_list r
       ]}
    2. Оператор @ для конкатенации списков
    3. Альтернатива с accumulator для эффективности:
       {[
         let rec aux acc = function
           | Empty -> acc
           | Node (l, v, r) -> aux (v :: aux acc r) l
       ]}

    Связанные темы: Tree traversal, in-order traversal
    Время: ~12 минут *)

module BST = struct
  type 'a t =
    | Empty
    | Node of 'a t * 'a * 'a t

  let empty : 'a t = Empty
  let insert (_value : 'a) (_tree : 'a t) : 'a t = failwith "todo"
  let mem (_value : 'a) (_tree : 'a t) : bool = failwith "todo"
  let to_sorted_list (_tree : 'a t) : 'a list = failwith "todo"
end

(* ===== Advent of Property-Based Testing 2024 ===== *)

(* Среднее *)
(** Упражнение 7: sort_letters — сортировка писем Санты (Advent of PBT Day 1).

    Эльфы Санты сортируют письма детей по возрасту (младшие первые),
    при одинаковом возрасте — по алфавиту (имени).

    Тип письма:
    {[
      type letter = { name : string; age : int }
    ]}

    Правила сортировки:
    1. Сначала по age (возрастанию)
    2. При равном age — по name (лексикографически)

    Примеры:
    {[
      sort_letters [
        { name = "Bob"; age = 8 };
        { name = "Alice"; age = 7 };
        { name = "Charlie"; age = 7 }
      ] = [
        { name = "Alice"; age = 7 };
        { name = "Charlie"; age = 7 };
        { name = "Bob"; age = 8 }
      ]
    ]}

    Подсказки:
    1. List.sort с custom compare:
       {[
         List.sort (fun a b ->
           match Int.compare a.age b.age with
           | 0 -> String.compare a.name b.name
           | c -> c
         ) letters
       ]}
    2. Int.compare для чисел, String.compare для строк
    3. 0 означает равенство — переходим к следующему критерию

    Связанные темы: Multi-key sorting, custom comparators
    Время: ~15 минут *)

type letter = { name : string; age : int }

let sort_letters (_letters : letter list) : letter list = failwith "todo"

(* Вспомогательный генератор для писем *)
let letter_gen =
  QCheck.Gen.(map2
    (fun name age -> { name; age })
    string
    (0 -- 10))

(* Среднее *)
(** Упражнение 7a: prop_age_ordering — письма отсортированы по возрасту.

    Свойство: все дети младшего возраста идут раньше детей старшего возраста.

    Проверка:
    - Для каждой пары соседних писем (l1, l2): l1.age <= l2.age

    Подсказки:
    1. Генератор списка писем:
       {[
         let open QCheck.Gen in list (map2
           (fun name age -> { name; age })
           string
           (0 -- 10)))
       ]}
    2. Вспомогательная функция для проверки упорядоченности:
       {[
         let rec check_age_order = function
           | [] | [_] -> true
           | l1 :: l2 :: rest ->
               l1.age <= l2.age && check_age_order (l2 :: rest)
       ]}
    3. Предикат: sort_letters ls |> check_age_order

    Связанные темы: Ordering properties, adjacent pairs
    Время: ~12 минут *)

let prop_age_ordering =
  QCheck.Test.make ~name:"age_ordering" ~count:100
    QCheck.(list (make letter_gen))
    (fun _letters -> failwith "todo")

(* Среднее *)
(** Упражнение 7b: prop_alphabetical_tiebreak — при равном возрасте — алфавитный порядок.

    Свойство: письма с одинаковым возрастом отсортированы по имени.

    Проверка:
    - Для пары (l1, l2) где l1.age = l2.age: l1.name <= l2.name

    Подсказки:
    1. Тот же генератор
    2. Проверка:
       {[
         let rec check_name_order = function
           | [] | [_] -> true
           | l1 :: l2 :: rest ->
               if l1.age = l2.age then
                 l1.name <= l2.name && check_name_order (l2 :: rest)
               else
                 check_name_order (l2 :: rest)
       ]}

    Связанные темы: Secondary sort key, tie-breaking
    Время: ~10 минут *)

let prop_alphabetical_tiebreak =
  QCheck.Test.make ~name:"alphabetical_tiebreak" ~count:100
    QCheck.(list (make letter_gen))
    (fun _letters -> failwith "todo")

(* Среднее *)
(** Упражнение 7c: prop_no_loss — сортировка не теряет письма.

    Свойство: количество писем до и после сортировки одинаково.

    Также можно проверить что все элементы сохранены (более сильное свойство).

    Подсказки:
    1. Простая проверка: List.length letters = List.length (sort_letters letters)
    2. Сильная проверка: все элементы из letters присутствуют в результате
       {[
         List.for_all (fun l -> List.mem l sorted) letters &&
         List.for_all (fun l -> List.mem l letters) sorted
       ]}

    Связанные темы: Permutation properties, data preservation
    Время: ~8 минут *)

let prop_no_loss =
  QCheck.Test.make ~name:"no_loss" ~count:100
    QCheck.(list (make letter_gen))
    (fun _letters -> failwith "todo")

(* Лёгкое *)
(** Упражнение 7d: prop_idempotent — сортировка идемпотентна.

    Свойство: sort (sort xs) = sort xs
    Повторная сортировка не меняет результат.

    Подсказки:
    1. Предикат:
       {[
         let sorted = sort_letters letters in
         sort_letters sorted = sorted
       ]}

    Связанные темы: Idempotence, stability
    Время: ~5 минут *)

let prop_idempotent =
  QCheck.Test.make ~name:"idempotent" ~count:100
    QCheck.(list (make letter_gen))
    (fun _letters -> failwith "todo")

(* Среднее *)
(** Упражнение 8: deduplicate_letters — удаление дубликатов писем (Advent of PBT Day 2).

    Удалить дубликаты писем от одного отправителя (по полю id),
    оставляя первое вхождение каждого id.

    Тип письма с ID:
    {[
      type letter_with_id = { id : int; name : string; age : int }
    ]}

    Примеры:
    {[
      deduplicate_letters [
        { id = 1; name = "Alice"; age = 7 };
        { id = 2; name = "Bob"; age = 8 };
        { id = 1; name = "Alice"; age = 7 };  (* дубликат *)
        { id = 3; name = "Charlie"; age = 9 }
      ] = [
        { id = 1; name = "Alice"; age = 7 };
        { id = 2; name = "Bob"; age = 8 };
        { id = 3; name = "Charlie"; age = 9 }
      ]
    ]}

    Подсказки:
    1. Использовать Hashtbl или Set для отслеживания виденных ID:
       {[
         let seen = Hashtbl.create 16 in
         List.filter (fun letter ->
           if Hashtbl.mem seen letter.id then false
           else (Hashtbl.add seen letter.id (); true)
         ) letters
       ]}
    2. Или List.fold_left с accumulator:
       {[
         List.fold_left (fun (seen, acc) letter ->
           if List.mem letter.id seen then (seen, acc)
           else (letter.id :: seen, letter :: acc)
         ) ([], []) letters
         |> snd |> List.rev
       ]}
    3. Порядок первых вхождений сохраняется

    Связанные темы: Deduplication, seen set pattern
    Время: ~18 минут *)

type letter_with_id = { id : int; name : string; age : int }

let deduplicate_letters (_letters : letter_with_id list) : letter_with_id list =
  failwith "todo"

(* Вспомогательный генератор для писем с ID *)
let letter_with_id_gen =
  QCheck.Gen.(map3
    (fun id name age -> { id; name; age })
    (0 -- 10)
    string
    (0 -- 10))

(* Среднее *)
(** Упражнение 8a: prop_unique_ids — каждый ID встречается максимум один раз.

    Свойство: в результате нет дубликатов ID.

    Подсказки:
    1. Генератор:
       {[
         QCheck.Gen.(list (map3
           (fun id name age -> { id; name; age })
           (0 -- 10)
           string
           (0 -- 10)))
       ]}
    2. Проверка уникальности:
       {[
         let ids = List.map (fun l -> l.id) deduped in
         List.length ids = List.length (List.sort_uniq Int.compare ids)
       ]}
    3. List.sort_uniq удаляет дубликаты после сортировки

    Связанные темы: Uniqueness properties, set operations
    Время: ~10 минут *)

let prop_unique_ids =
  QCheck.Test.make ~name:"unique_ids" ~count:100
    QCheck.(list (make letter_with_id_gen))
    (fun _letters -> failwith "todo")

(* Среднее *)
(** Упражнение 8b: prop_all_ids_present — все уникальные ID из входа присутствуют в выходе.

    Свойство: дедупликация не теряет уникальные элементы.

    Подсказки:
    1. Получить уникальные ID из входа:
       {[
         let input_ids = List.map (fun l -> l.id) letters
                         |> List.sort_uniq Int.compare
       ]}
    2. Получить ID из выхода:
       {[
         let output_ids = List.map (fun l -> l.id) deduped
                          |> List.sort Int.compare
       ]}
    3. Проверить равенство: input_ids = output_ids

    Связанные темы: Data preservation, set equality
    Время: ~12 минут *)

let prop_all_ids_present =
  QCheck.Test.make ~name:"all_ids_present" ~count:100
    QCheck.(list (make letter_with_id_gen))
    (fun _letters -> failwith "todo")

(* Сложное *)
(** Упражнение 9: is_valid_security_key — валидация ключей безопасности (Advent of PBT Day 5).

    Валидный ключ безопасности = произведение ровно двух различных простых чисел.

    Правила:
    - n = p * q где p и q — различные простые числа
    - Примеры валидных: 6 (2×3), 10 (2×5), 15 (3×5), 21 (3×7)
    - Примеры невалидных: 5 (простое), 8 (2³), 30 (2×3×5)

    Примеры:
    {[
      is_valid_security_key 6 = true   (* 2 × 3 *)
      is_valid_security_key 10 = true  (* 2 × 5 *)
      is_valid_security_key 5 = false  (* простое число *)
      is_valid_security_key 8 = false  (* 2³ *)
      is_valid_security_key 30 = false (* 2 × 3 × 5, три множителя *)
    ]}

    Подсказки:
    1. Вспомогательная функция: is_prime
       {[
         let is_prime n =
           if n < 2 then false
           else
             let rec check d =
               if d * d > n then true
               else if n mod d = 0 then false
               else check (d + 1)
             in check 2
       ]}
    2. Разложение на простые множители:
       {[
         let prime_factors n =
           let rec aux n d acc =
             if d * d > n then
               if n > 1 then n :: acc else acc
             else if n mod d = 0 then
               aux (n / d) d (d :: acc)
             else
               aux n (d + 1) acc
           in aux n 2 []
       ]}
    3. Проверить что факторов ровно 2 и они различны

    Связанные темы: Prime numbers, factorization, number theory
    Время: ~35 минут *)

let is_valid_security_key (_n : int) : bool = failwith "todo"

(* Сложное *)
(** Упражнение 9a: prop_two_primes — валидный ключ имеет ровно 2 простых делителя.

    Свойство:
    is_valid_security_key n = true ⟹ n имеет ровно 2 различных простых делителя

    Подсказки:
    1. Генератор произведений двух простых:
       {[
         let small_primes = [2; 3; 5; 7; 11; 13; 17; 19; 23; 29; 31] in
         QCheck.Gen.(
           pair (oneofl small_primes) (oneofl small_primes)
           |> map (fun (p, q) -> if p = q then p * (q + 2) else p * q))
       ]}
    2. Также тестировать на случайных числах и проверять консистентность
    3. Если is_valid вернул true, проверить факторизацию

    Связанные темы: Property-based testing for algorithms
    Время: ~20 минут *)

let prop_two_primes =
  QCheck.Test.make ~name:"two_primes" ~count:50
    QCheck.(small_int)
    (fun _n -> failwith "todo")

(* Среднее *)
(** Упражнение 10: is_palindrome — проверка палиндрома с учётом Unicode (Advent of PBT Day 10).

    Проверить, является ли строка палиндромом, учитывая Unicode grapheme clusters.

    Проблема: наивная реверсия символов может сломаться на составных emoji.
    Например, "⛄⭐⛄" — это палиндром, но String.to_seq может его неправильно обработать.

    Для упрощения, в этом упражнении работаем с ASCII строками,
    но используем правильную реверсию через список символов.

    Примеры:
    {[
      is_palindrome "racecar" = true
      is_palindrome "hello" = false
      is_palindrome "a" = true
      is_palindrome "" = true
      is_palindrome "Aa" = false  (* с учётом регистра *)
    ]}

    Подсказки:
    1. Преобразовать в список символов, реверснуть, сравнить:
       {[
         let chars = String.to_seq s |> List.of_seq in
         chars = List.rev chars
       ]}
    2. Для Unicode (опционально): использовать библиотеку Uuseg
    3. Игнорирование регистра (опционально): String.lowercase_ascii

    Связанные темы: String manipulation, palindromes, Unicode
    Время: ~15 минут *)

let is_palindrome (_s : string) : bool = failwith "todo"

(* Среднее *)
(** Упражнение 10a: prop_palindrome_symmetric — палиндром читается одинаково в обе стороны.

    Свойство:
    is_palindrome s ⟹ reverse(s) = s

    Также проверить обратное: если reverse(s) = s, то is_palindrome s = true

    Подсказки:
    1. Генератор строк: QCheck.(string_of_size (Gen.int_range 0 20))
    2. Вспомогательная функция reverse:
       {[
         let reverse s =
           String.to_seq s |> List.of_seq |> List.rev |> List.to_seq |> String.of_seq
       ]}
    3. Двустороннее свойство:
       {[
         is_palindrome s = (reverse s = s)
       ]}

    Связанные темы: Symmetry properties, bidirectional testing
    Время: ~12 минут *)

let prop_palindrome_symmetric =
  QCheck.Test.make ~name:"palindrome_symmetric" ~count:100
    QCheck.(string_of_size (Gen.int_range 0 20))
    (fun _s -> failwith "todo")

(* ===== Продвинутые техники PBT ===== *)

(* Сложное *)
(** Упражнение 11: Stack — model-based testing для стека.

    Проверить реализацию стека через модель (list).
    Генерировать последовательности операций (push/pop/peek)
    и проверять, что результаты совпадают с моделью.

    Реализуйте стек:
    {[
      type 'a t
      val empty : 'a t
      val push : 'a -> 'a t -> 'a t
      val pop : 'a t -> ('a * 'a t) option
      val peek : 'a t -> 'a option
    ]}

    Модель: обычный list, где:
    - push x xs = x :: xs
    - pop (x :: xs) = Some (x, xs)
    - peek (x :: _) = Some x

    Примеры:
    {[
      let s = Stack.empty |> Stack.push 1 |> Stack.push 2 in
      Stack.peek s = Some 2
      Stack.pop s = Some (2, Stack.empty |> Stack.push 1)
    ]}

    Подсказки:
    1. Реализация через list:
       {[
         type 'a t = 'a list
         let empty = []
         let push x s = x :: s
         let pop = function [] -> None | x :: xs -> Some (x, xs)
         let peek = function [] -> None | x :: _ -> Some x
       ]}
    2. Операция для тестирования:
       {[
         type 'a stack_op = Push of 'a | Pop | Peek
       ]}
    3. Генератор операций: QCheck.Gen.(list (oneof [map (fun x -> Push x) small_int; return Pop; return Peek]))

    Связанные темы: Model-based testing, state machines
    Время: ~40 минут *)

module Stack = struct
  type 'a t = 'a list
  let empty : 'a t = []
  let push (_x : 'a) (_s : 'a t) : 'a t = failwith "todo"
  let pop (_s : 'a t) : ('a * 'a t) option = failwith "todo"
  let peek (_s : 'a t) : 'a option = failwith "todo"
end

type stack_op = Push of int | Pop | Peek

(* Сложное *)
(** Упражнение 11a: prop_stack_model — стек соответствует модели.

    Свойство: выполнить последовательность операций на реализации и модели,
    результаты должны совпадать.

    Подсказки:
    1. Генератор операций:
       {[
         QCheck.Gen.(list (frequency [
           (3, map (fun x -> Push x) small_int);
           (1, return Pop);
           (1, return Peek)
         ]))
       ]}
    2. Выполнить операции параллельно на Stack и list:
       {[
         let rec run_ops stack model = function
           | [] -> true
           | Push x :: rest ->
               run_ops (Stack.push x stack) (x :: model) rest
           | Pop :: rest ->
               (match Stack.pop stack, model with
                | None, [] -> run_ops stack model rest
                | Some (v1, s'), v2 :: m' when v1 = v2 ->
                    run_ops s' m' rest
                | _ -> false)
           | Peek :: rest ->
               (match Stack.peek stack, model with
                | None, [] -> run_ops stack model rest
                | Some v1, v2 :: _ when v1 = v2 ->
                    run_ops stack model rest
                | _ -> false)
       ]}

    Связанные темы: Operational equivalence, reference implementation
    Время: ~30 минут *)

let prop_stack_model =
  let op_gen = QCheck.Gen.(frequency [
    (3, map (fun x -> Push x) small_int);
    (1, return Pop);
    (1, return Peek)
  ]) in
  QCheck.Test.make ~name:"stack_model" ~count:100
    QCheck.(list (make op_gen))
    (fun _ops -> failwith "todo")

(* Среднее *)
(** Упражнение 12: email_gen — генератор email с правильным shrinking.

    Создать генератор для email-адресов с корректным shrinking.
    При нахождении ошибки QCheck должен упрощать email до минимального.

    Формат email: <username>@<domain>.<tld>
    - username: [a-z0-9]+
    - domain: [a-z]+
    - tld: [a-z]{2,3}

    Примеры:
    {[
      "alice@example.com"
      "bob123@test.org"
      "x@y.co"
    ]}

    Подсказки:
    1. Генератор username:
       {[
         QCheck.Gen.(string_size ~gen:(1 -- 10) |> map String.lowercase_ascii)
       ]}
    2. Собрать email:
       {[
         QCheck.Gen.(map3
           (fun user domain tld -> user ^ "@" ^ domain ^ "." ^ tld)
           username_gen domain_gen tld_gen)
       ]}
    3. Shrinking работает автоматически для примитивных генераторов

    Связанные темы: Custom generators, shrinking, test case reduction
    Время: ~20 минут *)

let email_gen : string QCheck.Gen.t =
  failwith "todo"

(* Среднее *)
(** Упражнение 12a: prop_email_valid — сгенерированные email валидны.

    Свойство: все сгенерированные email содержат @ и точку.

    Простая валидация:
    {[
      let is_valid_email s =
        String.contains s '@' &&
        String.contains s '.' &&
        String.length s >= 5  (* минимум a@b.c *)
    ]}

    Подсказки:
    1. QCheck.Test.make с email_gen
    2. Предикат: is_valid_email email

    Связанные темы: Generator testing, format validation
    Время: ~8 минут *)

let prop_email_valid =
  QCheck.Test.make ~name:"email_valid" ~count:100
    QCheck.(make email_gen)
    (fun _email -> failwith "todo")

(* Сложное *)
(** Упражнение 13: prop_sort_complexity — проверка сложности сортировки.

    Проверить что сортировка работает за O(n log n).

    Измерить время выполнения на разных размерах входа
    и убедиться что рост времени логарифмический.

    ВНИМАНИЕ: это упражнение требует измерения времени,
    что может быть нестабильно на некоторых системах.
    Используйте достаточно большие размеры для статистической значимости.

    Подсказки:
    1. Измерение времени:
       {[
         let time f x =
           let t1 = Unix.gettimeofday () in
           let _ = f x in
           Unix.gettimeofday () -. t1
       ]}
    2. Генерировать массивы разных размеров: 100, 1000, 10000
    3. Проверить что time(10000) / time(1000) ≈ 10 * log(10) ≈ 23
       (а не 100 для O(n²))
    4. Это heuristic тест, может быть нестабильным!

    Связанные темы: Performance testing, algorithmic complexity
    Время: ~35 минут *)

let prop_sort_complexity =
  let large_list_gen = QCheck.Gen.(list_size (return 1000) small_int) in
  QCheck.Test.make ~name:"sort_complexity" ~count:10
    QCheck.(make large_list_gen)
    (fun _lst -> failwith "todo")

(* ===== Бонусные упражнения ===== *)

(* ★ Бонус *)
(** Упражнение 14: BankAccount — stateful property testing для банковского счёта.

    Проверить реализацию банковского счёта через stateful testing.
    Операции: create, deposit, withdraw, get_balance

    Свойства:
    - Баланс всегда неотрицательный
    - Сумма всех deposit - сумма всех withdraw = текущий balance
    - withdraw на сумму больше balance возвращает Error

    Реализуйте:
    {[
      type t
      val create : int -> t
      val deposit : t -> int -> (t, string) result
      val withdraw : t -> int -> (t, string) result
      val balance : t -> int
    ]}

    Примеры:
    {[
      let acc = BankAccount.create 100 in
      BankAccount.balance acc = 100

      let acc = BankAccount.deposit acc 50 |> Result.get_ok in
      BankAccount.balance acc = 150

      let res = BankAccount.withdraw acc 200 in
      res = Error "insufficient funds"
    ]}

    Подсказки:
    1. Тип с mutable balance:
       {[
         type t = { mutable balance : int }
         let create initial = { balance = initial }
         let deposit acc amount =
           if amount < 0 then Error "negative amount"
           else (acc.balance <- acc.balance + amount; Ok acc)
         let withdraw acc amount =
           if amount < 0 then Error "negative amount"
           else if amount > acc.balance then Error "insufficient funds"
           else (acc.balance <- acc.balance - amount; Ok acc)
         let balance acc = acc.balance
       ]}
    2. Операция для тестирования:
       {[
         type account_op = Create of int | Deposit of int | Withdraw of int | GetBalance
       ]}
    3. Отслеживать ожидаемый баланс в модели и сравнивать

    Связанные темы: Stateful testing, invariants, banking logic
    Время: ~50 минут *)

module BankAccount = struct
  type t = { mutable balance : int }
  
  let create (_initial : int) : t = failwith "todo"
  let deposit (_acc : t) (_amount : int) : (t, string) result = failwith "todo"
  let withdraw (_acc : t) (_amount : int) : (t, string) result = failwith "todo"
  let balance (_acc : t) : int = failwith "todo"
end

type account_op = Create of int | Deposit of int | Withdraw of int | GetBalance

(* ★ Бонус *)
(** Упражнение 14a: prop_bank_account — банковский счёт удовлетворяет инвариантам.

    Свойства:
    1. Баланс всегда >= 0
    2. Сумма операций = текущий баланс
    3. Withdraw на сумму > balance возвращает Error

    Подсказки:
    1. Генератор операций:
       {[
         QCheck.Gen.(list (frequency [
           (1, map (fun n -> Create (abs n)) small_int);
           (3, map (fun n -> Deposit (abs n)) small_int);
           (2, map (fun n -> Withdraw (abs n)) small_int);
           (1, return GetBalance)
         ]))
       ]}
    2. Отслеживать expected_balance в модели:
       {[
         let rec run expected_balance = function
           | [] -> true
           | Create initial :: rest ->
               run initial rest
           | Deposit amount :: rest ->
               run (expected_balance + amount) rest
           | Withdraw amount :: rest ->
               if amount > expected_balance then
                 run expected_balance rest  (* withdraw failed, ok *)
               else
                 run (expected_balance - amount) rest
           | GetBalance :: rest ->
               run expected_balance rest
       ]}

    Связанные темы: Stateful invariants, transaction testing
    Время: ~40 минут *)

let prop_bank_account =
  let op_gen = QCheck.Gen.(frequency [
    (1, map (fun n -> Create (abs n + 1)) small_int);
    (3, map (fun n -> Deposit (abs n + 1)) (0 -- 100));
    (2, map (fun n -> Withdraw (abs n + 1)) (0 -- 100));
    (1, return GetBalance)
  ]) in
  QCheck.Test.make ~name:"bank_account" ~count:100
    QCheck.(list (make op_gen))
    (fun _ops -> failwith "todo")
