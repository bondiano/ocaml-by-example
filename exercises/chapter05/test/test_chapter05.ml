open Chapter05.Path

(* --- Пользовательские testable для Alcotest --- *)

let path_testable : path Alcotest.testable =
  Alcotest.testable
    (fun fmt p -> Format.pp_print_string fmt (filename p))
    (fun a b -> a = b)

(* --- Тесты библиотеки --- *)

let filename_tests =
  let open Alcotest in
  [
    test_case "имя файла" `Quick (fun () ->
      check string "file" "readme.txt" (filename (File ("readme.txt", 100))));
    test_case "имя директории" `Quick (fun () ->
      check string "dir" "src" (filename (Directory ("src", []))));
  ]

let all_paths_tests =
  let open Alcotest in
  [
    test_case "все элементы root" `Quick (fun () ->
      check int "count" 11 (List.length (all_paths root)));
    test_case "все элементы одного файла" `Quick (fun () ->
      check int "single file" 1
        (List.length (all_paths (File ("a.ml", 10)))));
  ]

(* --- Тесты упражнений --- *)

let all_files_tests =
  let open Alcotest in
  [
    test_case "количество файлов в root" `Quick (fun () ->
      check int "files count" 7
        (List.length (My_solutions.all_files root)));
    test_case "файлы не содержат директорий" `Quick (fun () ->
      check bool "no dirs" true
        (My_solutions.all_files root
         |> List.for_all (fun p -> not (is_directory p))));
    test_case "один файл" `Quick (fun () ->
      let f = File ("a.ml", 10) in
      check (list path_testable) "single" [f]
        (My_solutions.all_files f));
  ]

let largest_file_tests =
  let open Alcotest in
  let pair = pair path_testable int in
  [
    test_case "наибольший файл в root" `Quick (fun () ->
      check (option pair) "largest"
        (Some (File ("parser.ml", 800), 800))
        (My_solutions.largest_file root));
    test_case "пустая директория" `Quick (fun () ->
      check (option pair) "empty dir"
        None
        (My_solutions.largest_file (Directory ("empty", []))));
    test_case "один файл" `Quick (fun () ->
      let f = File ("a.ml", 42) in
      check (option pair) "single"
        (Some (f, 42))
        (My_solutions.largest_file f));
  ]

let where_is_tests =
  let open Alcotest in
  [
    test_case "найти parser.ml" `Quick (fun () ->
      check (option string) "parser.ml"
        (Some "lib")
        (My_solutions.where_is root "parser.ml"
         |> Option.map filename));
    test_case "найти test_main.ml" `Quick (fun () ->
      check (option string) "test_main.ml"
        (Some "test")
        (My_solutions.where_is root "test_main.ml"
         |> Option.map filename));
    test_case "найти readme.txt" `Quick (fun () ->
      check (option string) "readme.txt"
        (Some "root")
        (My_solutions.where_is root "readme.txt"
         |> Option.map filename));
    test_case "файл не существует" `Quick (fun () ->
      check (option string) "not found"
        None
        (My_solutions.where_is root "nonexistent.ml"
         |> Option.map filename));
  ]

let total_size_tests =
  let open Alcotest in
  [
    test_case "суммарный размер root" `Quick (fun () ->
      check int "total" 2750 (My_solutions.total_size root));
    test_case "один файл" `Quick (fun () ->
      check int "single" 42 (My_solutions.total_size (File ("a.ml", 42))));
    test_case "пустая директория" `Quick (fun () ->
      check int "empty" 0
        (My_solutions.total_size (Directory ("empty", []))));
  ]

let fibs_tests =
  let open Alcotest in
  [
    test_case "первые 7 чисел Фибоначчи" `Quick (fun () ->
      check (list int) "fibs 7"
        [0; 1; 1; 2; 3; 5; 8]
        (Seq.take 7 My_solutions.fibs |> List.of_seq));
    test_case "первые 10 чисел Фибоначчи" `Quick (fun () ->
      check (list int) "fibs 10"
        [0; 1; 1; 2; 3; 5; 8; 13; 21; 34]
        (Seq.take 10 My_solutions.fibs |> List.of_seq));
  ]

let pangram_tests =
  let open Alcotest in
  [
    test_case "pangram" `Quick (fun () ->
      check bool "yes" true
        (My_solutions.is_pangram "The quick brown fox jumps over the lazy dog"));
    test_case "not pangram" `Quick (fun () ->
      check bool "no" false (My_solutions.is_pangram "hello world"));
  ]

let isogram_tests =
  let open Alcotest in
  [
    test_case "isogram" `Quick (fun () ->
      check bool "yes" true (My_solutions.is_isogram "subdermatoglyphic"));
    test_case "not isogram" `Quick (fun () ->
      check bool "no" false (My_solutions.is_isogram "hello"));
    test_case "with spaces" `Quick (fun () ->
      check bool "spaces ok" true (My_solutions.is_isogram "lumberjack"));
  ]

let anagram_tests =
  let open Alcotest in
  [
    test_case "найти анаграммы" `Quick (fun () ->
      check (list string) "anagrams"
        ["tan"; "nat"]
        (My_solutions.anagrams "ant" ["tan"; "stand"; "at"; "nat"]));
    test_case "без совпадений" `Quick (fun () ->
      check (list string) "none" []
        (My_solutions.anagrams "hello" ["world"; "hi"]));
    test_case "само слово не анаграмма" `Quick (fun () ->
      check (list string) "self" ["tan"]
        (My_solutions.anagrams "ant" ["ant"; "tan"]));
  ]

let reverse_string_tests =
  let open Alcotest in
  [
    test_case "reverse" `Quick (fun () ->
      check string "rev" "olleh" (My_solutions.reverse_string "hello"));
    test_case "empty" `Quick (fun () ->
      check string "empty" "" (My_solutions.reverse_string ""));
  ]

let nucleotide_tests =
  let open Alcotest in
  let pair = Alcotest.(pair char int) in
  [
    test_case "count nucleotides" `Quick (fun () ->
      check (list pair) "counts"
        [('A', 2); ('C', 1); ('G', 1); ('T', 1)]
        (My_solutions.nucleotide_count "AACGT"
         |> List.sort (fun (a, _) (b, _) -> Char.compare a b)));
  ]

let hamming_tests =
  let open Alcotest in
  [
    test_case "нет отличий" `Quick (fun () ->
      check (result int string) "same" (Ok 0)
        (My_solutions.hamming_distance "GAGCCTACTAACGGGAT" "GAGCCTACTAACGGGAT"));
    test_case "есть отличия" `Quick (fun () ->
      check (result int string) "diff" (Ok 7)
        (My_solutions.hamming_distance "GAGCCTACTAACGGGAT" "CATCGTAATGACGGCCT"));
    test_case "разная длина" `Quick (fun () ->
      match My_solutions.hamming_distance "ABC" "AB" with
      | Error _ -> ()
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let rle_tests =
  let open Alcotest in
  [
    test_case "encode" `Quick (fun () ->
      check string "encoded" "2A3B1C"
        (My_solutions.rle_encode "AABBBC"));
    test_case "decode" `Quick (fun () ->
      check string "decoded" "AABBBC"
        (My_solutions.rle_decode "2A3B1C"));
    test_case "roundtrip" `Quick (fun () ->
      let s = "AAABBBCCCD" in
      check string "roundtrip" s
        (My_solutions.rle_decode (My_solutions.rle_encode s)));
  ]

let list_ops_tests =
  let open Alcotest in
  [
    test_case "length пустого списка" `Quick (fun () ->
      check int "empty" 0 (My_solutions.List_ops.length []));
    test_case "length непустого" `Quick (fun () ->
      check int "len 4" 4 (My_solutions.List_ops.length [1; 2; 3; 4]));
    test_case "reverse" `Quick (fun () ->
      check (list int) "rev" [3; 2; 1]
        (My_solutions.List_ops.reverse [1; 2; 3]));
    test_case "map" `Quick (fun () ->
      check (list int) "map" [2; 4; 6]
        (My_solutions.List_ops.map (fun x -> x * 2) [1; 2; 3]));
    test_case "filter" `Quick (fun () ->
      check (list int) "filter" [2; 4]
        (My_solutions.List_ops.filter (fun x -> x mod 2 = 0) [1; 2; 3; 4]));
    test_case "fold_left" `Quick (fun () ->
      check int "sum" 10
        (My_solutions.List_ops.fold_left ( + ) 0 [1; 2; 3; 4]));
    test_case "fold_right" `Quick (fun () ->
      check (list int) "cons" [1; 2; 3]
        (My_solutions.List_ops.fold_right (fun x acc -> x :: acc) [1; 2; 3] []));
    test_case "append" `Quick (fun () ->
      check (list int) "append" [1; 2; 3; 4]
        (My_solutions.List_ops.append [1; 2] [3; 4]));
    test_case "concat" `Quick (fun () ->
      check (list int) "concat" [1; 2; 3; 4; 5; 6]
        (My_solutions.List_ops.concat [[1; 2]; [3; 4]; [5; 6]]));
  ]

let traverse_tests =
  let open Alcotest in
  [
    test_case "traverse_option все Some" `Quick (fun () ->
      check (option (list int)) "all some"
        (Some [1; 2; 3])
        (My_solutions.traverse_option int_of_string_opt ["1"; "2"; "3"]));
    test_case "traverse_option с None" `Quick (fun () ->
      check (option (list int)) "has none"
        None
        (My_solutions.traverse_option int_of_string_opt ["1"; "abc"; "3"]));
    test_case "traverse_option пустой список" `Quick (fun () ->
      check (option (list int)) "empty"
        (Some [])
        (My_solutions.traverse_option int_of_string_opt []));
    test_case "traverse_result все Ok" `Quick (fun () ->
      let parse s =
        match int_of_string_opt s with
        | Some n -> Ok n
        | None -> Error (Printf.sprintf "не число: %s" s)
      in
      check (result (list int) string) "all ok"
        (Ok [1; 2; 3])
        (My_solutions.traverse_result parse ["1"; "2"; "3"]));
    test_case "traverse_result с Error" `Quick (fun () ->
      let parse s =
        match int_of_string_opt s with
        | Some n -> Ok n
        | None -> Error (Printf.sprintf "не число: %s" s)
      in
      check (result (list int) string) "has error"
        (Error "не число: abc")
        (My_solutions.traverse_result parse ["1"; "abc"; "3"]));
  ]

let () =
  Alcotest.run "Chapter 05"
    [
      ("filename --- имя элемента", filename_tests);
      ("all_paths --- обход дерева", all_paths_tests);
      ("all_files --- только файлы", all_files_tests);
      ("largest_file --- наибольший файл", largest_file_tests);
      ("where_is --- поиск файла", where_is_tests);
      ("total_size --- суммарный размер", total_size_tests);
      ("fibs --- числа Фибоначчи", fibs_tests);
      ("Pangram", pangram_tests);
      ("Isogram", isogram_tests);
      ("Anagram", anagram_tests);
      ("Reverse String", reverse_string_tests);
      ("Nucleotide Count", nucleotide_tests);
      ("Hamming Distance", hamming_tests);
      ("Run-Length Encoding", rle_tests);
      ("Traverse", traverse_tests);
      ("List Ops", list_ops_tests);
    ]
