open Chapter15.Properties

(* --- Тесты библиотеки --- *)

let bst_unit_tests =
  let open Alcotest in
  [
    test_case "bst_of_list sorted" `Quick (fun () ->
      let tree = bst_of_list [3; 1; 4; 1; 5; 9] in
      let sorted = bst_to_sorted_list tree in
      check (list int) "sorted" [1; 3; 4; 5; 9] sorted);
    test_case "bst_mem" `Quick (fun () ->
      let tree = bst_of_list [3; 1; 4] in
      check bool "mem 3" true (bst_mem 3 tree);
      check bool "mem 1" true (bst_mem 1 tree);
      check bool "mem 2" false (bst_mem 2 tree));
    test_case "is_sorted" `Quick (fun () ->
      check bool "sorted" true (is_sorted [1; 2; 3; 4]);
      check bool "not sorted" false (is_sorted [1; 3; 2]));
    test_case "encode_pair / decode_pair" `Quick (fun () ->
      let p = (42, "hello") in
      check (option (pair int string)) "roundtrip" (Some p)
        (decode_pair (encode_pair p)));
  ]

(* Библиотечные property-тесты *)
let lib_property_tests =
  [
    QCheck_alcotest.to_alcotest
      (QCheck.Test.make ~name:"bst inorder sorted" ~count:200
         QCheck.(list small_int)
         (fun lst ->
            let tree = bst_of_list lst in
            is_sorted (bst_to_sorted_list tree)));
    QCheck_alcotest.to_alcotest
      (QCheck.Test.make ~name:"bst size <= input" ~count:200
         QCheck.(list small_int)
         (fun lst ->
            let tree = bst_of_list lst in
            let sorted = bst_to_sorted_list tree in
            List.length sorted <= List.length lst));
  ]

(* --- Тесты упражнений --- *)

let exercise_property_tests =
  [
    QCheck_alcotest.to_alcotest My_solutions.prop_rev_involution;
    QCheck_alcotest.to_alcotest My_solutions.prop_sort_sorted;
    QCheck_alcotest.to_alcotest My_solutions.prop_bst_membership;
    QCheck_alcotest.to_alcotest My_solutions.prop_codec_roundtrip;
  ]

let binary_search_tests =
  let open Alcotest in
  [
    test_case "найден" `Quick (fun () ->
      check (option int) "found" (Some 2)
        (My_solutions.binary_search [|1; 3; 5; 7; 9|] 5));
    test_case "не найден" `Quick (fun () ->
      check (option int) "not found" None
        (My_solutions.binary_search [|1; 3; 5; 7; 9|] 4));
    test_case "первый элемент" `Quick (fun () ->
      check (option int) "first" (Some 0)
        (My_solutions.binary_search [|1; 3; 5; 7; 9|] 1));
    test_case "последний элемент" `Quick (fun () ->
      check (option int) "last" (Some 4)
        (My_solutions.binary_search [|1; 3; 5; 7; 9|] 9));
    test_case "пустой массив" `Quick (fun () ->
      check (option int) "empty" None
        (My_solutions.binary_search [||] 1));
  ]

let bst_tests =
  let open Alcotest in
  [
    test_case "insert и mem" `Quick (fun () ->
      let tree = My_solutions.BST.empty
        |> My_solutions.BST.insert 5
        |> My_solutions.BST.insert 3
        |> My_solutions.BST.insert 7 in
      check bool "mem 5" true (My_solutions.BST.mem 5 tree);
      check bool "mem 3" true (My_solutions.BST.mem 3 tree);
      check bool "mem 4" false (My_solutions.BST.mem 4 tree));
    test_case "to_sorted_list" `Quick (fun () ->
      let tree = My_solutions.BST.empty
        |> My_solutions.BST.insert 5
        |> My_solutions.BST.insert 3
        |> My_solutions.BST.insert 7
        |> My_solutions.BST.insert 1 in
      check (list int) "sorted" [1; 3; 5; 7]
        (My_solutions.BST.to_sorted_list tree));
  ]

let () =
  Alcotest.run "Chapter 13"
    [
      ("bst --- бинарное дерево поиска", bst_unit_tests);
      ("lib_properties --- свойства библиотеки", lib_property_tests);
      ("exercises --- свойства упражнений", exercise_property_tests);
      ("Binary Search", binary_search_tests);
      ("BST — бинарное дерево поиска", bst_tests);
    ]
