open Chapter06.Hashable

(* --- Тесты библиотеки --- *)

let hash_tests =
  let open Alcotest in
  [
    test_case "хэш целого числа" `Quick (fun () ->
      check int "int hash" 42 (IntHash.hash 42));
    test_case "хэш строки непустой" `Quick (fun () ->
      check bool "string hash nonzero" true
        (StringHash.hash "hello" <> 0));
    test_case "хэш одинаковых строк совпадает" `Quick (fun () ->
      check int "same string same hash"
        (StringHash.hash "test") (StringHash.hash "test"));
  ]

let hashset_tests =
  let module HS = MakeHashSet(IntHash) in
  let open Alcotest in
  [
    test_case "пустой HashSet" `Quick (fun () ->
      check bool "empty" false (HS.mem 1 HS.empty));
    test_case "добавление и поиск" `Quick (fun () ->
      let s = HS.add 42 HS.empty in
      check bool "mem" true (HS.mem 42 s));
    test_case "отсутствующий элемент" `Quick (fun () ->
      let s = HS.add 42 HS.empty in
      check bool "not mem" false (HS.mem 99 s));
  ]

let pair_hash_tests =
  let module PH = PairHash(IntHash)(StringHash) in
  let open Alcotest in
  [
    test_case "хэш пары" `Quick (fun () ->
      check bool "pair hash nonzero" true
        (PH.hash (1, "hello") <> 0));
    test_case "разные пары --- разные хэши" `Quick (fun () ->
      check bool "different pairs"
        true
        (PH.hash (1, "a") <> PH.hash (2, "b")));
  ]

(* --- Тесты упражнений --- *)

let int_set_tests =
  let open Alcotest in
  [
    test_case "пустое множество" `Quick (fun () ->
      check (list int) "empty" []
        (My_solutions.IntSet.elements My_solutions.IntSet.empty));
    test_case "добавление элементов" `Quick (fun () ->
      let s =
        My_solutions.IntSet.empty
        |> My_solutions.IntSet.add 3
        |> My_solutions.IntSet.add 1
        |> My_solutions.IntSet.add 4
        |> My_solutions.IntSet.add 1
      in
      check (list int) "sorted unique" [1; 3; 4]
        (My_solutions.IntSet.elements s));
    test_case "mem --- элемент есть" `Quick (fun () ->
      let s =
        My_solutions.IntSet.empty
        |> My_solutions.IntSet.add 5
        |> My_solutions.IntSet.add 3
      in
      check bool "mem 5" true (My_solutions.IntSet.mem 5 s));
    test_case "mem --- элемента нет" `Quick (fun () ->
      let s = My_solutions.IntSet.add 5 My_solutions.IntSet.empty in
      check bool "mem 3" false (My_solutions.IntSet.mem 3 s));
    test_case "size" `Quick (fun () ->
      let s =
        My_solutions.IntSet.empty
        |> My_solutions.IntSet.add 1
        |> My_solutions.IntSet.add 2
        |> My_solutions.IntSet.add 3
      in
      check int "size" 3 (My_solutions.IntSet.size s));
  ]

let make_set_tests =
  let module SSet = My_solutions.MakeSet(String) in
  let open Alcotest in
  [
    test_case "MakeSet с String --- добавление" `Quick (fun () ->
      let s =
        SSet.empty
        |> SSet.add "banana"
        |> SSet.add "apple"
        |> SSet.add "cherry"
        |> SSet.add "apple"
      in
      check (list string) "sorted unique"
        ["apple"; "banana"; "cherry"]
        (SSet.elements s));
    test_case "MakeSet с String --- mem" `Quick (fun () ->
      let s = SSet.add "hello" SSet.empty in
      check bool "mem hello" true (SSet.mem "hello" s);
      check bool "not mem world" false (SSet.mem "world" s));
  ]

let max_element_tests =
  let open Alcotest in
  [
    test_case "max_element Int" `Quick (fun () ->
      check (option int) "max int"
        (Some 5)
        (My_solutions.max_element (module Int) [3; 1; 4; 1; 5]));
    test_case "max_element String" `Quick (fun () ->
      check (option string) "max string"
        (Some "cherry")
        (My_solutions.max_element (module String)
           ["banana"; "apple"; "cherry"]));
    test_case "max_element пустой список" `Quick (fun () ->
      check (option int) "max empty"
        None
        (My_solutions.max_element (module Int) []));
  ]

let extended_set_tests =
  let open Alcotest in
  let module E = My_solutions.ExtendedIntSet in
  [
    test_case "union" `Quick (fun () ->
      let s1 = E.empty |> E.add 1 |> E.add 3 in
      let s2 = E.empty |> E.add 2 |> E.add 3 |> E.add 4 in
      check (list int) "union"
        [1; 2; 3; 4]
        (E.elements (E.union s1 s2)));
    test_case "inter" `Quick (fun () ->
      let s1 = E.empty |> E.add 1 |> E.add 2 |> E.add 3 in
      let s2 = E.empty |> E.add 2 |> E.add 3 |> E.add 4 in
      check (list int) "inter"
        [2; 3]
        (E.elements (E.inter s1 s2)));
    test_case "size после union" `Quick (fun () ->
      let s1 = E.empty |> E.add 1 |> E.add 2 in
      let s2 = E.empty |> E.add 2 |> E.add 3 in
      check int "size" 3 (E.size (E.union s1 s2)));
  ]

let user_tests =
  let open Alcotest in
  let open Chapter06.Hashable.User in
  [
    test_case "create user" `Quick (fun () ->
      let u = make ~name:"Иван" ~age:25 in
      check string "name" "Иван" (name u);
      check int "age" 25 (age u));
    test_case "to_string" `Quick (fun () ->
      let u = make ~name:"Иван" ~age:25 in
      check string "str" "Иван (age 25)" (to_string u));
    test_case "negative age" `Quick (fun () ->
      check_raises "invalid" (Invalid_argument "User.make: age must be non-negative")
        (fun () -> ignore (make ~name:"X" ~age:(-1))));
  ]

let io_agnostic_tests =
  let open Alcotest in
  let open Chapter06.Hashable in
  [
    test_case "sync process" `Quick (fun () ->
      check string "process" "processed: HELLO"
        (Sync_service.process "hello"));
    test_case "sync process_all" `Quick (fun () ->
      check (list string) "process_all"
        ["processed: A"; "processed: B"]
        (Sync_service.process_all ["a"; "b"]));
  ]

module TestCustomSet = My_solutions.MakeCustomSet(Int)

let custom_set_tests =
  let open Alcotest in
  [
    test_case "empty set" `Quick (fun () ->
      check bool "is_empty" true (TestCustomSet.is_empty TestCustomSet.empty));
    test_case "add и mem" `Quick (fun () ->
      let s = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      check bool "mem 1" true (TestCustomSet.mem 1 s);
      check bool "mem 2" true (TestCustomSet.mem 2 s);
      check bool "mem 3" false (TestCustomSet.mem 3 s));
    test_case "elements отсортированы" `Quick (fun () ->
      let s = TestCustomSet.add 3 (TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty)) in
      check (list int) "sorted" [1; 2; 3] (TestCustomSet.elements s));
    test_case "size" `Quick (fun () ->
      let s = TestCustomSet.add 1 (TestCustomSet.add 2 (TestCustomSet.add 1 TestCustomSet.empty)) in
      check int "no duplicates" 2 (TestCustomSet.size s));
    test_case "union" `Quick (fun () ->
      let s1 = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      let s2 = TestCustomSet.add 2 (TestCustomSet.add 3 TestCustomSet.empty) in
      check (list int) "union" [1; 2; 3] (TestCustomSet.elements (TestCustomSet.union s1 s2)));
    test_case "inter" `Quick (fun () ->
      let s1 = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      let s2 = TestCustomSet.add 2 (TestCustomSet.add 3 TestCustomSet.empty) in
      check (list int) "inter" [2] (TestCustomSet.elements (TestCustomSet.inter s1 s2)));
    test_case "remove" `Quick (fun () ->
      let s = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      let s = TestCustomSet.remove 1 s in
      check (list int) "removed" [2] (TestCustomSet.elements s));
  ]

let () =
  Alcotest.run "Chapter 06"
    [
      ("hash --- хэширование", hash_tests);
      ("MakeHashSet --- хэш-множество", hashset_tests);
      ("PairHash --- хэш пары", pair_hash_tests);
      ("IntSet --- множество int", int_set_tests);
      ("MakeSet --- функтор множества", make_set_tests);
      ("max_element --- модуль первого класса", max_element_tests);
      ("ExtendedIntSet --- расширенное множество", extended_set_tests);
      ("User — modules-as-types", user_tests);
      ("IO-agnostic — синхронный сервис", io_agnostic_tests);
      ("Custom Set — параметрический модуль", custom_set_tests);
    ]
