open Chapter19.Ppx_examples

(* --- Тесты библиотеки --- *)

let show_tests =
  let open Alcotest in
  [
    test_case "при show_direction North возвращает строку с именем" `Quick (fun () ->
      check string "show" "Ppx_examples.North" (show_direction North));
    test_case "при show_point возвращает непустую строку" `Quick (fun () ->
      let s = show_point { x = 1.0; y = 2.0 } in
      check bool "not empty" true (String.length s > 0));
    test_case "при show_shape Circle возвращает непустую строку" `Quick (fun () ->
      let s = show_shape (Circle 5.0) in
      check bool "not empty" true (String.length s > 0));
  ]

let eq_tests =
  let open Alcotest in
  [
    test_case "при equal_direction с одинаковыми значениями возвращает true" `Quick (fun () ->
      check bool "equal" true (equal_direction North North));
    test_case "при equal_direction с разными значениями возвращает false" `Quick (fun () ->
      check bool "not equal" false (equal_direction North South));
    test_case "при equal_point с одинаковыми точками возвращает true" `Quick (fun () ->
      check bool "equal" true
        (equal_point { x = 1.0; y = 2.0 } { x = 1.0; y = 2.0 }));
    test_case "при equal_point с разными точками возвращает false" `Quick (fun () ->
      check bool "not equal" false
        (equal_point { x = 1.0; y = 2.0 } { x = 3.0; y = 4.0 }));
  ]

let lib_tests =
  let open Alcotest in
  [
    test_case "при all_directions возвращает список из 4 элементов" `Quick (fun () ->
      check int "count" 4 (List.length all_directions));
    test_case "при describe_direction North возвращает \"North\"" `Quick (fun () ->
      check string "value" "North" (describe_direction North));
    test_case "при dedup_points удаляет дубликаты" `Quick (fun () ->
      let pts = [{ x = 1.0; y = 2.0 }; { x = 1.0; y = 2.0 }; { x = 3.0; y = 4.0 }] in
      check int "count" 2 (List.length (dedup_points pts)));
    test_case "при area Circle 1.0 возвращает pi" `Quick (fun () ->
      let a = area (Circle 1.0) in
      check bool "pi" true (Float.abs (a -. Float.pi) < 0.001));
  ]

(* --- Тесты упражнений --- *)

let color_tests =
  let open Alcotest in
  [
    test_case "при all_colors возвращает список из 3 цветов" `Quick (fun () ->
      check int "count" 3 (List.length My_solutions.all_colors));
    test_case "при all_colors содержит Red" `Quick (fun () ->
      check bool "has Red" true
        (List.exists (My_solutions.equal_color My_solutions.Red) My_solutions.all_colors));
    test_case "при color_to_string Red возвращает непустую строку" `Quick (fun () ->
      let s = My_solutions.color_to_string My_solutions.Red in
      check bool "not empty" true (String.length s > 0));
    test_case "при color_to_string разные цвета дают разные строки" `Quick (fun () ->
      let r = My_solutions.color_to_string My_solutions.Red in
      let g = My_solutions.color_to_string My_solutions.Green in
      check bool "distinct" true (r <> g));
  ]

let dedup_person_tests =
  let open Alcotest in
  [
    test_case "при пустом списке возвращает пустой список" `Quick (fun () ->
      check int "count" 0 (List.length (My_solutions.dedup_persons [])));
    test_case "при списке без дубликатов возвращает исходный список" `Quick (fun () ->
      let lst = My_solutions.[
        { name = "Alice"; age = 30 };
        { name = "Bob"; age = 25 }
      ] in
      check int "count" 2 (List.length (My_solutions.dedup_persons lst)));
    test_case "при наличии дубликатов удаляет повторы" `Quick (fun () ->
      let p = My_solutions.{ name = "Alice"; age = 30 } in
      let lst = [p; p; My_solutions.{ name = "Bob"; age = 25 }] in
      check int "count" 2 (List.length (My_solutions.dedup_persons lst)));
  ]

let make_pair_tests =
  let open Alcotest in
  [
    test_case "при int и string возвращает отформатированную пару" `Quick (fun () ->
      let result = My_solutions.make_pair 42 "hello" string_of_int Fun.id in
      check string "pair" "(42, hello)" result);
    test_case "при float и bool возвращает отформатированную пару" `Quick (fun () ->
      let result = My_solutions.make_pair 3.14 true
        (Printf.sprintf "%.2f") string_of_bool in
      check string "pair" "(3.14, true)" result);
  ]

let suit_tests =
  let open Alcotest in
  [
    test_case "при all_suits возвращает список из 4 мастей" `Quick (fun () ->
      check int "count" 4 (List.length My_solutions.all_suits));
    test_case "при all_suits содержит Hearts" `Quick (fun () ->
      check bool "has Hearts" true
        (List.exists (My_solutions.equal_suit My_solutions.Hearts) My_solutions.all_suits));
    test_case "при next_suit Hearts возвращает Some Diamonds" `Quick (fun () ->
      check bool "Some Diamonds" true
        (My_solutions.next_suit My_solutions.Hearts = Some My_solutions.Diamonds));
    test_case "при next_suit Spades возвращает None" `Quick (fun () ->
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
