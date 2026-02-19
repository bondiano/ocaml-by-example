open Chapter18.Ppx_examples

(* --- Тесты библиотеки --- *)

let show_tests =
  let open Alcotest in
  [
    test_case "show_direction North" `Quick (fun () ->
      check string "show" "Ppx_examples.North" (show_direction North));
    test_case "show_point" `Quick (fun () ->
      let s = show_point { x = 1.0; y = 2.0 } in
      check bool "contains x" true (String.length s > 0));
    test_case "show_shape Circle" `Quick (fun () ->
      let s = show_shape (Circle 5.0) in
      check bool "not empty" true (String.length s > 0));
  ]

let eq_tests =
  let open Alcotest in
  [
    test_case "equal_direction same" `Quick (fun () ->
      check bool "equal" true (equal_direction North North));
    test_case "equal_direction diff" `Quick (fun () ->
      check bool "not equal" false (equal_direction North South));
    test_case "equal_point same" `Quick (fun () ->
      check bool "equal" true
        (equal_point { x = 1.0; y = 2.0 } { x = 1.0; y = 2.0 }));
    test_case "equal_point diff" `Quick (fun () ->
      check bool "not equal" false
        (equal_point { x = 1.0; y = 2.0 } { x = 3.0; y = 4.0 }));
  ]

let lib_tests =
  let open Alcotest in
  [
    test_case "all_directions" `Quick (fun () ->
      check int "4 directions" 4 (List.length all_directions));
    test_case "describe_direction" `Quick (fun () ->
      check string "North" "North" (describe_direction North));
    test_case "dedup_points" `Quick (fun () ->
      let pts = [{ x = 1.0; y = 2.0 }; { x = 1.0; y = 2.0 }; { x = 3.0; y = 4.0 }] in
      check int "deduped" 2 (List.length (dedup_points pts)));
    test_case "area circle" `Quick (fun () ->
      let a = area (Circle 1.0) in
      check bool "pi" true (Float.abs (a -. Float.pi) < 0.001));
  ]

(* --- Тесты упражнений --- *)

let color_tests =
  let open Alcotest in
  [
    test_case "all_colors length" `Quick (fun () ->
      check int "3 colors" 3 (List.length My_solutions.all_colors));
    test_case "all_colors contains Red" `Quick (fun () ->
      check bool "has Red" true
        (List.exists (My_solutions.equal_color My_solutions.Red) My_solutions.all_colors));
    test_case "color_to_string Red" `Quick (fun () ->
      let s = My_solutions.color_to_string My_solutions.Red in
      check bool "not empty" true (String.length s > 0));
    test_case "color_to_string distinct" `Quick (fun () ->
      let r = My_solutions.color_to_string My_solutions.Red in
      let g = My_solutions.color_to_string My_solutions.Green in
      check bool "distinct" true (r <> g));
  ]

let dedup_person_tests =
  let open Alcotest in
  [
    test_case "dedup empty" `Quick (fun () ->
      check int "empty" 0 (List.length (My_solutions.dedup_persons [])));
    test_case "dedup no dups" `Quick (fun () ->
      let lst = My_solutions.[
        { name = "Alice"; age = 30 };
        { name = "Bob"; age = 25 }
      ] in
      check int "no dups" 2 (List.length (My_solutions.dedup_persons lst)));
    test_case "dedup with dups" `Quick (fun () ->
      let p = My_solutions.{ name = "Alice"; age = 30 } in
      let lst = [p; p; My_solutions.{ name = "Bob"; age = 25 }] in
      check int "deduped" 2 (List.length (My_solutions.dedup_persons lst)));
  ]

let make_pair_tests =
  let open Alcotest in
  [
    test_case "make_pair int string" `Quick (fun () ->
      let result = My_solutions.make_pair 42 "hello" string_of_int Fun.id in
      check string "pair" "(42, hello)" result);
    test_case "make_pair float bool" `Quick (fun () ->
      let result = My_solutions.make_pair 3.14 true
        (Printf.sprintf "%.2f") string_of_bool in
      check string "pair" "(3.14, true)" result);
  ]

let suit_tests =
  let open Alcotest in
  [
    test_case "all_suits length" `Quick (fun () ->
      check int "4 suits" 4 (List.length My_solutions.all_suits));
    test_case "all_suits contains Hearts" `Quick (fun () ->
      check bool "has Hearts" true
        (List.exists (My_solutions.equal_suit My_solutions.Hearts) My_solutions.all_suits));
    test_case "next_suit Hearts" `Quick (fun () ->
      check bool "Some Diamonds" true
        (My_solutions.next_suit My_solutions.Hearts = Some My_solutions.Diamonds));
    test_case "next_suit Spades" `Quick (fun () ->
      check bool "None" true
        (My_solutions.next_suit My_solutions.Spades = None));
  ]

let () =
  Alcotest.run "Chapter 16"
    [
      ("show --- ppx_deriving show", show_tests);
      ("eq --- ppx_deriving eq", eq_tests);
      ("lib --- библиотечные функции", lib_tests);
      ("color --- тип color", color_tests);
      ("dedup --- дедупликация записей", dedup_person_tests);
      ("make_pair --- строковое представление пары", make_pair_tests);
      ("suit --- перечисление вариантов", suit_tests);
    ]
