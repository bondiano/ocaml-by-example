(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Appendix_c.Schemes

(** Упражнение 1: Катаморфизм для дерева --- глубина и размер. *)

let cata_tree (alg : 'a tree_f -> 'a) (Fix_tree layer : fix_tree) : 'a =
  alg (map_tree_f (cata_tree alg) layer)

let tree_depth (t : fix_tree) : int =
  let alg = function
    | Leaf -> 0
    | Node (l, _, r) -> 1 + max l r
  in
  cata_tree alg t

let tree_size (t : fix_tree) : int =
  let alg = function
    | Leaf -> 0
    | Node (l, _, r) -> 1 + l + r
  in
  cata_tree alg t

(** Упражнение 2: Анаморфизм для дерева --- генерация сбалансированного дерева. *)

let ana_tree (coalg : 'a -> 'a tree_f) (seed : 'a) : fix_tree =
  Fix_tree (map_tree_f (ana_tree coalg) (coalg seed))

let gen_balanced (depth : int) : fix_tree =
  let coalg = function
    | 0 -> Leaf
    | n -> Node (n - 1, n, n - 1)
  in
  ana_tree coalg depth

(** Упражнение 3: Гиломорфизм для списка --- сортировка выбором.
    Разворачиваем список, на каждом шаге извлекая минимальный элемент,
    затем сворачиваем в отсортированный список. *)

let hylo_list
    (alg : 'b list_f -> 'b)
    (coalg : 'a -> 'a list_f)
    (seed : 'a) : 'b =
  alg (map_list_f (hylo_list alg coalg) (coalg seed))

let merge_sort (lst : int list) : int list =
  (* Вспомогательная функция: найти и извлечь минимальный элемент *)
  let extract_min = function
    | [] -> None
    | x :: rest ->
      let min_val, others =
        List.fold_left (fun (m, acc) y ->
          if y < m then (y, m :: acc)
          else (m, y :: acc)
        ) (x, []) rest
      in
      Some (min_val, others)
  in
  (* Коалгебра: извлекаем минимум из списка *)
  let coalg (lst : int list) : int list list_f =
    match extract_min lst with
    | None -> Nil
    | Some (min_val, rest) -> Cons (min_val, rest)
  in
  (* Алгебра: собираем отсортированный список *)
  let alg : int list list_f -> int list = function
    | Nil -> []
    | Cons (x, sorted) -> x :: sorted
  in
  hylo_list alg coalg lst

(** Упражнение 4: Параморфизм для списка --- вычисление всех суффиксов.
    Алгебра получает пару (исходный хвост, результат рекурсии). *)

let para_list
    (alg : (fix_list * 'a) list_f -> 'a)
    (Fix_list layer : fix_list) : 'a =
  let mapped = map_list_f
    (fun sub -> (sub, para_list alg sub))
    layer
  in
  alg mapped

let tails (fl : fix_list) : fix_list list =
  let alg : (fix_list * fix_list list) list_f -> fix_list list = function
    | Nil -> [Fix_list Nil]
    | Cons (x, (original_tail, tails_of_tail)) ->
      (* Восстанавливаем текущий список: Cons (x, original_tail) *)
      let current = Fix_list (Cons (x, original_tail)) in
      current :: tails_of_tail
  in
  para_list alg fl

(** Упражнение 5: Замена JNull через cata --- трансформация JSON.
    Рекурсивно заменяет все JNull на заданное значение по умолчанию. *)

let replace_nulls (default : json) (j : json) : json =
  let alg : json json_f -> json = function
    | JNull -> default
    | other -> JsonSchemes.fix other
  in
  JsonSchemes.cata alg j
