open Chapter06.Path

(* --- Пользовательские testable для Alcotest --- *)

let path_testable : path Alcotest.testable =
  Alcotest.testable
    (fun fmt p -> Format.pp_print_string fmt (filename p))
    (fun a b -> a = b)

(* --- Тесты библиотеки --- *)

let filename_tests =
  let open Alcotest in
  [
    test_case "при файле возвращает его имя" `Quick (fun () ->
      check string "filename" "readme.txt" (filename (File ("readme.txt", 100))));
    test_case "при директории возвращает её имя" `Quick (fun () ->
      check string "filename" "src" (filename (Directory ("src", []))));
  ]

let all_paths_tests =
  let open Alcotest in
  [
    test_case "при root возвращает 11 элементов" `Quick (fun () ->
      check int "all_paths" 11 (List.length (all_paths root)));
    test_case "при одиночном файле возвращает 1 элемент" `Quick (fun () ->
      check int "all_paths" 1
        (List.length (all_paths (File ("a.ml", 10)))));
  ]

(* --- Тесты упражнений --- *)

let all_files_tests =
  let open Alcotest in
  [
    test_case "при root возвращает 7 файлов" `Quick (fun () ->
      check int "all_files" 7
        (List.length (My_solutions.all_files root)));
    test_case "при root не содержит директорий" `Quick (fun () ->
      check bool "all_files" true
        (My_solutions.all_files root
         |> List.for_all (fun p -> not (is_directory p))));
    test_case "при одиночном файле возвращает список из него" `Quick (fun () ->
      let f = File ("a.ml", 10) in
      check (list path_testable) "all_files" [f]
        (My_solutions.all_files f));
  ]

let largest_file_tests =
  let open Alcotest in
  let pair = pair path_testable int in
  [
    test_case "при root возвращает parser.ml размером 800" `Quick (fun () ->
      check (option pair) "largest_file"
        (Some (File ("parser.ml", 800), 800))
        (My_solutions.largest_file root));
    test_case "при пустой директории возвращает None" `Quick (fun () ->
      check (option pair) "largest_file"
        None
        (My_solutions.largest_file (Directory ("empty", []))));
    test_case "при одиночном файле возвращает его с размером" `Quick (fun () ->
      let f = File ("a.ml", 42) in
      check (option pair) "largest_file"
        (Some (f, 42))
        (My_solutions.largest_file f));
  ]

let where_is_tests =
  let open Alcotest in
  [
    test_case "при поиске parser.ml возвращает директорию lib" `Quick (fun () ->
      check (option string) "where_is"
        (Some "lib")
        (My_solutions.where_is root "parser.ml"
         |> Option.map filename));
    test_case "при поиске test_main.ml возвращает директорию test" `Quick (fun () ->
      check (option string) "where_is"
        (Some "test")
        (My_solutions.where_is root "test_main.ml"
         |> Option.map filename));
    test_case "при поиске readme.txt возвращает директорию root" `Quick (fun () ->
      check (option string) "where_is"
        (Some "root")
        (My_solutions.where_is root "readme.txt"
         |> Option.map filename));
    test_case "при поиске несуществующего файла возвращает None" `Quick (fun () ->
      check (option string) "where_is"
        None
        (My_solutions.where_is root "nonexistent.ml"
         |> Option.map filename));
  ]

let total_size_tests =
  let open Alcotest in
  [
    test_case "при root возвращает 2750" `Quick (fun () ->
      check int "total_size" 2750 (My_solutions.total_size root));
    test_case "при одиночном файле возвращает его размер" `Quick (fun () ->
      check int "total_size" 42 (My_solutions.total_size (File ("a.ml", 42))));
    test_case "при пустой директории возвращает 0" `Quick (fun () ->
      check int "total_size" 0
        (My_solutions.total_size (Directory ("empty", []))));
  ]

let fibs_tests =
  let open Alcotest in
  [
    test_case "при взятии 7 элементов возвращает [0;1;1;2;3;5;8]" `Quick (fun () ->
      check (list int) "fibs"
        [0; 1; 1; 2; 3; 5; 8]
        (Seq.take 7 My_solutions.fibs |> List.of_seq));
    test_case "при взятии 10 элементов возвращает первые 10 чисел Фибоначчи" `Quick (fun () ->
      check (list int) "fibs"
        [0; 1; 1; 2; 3; 5; 8; 13; 21; 34]
        (Seq.take 10 My_solutions.fibs |> List.of_seq));
  ]

let pangram_tests =
  let open Alcotest in
  [
    test_case "при строке со всеми буквами возвращает true" `Quick (fun () ->
      check bool "is_pangram" true
        (My_solutions.is_pangram "The quick brown fox jumps over the lazy dog"));
    test_case "при строке без всех букв возвращает false" `Quick (fun () ->
      check bool "is_pangram" false (My_solutions.is_pangram "hello world"));
  ]

let isogram_tests =
  let open Alcotest in
  [
    test_case "при слове без повторов возвращает true" `Quick (fun () ->
      check bool "is_isogram" true (My_solutions.is_isogram "subdermatoglyphic"));
    test_case "при слове с повторами возвращает false" `Quick (fun () ->
      check bool "is_isogram" false (My_solutions.is_isogram "hello"));
    test_case "при слове с пробелами без повторов возвращает true" `Quick (fun () ->
      check bool "is_isogram" true (My_solutions.is_isogram "lumberjack"));
  ]

let anagram_tests =
  let open Alcotest in
  [
    test_case "при наличии анаграмм возвращает их список" `Quick (fun () ->
      check (list string) "anagrams"
        ["tan"; "nat"]
        (My_solutions.anagrams "ant" ["tan"; "stand"; "at"; "nat"]));
    test_case "при отсутствии анаграмм возвращает пустой список" `Quick (fun () ->
      check (list string) "anagrams" []
        (My_solutions.anagrams "hello" ["world"; "hi"]));
    test_case "при наличии самого слова не включает его в результат" `Quick (fun () ->
      check (list string) "anagrams" ["tan"]
        (My_solutions.anagrams "ant" ["ant"; "tan"]));
  ]

let reverse_string_tests =
  let open Alcotest in
  [
    test_case "при \"hello\" возвращает \"olleh\"" `Quick (fun () ->
      check string "reverse_string" "olleh" (My_solutions.reverse_string "hello"));
    test_case "при пустой строке возвращает пустую строку" `Quick (fun () ->
      check string "reverse_string" "" (My_solutions.reverse_string ""));
  ]

let nucleotide_tests =
  let open Alcotest in
  let pair = Alcotest.(pair char int) in
  [
    test_case "при \"AACGT\" возвращает корректные счётчики" `Quick (fun () ->
      check (list pair) "nucleotide_count"
        [('A', 2); ('C', 1); ('G', 1); ('T', 1)]
        (My_solutions.nucleotide_count "AACGT"
         |> List.sort (fun (a, _) (b, _) -> Char.compare a b)));
  ]

let hamming_tests =
  let open Alcotest in
  [
    test_case "при одинаковых строках возвращает Ok 0" `Quick (fun () ->
      check (result int string) "hamming_distance" (Ok 0)
        (My_solutions.hamming_distance "GAGCCTACTAACGGGAT" "GAGCCTACTAACGGGAT"));
    test_case "при различающихся строках возвращает Ok 7" `Quick (fun () ->
      check (result int string) "hamming_distance" (Ok 7)
        (My_solutions.hamming_distance "GAGCCTACTAACGGGAT" "CATCGTAATGACGGCCT"));
    test_case "при строках разной длины возвращает Error" `Quick (fun () ->
      match My_solutions.hamming_distance "ABC" "AB" with
      | Error _ -> ()
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let rle_tests =
  let open Alcotest in
  [
    test_case "при кодировании \"AABBBC\" возвращает \"2A3B1C\"" `Quick (fun () ->
      check string "rle_encode" "2A3B1C"
        (My_solutions.rle_encode "AABBBC"));
    test_case "при декодировании \"2A3B1C\" возвращает \"AABBBC\"" `Quick (fun () ->
      check string "rle_decode" "AABBBC"
        (My_solutions.rle_decode "2A3B1C"));
    test_case "при encode+decode возвращает исходную строку" `Quick (fun () ->
      let s = "AAABBBCCCD" in
      check string "rle_roundtrip" s
        (My_solutions.rle_decode (My_solutions.rle_encode s)));
  ]

let list_ops_tests =
  let open Alcotest in
  [
    test_case "при пустом списке length возвращает 0" `Quick (fun () ->
      check int "length" 0 (My_solutions.List_ops.length []));
    test_case "при [1;2;3;4] length возвращает 4" `Quick (fun () ->
      check int "length" 4 (My_solutions.List_ops.length [1; 2; 3; 4]));
    test_case "при [1;2;3] reverse возвращает [3;2;1]" `Quick (fun () ->
      check (list int) "reverse" [3; 2; 1]
        (My_solutions.List_ops.reverse [1; 2; 3]));
    test_case "при map (*2) [1;2;3] возвращает [2;4;6]" `Quick (fun () ->
      check (list int) "map" [2; 4; 6]
        (My_solutions.List_ops.map (fun x -> x * 2) [1; 2; 3]));
    test_case "при filter чётных из [1;2;3;4] возвращает [2;4]" `Quick (fun () ->
      check (list int) "filter" [2; 4]
        (My_solutions.List_ops.filter (fun x -> x mod 2 = 0) [1; 2; 3; 4]));
    test_case "при fold_left (+) 0 [1;2;3;4] возвращает 10" `Quick (fun () ->
      check int "fold_left" 10
        (My_solutions.List_ops.fold_left ( + ) 0 [1; 2; 3; 4]));
    test_case "при fold_right cons [] [1;2;3] возвращает [1;2;3]" `Quick (fun () ->
      check (list int) "fold_right" [1; 2; 3]
        (My_solutions.List_ops.fold_right (fun x acc -> x :: acc) [1; 2; 3] []));
    test_case "при append [1;2] [3;4] возвращает [1;2;3;4]" `Quick (fun () ->
      check (list int) "append" [1; 2; 3; 4]
        (My_solutions.List_ops.append [1; 2] [3; 4]));
    test_case "при concat [[1;2];[3;4];[5;6]] возвращает [1;2;3;4;5;6]" `Quick (fun () ->
      check (list int) "concat" [1; 2; 3; 4; 5; 6]
        (My_solutions.List_ops.concat [[1; 2]; [3; 4]; [5; 6]]));
  ]

let traverse_tests =
  let open Alcotest in
  [
    test_case "при всех валидных строках возвращает Some список" `Quick (fun () ->
      check (option (list int)) "traverse_option"
        (Some [1; 2; 3])
        (My_solutions.traverse_option int_of_string_opt ["1"; "2"; "3"]));
    test_case "при наличии невалидной строки возвращает None" `Quick (fun () ->
      check (option (list int)) "traverse_option"
        None
        (My_solutions.traverse_option int_of_string_opt ["1"; "abc"; "3"]));
    test_case "при пустом списке возвращает Some []" `Quick (fun () ->
      check (option (list int)) "traverse_option"
        (Some [])
        (My_solutions.traverse_option int_of_string_opt []));
    test_case "при всех валидных строках возвращает Ok список" `Quick (fun () ->
      let parse s =
        match int_of_string_opt s with
        | Some n -> Ok n
        | None -> Error (Printf.sprintf "не число: %s" s)
      in
      check (result (list int) string) "traverse_result"
        (Ok [1; 2; 3])
        (My_solutions.traverse_result parse ["1"; "2"; "3"]));
    test_case "при невалидной строке возвращает Error с сообщением" `Quick (fun () ->
      let parse s =
        match int_of_string_opt s with
        | Some n -> Ok n
        | None -> Error (Printf.sprintf "не число: %s" s)
      in
      check (result (list int) string) "traverse_result"
        (Error "не число: abc")
        (My_solutions.traverse_result parse ["1"; "abc"; "3"]));
  ]

let windowed_pairs_tests =
  let open Alcotest in
  [
    test_case "при [1; 2; 3; 4] возвращает пары соседних элементов" `Quick (fun () ->
      let result = My_solutions.windowed_pairs (List.to_seq [1; 2; 3; 4]) |> List.of_seq in
      check (list (pair int int)) "windowed_pairs"
        [(1, 2); (2, 3); (3, 4)] result);
    test_case "при пустом списке возвращает пустую последовательность" `Quick (fun () ->
      let result = My_solutions.windowed_pairs (List.to_seq []) |> List.of_seq in
      check (list (pair int int)) "windowed_pairs" [] result);
    test_case "при одном элементе возвращает пустую последовательность" `Quick (fun () ->
      let result = My_solutions.windowed_pairs (List.to_seq [1]) |> List.of_seq in
      check (list (pair int int)) "windowed_pairs" [] result);
  ]

let cartesian_tests =
  let open Alcotest in
  [
    test_case "при [1; 2] и ['a'; 'b'] возвращает декартово произведение" `Quick (fun () ->
      let result = My_solutions.cartesian
        (List.to_seq [1; 2])
        (List.to_seq ['a'; 'b'])
        |> List.of_seq
      in
      check (list (pair int char)) "cartesian"
        [(1, 'a'); (1, 'b'); (2, 'a'); (2, 'b')] result);
    test_case "при пустом первом списке возвращает пустую последовательность" `Quick (fun () ->
      let result = My_solutions.cartesian
        (List.to_seq [])
        (List.to_seq ['a'; 'b'])
        |> List.of_seq
      in
      check (list (pair int char)) "cartesian" [] result);
    test_case "при пустом втором списке возвращает пустую последовательность" `Quick (fun () ->
      let result = My_solutions.cartesian
        (List.to_seq [1; 2])
        (List.to_seq [])
        |> List.of_seq
      in
      check (list (pair int char)) "cartesian" [] result);
  ]

let () =
  Alcotest.run "Chapter 06"
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
      ("Windowed Pairs", windowed_pairs_tests);
      ("Cartesian Product", cartesian_tests);
    ]
