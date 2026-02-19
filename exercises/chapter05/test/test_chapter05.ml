open Chapter05.Shapes

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
    test_case "при начале координат возвращает \"(0., 0.)\"" `Quick (fun () ->
      check string "show_point" "(0., 0.)" (show_point origin));
    test_case "при точке (1, 2) возвращает \"(1., 2.)\"" `Quick (fun () ->
      check string "show_point" "(1., 2.)" (show_point p1));
  ]

let shape_bounds_tests =
  let open Alcotest in
  [
    test_case "при круге радиуса 5 возвращает bounds [-5;5]x[-5;5]" `Quick (fun () ->
      check bounds_testable "shape_bounds"
        { min_x = -5.0; min_y = -5.0; max_x = 5.0; max_y = 5.0 }
        (shape_bounds circle));
    test_case "при прямоугольнике 3x4 возвращает bounds [0;3]x[0;4]" `Quick (fun () ->
      check bounds_testable "shape_bounds"
        { min_x = 0.0; min_y = 0.0; max_x = 3.0; max_y = 4.0 }
        (shape_bounds rect));
    test_case "при линии из (1,2) в (4,6) возвращает корректные bounds" `Quick (fun () ->
      check bounds_testable "shape_bounds"
        { min_x = 1.0; min_y = 2.0; max_x = 4.0; max_y = 6.0 }
        (shape_bounds line));
  ]

let bounds_tests =
  let open Alcotest in
  [
    test_case "при пустой картинке возвращает нулевые bounds" `Quick (fun () ->
      check bounds_testable "bounds"
        { min_x = 0.0; min_y = 0.0; max_x = 0.0; max_y = 0.0 }
        (bounds []));
    test_case "при нескольких фигурах возвращает объединённые bounds" `Quick (fun () ->
      check bounds_testable "bounds"
        { min_x = -5.0; min_y = -5.0; max_x = 5.0; max_y = 6.0 }
        (bounds [circle; rect; line]));
  ]

(* --- Тесты упражнений --- *)

let area_tests =
  let open Alcotest in
  [
    test_case "при круге радиуса 5 возвращает 25*pi" `Quick (fun () ->
      check (float 1e-9) "area"
        (Float.pi *. 25.0) (My_solutions.area circle));
    test_case "при единичном круге возвращает pi" `Quick (fun () ->
      check (float 1e-9) "area"
        Float.pi (My_solutions.area unit_circle));
    test_case "при прямоугольнике 3x4 возвращает 12" `Quick (fun () ->
      check (float 1e-9) "area" 12.0 (My_solutions.area rect));
    test_case "при линии возвращает 0" `Quick (fun () ->
      check (float 1e-9) "area" 0.0 (My_solutions.area line));
    test_case "при тексте возвращает 0" `Quick (fun () ->
      check (float 1e-9) "area" 0.0 (My_solutions.area text));
  ]

let scale_tests =
  let open Alcotest in
  [
    test_case "при круге и множителе 2 возвращает круг с радиусом 10" `Quick (fun () ->
      check shape_testable "scale"
        (Circle (origin, 10.0))
        (My_solutions.scale 2.0 circle));
    test_case "при прямоугольнике и множителе 3 возвращает прямоугольник 9x12" `Quick (fun () ->
      check shape_testable "scale"
        (Rectangle (origin, 9.0, 12.0))
        (My_solutions.scale 3.0 rect));
    test_case "при линии и множителе 2 возвращает масштабированную линию" `Quick (fun () ->
      check shape_testable "scale"
        (Line ({ x = 2.0; y = 4.0 }, { x = 8.0; y = 12.0 }))
        (My_solutions.scale 2.0 line));
    test_case "при тексте и множителе 0.5 возвращает смещённый текст" `Quick (fun () ->
      check shape_testable "scale"
        (Text ({ x = 0.5; y = 1.0 }, "hello"))
        (My_solutions.scale 0.5 text));
  ]

let shape_text_tests =
  let open Alcotest in
  [
    test_case "при Text возвращает Some с содержимым" `Quick (fun () ->
      check (option string) "shape_text"
        (Some "hello") (My_solutions.shape_text text));
    test_case "при Circle возвращает None" `Quick (fun () ->
      check (option string) "shape_text"
        None (My_solutions.shape_text circle));
    test_case "при Rectangle возвращает None" `Quick (fun () ->
      check (option string) "shape_text"
        None (My_solutions.shape_text rect));
    test_case "при Line возвращает None" `Quick (fun () ->
      check (option string) "shape_text"
        None (My_solutions.shape_text line));
  ]

let safe_head_tests =
  let open Alcotest in
  [
    test_case "при непустом списке возвращает Some первого элемента" `Quick (fun () ->
      check (option int) "safe_head"
        (Some 1) (My_solutions.safe_head [1; 2; 3]));
    test_case "при пустом списке возвращает None" `Quick (fun () ->
      check (option int) "safe_head"
        None (My_solutions.safe_head []));
    test_case "при списке строк возвращает Some первой строки" `Quick (fun () ->
      check (option string) "safe_head"
        (Some "hello") (My_solutions.safe_head ["hello"; "world"]));
  ]

let bob_tests =
  let open Alcotest in
  [
    test_case "при вопросе возвращает Sure." `Quick (fun () ->
      check string "bob" "Sure."
        (My_solutions.bob "How are you?"));
    test_case "при крике возвращает Whoa, chill out!" `Quick (fun () ->
      check string "bob" "Whoa, chill out!"
        (My_solutions.bob "WHAT ARE YOU DOING"));
    test_case "при кричащем вопросе возвращает Calm down..." `Quick (fun () ->
      check string "bob" "Calm down, I know what I'm doing!"
        (My_solutions.bob "WHAT?"));
    test_case "при тишине возвращает Fine. Be that way!" `Quick (fun () ->
      check string "bob" "Fine. Be that way!"
        (My_solutions.bob "   "));
    test_case "при обычной фразе возвращает Whatever." `Quick (fun () ->
      check string "bob" "Whatever."
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
    test_case "при сторонах 2,2,2 возвращает Equilateral" `Quick (fun () ->
      check (result triangle_testable string) "classify_triangle"
        (Ok My_solutions.Equilateral)
        (My_solutions.classify_triangle 2.0 2.0 2.0));
    test_case "при сторонах 3,3,4 возвращает Isosceles" `Quick (fun () ->
      check (result triangle_testable string) "classify_triangle"
        (Ok My_solutions.Isosceles)
        (My_solutions.classify_triangle 3.0 3.0 4.0));
    test_case "при сторонах 3,4,5 возвращает Scalene" `Quick (fun () ->
      check (result triangle_testable string) "classify_triangle"
        (Ok My_solutions.Scalene)
        (My_solutions.classify_triangle 3.0 4.0 5.0));
    test_case "при невалидных сторонах 1,1,3 возвращает Error" `Quick (fun () ->
      match My_solutions.classify_triangle 1.0 1.0 3.0 with
      | Error _ -> ()
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let raindrops_tests =
  let open Alcotest in
  [
    test_case "при n=3 возвращает Pling" `Quick (fun () ->
      check string "raindrops" "Pling" (My_solutions.raindrops 3));
    test_case "при n=5 возвращает Plang" `Quick (fun () ->
      check string "raindrops" "Plang" (My_solutions.raindrops 5));
    test_case "при n=7 возвращает Plong" `Quick (fun () ->
      check string "raindrops" "Plong" (My_solutions.raindrops 7));
    test_case "при n=15 возвращает PlingPlang" `Quick (fun () ->
      check string "raindrops" "PlingPlang" (My_solutions.raindrops 15));
    test_case "при n=34 возвращает \"34\"" `Quick (fun () ->
      check string "raindrops" "34" (My_solutions.raindrops 34));
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
    test_case "при n=6 возвращает Perfect" `Quick (fun () ->
      check (result class_testable string) "classify"
        (Ok My_solutions.Perfect) (My_solutions.classify 6));
    test_case "при n=12 возвращает Abundant" `Quick (fun () ->
      check (result class_testable string) "classify"
        (Ok My_solutions.Abundant) (My_solutions.classify 12));
    test_case "при n=7 возвращает Deficient" `Quick (fun () ->
      check (result class_testable string) "classify"
        (Ok My_solutions.Deficient) (My_solutions.classify 7));
    test_case "при n=0 возвращает Error" `Quick (fun () ->
      match My_solutions.classify 0 with
      | Error _ -> ()
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let allergies_tests =
  let open Alcotest in
  [
    test_case "при score=0 возвращает пустой список" `Quick (fun () ->
      check (list int) "allergies" [] (List.map Obj.magic (My_solutions.allergies 0)));
    test_case "при score=1 содержит аллергию на яйца" `Quick (fun () ->
      check bool "is_allergic_to" true
        (My_solutions.is_allergic_to My_solutions.Eggs 1));
    test_case "при score=5 возвращает два аллергена" `Quick (fun () ->
      let a = My_solutions.allergies 5 in
      check bool "allergies" true
        (List.length a = 2));
  ]

let () =
  Alcotest.run "Chapter 05"
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
