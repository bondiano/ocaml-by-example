# Генеративное тестирование

## Цели главы

В этой главе мы изучим **генеративное тестирование** (property-based testing) --- подход, при котором тесты проверяют не конкретные примеры, а свойства, которым должен удовлетворять код. Мы познакомимся с библиотекой QCheck --- OCaml-аналогом Haskell-овского QuickCheck.

## Юнит-тесты vs генеративное тестирование

В предыдущих главах мы писали тесты с Alcotest в классическом стиле: задаём конкретный вход и проверяем конкретный ожидаемый выход. Такие тесты называются **юнит-тестами** (unit tests):

```ocaml
(* Юнит-тест: конкретный вход -> конкретный выход *)
let () =
  Alcotest.(check int) "rev [1;2;3]" [3;2;1] (List.rev [1;2;3])
```

Юнит-тесты полезны, но у них есть ограничение: мы проверяем только те случаи, о которых подумали заранее. Если граничный случай не пришёл нам в голову, он останется непроверенным.

**Генеративное тестирование** (property-based testing, PBT) переворачивает подход: вместо конкретных примеров мы описываем *свойства*, которые должны выполняться для *любых* входных данных. Фреймворк генерирует сотни случайных входов и проверяет свойство для каждого из них:

```ocaml
(* Свойство: rev (rev xs) = xs для любого списка xs *)
let prop_rev_involution =
  QCheck.Test.make ~name:"rev involution" ~count:100
    QCheck.(list small_int)
    (fun xs -> List.rev (List.rev xs) = xs)
```

Генеративные тесты особенно хороши для нахождения граничных случаев, о которых вы не подумали: пустые списки, отрицательные числа, строки с управляющими символами и так далее.

## Библиотека QCheck

[QCheck](https://github.com/c-cube/qcheck) --- основная библиотека для генеративного тестирования в OCaml. Она вдохновлена Haskell-овским QuickCheck и предоставляет:

- **Генераторы** случайных данных для всех стандартных типов.
- **Механизм shrinking** --- автоматическое уменьшение контрпримера до минимального.
- **Интеграцию с Alcotest** через пакет `qcheck-alcotest`.

Для работы нужны пакеты `qcheck-core` и `qcheck-alcotest`. В `dune`-файлах:

```text
; lib/dune
(library
 (name chapter15)
 (libraries qcheck-core))

; test/dune
(test
 (name test_chapter15)
 (libraries chapter15 qcheck-core qcheck-alcotest alcotest))
```

## Генераторы

Генератор --- это значение типа `'a QCheck.arbitrary`, которое описывает, как создавать случайные значения типа `'a`. QCheck предоставляет генераторы для всех стандартных типов.

### Встроенные генераторы

```ocaml
(* Целые числа (малые, для удобства shrinking) *)
QCheck.small_int          (* 'a = int, значения от 0 до ~100 *)

(* Целые числа из полного диапазона *)
QCheck.int                (* 'a = int *)

(* Строки *)
QCheck.string             (* 'a = string *)

(* Строки фиксированной длины *)
QCheck.(string_of_size (Gen.return 5))   (* строки длины 5 *)

(* Списки *)
QCheck.(list small_int)   (* 'a = int list *)

(* Пары *)
QCheck.(pair small_int string)   (* 'a = int * string *)

(* Тройки *)
QCheck.(triple small_int small_int string)
```

Обратите внимание на различие: `QCheck.Gen.int` --- это *низкоуровневый* генератор типа `int QCheck.Gen.t`, а `QCheck.int` --- это *arbitrary* (генератор + printer + shrinker) типа `int QCheck.arbitrary`. Для `QCheck.Test.make` нужен именно `arbitrary`.

### Генераторы из модуля Gen

Модуль `QCheck.Gen` содержит комбинаторы для создания новых генераторов:

```ocaml
(* Генератор из диапазона *)
QCheck.Gen.int_range 1 100

(* Преобразование *)
QCheck.Gen.map (fun n -> n * 2) QCheck.Gen.small_int

(* Генератор списков *)
QCheck.Gen.list QCheck.Gen.small_int

(* Генератор пар *)
QCheck.Gen.pair QCheck.Gen.int QCheck.Gen.string

(* Выбор из вариантов *)
QCheck.Gen.oneof [
  QCheck.Gen.return 0;
  QCheck.Gen.int_range 1 100;
]

(* Частотный выбор *)
QCheck.Gen.frequency [
  (3, QCheck.Gen.return 0);      (* 0 с вероятностью 3/4 *)
  (1, QCheck.Gen.int_range 1 10); (* 1..10 с вероятностью 1/4 *)
]

(* Связывание генераторов *)
QCheck.Gen.bind (QCheck.Gen.int_range 1 10) (fun n ->
  QCheck.Gen.list_size (QCheck.Gen.return n) QCheck.Gen.small_int)
```

## Создание тестов

Тест создаётся функцией `QCheck.Test.make`:

```ocaml
QCheck.Test.make
  ~name:"описание"     (* имя теста *)
  ~count:100           (* сколько раз запустить, по умолчанию 100 *)
  arbitrary            (* генератор входных данных *)
  (fun input -> bool)  (* свойство: true = прошёл, false = провалился *)
```

Результат имеет тип `'a QCheck.Test.t`.

### Свойства List.rev

Рассмотрим классические свойства функции `List.rev`:

```ocaml
(* Инволюция: rev (rev xs) = xs *)
let prop_rev_involution =
  QCheck.Test.make ~name:"rev is involution" ~count:200
    QCheck.(list small_int)
    (fun xs -> List.rev (List.rev xs) = xs)

(* Сохранение длины: length (rev xs) = length xs *)
let prop_rev_length =
  QCheck.Test.make ~name:"rev preserves length" ~count:200
    QCheck.(list small_int)
    (fun xs -> List.length (List.rev xs) = List.length xs)

(* rev переворачивает порядок: первый элемент становится последним *)
let prop_rev_head_last =
  QCheck.Test.make ~name:"rev head = last" ~count:200
    QCheck.(list_of_size (Gen.int_range 1 20) small_int)
    (fun xs ->
       let rev_xs = List.rev xs in
       List.hd xs = List.nth rev_xs (List.length rev_xs - 1))
```

### Свойства List.sort

```ocaml
(* Идемпотентность: sort (sort xs) = sort xs *)
let prop_sort_idempotent =
  QCheck.Test.make ~name:"sort is idempotent" ~count:200
    QCheck.(list small_int)
    (fun xs ->
       let sorted = List.sort compare xs in
       List.sort compare sorted = sorted)

(* Сохранение длины *)
let prop_sort_length =
  QCheck.Test.make ~name:"sort preserves length" ~count:200
    QCheck.(list small_int)
    (fun xs -> List.length (List.sort compare xs) = List.length xs)

(* Результат отсортирован *)
let rec is_sorted = function
  | [] | [_] -> true
  | x :: y :: rest -> x <= y && is_sorted (y :: rest)

let prop_sort_sorted =
  QCheck.Test.make ~name:"sort result is sorted" ~count:200
    QCheck.(list small_int)
    (fun xs -> is_sorted (List.sort compare xs))
```

## Интеграция с Alcotest

Для запуска QCheck-тестов через Alcotest используем `QCheck_alcotest.to_alcotest`, который преобразует `QCheck.Test.t` в `Alcotest.test_case`:

```ocaml
let () =
  Alcotest.run "My tests"
    [
      ("unit tests", [
        Alcotest.test_case "basic" `Quick (fun () ->
          Alcotest.(check int) "1+1" 2 (1 + 1));
      ]);
      ("properties", [
        QCheck_alcotest.to_alcotest prop_rev_involution;
        QCheck_alcotest.to_alcotest prop_sort_sorted;
      ]);
    ]
```

При провале теста QCheck покажет контрпример --- минимальное значение, нарушающее свойство:

```text
[FAIL] properties  0  rev is involution.

--- Failure ---

Test rev is involution failed (0 shrink steps):

[42; -7; 0]
```

## Shrinking

**Shrinking** --- одна из самых полезных возможностей QCheck. Когда генератор находит контрпример, QCheck автоматически пытается его *уменьшить* (shrink), сохраняя нарушение свойства.

Например, если свойство нарушается для списка `[738; -12; 0; 441; 99; -3]`, QCheck попытается убрать элементы и уменьшить числа, пока не найдёт минимальный контрпример вроде `[1; 0]`.

Встроенные arbitrary (`QCheck.int`, `QCheck.list`, `QCheck.string` и другие) уже умеют делать shrinking. Для пользовательских типов нужно определять shrinker самостоятельно.

### Как работает shrinking

1. QCheck находит значение `x`, нарушающее свойство.
2. Генерирует набор "уменьшённых" вариантов `x` (shrinked candidates).
3. Для каждого варианта проверяет, нарушает ли он свойство.
4. Если да --- повторяет процесс с уменьшённым вариантом.
5. Продолжает, пока ни один уменьшённый вариант не нарушает свойство.

Результат --- минимальный контрпример, который легко анализировать и отлаживать.

## Пользовательские генераторы

### Создание arbitrary с QCheck.make

Для пользовательских типов нужно создать `arbitrary` с помощью `QCheck.make`:

```ocaml
type color = Red | Green | Blue

let color_gen : color QCheck.Gen.t =
  QCheck.Gen.oneofl [Red; Green; Blue]

let color_arb : color QCheck.arbitrary =
  QCheck.make
    ~print:(fun c -> match c with
      | Red -> "Red" | Green -> "Green" | Blue -> "Blue")
    color_gen
```

Функция `QCheck.make` принимает:

- Обязательный аргумент: `'a QCheck.Gen.t` --- низкоуровневый генератор.
- `~print` (опционально): `'a -> string` --- как напечатать значение для отладки.
- `~shrink` (опционально): `'a QCheck.Shrink.t` --- как уменьшать значение.

### Генерация деревьев

Создадим генератор для бинарного дерева:

```ocaml
type 'a tree =
  | Leaf
  | Node of 'a tree * 'a * 'a tree

let tree_gen (elem_gen : int QCheck.Gen.t) : int tree QCheck.Gen.t =
  QCheck.Gen.sized (fun n ->
    QCheck.Gen.fix (fun self n ->
      if n = 0 then QCheck.Gen.return Leaf
      else
        QCheck.Gen.frequency [
          (1, QCheck.Gen.return Leaf);
          (3, QCheck.Gen.map3
                (fun l v r -> Node (l, v, r))
                (self (n / 2))
                elem_gen
                (self (n / 2)));
        ]
    ) n)
```

Ключевые комбинаторы:

- `QCheck.Gen.sized` --- даёт доступ к текущему "размеру" (контролирует глубину).
- `QCheck.Gen.fix` --- рекурсивный генератор.
- `QCheck.Gen.frequency` --- выбор с весами (листья реже, узлы чаще).
- `QCheck.Gen.map3` --- применяет функцию к трём сгенерированным значениям.

### Генерация выражений

Аналогичный подход для арифметических выражений:

```ocaml
type expr =
  | Lit of int
  | Add of expr * expr
  | Mul of expr * expr

let expr_gen : expr QCheck.Gen.t =
  QCheck.Gen.sized (fun n ->
    QCheck.Gen.fix (fun self n ->
      if n = 0 then
        QCheck.Gen.map (fun x -> Lit x) QCheck.Gen.small_int
      else
        QCheck.Gen.frequency [
          (3, QCheck.Gen.map (fun x -> Lit x) QCheck.Gen.small_int);
          (2, QCheck.Gen.map2 (fun a b -> Add (a, b))
                (self (n / 2)) (self (n / 2)));
          (1, QCheck.Gen.map2 (fun a b -> Mul (a, b))
                (self (n / 2)) (self (n / 2)));
        ]
    ) n)
```

## Roundtrip-тестирование

Один из самых мощных паттернов PBT --- **roundtrip-тестирование**: если у вас есть пара encode/decode, то для любого входа `decode (encode x) = Some x`.

```ocaml
let encode_pair (n, s) = Printf.sprintf "%d:%s" n s

let decode_pair str =
  match String.split_on_char ':' str with
  | [n_str; s] ->
    (match int_of_string_opt n_str with
     | Some n -> Some (n, s)
     | None -> None)
  | _ -> None

(* Roundtrip-свойство *)
let prop_roundtrip =
  QCheck.Test.make ~name:"encode/decode roundtrip" ~count:200
    QCheck.(pair small_int small_printable_string)
    (fun (n, s) ->
       (* Убираем ':' из строки, чтобы кодек работал корректно *)
       let s_clean = String.map (fun c -> if c = ':' then '_' else c) s in
       decode_pair (encode_pair (n, s_clean)) = Some (n, s_clean))
```

Roundtrip-тесты прекрасно подходят для:

- Сериализации/десериализации (JSON, binary, CSV).
- Парсеров и pretty-printers.
- Кодировки/декодировки (Base64, URL encoding).
- Миграций данных.

## Стратегии написания свойств

Формулировать свойства --- это навык, который приходит с практикой. Вот несколько полезных паттернов:

### 1. Инволюция

Если `f (f x) = x` для всех `x`:

```ocaml
(* List.rev, битовое NOT, кодирование/декодирование *)
fun x -> f (f x) = x
```

### 2. Идемпотентность

Если `f (f x) = f x` для всех `x`:

```ocaml
(* List.sort, String.trim, Set.of_list *)
fun x -> f (f x) = f x
```

### 3. Инвариант

После операции выполняется некоторое условие:

```ocaml
(* Результат sort всегда отсортирован *)
fun xs -> is_sorted (List.sort compare xs)
```

### 4. Эквивалентность с эталоном

Оптимизированная функция ведёт себя как простая эталонная:

```ocaml
fun x -> fast_function x = naive_function x
```

### 5. Roundtrip

Кодирование и декодирование --- взаимно обратные операции:

```ocaml
fun x -> decode (encode x) = Some x
```

## Бинарное дерево поиска: полный пример

Соберём всё вместе на примере BST (binary search tree). Определим структуру и операции:

```ocaml
type 'a bst =
  | Leaf
  | Node of 'a bst * 'a * 'a bst

let rec bst_insert x = function
  | Leaf -> Node (Leaf, x, Leaf)
  | Node (left, v, right) ->
    if x < v then Node (bst_insert x left, v, right)
    else if x > v then Node (left, v, bst_insert x right)
    else Node (left, v, right)

let bst_of_list lst =
  List.fold_left (fun acc x -> bst_insert x acc) Leaf lst

let rec bst_to_sorted_list = function
  | Leaf -> []
  | Node (left, v, right) ->
    bst_to_sorted_list left @ [v] @ bst_to_sorted_list right

let rec bst_mem x = function
  | Leaf -> false
  | Node (left, v, right) ->
    if x = v then true
    else if x < v then bst_mem x left
    else bst_mem x right
```

Теперь напишем свойства:

```ocaml
(* In-order обход даёт отсортированный список *)
let prop_bst_sorted =
  QCheck.Test.make ~name:"bst inorder sorted" ~count:200
    QCheck.(list small_int)
    (fun lst ->
       let tree = bst_of_list lst in
       is_sorted (bst_to_sorted_list tree))

(* Вставленный элемент можно найти *)
let prop_bst_membership =
  QCheck.Test.make ~name:"bst membership" ~count:200
    QCheck.(pair small_int (list small_int))
    (fun (x, xs) ->
       let tree = bst_of_list (x :: xs) in
       bst_mem x tree)

(* Размер BST <= размер входного списка (дубликаты удаляются) *)
let prop_bst_size =
  QCheck.Test.make ~name:"bst size <= input" ~count:200
    QCheck.(list small_int)
    (fun lst ->
       let tree = bst_of_list lst in
       let sorted = bst_to_sorted_list tree in
       List.length sorted <= List.length lst)
```

## Сравнение с Haskell QuickCheck

Если вы знакомы с Haskell-овским QuickCheck, вот основные соответствия:

| Haskell (QuickCheck) | OCaml (QCheck) |
|---|---|
| `Arbitrary a` (тайпкласс) | `'a QCheck.arbitrary` (значение) |
| `Gen a` | `'a QCheck.Gen.t` |
| `property` | `QCheck.Test.t` |
| `forAll gen prop` | `QCheck.Test.make gen prop` |
| `arbitrary` | `QCheck.int`, `QCheck.string` и т.д. |
| `shrink` | Встроен в `arbitrary` |
| `oneof [gen1, gen2]` | `QCheck.Gen.oneof [gen1; gen2]` |
| `frequency [(3, g1), (1, g2)]` | `QCheck.Gen.frequency [(3, g1); (1, g2)]` |
| `sized $ \n -> ...` | `QCheck.Gen.sized (fun n -> ...)` |

Главное отличие: в Haskell `Arbitrary` --- это тайпкласс, и генератор для типа определяется один раз глобально. В OCaml генераторы --- это обычные значения, которые передаются явно. Это более гибко (можно иметь несколько генераторов для одного типа), но требует чуть больше кода.

## Упражнения

Решения пишите в файле `test/my_solutions.ml`. Запускайте `dune test` для проверки.

1. **(Лёгкое)** Реализуйте свойство `prop_rev_involution`: для любого списка целых чисел `List.rev (List.rev xs) = xs`.

2. **(Лёгкое)** Реализуйте свойство `prop_sort_sorted`: для любого списка целых чисел результат `List.sort compare xs` отсортирован. Используйте функцию `is_sorted` из библиотеки.

3. **(Среднее)** Реализуйте свойство `prop_bst_membership`: если вставить элемент `x` в BST (построенный из списка `xs`), то `bst_mem x tree` вернёт `true`. Используйте функции `bst_of_list` и `bst_mem` из библиотеки.

4. **(Среднее)** Реализуйте свойство `prop_codec_roundtrip`: для любой пары `(n, s)` выполняется `decode_pair (encode_pair (n, s_clean)) = Some (n, s_clean)`, где `s_clean` --- строка `s` с заменой символа `':'` на `'_'`. Используйте функции `encode_pair` и `decode_pair` из библиотеки.

## Заключение

В этой главе мы:

- Познакомились с генеративным (property-based) тестированием и его отличиями от юнит-тестов.
- Изучили библиотеку QCheck: генераторы, свойства, запуск тестов.
- Написали свойства для стандартных функций (`List.rev`, `List.sort`).
- Научились создавать пользовательские генераторы для деревьев и выражений.
- Разобрали механизм shrinking --- автоматическое уменьшение контрпримеров.
- Освоили паттерны: инволюция, идемпотентность, инвариант, roundtrip, эквивалентность с эталоном.
- Применили всё это к тестированию BST.

Генеративное тестирование --- мощный инструмент, который дополняет юнит-тесты. Оно особенно эффективно для алгоритмов, структур данных и любого кода с чётко формулируемыми инвариантами. Попробуйте добавить QCheck-тесты к коду из предыдущих глав --- вы можете обнаружить баги, о которых даже не подозревали.
