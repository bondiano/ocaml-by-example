let euler_tests =
  let open Alcotest in
  [
    test_case "ниже 10 равна 23" `Quick (fun () ->
      check int "answer 10" 23 (Chapter02.Euler.answer 10));
    test_case "ниже 1000 равна 233168" `Quick (fun () ->
      check int "answer 1000" 233168 (Chapter02.Euler.answer 1000));
  ]

let close_to expected actual =
  Float.abs (actual -. expected) < 1e-9

let diagonal_tests =
  let open Alcotest in
  [
    test_case "диагональ 3×4 равна 5" `Quick (fun () ->
      check (float 1e-9) "diagonal 3 4" 5.0 (My_solutions.diagonal 3.0 4.0));
    test_case "диагональ 5×12 равна 13" `Quick (fun () ->
      check (float 1e-9) "diagonal 5 12" 13.0 (My_solutions.diagonal 5.0 12.0));
  ]

let circle_area_tests =
  let open Alcotest in
  [
    test_case "площадь круга с радиусом 1" `Quick (fun () ->
      check bool "circle_area 1 ≈ π" true
        (close_to Float.pi (My_solutions.circle_area 1.0)));
    test_case "площадь круга с радиусом 10" `Quick (fun () ->
      check bool "circle_area 10 ≈ 100π" true
        (close_to (100.0 *. Float.pi) (My_solutions.circle_area 10.0)));
  ]

let collatz_tests =
  let open Alcotest in
  [
    test_case "длина цепочки для 1 равна 0" `Quick (fun () ->
      check int "collatz 1" 0 (My_solutions.collatz_length 1));
    test_case "длина цепочки для 2 равна 1" `Quick (fun () ->
      check int "collatz 2" 1 (My_solutions.collatz_length 2));
    test_case "длина цепочки для 6 равна 8" `Quick (fun () ->
      check int "collatz 6" 8 (My_solutions.collatz_length 6));
    test_case "длина цепочки для 27 равна 111" `Quick (fun () ->
      check int "collatz 27" 111 (My_solutions.collatz_length 27));
  ]

let sum_tests =
  let open Alcotest in
  [
    test_case "sum пустого списка" `Quick (fun () ->
      check int "empty" 0 (Chapter02.Euler.sum []));
    test_case "sum [1;2;3;4;5]" `Quick (fun () ->
      check int "sum" 15 (Chapter02.Euler.sum [1; 2; 3; 4; 5]));
  ]

let factorial_tests =
  let open Alcotest in
  [
    test_case "factorial 0" `Quick (fun () ->
      check int "0!" 1 (Chapter02.Euler.factorial 0));
    test_case "factorial 5" `Quick (fun () ->
      check int "5!" 120 (Chapter02.Euler.factorial 5));
    test_case "factorial 10" `Quick (fun () ->
      check int "10!" 3628800 (Chapter02.Euler.factorial 10));
  ]

let sieve_lib_tests =
  let open Alcotest in
  [
    test_case "простые числа до 10" `Quick (fun () ->
      check (list int) "primes" [2; 3; 5; 7] (Chapter02.Euler.sieve 10));
    test_case "простые числа до 30" `Quick (fun () ->
      check (list int) "primes 30" [2; 3; 5; 7; 11; 13; 17; 19; 23; 29]
        (Chapter02.Euler.sieve 30));
  ]

let leap_year_tests =
  let open Alcotest in
  [
    test_case "2000 — високосный" `Quick (fun () ->
      check bool "2000" true (My_solutions.is_leap_year 2000));
    test_case "1900 — не високосный" `Quick (fun () ->
      check bool "1900" false (My_solutions.is_leap_year 1900));
    test_case "2024 — високосный" `Quick (fun () ->
      check bool "2024" true (My_solutions.is_leap_year 2024));
    test_case "2023 — не високосный" `Quick (fun () ->
      check bool "2023" false (My_solutions.is_leap_year 2023));
  ]

let space_age_tests =
  let open Alcotest in
  [
    test_case "возраст на Земле" `Quick (fun () ->
      check (float 0.01) "earth" 31.69
        (My_solutions.space_age My_solutions.Earth 1000000000.0));
    test_case "возраст на Меркурии" `Quick (fun () ->
      check (float 0.01) "mercury" 280.88
        (My_solutions.space_age My_solutions.Mercury 2134835688.0));
  ]

let difference_of_squares_tests =
  let open Alcotest in
  [
    test_case "квадрат суммы 5" `Quick (fun () ->
      check int "sq_sum 5" 225 (My_solutions.square_of_sum 5));
    test_case "сумма квадратов 5" `Quick (fun () ->
      check int "sum_sq 5" 55 (My_solutions.sum_of_squares 5));
    test_case "разность для 5" `Quick (fun () ->
      check int "diff 5" 170 (My_solutions.difference_of_squares 5));
    test_case "разность для 10" `Quick (fun () ->
      check int "diff 10" 2640 (My_solutions.difference_of_squares 10));
  ]

let sieve_tests =
  let open Alcotest in
  [
    test_case "простые до 10" `Quick (fun () ->
      check (list int) "sieve 10" [2; 3; 5; 7]
        (My_solutions.sieve 10));
    test_case "простые до 2" `Quick (fun () ->
      check (list int) "sieve 2" [2]
        (My_solutions.sieve 2));
  ]

let () =
  Alcotest.run "Chapter 02"
    [
      ("Euler — сумма кратных", euler_tests);
      ("diagonal", diagonal_tests);
      ("circle_area", circle_area_tests);
      ("collatz_length", collatz_tests);
      ("sum — хвостовая рекурсия", sum_tests);
      ("factorial — хвостовой", factorial_tests);
      ("sieve (lib) — решето", sieve_lib_tests);
      ("Leap Year — високосный год", leap_year_tests);
      ("Space Age — возраст на планетах", space_age_tests);
      ("Difference of Squares", difference_of_squares_tests);
      ("sieve — решето (упражнение)", sieve_tests);
    ]
