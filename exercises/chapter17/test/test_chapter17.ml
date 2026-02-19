open Chapter17.Lwt_examples

(* --- Тесты библиотеки --- *)

let lwt_tc name f =
  Alcotest.test_case name `Quick (fun () -> Lwt_main.run (f ()))

let basic_tests =
  [
    lwt_tc "delay returns unit" (fun () ->
      let open Lwt.Syntax in
      let* () = delay 0.01 in
      Lwt.return (Alcotest.(check unit) "unit" () ()));

    lwt_tc "sequence" (fun () ->
      let open Lwt.Syntax in
      let* results = sequence [Lwt.return 1; Lwt.return 2; Lwt.return 3] in
      Lwt.return (Alcotest.(check (list int)) "seq" [1; 2; 3] results));

    lwt_tc "parallel2" (fun () ->
      let open Lwt.Syntax in
      let* (a, b) = parallel2 (Lwt.return 1) (Lwt.return "hello") in
      Alcotest.(check int) "a" 1 a;
      Lwt.return (Alcotest.(check string) "b" "hello" b));

    lwt_tc "race" (fun () ->
      let open Lwt.Syntax in
      let slow = let* () = delay 1.0 in Lwt.return "slow" in
      let fast = let* () = delay 0.01 in Lwt.return "fast" in
      let* winner = race fast slow in
      Lwt.return (Alcotest.(check string) "winner" "fast" winner));

    lwt_tc "parallel_delays" (fun () ->
      let open Lwt.Syntax in
      let* results = parallel_delays () in
      Lwt.return (Alcotest.(check (list string)) "results" ["first"; "second"] results));

    lwt_tc "race_example" (fun () ->
      let open Lwt.Syntax in
      let* result = race_example () in
      Lwt.return (Alcotest.(check string) "fast" "fast" result));
  ]

(* --- Тесты упражнений --- *)

let sequential_map_tests =
  [
    lwt_tc "sequential_map identity" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.sequential_map Lwt.return [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "identity" [1; 2; 3] results));

    lwt_tc "sequential_map double" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.sequential_map
        (fun x -> Lwt.return (x * 2)) [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "doubled" [2; 4; 6] results));

    lwt_tc "sequential_map empty" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.sequential_map Lwt.return [] in
      Lwt.return (Alcotest.(check (list int)) "empty" [] results));

    lwt_tc "sequential_map preserves order" (fun () ->
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
    lwt_tc "concurrent_map identity" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.concurrent_map Lwt.return [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "identity" [1; 2; 3] results));

    lwt_tc "concurrent_map double" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.concurrent_map
        (fun x -> Lwt.return (x * 2)) [1; 2; 3] in
      Lwt.return (Alcotest.(check (list int)) "doubled" [2; 4; 6] results));

    lwt_tc "concurrent_map empty" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.concurrent_map Lwt.return [] in
      Lwt.return (Alcotest.(check (list int)) "empty" [] results));
  ]

let timeout_tests =
  [
    lwt_tc "timeout succeeds" (fun () ->
      let open Lwt.Syntax in
      let* result = My_solutions.timeout 1.0 (Lwt.return 42) in
      Lwt.return (Alcotest.(check (option int)) "some" (Some 42) result));

    lwt_tc "timeout expires" (fun () ->
      let open Lwt.Syntax in
      let slow =
        let* () = Lwt_unix.sleep 1.0 in
        Lwt.return 42
      in
      let* result = My_solutions.timeout 0.01 slow in
      Lwt.return (Alcotest.(check (option int)) "none" None result));
  ]

let rate_limit_tests =
  [
    lwt_tc "rate_limit all" (fun () ->
      let open Lwt.Syntax in
      let tasks = List.init 5 (fun i -> fun () -> Lwt.return i) in
      let* results = My_solutions.rate_limit 2 tasks in
      Lwt.return (Alcotest.(check (list int)) "all" [0; 1; 2; 3; 4] results));

    lwt_tc "rate_limit respects limit" (fun () ->
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
      Alcotest.(check (list int)) "all results" [0; 1; 2; 3; 4; 5] results;
      Lwt.return (Alcotest.(check bool) "max 3" true (!max_running <= 3)));

    lwt_tc "rate_limit empty" (fun () ->
      let open Lwt.Syntax in
      let* results = My_solutions.rate_limit 5 [] in
      Lwt.return (Alcotest.(check (list int)) "empty" [] results));
  ]

let () =
  Alcotest.run "Chapter 17"
    [
      ("basic --- базовые операции Lwt", basic_tests);
      ("sequential_map --- последовательный map", sequential_map_tests);
      ("concurrent_map --- параллельный map", concurrent_map_tests);
      ("timeout --- таймаут", timeout_tests);
      ("rate_limit --- ограничение параллелизма", rate_limit_tests);
    ]
