(** Примеры генеративного тестирования с QCheck. *)

(** Бинарное дерево поиска. *)
type 'a bst =
  | Leaf
  | Node of 'a bst * 'a * 'a bst

(** Вставить элемент в BST. *)
let rec bst_insert x = function
  | Leaf -> Node (Leaf, x, Leaf)
  | Node (left, v, right) ->
    if x < v then Node (bst_insert x left, v, right)
    else if x > v then Node (left, v, bst_insert x right)
    else Node (left, v, right)

(** Построить BST из списка. *)
let bst_of_list lst =
  List.fold_left (fun acc x -> bst_insert x acc) Leaf lst

(** Обход BST в порядке in-order. *)
let rec bst_to_sorted_list = function
  | Leaf -> []
  | Node (left, v, right) ->
    bst_to_sorted_list left @ [v] @ bst_to_sorted_list right

(** Проверка: список отсортирован? *)
let rec is_sorted = function
  | [] | [_] -> true
  | x :: y :: rest -> x <= y && is_sorted (y :: rest)

(** Членство в BST. *)
let rec bst_mem x = function
  | Leaf -> false
  | Node (left, v, right) ->
    if x = v then true
    else if x < v then bst_mem x left
    else bst_mem x right

(** Простой кодек: кодирование/декодирование пары (int * string). *)
let encode_pair (n, s) =
  Printf.sprintf "%d:%s" n s

let decode_pair str =
  match String.split_on_char ':' str with
  | [n_str; s] ->
    (match int_of_string_opt n_str with
     | Some n -> Some (n, s)
     | None -> None)
  | _ -> None
