open Chapter11.Concurrent

(* --- Утилита: запуск теста внутри Eio --- *)

let run_eio f () =
  Eio_main.run @@ fun _env -> f ()

(* --- Тесты библиотеки --- *)

let fib_tests =
  let open Alcotest in
  [
    test_case "fib 0" `Quick (fun () ->
      check int "fib 0" 0 (fib 0));
    test_case "fib 1" `Quick (fun () ->
      check int "fib 1" 1 (fib 1));
    test_case "fib 10" `Quick (fun () ->
      check int "fib 10" 55 (fib 10));
  ]

let parallel_map_tests =
  let open Alcotest in
  [
    test_case "parallel_map double" `Quick (run_eio (fun () ->
      check (list int) "double" [2; 4; 6]
        (parallel_map (fun x -> x * 2) [1; 2; 3])));
    test_case "parallel_map пустой список" `Quick (run_eio (fun () ->
      check (list int) "empty" []
        (parallel_map (fun x -> x * 2) [])));
  ]

let parallel_sum_tests =
  let open Alcotest in
  [
    test_case "parallel_sum" `Quick (run_eio (fun () ->
      check int "sum" 15 (parallel_sum [1; 2; 3; 4; 5])));
    test_case "parallel_sum пустой" `Quick (run_eio (fun () ->
      check int "empty" 0 (parallel_sum [])));
  ]

let produce_and_collect_tests =
  let open Alcotest in
  [
    test_case "produce_and_collect" `Quick (run_eio (fun () ->
      let result = produce_and_collect (fun stream ->
        for i = 1 to 3 do
          Eio.Stream.add stream (Some i)
        done;
        Eio.Stream.add stream None
      ) in
      check (list int) "collected" [1; 2; 3] result));
  ]

(* --- Тесты упражнений --- *)

let parallel_fib_tests =
  let open Alcotest in
  [
    test_case "parallel_fib 10 10" `Quick (run_eio (fun () ->
      check int "fib 10 + fib 10" 110
        (My_solutions.parallel_fib 10 10)));
    test_case "parallel_fib 5 7" `Quick (run_eio (fun () ->
      check int "fib 5 + fib 7" 18
        (My_solutions.parallel_fib 5 7)));
    test_case "parallel_fib 0 1" `Quick (run_eio (fun () ->
      check int "fib 0 + fib 1" 1
        (My_solutions.parallel_fib 0 1)));
  ]

let concurrent_map_tests =
  let open Alcotest in
  [
    test_case "concurrent_map square" `Quick (run_eio (fun () ->
      check (list int) "squares" [1; 4; 9; 16]
        (My_solutions.concurrent_map (fun x -> x * x) [1; 2; 3; 4])));
    test_case "concurrent_map strings" `Quick (run_eio (fun () ->
      check (list string) "upper"
        ["HELLO"; "WORLD"]
        (My_solutions.concurrent_map String.uppercase_ascii
           ["hello"; "world"])));
    test_case "concurrent_map пустой" `Quick (run_eio (fun () ->
      check (list int) "empty" []
        (My_solutions.concurrent_map (fun x -> x) [])));
  ]

let produce_consume_tests =
  let open Alcotest in
  [
    test_case "produce_consume 5" `Quick (run_eio (fun () ->
      check int "sum 1..5" 15
        (My_solutions.produce_consume 5)));
    test_case "produce_consume 10" `Quick (run_eio (fun () ->
      check int "sum 1..10" 55
        (My_solutions.produce_consume 10)));
    test_case "produce_consume 0" `Quick (run_eio (fun () ->
      check int "sum 0" 0
        (My_solutions.produce_consume 0)));
  ]

let race_tests =
  let open Alcotest in
  [
    test_case "race возвращает результат" `Quick (run_eio (fun () ->
      let result = My_solutions.race [
        (fun () -> 42);
        (fun () -> 99);
      ] in
      check bool "result is 42 or 99" true
        (result = 42 || result = 99)));
    test_case "race с одной задачей" `Quick (run_eio (fun () ->
      check int "single" 7
        (My_solutions.race [(fun () -> 7)])));
  ]

let () =
  Alcotest.run "Chapter 09"
    [
      ("fib --- числа Фибоначчи", fib_tests);
      ("parallel_map --- параллельный map", parallel_map_tests);
      ("parallel_sum --- параллельная сумма", parallel_sum_tests);
      ("produce_and_collect --- producer-consumer", produce_and_collect_tests);
      ("parallel_fib --- параллельный Фибоначчи", parallel_fib_tests);
      ("concurrent_map --- конкурентный map", concurrent_map_tests);
      ("produce_consume --- producer-consumer сумма", produce_consume_tests);
      ("race --- гонка задач", race_tests);
    ]
