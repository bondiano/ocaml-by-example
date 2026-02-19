open Appendix_b.Lwt_examples

(* --- Тесты библиотеки --- *)

let lwt_tc name f =
  Alcotest.test_case name `Quick (fun () -> Lwt_main.run (f ()))

let basic_tests =
  [
    lwt_tc "при delay 0.01 возвращает unit" (fun () ->
      let open Lwt.Syntax in
      let* () = delay 0.01 in
      Lwt.return (Alcotest.(check unit) "result" () ()));

    lwt_tc "при [1;2;3] sequence возвращает [1;2;3]" (fun () ->
      let open Lwt.Syntax in
      let* results = sequence [Lwt.return 1; Lwt.return 2; Lwt.return 3] in
      Lwt.return (Alcotest.(check (list int)) "result" [1; 2; 3] results));

    lwt_tc "при двух промисах parallel2 возвращает пару" (fun () ->
      let open Lwt.Syntax in
      let* (a, b) = parallel2 (Lwt.return 1) (Lwt.return "hello") in
      Alcotest.(check int) "a" 1 a;
      Lwt.return (Alcotest.(check string) "b" "hello" b));

    lwt_tc "при быстром и медленном race возвращает fast" (fun () ->
      let open Lwt.Syntax in
      let slow = let* () = delay 1.0 in Lwt.return "slow" in
      let fast = let* () = delay 0.01 in Lwt.return "fast" in
      let* winner = race fast slow in
      Lwt.return (Alcotest.(check string) "result" "fast" winner));

    lwt_tc "при двух задержках parallel_delays возвращает [first;second]" (fun () ->
      let open Lwt.Syntax in
      let* results = parallel_delays () in
      Lwt.return (Alcotest.(check (list string)) "result" ["first"; "second"] results));

    lwt_tc "при race_example возвращает fast" (fun () ->
      let open Lwt.Syntax in
      let* result = race_example () in
      Lwt.return (Alcotest.(check string) "result" "fast" result));
  ]

(* --- Тесты упражнений --- *)

let sequential_map_tests =
  [
    lwt_tc "при identity fn и [1;2;3] возвращает [1;2;3]" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.sequential_map Lwt.return [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "result" [1; 2; 3] results));

    lwt_tc "при fn*2 и [1;2;3] возвращает [2;4;6]" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.sequential_map
        (fun x -> Lwt.return (x * 2)) [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "result" [2; 4; 6] results));

    lwt_tc "при пустом списке возвращает []" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.sequential_map Lwt.return [] in
      Lwt.return (Alcotest.(check (list int)) "result" [] results));

    lwt_tc "при разных задержках сохраняет порядок обработки" (fun () ->
      let open Lwt.Syntax in
      let order = ref [] in
      let f x =
        let* () = Lwt_unix.sleep (Float.of_int (3 - x) *. 0.01) in
        order := x :: !order;
        Lwt.return x
      in
      let* results = My_solutions.sequential_map f [1; 2; 3] in
      Alcotest.(check (list int)) "results" [1; 2; 3] results;
      Lwt.return (Alcotest.(check (list int)) "order" [3; 2; 1] !order));
  ]

let concurrent_map_tests =
  [
    lwt_tc "при identity fn и [1;2;3] возвращает [1;2;3]" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.concurrent_map Lwt.return [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "result" [1; 2; 3] results));

    lwt_tc "при fn*2 и [1;2;3] возвращает [2;4;6]" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.concurrent_map
        (fun x -> Lwt.return (x * 2)) [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "result" [2; 4; 6] results));

    lwt_tc "при пустом списке возвращает []" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.concurrent_map Lwt.return [] in
      Lwt.return (Alcotest.(check (list int)) "result" [] results));
  ]

let timeout_tests =
  [
    lwt_tc "при быстром промисе возвращает Some 42" (fun () ->
      let open Lwt.Syntax in
      let* result = My_solutions.timeout 1.0 (Lwt.return 42) in
      Lwt.return (Alcotest.(check (option int)) "result" (Some 42) result));

    lwt_tc "при медленном промисе возвращает None" (fun () ->
      let open Lwt.Syntax in
      let slow =
        let* () = Lwt_unix.sleep 1.0 in
        Lwt.return 42
      in
      let* result = My_solutions.timeout 0.01 slow in
      Lwt.return (Alcotest.(check (option int)) "result" None result));
  ]

let rate_limit_tests =
  [
    lwt_tc "при 5 задачах возвращает все результаты" (fun () ->
      let open Lwt.Syntax in
      let tasks = List.init 5 (fun i -> fun () -> Lwt.return i) in
      let* results = My_solutions.rate_limit 2 tasks in
      Lwt.return (Alcotest.(check (list int)) "result" [0; 1; 2; 3; 4] results));

    lwt_tc "при limit=3 одновременно выполняет не более 3 задач" (fun () ->
      let open Lwt.Syntax in
      let running = ref 0 in
      let max_running = ref 0 in
      let tasks = List.init 6 (fun i -> fun () ->
        running := !running + 1;
        if !running > !max_running then max_running := !running;
        let* () = Lwt_unix.sleep 0.02 in
        running := !running - 1;
        Lwt.return i
      ) in
      let* results = My_solutions.rate_limit 3 tasks in
      Alcotest.(check (list int)) "results" [0; 1; 2; 3; 4; 5] results;
      Lwt.return (Alcotest.(check bool) "result" true (!max_running <= 3)));

    lwt_tc "при пустом списке возвращает []" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.rate_limit 5 [] in
      Lwt.return (Alcotest.(check (list int)) "result" [] results));
  ]

let () =
  Alcotest.run "Appendix B"
    [
      ("basic --- базовые операции Lwt", basic_tests);
      ("sequential_map --- последовательный map", sequential_map_tests);
      ("concurrent_map --- параллельный map", concurrent_map_tests);
      ("timeout --- таймаут", timeout_tests);
      ("rate_limit --- ограничение параллелизма", rate_limit_tests);
    ]
