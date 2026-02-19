open Chapter04.Shapes

(* --- Тестовые данные --- *)

let origin = { x = 0.0; y = 0.0 }
let p1 = { x = 1.0; y = 2.0 }
let p2 = { x = 4.0; y = 6.0 }

let circle = Circle (origin, 5.0)
let rect = Rectangle (origin, 3.0, 4.0)
let line = Line (p1, p2)
let text = Text (p1, "hello")

let unit_circle = Circle (origin, 1.0)

(* --- Пользовательские testable для Alcotest --- *)

let shape_testable : shape Alcotest.testable =
  Alcotest.testable
    (fun fmt s -> Format.pp_print_string fmt (show_shape s))
    ( = )

let bounds_testable : bounds Alcotest.testable =
  Alcotest.testable
    (fun fmt b ->
      Format.fprintf fmt "{min_x=%g; min_y=%g; max_x=%g; max_y=%g}"
        b.min_x b.min_y b.max_x b.max_y)
    (fun a b ->
      a.min_x = b.min_x && a.min_y = b.min_y
      && a.max_x = b.max_x && a.max_y = b.max_y)

(* --- Тесты библиотеки --- *)

let show_point_tests =
  let open Alcotest in
  [
    test_case "начало координат" `Quick (fun () ->
      check string "origin" "(0., 0.)" (show_point origin));
    test_case "произвольная точка" `Quick (fun () ->
      check string "p1" "(1., 2.)" (show_point p1));
  ]

let shape_bounds_tests =
  let open Alcotest in
  [
    test_case "bounds круга" `Quick (fun () ->
      check bounds_testable "circle bounds"
        { min_x = -5.0; min_y = -5.0; max_x = 5.0; max_y = 5.0 }
        (shape_bounds circle));
    test_case "bounds прямоугольника" `Quick (fun () ->
      check bounds_testable "rect bounds"
        { min_x = 0.0; min_y = 0.0; max_x = 3.0; max_y = 4.0 }
        (shape_bounds rect));
    test_case "bounds линии" `Quick (fun () ->
      check bounds_testable "line bounds"
        { min_x = 1.0; min_y = 2.0; max_x = 4.0; max_y = 6.0 }
        (shape_bounds line));
  ]

let bounds_tests =
  let open Alcotest in
  [
    test_case "bounds пустой картинки" `Quick (fun () ->
      check bounds_testable "empty"
        { min_x = 0.0; min_y = 0.0; max_x = 0.0; max_y = 0.0 }
        (bounds []));
    test_case "bounds картинки из нескольких фигур" `Quick (fun () ->
      check bounds_testable "picture"
        { min_x = -5.0; min_y = -5.0; max_x = 5.0; max_y = 6.0 }
        (bounds [circle; rect; line]));
  ]

(* --- Тесты упражнений --- *)

let area_tests =
  let open Alcotest in
  [
    test_case "площадь круга" `Quick (fun () ->
      check (float 1e-9) "circle"
        (Float.pi *. 25.0) (My_solutions.area circle));
    test_case "площадь единичного круга" `Quick (fun () ->
      check (float 1e-9) "unit circle"
        Float.pi (My_solutions.area unit_circle));
    test_case "площадь прямоугольника" `Quick (fun () ->
      check (float 1e-9) "rect" 12.0 (My_solutions.area rect));
    test_case "площадь линии" `Quick (fun () ->
      check (float 1e-9) "line" 0.0 (My_solutions.area line));
    test_case "площадь текста" `Quick (fun () ->
      check (float 1e-9) "text" 0.0 (My_solutions.area text));
  ]

let scale_tests =
  let open Alcotest in
  [
    test_case "масштабирование круга" `Quick (fun () ->
      check shape_testable "scale circle"
        (Circle (origin, 10.0))
        (My_solutions.scale 2.0 circle));
    test_case "масштабирование прямоугольника" `Quick (fun () ->
      check shape_testable "scale rect"
        (Rectangle (origin, 9.0, 12.0))
        (My_solutions.scale 3.0 rect));
    test_case "масштабирование линии" `Quick (fun () ->
      check shape_testable "scale line"
        (Line ({ x = 2.0; y = 4.0 }, { x = 8.0; y = 12.0 }))
        (My_solutions.scale 2.0 line));
    test_case "масштабирование текста" `Quick (fun () ->
      check shape_testable "scale text"
        (Text ({ x = 0.5; y = 1.0 }, "hello"))
        (My_solutions.scale 0.5 text));
  ]

let shape_text_tests =
  let open Alcotest in
  [
    test_case "текст из Text" `Quick (fun () ->
      check (option string) "text"
        (Some "hello") (My_solutions.shape_text text));
    test_case "текст из Circle" `Quick (fun () ->
      check (option string) "circle"
        None (My_solutions.shape_text circle));
    test_case "текст из Rectangle" `Quick (fun () ->
      check (option string) "rect"
        None (My_solutions.shape_text rect));
    test_case "текст из Line" `Quick (fun () ->
      check (option string) "line"
        None (My_solutions.shape_text line));
  ]

let safe_head_tests =
  let open Alcotest in
  [
    test_case "head непустого списка" `Quick (fun () ->
      check (option int) "non-empty"
        (Some 1) (My_solutions.safe_head [1; 2; 3]));
    test_case "head пустого списка" `Quick (fun () ->
      check (option int) "empty"
        None (My_solutions.safe_head []));
    test_case "head списка строк" `Quick (fun () ->
      check (option string) "strings"
        (Some "hello") (My_solutions.safe_head ["hello"; "world"]));
  ]

let bob_tests =
  let open Alcotest in
  [
    test_case "вопрос" `Quick (fun () ->
      check string "question" "Sure."
        (My_solutions.bob "How are you?"));
    test_case "крик" `Quick (fun () ->
      check string "yell" "Whoa, chill out!"
        (My_solutions.bob "WHAT ARE YOU DOING"));
    test_case "крик-вопрос" `Quick (fun () ->
      check string "yell question" "Calm down, I know what I'm doing!"
        (My_solutions.bob "WHAT?"));
    test_case "тишина" `Quick (fun () ->
      check string "silence" "Fine. Be that way!"
        (My_solutions.bob "   "));
    test_case "обычное" `Quick (fun () ->
      check string "normal" "Whatever."
        (My_solutions.bob "Hello there"));
  ]

let triangle_tests =
  let open Alcotest in
  let triangle_testable = Alcotest.testable
    (fun fmt t -> Format.pp_print_string fmt (match t with
      | My_solutions.Equilateral -> "Equilateral"
      | My_solutions.Isosceles -> "Isosceles"
      | My_solutions.Scalene -> "Scalene"))
    ( = ) in
  [
    test_case "равносторонний" `Quick (fun () ->
      check (result triangle_testable string) "equilateral"
        (Ok My_solutions.Equilateral)
        (My_solutions.classify_triangle 2.0 2.0 2.0));
    test_case "равнобедренный" `Quick (fun () ->
      check (result triangle_testable string) "isosceles"
        (Ok My_solutions.Isosceles)
        (My_solutions.classify_triangle 3.0 3.0 4.0));
    test_case "разносторонний" `Quick (fun () ->
      check (result triangle_testable string) "scalene"
        (Ok My_solutions.Scalene)
        (My_solutions.classify_triangle 3.0 4.0 5.0));
    test_case "невалидный" `Quick (fun () ->
      match My_solutions.classify_triangle 1.0 1.0 3.0 with
      | Error _ -> ()
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let raindrops_tests =
  let open Alcotest in
  [
    test_case "3 → Pling" `Quick (fun () ->
      check string "3" "Pling" (My_solutions.raindrops 3));
    test_case "5 → Plang" `Quick (fun () ->
      check string "5" "Plang" (My_solutions.raindrops 5));
    test_case "7 → Plong" `Quick (fun () ->
      check string "7" "Plong" (My_solutions.raindrops 7));
    test_case "15 → PlingPlang" `Quick (fun () ->
      check string "15" "PlingPlang" (My_solutions.raindrops 15));
    test_case "34 → 34" `Quick (fun () ->
      check string "34" "34" (My_solutions.raindrops 34));
  ]

let perfect_numbers_tests =
  let open Alcotest in
  let class_testable = Alcotest.testable
    (fun fmt c -> Format.pp_print_string fmt (match c with
      | My_solutions.Perfect -> "Perfect"
      | My_solutions.Abundant -> "Abundant"
      | My_solutions.Deficient -> "Deficient"))
    ( = ) in
  [
    test_case "6 — совершенное" `Quick (fun () ->
      check (result class_testable string) "6"
        (Ok My_solutions.Perfect) (My_solutions.classify 6));
    test_case "12 — избыточное" `Quick (fun () ->
      check (result class_testable string) "12"
        (Ok My_solutions.Abundant) (My_solutions.classify 12));
    test_case "7 — недостаточное" `Quick (fun () ->
      check (result class_testable string) "7"
        (Ok My_solutions.Deficient) (My_solutions.classify 7));
    test_case "0 — ошибка" `Quick (fun () ->
      match My_solutions.classify 0 with
      | Error _ -> ()
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let allergies_tests =
  let open Alcotest in
  [
    test_case "нет аллергий" `Quick (fun () ->
      check (list int) "empty" [] (List.map Obj.magic (My_solutions.allergies 0)));
    test_case "аллергия на яйца" `Quick (fun () ->
      check bool "eggs" true
        (My_solutions.is_allergic_to My_solutions.Eggs 1));
    test_case "аллергия на несколько" `Quick (fun () ->
      let a = My_solutions.allergies 5 in
      check bool "eggs+shellfish" true
        (List.length a = 2));
  ]

let () =
  Alcotest.run "Chapter 04"
    [
      ("show_point --- форматирование точки", show_point_tests);
      ("shape_bounds --- bounds фигуры", shape_bounds_tests);
      ("bounds --- bounds картинки", bounds_tests);
      ("area --- площадь фигуры", area_tests);
      ("scale --- масштабирование", scale_tests);
      ("shape_text --- извлечение текста", shape_text_tests);
      ("safe_head --- безопасный head", safe_head_tests);
      ("Bob — ответы", bob_tests);
      ("Triangle — классификация", triangle_tests);
      ("Raindrops", raindrops_tests);
      ("Perfect Numbers", perfect_numbers_tests);
      ("Allergies — аллергии", allergies_tests);
    ]
