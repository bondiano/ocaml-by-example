let euler_tests =
  let open Alcotest in
  [
    test_case "при limit=10 возвращает 23" `Quick (fun () ->
      check int "answer" 23 (Chapter02.Euler.answer 10));
    test_case "при limit=1000 возвращает 233168" `Quick (fun () ->
      check int "answer" 233168 (Chapter02.Euler.answer 1000));
  ]

let close_to expected actual =
  Float.abs (actual -. expected) < 1e-9

let diagonal_tests =
  let open Alcotest in
  [
    test_case "при 3×4 возвращает 5" `Quick (fun () ->
      check (float 1e-9) "diagonal" 5.0 (My_solutions.diagonal 3.0 4.0));
    test_case "при 5×12 возвращает 13" `Quick (fun () ->
      check (float 1e-9) "diagonal" 13.0 (My_solutions.diagonal 5.0 12.0));
  ]

let circle_area_tests =
  let open Alcotest in
  [
    test_case "при r=1 возвращает π" `Quick (fun () ->
      check bool "circle_area" true
        (close_to Float.pi (My_solutions.circle_area 1.0)));
    test_case "при r=10 возвращает 100π" `Quick (fun () ->
      check bool "circle_area" true
        (close_to (100.0 *. Float.pi) (My_solutions.circle_area 10.0)));
  ]

let collatz_tests =
  let open Alcotest in
  [
    test_case "при n=1 возвращает 0" `Quick (fun () ->
      check int "collatz" 0 (My_solutions.collatz_length 1));
    test_case "при n=2 возвращает 1" `Quick (fun () ->
      check int "collatz" 1 (My_solutions.collatz_length 2));
    test_case "при n=6 возвращает 8" `Quick (fun () ->
      check int "collatz" 8 (My_solutions.collatz_length 6));
    test_case "при n=27 возвращает 111" `Quick (fun () ->
      check int "collatz" 111 (My_solutions.collatz_length 27));
  ]

let sum_tests =
  let open Alcotest in
  [
    test_case "при пустом списке возвращает 0" `Quick (fun () ->
      check int "sum" 0 (Chapter02.Euler.sum []));
    test_case "при [1;2;3;4;5] возвращает 15" `Quick (fun () ->
      check int "sum" 15 (Chapter02.Euler.sum [1; 2; 3; 4; 5]));
  ]

let factorial_tests =
  let open Alcotest in
  [
    test_case "при n=0 возвращает 1" `Quick (fun () ->
      check int "factorial" 1 (Chapter02.Euler.factorial 0));
    test_case "при n=5 возвращает 120" `Quick (fun () ->
      check int "factorial" 120 (Chapter02.Euler.factorial 5));
    test_case "при n=10 возвращает 3628800" `Quick (fun () ->
      check int "factorial" 3628800 (Chapter02.Euler.factorial 10));
  ]

let sieve_lib_tests =
  let open Alcotest in
  [
    test_case "при limit=10 возвращает [2;3;5;7]" `Quick (fun () ->
      check (list int) "sieve" [2; 3; 5; 7] (Chapter02.Euler.sieve 10));
    test_case "при limit=30 возвращает 10 простых" `Quick (fun () ->
      check (list int) "sieve" [2; 3; 5; 7; 11; 13; 17; 19; 23; 29]
        (Chapter02.Euler.sieve 30));
  ]

let leap_year_tests =
  let open Alcotest in
  [
    test_case "при 2000 (кратен 400) возвращает true" `Quick (fun () ->
      check bool "leap_year" true (My_solutions.is_leap_year 2000));
    test_case "при 1900 (кратен 100, не 400) возвращает false" `Quick (fun () ->
      check bool "leap_year" false (My_solutions.is_leap_year 1900));
    test_case "при 2024 (кратен 4, не 100) возвращает true" `Quick (fun () ->
      check bool "leap_year" true (My_solutions.is_leap_year 2024));
    test_case "при 2023 (не кратен 4) возвращает false" `Quick (fun () ->
      check bool "leap_year" false (My_solutions.is_leap_year 2023));
  ]

let space_age_tests =
  let open Alcotest in
  [
    test_case "при 1e9 секунд на Земле возвращает 31.69" `Quick (fun () ->
      check (float 0.01) "space_age" 31.69
        (My_solutions.space_age My_solutions.Earth 1000000000.0));
    test_case "при 2.1e9 секунд на Меркурии возвращает 280.88" `Quick (fun () ->
      check (float 0.01) "space_age" 280.88
        (My_solutions.space_age My_solutions.Mercury 2134835688.0));
  ]

let difference_of_squares_tests =
  let open Alcotest in
  [
    test_case "square_of_sum при n=5 возвращает 225" `Quick (fun () ->
      check int "sq_sum" 225 (My_solutions.square_of_sum 5));
    test_case "sum_of_squares при n=5 возвращает 55" `Quick (fun () ->
      check int "sum_sq" 55 (My_solutions.sum_of_squares 5));
    test_case "difference при n=5 возвращает 170" `Quick (fun () ->
      check int "diff" 170 (My_solutions.difference_of_squares 5));
    test_case "difference при n=10 возвращает 2640" `Quick (fun () ->
      check int "diff" 2640 (My_solutions.difference_of_squares 10));
  ]

let sieve_tests =
  let open Alcotest in
  [
    test_case "при limit=10 возвращает [2;3;5;7]" `Quick (fun () ->
      check (list int) "sieve" [2; 3; 5; 7]
        (My_solutions.sieve 10));
    test_case "при limit=2 возвращает [2]" `Quick (fun () ->
      check (list int) "sieve" [2]
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
