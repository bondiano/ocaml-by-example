(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Chapter05.Path

(** Извлечь только файлы (не директории) из дерева. *)
let all_files p =
  all_paths p |> List.filter (fun p -> not (is_directory p))

(** Найти файл с наибольшим размером. *)
let largest_file p =
  let files = all_files p in
  let with_sizes =
    List.filter_map (fun f ->
      match file_size f with
      | Some s -> Some (f, s)
      | None -> None
    ) files
  in
  match with_sizes with
  | [] -> None
  | first :: rest ->
    Some (List.fold_left (fun (best_f, best_s) (f, s) ->
      if s > best_s then (f, s) else (best_f, best_s)
    ) first rest)

(** Найти директорию, содержащую файл с данным именем. *)
let rec where_is p name =
  match p with
  | File _ -> None
  | Directory _ ->
    let cs = children p in
    if List.exists (fun c -> not (is_directory c) && filename c = name) cs then
      Some p
    else
      List.find_map (fun c -> where_is c name) cs

(** Суммарный размер всех файлов. *)
let total_size p =
  all_files p
  |> List.filter_map file_size
  |> List.fold_left ( + ) 0

(** Бесконечная последовательность чисел Фибоначчи. *)
let fibs =
  Seq.unfold (fun (a, b) -> Some (a, (b, a + b))) (0, 1)

(** Pangram. *)
let is_pangram sentence =
  let lower = String.lowercase_ascii sentence in
  let has_char c = String.contains lower c in
  let rec check c =
    if c > 'z' then true
    else has_char c && check (Char.chr (Char.code c + 1))
  in
  check 'a'

(** Isogram. *)
let is_isogram word =
  let lower = String.lowercase_ascii word in
  let chars =
    String.to_seq lower
    |> Seq.filter (fun c -> c >= 'a' && c <= 'z')
    |> List.of_seq
  in
  let unique = List.sort_uniq Char.compare chars in
  List.length chars = List.length unique

(** Anagram. *)
let anagrams word candidates =
  let sort_word w =
    String.lowercase_ascii w
    |> String.to_seq |> List.of_seq
    |> List.sort Char.compare
  in
  let sorted_word = sort_word word in
  let lower_word = String.lowercase_ascii word in
  List.filter (fun c ->
    String.lowercase_ascii c <> lower_word && sort_word c = sorted_word
  ) candidates

(** Reverse String. *)
let reverse_string s =
  let len = String.length s in
  String.init len (fun i -> s.[len - 1 - i])

(** Nucleotide Count. *)
let nucleotide_count dna =
  let counts = Hashtbl.create 4 in
  List.iter (fun c -> Hashtbl.replace counts c 0) ['A'; 'C'; 'G'; 'T'];
  String.iter (fun c ->
    match Hashtbl.find_opt counts c with
    | Some n -> Hashtbl.replace counts c (n + 1)
    | None -> ()
  ) dna;
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) counts []
  |> List.sort (fun (a, _) (b, _) -> Char.compare a b)

(** Hamming distance. *)
let hamming_distance s1 s2 =
  if String.length s1 <> String.length s2 then
    Error "строки должны быть одной длины"
  else
    let count = ref 0 in
    String.iteri (fun i c ->
      if c <> s2.[i] then incr count
    ) s1;
    Ok !count

(** Run-Length Encoding. *)
let rle_encode s =
  let len = String.length s in
  if len = 0 then ""
  else
    let buf = Buffer.create len in
    let count = ref 1 in
    for i = 1 to len - 1 do
      if s.[i] = s.[i - 1] then incr count
      else begin
        Buffer.add_string buf (string_of_int !count);
        Buffer.add_char buf s.[i - 1];
        count := 1
      end
    done;
    Buffer.add_string buf (string_of_int !count);
    Buffer.add_char buf s.[len - 1];
    Buffer.contents buf

let rle_decode s =
  let buf = Buffer.create (String.length s) in
  let num = Buffer.create 8 in
  String.iter (fun c ->
    if c >= '0' && c <= '9' then
      Buffer.add_char num c
    else begin
      let n = if Buffer.length num > 0 then int_of_string (Buffer.contents num) else 1 in
      for _ = 1 to n do Buffer.add_char buf c done;
      Buffer.clear num
    end
  ) s;
  Buffer.contents buf

(** Traverse option. *)
let traverse_option f lst =
  List.fold_right
    (fun x acc ->
      match f x, acc with
      | Some v, Some vs -> Some (v :: vs)
      | _ -> None)
    lst (Some [])

(** Traverse result. *)
let traverse_result f lst =
  List.fold_right
    (fun x acc ->
      match f x, acc with
      | Ok v, Ok vs -> Ok (v :: vs)
      | Error e, _ -> Error e
      | _, Error e -> Error e)
    lst (Ok [])

(** List Ops — реализация стандартных операций вручную. *)
module List_ops = struct
  let rec length = function
    | [] -> 0
    | _ :: tl -> 1 + length tl

  let reverse lst =
    let rec loop acc = function
      | [] -> acc
      | hd :: tl -> loop (hd :: acc) tl
    in
    loop [] lst

  let map f lst =
    let rec loop acc = function
      | [] -> reverse acc
      | hd :: tl -> loop (f hd :: acc) tl
    in
    loop [] lst

  let filter f lst =
    let rec loop acc = function
      | [] -> reverse acc
      | hd :: tl ->
        if f hd then loop (hd :: acc) tl
        else loop acc tl
    in
    loop [] lst

  let fold_left f init lst =
    let rec loop acc = function
      | [] -> acc
      | hd :: tl -> loop (f acc hd) tl
    in
    loop init lst

  let rec fold_right f lst init =
    match lst with
    | [] -> init
    | hd :: tl -> f hd (fold_right f tl init)

  let append xs ys =
    fold_right (fun x acc -> x :: acc) xs ys

  let concat lists =
    fold_right append lists []
end
