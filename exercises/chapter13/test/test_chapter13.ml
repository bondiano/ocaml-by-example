open Chapter13.Effects

(* --- Тесты библиотеки --- *)

let state_tests =
  let open Alcotest in
  [
    test_case "run_state example" `Quick (fun () ->
      let result = run_state 5 state_example in
      check int "5 + 15" 20 result);
    test_case "run_state set/get" `Quick (fun () ->
      let result = run_state 0 (fun () ->
        Effect.perform (Set 42);
        Effect.perform Get
      ) in
      check int "42" 42 result);
  ]

let log_tests =
  let open Alcotest in
  [
    test_case "run_log example" `Quick (fun () ->
      let (result, logs) = run_log log_example in
      check int "result" 5 result;
      check int "log count" 3 (List.length logs);
      check string "first" "start" (List.hd logs));
  ]

let combined_tests =
  let open Alcotest in
  [
    test_case "state + log" `Quick (fun () ->
      let (result, logs) = run_log (fun () ->
        run_state 7 combined_example
      ) in
      check int "result" 14 result;
      check int "log count" 3 (List.length logs));
  ]

(* --- Тесты упражнений --- *)

let emit_tests =
  let open Alcotest in
  [
    test_case "run_emit basic" `Quick (fun () ->
      let ((), items) = My_solutions.run_emit (fun () ->
        Effect.perform (My_solutions.Emit 1);
        Effect.perform (My_solutions.Emit 2);
        Effect.perform (My_solutions.Emit 3)
      ) in
      check (list int) "items" [1; 2; 3] items);
    test_case "run_emit with result" `Quick (fun () ->
      let (result, items) = My_solutions.run_emit (fun () ->
        Effect.perform (My_solutions.Emit 10);
        42
      ) in
      check int "result" 42 result;
      check (list int) "items" [10] items);
    test_case "run_emit empty" `Quick (fun () ->
      let ((), items) = My_solutions.run_emit (fun () -> ()) in
      check (list int) "empty" [] items);
  ]

let reader_tests =
  let open Alcotest in
  [
    test_case "run_reader" `Quick (fun () ->
      let result = My_solutions.run_reader "hello" (fun () ->
        let env = Effect.perform My_solutions.Ask in
        String.uppercase_ascii env
      ) in
      check string "HELLO" "HELLO" result);
    test_case "run_reader multiple asks" `Quick (fun () ->
      let result = My_solutions.run_reader "world" (fun () ->
        let a = Effect.perform My_solutions.Ask in
        let b = Effect.perform My_solutions.Ask in
        a ^ " " ^ b
      ) in
      check string "world world" "world world" result);
  ]

let count_and_emit_tests =
  let open Alcotest in
  [
    test_case "count_and_emit 3" `Quick (fun () ->
      let ((), items) = My_solutions.run_emit (fun () ->
        run_state 0 (fun () ->
          My_solutions.count_and_emit 3
        )
      ) in
      check (list int) "items" [1; 3; 6] items);
    test_case "count_and_emit 0" `Quick (fun () ->
      let ((), items) = My_solutions.run_emit (fun () ->
        run_state 0 (fun () ->
          My_solutions.count_and_emit 0
        )
      ) in
      check (list int) "empty" [] items);
  ]

let result_testable =
  Alcotest.result Alcotest.int Alcotest.string

let fail_tests =
  let open Alcotest in
  [
    test_case "run_fail ok" `Quick (fun () ->
      let r = My_solutions.run_fail (fun () -> 42) in
      check result_testable "ok" (Ok 42) r);
    test_case "run_fail error" `Quick (fun () ->
      let r = My_solutions.run_fail (fun () ->
        Effect.perform (My_solutions.Fail "oops")
      ) in
      check result_testable "error" (Error "oops") r);
    test_case "run_fail error midway" `Quick (fun () ->
      let r = My_solutions.run_fail (fun () ->
        let x = 1 + 2 in
        if x > 0 then Effect.perform (My_solutions.Fail "positive");
        x
      ) in
      check result_testable "error" (Error "positive") r);
  ]

let () =
  Alcotest.run "Chapter 11"
    [
      ("state --- эффект State", state_tests);
      ("log --- эффект Log", log_tests);
      ("combined --- State + Log", combined_tests);
      ("emit --- эффект Emit", emit_tests);
      ("reader --- эффект Reader", reader_tests);
      ("count_and_emit --- State + Emit", count_and_emit_tests);
      ("fail --- эффект Fail", fail_tests);
    ]
