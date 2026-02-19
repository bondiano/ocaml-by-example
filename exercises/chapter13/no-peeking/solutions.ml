(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)
open Chapter13.Properties

(** Инволюция reverse. *)
let prop_rev_involution =
  QCheck.Test.make ~name:"rev_involution" ~count:100
    QCheck.(list small_int)
    (fun lst -> List.rev (List.rev lst) = lst)

(** Sort возвращает отсортированный список. *)
let prop_sort_sorted =
  QCheck.Test.make ~name:"sort_sorted" ~count:100
    QCheck.(list small_int)
    (fun lst -> is_sorted (List.sort compare lst))

(** BST содержит все вставленные элементы. *)
let prop_bst_membership =
  QCheck.Test.make ~name:"bst_membership" ~count:100
    QCheck.(pair small_int (list small_int))
    (fun (x, xs) ->
       let tree = bst_of_list (x :: xs) in
       bst_mem x tree)

(** Roundtrip для кодека (только строки без ':'). *)
let prop_codec_roundtrip =
  QCheck.Test.make ~name:"codec_roundtrip" ~count:100
    QCheck.(pair small_int (string_of_size (Gen.return 5)))
    (fun (n, s) ->
       let s_clean = String.map (fun c -> if c = ':' then '_' else c) s in
       decode_pair (encode_pair (n, s_clean)) = Some (n, s_clean))

(** Binary Search. *)
let binary_search arr target =
  let rec loop lo hi =
    if lo > hi then None
    else
      let mid = lo + (hi - lo) / 2 in
      if arr.(mid) = target then Some mid
      else if arr.(mid) < target then loop (mid + 1) hi
      else loop lo (mid - 1)
  in
  if Array.length arr = 0 then None
  else loop 0 (Array.length arr - 1)

(** BST. *)
module BST = struct
  type 'a t =
    | Empty
    | Node of 'a t * 'a * 'a t

  let empty = Empty

  let rec insert value = function
    | Empty -> Node (Empty, value, Empty)
    | Node (left, v, right) ->
      if value <= v then Node (insert value left, v, right)
      else Node (left, v, insert value right)

  let rec mem value = function
    | Empty -> false
    | Node (left, v, right) ->
      if value = v then true
      else if value < v then mem value left
      else mem value right

  let to_sorted_list tree =
    let rec loop acc = function
      | Empty -> acc
      | Node (left, v, right) ->
        loop (v :: loop acc right) left
    in
    loop [] tree
end
