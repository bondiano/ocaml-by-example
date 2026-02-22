(* Тесты для упражнений главы 03 *)

open Alcotest

(* Тесты для упражнения 1: Високосный год *)
let test_is_leap_year () =
  check bool "2000 — високосный" true (My_solutions.is_leap_year 2000);
  check bool "1900 — не високосный" false (My_solutions.is_leap_year 1900);
  check bool "2020 — високосный" true (My_solutions.is_leap_year 2020);
  check bool "2021 — не високосный" false (My_solutions.is_leap_year 2021);
  check bool "2024 — високосный" true (My_solutions.is_leap_year 2024);
  check bool "2100 — не високосный" false (My_solutions.is_leap_year 2100);
  check bool "2400 — високосный" true (My_solutions.is_leap_year 2400)

(* Тесты для упражнения 2: Треугольник *)
let test_triangle () =
  check string "equilateral" "equilateral" (My_solutions.triangle 2 2 2);
  check string "isosceles 1" "isosceles" (My_solutions.triangle 3 4 4);
  check string "isosceles 2" "isosceles" (My_solutions.triangle 4 3 4);
  check string "scalene" "scalene" (My_solutions.triangle 3 4 5);
  check string "invalid 1" "invalid" (My_solutions.triangle 1 1 3);
  check string "invalid 2" "invalid" (My_solutions.triangle 0 0 0);
  check string "invalid 3" "invalid" (My_solutions.triangle (-1) 2 3)

(* Тесты для упражнения 3: Raindrops *)
let test_raindrops () =
  check string "28 = Plong" "Plong" (My_solutions.raindrops 28);
  check string "30 = PlingPlang" "PlingPlang" (My_solutions.raindrops 30);
  check string "34 = 34" "34" (My_solutions.raindrops 34);
  check string "105 = PlingPlangPlong" "PlingPlangPlong"
    (My_solutions.raindrops 105);
  check string "3 = Pling" "Pling" (My_solutions.raindrops 3);
  check string "5 = Plang" "Plang" (My_solutions.raindrops 5);
  check string "7 = Plong" "Plong" (My_solutions.raindrops 7);
  check string "1 = 1" "1" (My_solutions.raindrops 1)

(* Тесты для упражнения 4: Форматирование имени *)
let test_format_name () =
  check string "иван петров" "Петров, Иван"
    (My_solutions.format_name "иван" "петров");
  check string "АННА сидорова" "Сидорова, Анна"
    (My_solutions.format_name "АННА" "сидорова");
  check string "Mixed case" "Кузнецов, Алексей"
    (My_solutions.format_name "АлЕкСеЙ" "КуЗнЕцОв")

(* Тесты для упражнения 5: Сумма списка *)
let test_sum_list () =
  check int "empty list" 0 (My_solutions.sum_list []);
  check int "[1; 2; 3; 4]" 10 (My_solutions.sum_list [ 1; 2; 3; 4 ]);
  check int "[42]" 42 (My_solutions.sum_list [ 42 ]);
  check int "negative numbers" (-10) (My_solutions.sum_list [ 1; -2; 3; -4; -8 ])

(* Тесты для упражнения 6: Фибоначчи *)
let test_fib () =
  check int "fib 0" 0 (My_solutions.fib 0);
  check int "fib 1" 1 (My_solutions.fib 1);
  check int "fib 2" 1 (My_solutions.fib 2);
  check int "fib 6" 8 (My_solutions.fib 6);
  check int "fib 10" 55 (My_solutions.fib 10);
  check int "fib 15" 610 (My_solutions.fib 15)

let () =
  run "Chapter 03"
    [
      ("Упражнение 1: Високосный год", [ test_case "is_leap_year" `Quick test_is_leap_year ]);
      ("Упражнение 2: Треугольник", [ test_case "triangle" `Quick test_triangle ]);
      ("Упражнение 3: Raindrops", [ test_case "raindrops" `Quick test_raindrops ]);
      ("Упражнение 4: Форматирование имени", [ test_case "format_name" `Quick test_format_name ]);
      ("Упражнение 5: Сумма списка", [ test_case "sum_list" `Quick test_sum_list ]);
      ("Упражнение 6: Фибоначчи", [ test_case "fib" `Quick test_fib ]);
    ]
