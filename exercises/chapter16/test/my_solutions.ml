(** Здесь вы можете писать свои решения упражнений. *)
open Chapter16.Properties
[@@warning "-33"]

(** Упражнение 1: Свойство reverse --- инволюция. *)
let prop_rev_involution =
  QCheck.Test.make ~name:"rev_involution" ~count:100
    QCheck.(list small_int)
    (fun _lst -> failwith "todo")

(** Упражнение 2: Свойство sort --- результат отсортирован. *)
let prop_sort_sorted =
  QCheck.Test.make ~name:"sort_sorted" ~count:100
    QCheck.(list small_int)
    (fun _lst -> failwith "todo")

(** Упражнение 3: Свойство BST --- все вставленные элементы присутствуют. *)
let prop_bst_membership =
  QCheck.Test.make ~name:"bst_membership" ~count:100
    QCheck.(pair small_int (list small_int))
    (fun (_x, _xs) -> failwith "todo")

(** Упражнение 4: Roundtrip для кодека. *)
let prop_codec_roundtrip =
  QCheck.Test.make ~name:"codec_roundtrip" ~count:100
    QCheck.(pair small_int (string_of_size (Gen.return 5)))
    (fun (_n, _s) -> failwith "todo")

(** Упражнение: Binary Search *)
let binary_search (_arr : int array) (_target : int) : int option = failwith "todo"

(** Упражнение: Binary Search Tree *)
module BST = struct
  type 'a t =
    | Empty
    | Node of 'a t * 'a * 'a t

  let empty : 'a t = Empty
  let insert (_value : 'a) (_tree : 'a t) : 'a t = failwith "todo"
  let mem (_value : 'a) (_tree : 'a t) : bool = failwith "todo"
  let to_sorted_list (_tree : 'a t) : 'a list = failwith "todo"
end
