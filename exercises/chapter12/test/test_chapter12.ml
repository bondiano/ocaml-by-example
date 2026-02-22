open Chapter12.Concurrent

(* --- Утилита: запуск теста внутри Eio --- *)

let run_eio f () =
  Eio_main.run @@ fun _env -> f ()

(* --- Тесты библиотеки --- *)

let fib_tests =
  let open Alcotest in
  [
    test_case "при n=0 возвращает 0" `Quick (fun () ->
      check int "fib" 0 (fib 0));
    test_case "при n=1 возвращает 1" `Quick (fun () ->
      check int "fib" 1 (fib 1));
    test_case "при n=10 возвращает 55" `Quick (fun () ->
      check int "fib" 55 (fib 10));
  ]

let parallel_map_tests =
  let open Alcotest in
  [
    test_case "при функции (*2) и [1;2;3] возвращает [2;4;6]" `Quick (run_eio (fun () ->
      check (list int) "double" [2; 4; 6]
        (parallel_map (fun x -> x * 2) [1; 2; 3])));
    test_case "при пустом списке возвращает []" `Quick (run_eio (fun () ->
      check (list int) "empty" []
        (parallel_map (fun x -> x * 2) [])));
  ]

let parallel_sum_tests =
  let open Alcotest in
  [
    test_case "при [1;2;3;4;5] возвращает 15" `Quick (run_eio (fun () ->
      check int "sum" 15 (parallel_sum [1; 2; 3; 4; 5])));
    test_case "при пустом списке возвращает 0" `Quick (run_eio (fun () ->
      check int "empty" 0 (parallel_sum [])));
  ]

let produce_and_collect_tests =
  let open Alcotest in
  [
    test_case "при produce [1;2;3] возвращает [1;2;3]" `Quick (run_eio (fun () ->
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
    test_case "при n=10 m=10 возвращает 110" `Quick (run_eio (fun () ->
      check int "parallel_fib" 110
        (My_solutions.parallel_fib 10 10)));
    test_case "при n=5 m=7 возвращает 18" `Quick (run_eio (fun () ->
      check int "parallel_fib" 18
        (My_solutions.parallel_fib 5 7)));
    test_case "при n=0 m=1 возвращает 1" `Quick (run_eio (fun () ->
      check int "parallel_fib" 1
        (My_solutions.parallel_fib 0 1)));
  ]

let concurrent_map_tests =
  let open Alcotest in
  [
    test_case "при функции (^2) и [1;2;3;4] возвращает [1;4;9;16]" `Quick (run_eio (fun () ->
      check (list int) "squares" [1; 4; 9; 16]
        (My_solutions.concurrent_map (fun x -> x * x) [1; 2; 3; 4])));
    test_case "при uppercase и [\"hello\";\"world\"] возвращает [\"HELLO\";\"WORLD\"]" `Quick (run_eio (fun () ->
      check (list string) "upper"
        ["HELLO"; "WORLD"]
        (My_solutions.concurrent_map String.uppercase_ascii
           ["hello"; "world"])));
    test_case "при пустом списке возвращает []" `Quick (run_eio (fun () ->
      check (list int) "empty" []
        (My_solutions.concurrent_map (fun x -> x) [])));
  ]

let produce_consume_tests =
  let open Alcotest in
  [
    test_case "при n=5 возвращает 15" `Quick (run_eio (fun () ->
      check int "sum" 15
        (My_solutions.produce_consume 5)));
    test_case "при n=10 возвращает 55" `Quick (run_eio (fun () ->
      check int "sum" 55
        (My_solutions.produce_consume 10)));
    test_case "при n=0 возвращает 0" `Quick (run_eio (fun () ->
      check int "sum" 0
        (My_solutions.produce_consume 0)));
  ]

let race_tests =
  let open Alcotest in
  [
    test_case "при двух задачах возвращает результат одной из них" `Quick (run_eio (fun () ->
      let result = My_solutions.race [
        (fun () -> 42);
        (fun () -> 99);
      ] in
      check bool "result is 42 or 99" true
        (result = 42 || result = 99)));
    test_case "при одной задаче возвращает её результат" `Quick (run_eio (fun () ->
      check int "single" 7
        (My_solutions.race [(fun () -> 7)])));
  ]

let rate_limit_tests =
  let open Alcotest in
  [
    test_case "применяет функцию к каждому элементу с задержкой" `Quick (fun () ->
      Eio_main.run @@ fun env ->
      let clock = Eio.Stdenv.clock env in
      let result = My_solutions.rate_limit ~clock (fun x -> x * 2) [1; 2; 3] 0.01 in
      check (list int) "rate_limit" [2; 4; 6] result);
  ]

let worker_pool_tests =
  let open Alcotest in
  [
    test_case "распределяет задачи между воркерами" `Quick (run_eio (fun () ->
      let tasks = List.init 10 (fun i -> fun () -> i + 1) in
      let results = My_solutions.worker_pool 3 tasks in
      check int "sum of results" 55 (List.fold_left (+) 0 results)));
  ]

let parallel_process_tests =
  let open Alcotest in
  [
    test_case "обрабатывает файлы конкурентно" `Quick (run_eio (fun () ->
      let files = ["file1.txt"; "file2.txt"; "file3.txt"] in
      let result = My_solutions.parallel_process String.length files in
      check int "total length" 30 result));
  ]

let () =
  Alcotest.run "Chapter 12"
    [
      ("fib --- числа Фибоначчи", fib_tests);
      ("parallel_map --- параллельный map", parallel_map_tests);
      ("parallel_sum --- параллельная сумма", parallel_sum_tests);
      ("produce_and_collect --- producer-consumer", produce_and_collect_tests);
      ("parallel_fib --- параллельный Фибоначчи", parallel_fib_tests);
      ("concurrent_map --- конкурентный map", concurrent_map_tests);
      ("produce_consume --- producer-consumer сумма", produce_consume_tests);
      ("race --- гонка задач", race_tests);
      ("rate_limit --- ограничение скорости", rate_limit_tests);
      ("worker_pool --- пул воркеров", worker_pool_tests);
      ("parallel_process --- параллельная обработка", parallel_process_tests);
    ]
