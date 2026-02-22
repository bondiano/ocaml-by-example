(** Здесь вы можете писать свои решения упражнений. *)

open Appendix_c.Schemes

(* ===== Катаморфизм (складка) ===== *)

(* Сложное *)
(** Упражнение 1: cata_tree — катаморфизм для дерева.

    Катаморфизм (catamorphism) — это обобщённая складка для рекурсивных структур.

    Идея:
    1. Развернуть fix-point: Fix t -> t (Fix t)
    2. Рекурсивно применить cata к поддеревьям
    3. Применить алгебру к результату

    Реализуйте три функции:
    a) cata_tree: общий катаморфизм для дерева
    b) tree_depth: глубина дерева через cata_tree
    c) tree_size: количество узлов через cata_tree

    Типы из библиотеки:
    {[
      type 'a tree_f = Leaf | Node of 'a * 'a
      type fix_tree = Fix of fix_tree tree_f

      (* Алгебра для катаморфизма *)
      type 'a algebra = 'a tree_f -> 'a
    ]}

    Примеры:
    {[
      let t = Fix (Node (Fix Leaf, Fix Leaf)) in

      tree_depth t = 1  (* один уровень узлов *)
      tree_size t = 3   (* 1 узел + 2 листа *)
    ]}

    Подсказки:
    1. cata_tree:
       {[
         let rec cata_tree alg (Fix t) =
           match t with
           | Leaf -> alg Leaf
           | Node (l, r) ->
               let l' = cata_tree alg l in
               let r' = cata_tree alg r in
               alg (Node (l', r'))
       ]}
    2. tree_depth через алгебру:
       {[
         cata_tree (function
           | Leaf -> 0
           | Node (dl, dr) -> 1 + max dl dr
         ) t
       ]}
    3. tree_size через алгебру:
       {[
         cata_tree (function
           | Leaf -> 1
           | Node (sl, sr) -> sl + sr
         ) t
       ]}

    Связанные темы: Catamorphism, recursion schemes, F-algebras
    Время: ~35 минут *)
let cata_tree (_alg : 'a tree_f -> 'a) (_t : fix_tree) : 'a =
  ignore _alg; ignore _t;
  failwith "todo"

let tree_depth (_t : fix_tree) : int =
  ignore _t;
  failwith "todo"

let tree_size (_t : fix_tree) : int =
  ignore _t;
  failwith "todo"

(* ===== Анаморфизм (разворачивание) ===== *)

(* Сложное *)
(** Упражнение 2: ana_tree — анаморфизм для дерева.

    Анаморфизм (anamorphism) — это обобщённая генерация рекурсивных структур.
    Dual к катаморфизму.

    Идея:
    1. Применить коалгебру к seed
    2. Рекурсивно применить ana к поддеревьям
    3. Обернуть в Fix

    Реализуйте две функции:
    a) ana_tree: общий анаморфизм для дерева
    b) gen_balanced: генерация сбалансированного дерева заданной глубины

    Типы:
    {[
      type 'a coalgebra = 'a -> 'a tree_f
    ]}

    Примеры:
    {[
      gen_balanced 0 = Fix Leaf
      gen_balanced 1 = Fix (Node (Fix Leaf, Fix Leaf))
      gen_balanced 2 = Fix (Node (
        Fix (Node (Fix Leaf, Fix Leaf)),
        Fix (Node (Fix Leaf, Fix Leaf))
      ))
    ]}

    Подсказки:
    1. ana_tree:
       {[
         let rec ana_tree coalg seed =
           match coalg seed with
           | Leaf -> Fix Leaf
           | Node (l_seed, r_seed) ->
               let l = ana_tree coalg l_seed in
               let r = ana_tree coalg r_seed in
               Fix (Node (l, r))
       ]}
    2. gen_balanced через коалгебру:
       {[
         ana_tree (fun depth ->
           if depth <= 0 then Leaf
           else Node (depth - 1, depth - 1)
         ) depth
       ]}

    Связанные темы: Anamorphism, unfold, F-coalgebras
    Время: ~30 минут *)
let ana_tree (_coalg : 'a -> 'a tree_f) (_seed : 'a) : fix_tree =
  ignore _coalg; ignore _seed;
  failwith "todo"

let gen_balanced (_depth : int) : fix_tree =
  ignore _depth;
  failwith "todo"

(* ===== Гиломорфизм (разворачивание + складка) ===== *)

(* Сложное *)
(** Упражнение 3: hylo_list — гиломорфизм для списка.

    Гиломорфизм (hylomorphism) = anamorphism + catamorphism.
    Сначала разворачиваем структуру, потом сворачиваем, но БЕЗ создания
    промежуточной структуры в памяти!

    Идея:
    hylo alg coalg seed = cata alg (ana coalg seed)
    НО без создания промежуточного дерева!

    Реализуйте две функции:
    a) hylo_list: общий гиломорфизм для списка
    b) merge_sort: сортировка слиянием через hylo_list

    Типы:
    {[
      type 'a list_f = Nil | Cons of 'a * 'b
    ]}

    Примеры:
    {[
      merge_sort [3; 1; 4; 1; 5; 9; 2; 6] = [1; 1; 2; 3; 4; 5; 6; 9]
      merge_sort [] = []
    ]}

    Подсказки:
    1. hylo_list:
       {[
         let rec hylo_list alg coalg seed =
           match coalg seed with
           | Nil -> alg Nil
           | Cons (x, next_seed) ->
               let rest = hylo_list alg coalg next_seed in
               alg (Cons (x, rest))
       ]}
    2. merge_sort через гиломорфизм:
       - Коалгебра: разбить список пополам (divide)
       - Алгебра: слить два отсортированных списка (merge)
       {[
         hylo_list
           (function  (* merge *)
             | Nil -> []
             | Cons (x, xs) -> merge x xs)
           (function  (* split *)
             | [] -> Nil
             | [x] -> Cons (x, [])
             | lst -> let (l, r) = split lst in Cons (l, r))
           lst
       ]}
    3. Вспомогательные функции split и merge

    Связанные темы: Hylomorphism, merge sort, divide-and-conquer
    Время: ~35 минут *)
let hylo_list
    (_alg : 'b list_f -> 'b)
    (_coalg : 'a -> 'a list_f)
    (_seed : 'a) : 'b =
  ignore _alg; ignore _coalg; ignore _seed;
  failwith "todo"

let merge_sort (_lst : int list) : int list =
  ignore _lst;
  failwith "todo"

(* ===== Параморфизм (складка с историей) ===== *)

(* Сложное *)
(** Упражнение 4: para_list — параморфизм для списка.

    Параморфизм (paramorphism) — это катаморфизм, где алгебра получает доступ
    не только к результату рекурсии, но и к исходной подструктуре.

    Идея:
    При обработке Cons (x, xs) алгебра получает:
    - x: текущий элемент
    - (xs, результат_рекурсии_на_xs): пара из исходного хвоста и результата

    Реализуйте две функции:
    a) para_list: общий параморфизм для списка
    b) tails: все суффиксы списка через para_list

    Примеры:
    {[
      tails (list_of [1; 2; 3]) = [
        list_of [1; 2; 3];
        list_of [2; 3];
        list_of [3];
        list_of []
      ]
    ]}

    Подсказки:
    1. para_list:
       {[
         let rec para_list alg (Fix lst) =
           match lst with
           | Nil -> alg Nil
           | Cons (x, xs) ->
               let rest = para_list alg xs in
               alg (Cons (x, (xs, rest)))
       ]}
    2. tails через параморфизм:
       {[
         para_list (function
           | Nil -> [Fix Nil]  (* пустой список *)
           | Cons (_, (xs, ts)) -> Fix (Cons (_, xs)) :: ts
         ) fl
       ]}
    3. Параморфизм даёт доступ к xs (исходному хвосту)

    Связанные темы: Paramorphism, history-aware fold, tails
    Время: ~30 минут *)
let para_list
    (_alg : (fix_list * 'a) list_f -> 'a)
    (_fl : fix_list) : 'a =
  ignore _alg; ignore _fl;
  failwith "todo"

let tails (_fl : fix_list) : fix_list list =
  ignore _fl;
  failwith "todo"

(* ===== Применение cata к JSON ===== *)

(* Среднее *)
(** Упражнение 5: replace_nulls — замена null значений в JSON.

    Использовать катаморфизм для трансформации JSON:
    заменить все JNull на заданное default значение.

    Тип json (из библиотеки):
    {[
      type json =
        | JNull
        | JBool of bool
        | JInt of int
        | JString of string
        | JArray of json list
        | JObject of (string * json) list
    ]}

    Примеры:
    {[
      let j = JObject [
        ("name", JString "Alice");
        ("age", JNull);
        ("tags", JArray [JString "dev"; JNull])
      ]

      replace_nulls (JInt 0) j = JObject [
        ("name", JString "Alice");
        ("age", JInt 0);
        ("tags", JArray [JString "dev"; JInt 0])
      ]
    ]}

    Подсказки:
    1. Написать катаморфизм (рекурсивная функция):
       {[
         let rec replace j =
           match j with
           | JNull -> default
           | JBool b -> JBool b
           | JInt n -> JInt n
           | JString s -> JString s
           | JArray items -> JArray (List.map replace items)
           | JObject fields -> JObject (List.map (fun (k, v) -> (k, replace v)) fields)
       ]}
    2. Рекурсивно обходить все поля
    3. При встрече JNull заменять на default

    Связанные темы: JSON transformation, catamorphism application
    Время: ~20 минут *)
let replace_nulls (_default : json) (_j : json) : json =
  ignore _default; ignore _j;
  failwith "todo"
