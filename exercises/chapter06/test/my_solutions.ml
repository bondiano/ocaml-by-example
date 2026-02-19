(** Здесь вы можете писать свои решения упражнений. *)

open Chapter06.Path

let all_files (_p : path) : path list =
  failwith "todo"

let largest_file (_p : path) : (path * int) option =
  failwith "todo"

let where_is (_p : path) (_name : string) : path option =
  failwith "todo"

let total_size (_p : path) : int =
  failwith "todo"

let fibs : int Seq.t =
  fun () -> failwith "todo"

(** Упражнение: Pangram — проверить, содержит ли строка все буквы алфавита. *)
let is_pangram (_sentence : string) : bool = failwith "todo"

(** Упражнение: Isogram — проверить, все ли буквы уникальны. *)
let is_isogram (_word : string) : bool = failwith "todo"

(** Упражнение: Anagram — найти анаграммы слова из списка. *)
let anagrams (_word : string) (_candidates : string list) : string list = failwith "todo"

(** Упражнение: Reverse String *)
let reverse_string (_s : string) : string = failwith "todo"

(** Упражнение: Nucleotide Count *)
let nucleotide_count (_dna : string) : (char * int) list = failwith "todo"

(** Упражнение: Hamming distance *)
let hamming_distance (_s1 : string) (_s2 : string) : (int, string) result = failwith "todo"

(** Упражнение: Run-Length Encoding *)
let rle_encode (_s : string) : string = failwith "todo"
let rle_decode (_s : string) : string = failwith "todo"

(** Упражнение: Traverse option *)
let traverse_option (_f : 'a -> 'b option) (_lst : 'a list) : 'b list option =
  failwith "todo"

(** Упражнение: Traverse result *)
let traverse_result (_f : 'a -> ('b, 'e) result) (_lst : 'a list) : ('b list, 'e) result =
  failwith "todo"

(** Упражнение: List Ops — реализуйте операции над списками без List.*. *)
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
