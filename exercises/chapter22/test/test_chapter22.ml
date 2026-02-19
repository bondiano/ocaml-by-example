open Chapter22.Schemes

(* ===== Вспомогательные функции для тестов ===== *)

(** Сравнение fix_list по содержимому. *)
let fix_list_eq (a : fix_list) (b : fix_list) : bool =
  list_of_fix_list a = list_of_fix_list b

(** Строковое представление fix_list для отладки. *)
let fix_list_to_string (fl : fix_list) : string =
  let items = list_of_fix_list fl in
  "[" ^ String.concat "; " (List.map string_of_int items) ^ "]"

(** Alcotest testable для fix_list. *)
let _fix_list_testable : fix_list Alcotest.testable =
  Alcotest.testable
    (fun fmt fl -> Format.pp_print_string fmt (fix_list_to_string fl))
    fix_list_eq

(** Преобразовать fix_tree в строку для отладки. *)
let rec fix_tree_to_string (Fix_tree layer : fix_tree) : string =
  match layer with
  | Leaf -> "Leaf"
  | Node (l, x, r) ->
    Printf.sprintf "Node(%s, %d, %s)"
      (fix_tree_to_string l) x (fix_tree_to_string r)

(** Сравнение fix_tree. *)
let rec fix_tree_eq (Fix_tree a : fix_tree) (Fix_tree b : fix_tree) : bool =
  match a, b with
  | Leaf, Leaf -> true
  | Node (la, xa, ra), Node (lb, xb, rb) ->
    xa = xb && fix_tree_eq la lb && fix_tree_eq ra rb
  | _ -> false

let fix_tree_testable : fix_tree Alcotest.testable =
  Alcotest.testable
    (fun fmt ft -> Format.pp_print_string fmt (fix_tree_to_string ft))
    fix_tree_eq

(* ===== Тесты библиотеки ===== *)

let lib_list_tests =
  let open Alcotest in
  [
    test_case "fix_list_of_list и list_of_fix_list --- roundtrip" `Quick (fun () ->
      let lst = [1; 2; 3; 4; 5] in
      check (list int) "roundtrip" lst (list_of_fix_list (fix_list_of_list lst)));
    test_case "fix_list_of_list --- пустой список" `Quick (fun () ->
      check (list int) "empty" [] (list_of_fix_list (fix_list_of_list [])));
    test_case "cata_list --- сумма" `Quick (fun () ->
      let sum_alg = function Nil -> 0 | Cons (x, acc) -> x + acc in
      let fl = fix_list_of_list [1; 2; 3; 4; 5] in
      check int "sum" 15 (cata_list sum_alg fl));
    test_case "cata_list --- длина" `Quick (fun () ->
      let len_alg = function Nil -> 0 | Cons (_, acc) -> 1 + acc in
      let fl = fix_list_of_list [10; 20; 30] in
      check int "length" 3 (cata_list len_alg fl));
    test_case "ana_list --- range" `Quick (fun () ->
      let coalg = function 0 -> Nil | n -> Cons (n, n - 1) in
      let fl = ana_list coalg 3 in
      check (list int) "range 3" [3; 2; 1] (list_of_fix_list fl));
    test_case "hylo_list --- факториал" `Quick (fun () ->
      let coalg = function 0 -> Nil | n -> Cons (n, n - 1) in
      let alg = function Nil -> 1 | Cons (x, acc) -> x * acc in
      check int "5!" 120 (hylo_list alg coalg 5));
    test_case "hylo_list --- факториал 0" `Quick (fun () ->
      let coalg = function 0 -> Nil | n -> Cons (n, n - 1) in
      let alg = function Nil -> 1 | Cons (x, acc) -> x * acc in
      check int "0!" 1 (hylo_list alg coalg 0));
  ]

let lib_tree_tests =
  let open Alcotest in
  let leaf = Fix_tree Leaf in
  let node l x r = Fix_tree (Node (l, x, r)) in
  let t = node (node leaf 1 leaf) 2 (node leaf 3 leaf) in
  [
    test_case "cata_tree --- сумма" `Quick (fun () ->
      let alg = function Leaf -> 0 | Node (l, x, r) -> l + x + r in
      check int "tree sum" 6 (cata_tree alg t));
    test_case "cata_tree --- глубина" `Quick (fun () ->
      let alg = function Leaf -> 0 | Node (l, _, r) -> 1 + max l r in
      check int "tree depth" 2 (cata_tree alg t));
    test_case "ana_tree --- сбалансированное дерево" `Quick (fun () ->
      let coalg = function 0 -> Leaf | n -> Node (n - 1, n, n - 1) in
      let expected = node (node leaf 1 leaf) 2 (node leaf 1 leaf) in
      check fix_tree_testable "balanced 2" expected (ana_tree coalg 2));
    test_case "para_tree --- сумма (как cata)" `Quick (fun () ->
      let alg = function
        | Leaf -> 0
        | Node ((_, l), x, (_, r)) -> l + x + r
      in
      check int "para tree sum" 6 (para_tree alg t));
  ]

let lib_json_tests =
  let open Alcotest in
  [
    test_case "json_depth --- плоский объект" `Quick (fun () ->
      let j = jobject [("a", jnumber 1.0); ("b", jstring "hello")] in
      check int "depth" 1 (json_depth j));
    test_case "json_depth --- вложенный объект" `Quick (fun () ->
      let j = jobject [("a", jobject [("b", jnumber 1.0)])] in
      check int "depth" 2 (json_depth j));
    test_case "json_depth --- скаляр" `Quick (fun () ->
      check int "depth null" 0 (json_depth jnull);
      check int "depth number" 0 (json_depth (jnumber 42.0)));
    test_case "json_depth --- массив" `Quick (fun () ->
      let j = jarray [jnumber 1.0; jarray [jnumber 2.0]] in
      check int "depth" 2 (json_depth j));
    test_case "pretty_print --- null" `Quick (fun () ->
      check string "null" "null" (pretty_print jnull));
    test_case "pretty_print --- число" `Quick (fun () ->
      check string "number" "42" (pretty_print (jnumber 42.0)));
    test_case "pretty_print --- строка" `Quick (fun () ->
      check string "string" "\"hello\"" (pretty_print (jstring "hello")));
    test_case "pretty_print --- пустой массив" `Quick (fun () ->
      check string "empty array" "[]" (pretty_print (jarray [])));
    test_case "pretty_print --- пустой объект" `Quick (fun () ->
      check string "empty object" "{}" (pretty_print (jobject [])));
    test_case "schema_to_json --- простая схема" `Quick (fun () ->
      let j = schema_to_json SNull in
      check string "null schema" "\"null\"" (pretty_print j));
  ]

(* ===== Тесты упражнений ===== *)

let ex1_cata_tree_tests =
  let open Alcotest in
  let leaf = Fix_tree Leaf in
  let node l x r = Fix_tree (Node (l, x, r)) in
  [
    test_case "tree_depth --- лист" `Quick (fun () ->
      check int "leaf depth" 0 (My_solutions.tree_depth leaf));
    test_case "tree_depth --- один узел" `Quick (fun () ->
      check int "single node" 1 (My_solutions.tree_depth (node leaf 1 leaf)));
    test_case "tree_depth --- несбалансированное" `Quick (fun () ->
      let t = node (node (node leaf 1 leaf) 2 leaf) 3 leaf in
      check int "unbalanced depth" 3 (My_solutions.tree_depth t));
    test_case "tree_size --- лист" `Quick (fun () ->
      check int "leaf size" 0 (My_solutions.tree_size leaf));
    test_case "tree_size --- три узла" `Quick (fun () ->
      let t = node (node leaf 1 leaf) 2 (node leaf 3 leaf) in
      check int "3 nodes" 3 (My_solutions.tree_size t));
    test_case "tree_size --- семь узлов" `Quick (fun () ->
      let t = node
        (node (node leaf 1 leaf) 2 (node leaf 3 leaf))
        4
        (node (node leaf 5 leaf) 6 (node leaf 7 leaf))
      in
      check int "7 nodes" 7 (My_solutions.tree_size t));
  ]

let ex2_ana_tree_tests =
  let open Alcotest in
  let leaf = Fix_tree Leaf in
  let node l x r = Fix_tree (Node (l, x, r)) in
  [
    test_case "gen_balanced 0 --- лист" `Quick (fun () ->
      check fix_tree_testable "leaf" leaf (My_solutions.gen_balanced 0));
    test_case "gen_balanced 1 --- один узел" `Quick (fun () ->
      let expected = node leaf 1 leaf in
      check fix_tree_testable "depth 1" expected (My_solutions.gen_balanced 1));
    test_case "gen_balanced 2" `Quick (fun () ->
      let expected = node (node leaf 1 leaf) 2 (node leaf 1 leaf) in
      check fix_tree_testable "depth 2" expected (My_solutions.gen_balanced 2));
    test_case "gen_balanced 3 --- глубина" `Quick (fun () ->
      let t = My_solutions.gen_balanced 3 in
      let depth_alg = function Leaf -> 0 | Node (l, _, r) -> 1 + max l r in
      check int "depth of balanced 3" 3 (cata_tree depth_alg t));
  ]

let ex3_hylo_sort_tests =
  let open Alcotest in
  [
    test_case "merge_sort --- пустой список" `Quick (fun () ->
      check (list int) "empty" [] (My_solutions.merge_sort []));
    test_case "merge_sort --- один элемент" `Quick (fun () ->
      check (list int) "single" [1] (My_solutions.merge_sort [1]));
    test_case "merge_sort --- уже отсортирован" `Quick (fun () ->
      check (list int) "sorted" [1; 2; 3] (My_solutions.merge_sort [1; 2; 3]));
    test_case "merge_sort --- обратный порядок" `Quick (fun () ->
      check (list int) "reversed" [1; 2; 3; 4; 5]
        (My_solutions.merge_sort [5; 4; 3; 2; 1]));
    test_case "merge_sort --- произвольный порядок" `Quick (fun () ->
      check (list int) "random" [1; 2; 3; 4; 5]
        (My_solutions.merge_sort [3; 1; 4; 5; 2]));
    test_case "merge_sort --- дубликаты" `Quick (fun () ->
      check (list int) "duplicates" [1; 2; 2; 3; 3]
        (My_solutions.merge_sort [3; 2; 1; 3; 2]));
  ]

let ex4_para_tails_tests =
  let open Alcotest in
  [
    test_case "tails --- пустой список" `Quick (fun () ->
      let result = My_solutions.tails (fix_list_of_list []) in
      check int "one element (empty list)" 1 (List.length result);
      check (list int) "tail 0" []
        (list_of_fix_list (List.nth result 0)));
    test_case "tails --- [1; 2; 3]" `Quick (fun () ->
      let result = My_solutions.tails (fix_list_of_list [1; 2; 3]) in
      check int "4 tails" 4 (List.length result);
      check (list int) "tail 0" [1; 2; 3]
        (list_of_fix_list (List.nth result 0));
      check (list int) "tail 1" [2; 3]
        (list_of_fix_list (List.nth result 1));
      check (list int) "tail 2" [3]
        (list_of_fix_list (List.nth result 2));
      check (list int) "tail 3" []
        (list_of_fix_list (List.nth result 3)));
    test_case "tails --- [42]" `Quick (fun () ->
      let result = My_solutions.tails (fix_list_of_list [42]) in
      check int "2 tails" 2 (List.length result);
      check (list int) "tail 0" [42]
        (list_of_fix_list (List.nth result 0));
      check (list int) "tail 1" []
        (list_of_fix_list (List.nth result 1)));
  ]

(** Вспомогательная функция: сравнение JSON по структуре. *)
let rec json_eq (JsonSchemes.Fix a) (JsonSchemes.Fix b) =
  match a, b with
  | JNull, JNull -> true
  | JBool a, JBool b -> a = b
  | JNumber a, JNumber b -> Float.equal a b
  | JString a, JString b -> String.equal a b
  | JArray a, JArray b ->
    List.length a = List.length b
    && List.for_all2 json_eq a b
  | JObject a, JObject b ->
    List.length a = List.length b
    && List.for_all2
         (fun (ka, va) (kb, vb) -> String.equal ka kb && json_eq va vb)
         a b
  | _ -> false

let json_testable : json Alcotest.testable =
  Alcotest.testable
    (fun fmt j -> Format.pp_print_string fmt (pretty_print j))
    json_eq

let ex5_replace_nulls_tests =
  let open Alcotest in
  [
    test_case "replace_nulls --- null -> default" `Quick (fun () ->
      let default = jstring "N/A" in
      let result = My_solutions.replace_nulls default jnull in
      check json_testable "null replaced" default result);
    test_case "replace_nulls --- число не меняется" `Quick (fun () ->
      let default = jstring "N/A" in
      let n = jnumber 42.0 in
      check json_testable "number unchanged" n
        (My_solutions.replace_nulls default n));
    test_case "replace_nulls --- массив с null" `Quick (fun () ->
      let default = jnumber 0.0 in
      let input = jarray [jnumber 1.0; jnull; jnumber 3.0] in
      let expected = jarray [jnumber 1.0; jnumber 0.0; jnumber 3.0] in
      check json_testable "array with null" expected
        (My_solutions.replace_nulls default input));
    test_case "replace_nulls --- вложенный объект" `Quick (fun () ->
      let default = jstring "default" in
      let input = jobject [
        ("a", jnull);
        ("b", jobject [("c", jnull); ("d", jnumber 1.0)])
      ] in
      let expected = jobject [
        ("a", jstring "default");
        ("b", jobject [("c", jstring "default"); ("d", jnumber 1.0)])
      ] in
      check json_testable "nested object" expected
        (My_solutions.replace_nulls default input));
    test_case "replace_nulls --- без null" `Quick (fun () ->
      let default = jstring "N/A" in
      let input = jobject [("x", jnumber 1.0); ("y", jbool true)] in
      check json_testable "no nulls" input
        (My_solutions.replace_nulls default input));
  ]

let () =
  Alcotest.run "Chapter 22 --- Рекурсивные схемы"
    [
      ("lib/list --- списковые схемы", lib_list_tests);
      ("lib/tree --- древовидные схемы", lib_tree_tests);
      ("lib/json --- JSON через схемы", lib_json_tests);
      ("ex1 --- cata_tree (глубина и размер)", ex1_cata_tree_tests);
      ("ex2 --- ana_tree (генерация дерева)", ex2_ana_tree_tests);
      ("ex3 --- hylo_list (сортировка)", ex3_hylo_sort_tests);
      ("ex4 --- para_list (tails)", ex4_para_tails_tests);
      ("ex5 --- replace_nulls (JSON трансформация)", ex5_replace_nulls_tests);
    ]
