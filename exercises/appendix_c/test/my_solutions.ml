(** Здесь вы можете писать свои решения упражнений. *)

open Appendix_c.Schemes

(** Упражнение 1: Катаморфизм для дерева --- глубина и размер.
    Реализуйте cata_tree, tree_depth и tree_size. *)

let cata_tree (_alg : 'a tree_f -> 'a) (_t : fix_tree) : 'a =
  ignore _alg; ignore _t;
  failwith "todo"

let tree_depth (_t : fix_tree) : int =
  ignore _t;
  failwith "todo"

let tree_size (_t : fix_tree) : int =
  ignore _t;
  failwith "todo"

(** Упражнение 2: Анаморфизм для дерева --- генерация сбалансированного дерева. *)

let ana_tree (_coalg : 'a -> 'a tree_f) (_seed : 'a) : fix_tree =
  ignore _coalg; ignore _seed;
  failwith "todo"

let gen_balanced (_depth : int) : fix_tree =
  ignore _depth;
  failwith "todo"

(** Упражнение 3: Гиломорфизм для списка --- сортировка выбором.
    Реализуйте hylo_list и merge_sort. *)

let hylo_list
    (_alg : 'b list_f -> 'b)
    (_coalg : 'a -> 'a list_f)
    (_seed : 'a) : 'b =
  ignore _alg; ignore _coalg; ignore _seed;
  failwith "todo"

let merge_sort (_lst : int list) : int list =
  ignore _lst;
  failwith "todo"

(** Упражнение 4: Параморфизм для списка --- вычисление всех суффиксов.
    Реализуйте para_list и tails. *)

let para_list
    (_alg : (fix_list * 'a) list_f -> 'a)
    (_fl : fix_list) : 'a =
  ignore _alg; ignore _fl;
  failwith "todo"

let tails (_fl : fix_list) : fix_list list =
  ignore _fl;
  failwith "todo"

(** Упражнение 5: Замена JNull через cata --- трансформация JSON.
    Реализуйте replace_nulls. *)

let replace_nulls (_default : json) (_j : json) : json =
  ignore _default; ignore _j;
  failwith "todo"
