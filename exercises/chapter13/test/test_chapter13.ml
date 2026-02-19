open Chapter13.Effects

(* --- Тесты библиотеки --- *)

let state_tests =
  let open Alcotest in
  [
    test_case "при начальном состоянии 5 state_example возвращает 20" `Quick (fun () ->
      let result = run_state 5 state_example in
      check int "result" 20 result);
    test_case "при Set 42 затем Get возвращает 42" `Quick (fun () ->
      let result = run_state 0 (fun () ->
        Effect.perform (Set 42);
        Effect.perform Get
      ) in
      check int "result" 42 result);
  ]

let log_tests =
  let open Alcotest in
  [
    test_case "при log_example возвращает 5 и три сообщения" `Quick (fun () ->
      let (result, logs) = run_log log_example in
      check int "result" 5 result;
      check int "log count" 3 (List.length logs);
      check string "first" "start" (List.hd logs));
  ]

let combined_tests =
  let open Alcotest in
  [
    test_case "при combined_example с state=7 возвращает 14 и три лога" `Quick (fun () ->
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
    test_case "при трёх Emit возвращает [1;2;3]" `Quick (fun () ->
      let ((), items) = My_solutions.run_emit (fun () ->
        Effect.perform (My_solutions.Emit 1);
        Effect.perform (My_solutions.Emit 2);
        Effect.perform (My_solutions.Emit 3)
      ) in
      check (list int) "items" [1; 2; 3] items);
    test_case "при Emit 10 и возврате 42 возвращает (42, [10])" `Quick (fun () ->
      let (result, items) = My_solutions.run_emit (fun () ->
        Effect.perform (My_solutions.Emit 10);
        42
      ) in
      check int "result" 42 result;
      check (list int) "items" [10] items);
    test_case "при отсутствии Emit возвращает пустой список" `Quick (fun () ->
      let ((), items) = My_solutions.run_emit (fun () -> ()) in
      check (list int) "empty" [] items);
  ]

let reader_tests =
  let open Alcotest in
  [
    test_case "при окружении \"hello\" возвращает \"HELLO\"" `Quick (fun () ->
      let result = My_solutions.run_reader "hello" (fun () ->
        let env = Effect.perform My_solutions.Ask in
        String.uppercase_ascii env
      ) in
      check string "result" "HELLO" result);
    test_case "при двух Ask с окружением \"world\" возвращает \"world world\"" `Quick (fun () ->
      let result = My_solutions.run_reader "world" (fun () ->
        let a = Effect.perform My_solutions.Ask in
        let b = Effect.perform My_solutions.Ask in
        a ^ " " ^ b
      ) in
      check string "result" "world world" result);
  ]

let count_and_emit_tests =
  let open Alcotest in
  [
    test_case "при n=3 и state=0 возвращает [1;3;6]" `Quick (fun () ->
      let ((), items) = My_solutions.run_emit (fun () ->
        run_state 0 (fun () ->
          My_solutions.count_and_emit 3
        )
      ) in
      check (list int) "items" [1; 3; 6] items);
    test_case "при n=0 возвращает пустой список" `Quick (fun () ->
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
    test_case "при нормальном завершении возвращает Ok 42" `Quick (fun () ->
      let r = My_solutions.run_fail (fun () -> 42) in
      check result_testable "ok" (Ok 42) r);
    test_case "при Fail \"oops\" возвращает Error \"oops\"" `Quick (fun () ->
      let r = My_solutions.run_fail (fun () ->
        Effect.perform (My_solutions.Fail "oops")
      ) in
      check result_testable "error" (Error "oops") r);
    test_case "при Fail в середине вычисления возвращает Error" `Quick (fun () ->
      let r = My_solutions.run_fail (fun () ->
        let x = 1 + 2 in
        if x > 0 then Effect.perform (My_solutions.Fail "positive");
        x
      ) in
      check result_testable "error" (Error "positive") r);
  ]

let () =
  Alcotest.run "Chapter 13"
    [
      ("state --- эффект State", state_tests);
      ("log --- эффект Log", log_tests);
      ("combined --- State + Log", combined_tests);
      ("emit --- эффект Emit", emit_tests);
      ("reader --- эффект Reader", reader_tests);
      ("count_and_emit --- State + Emit", count_and_emit_tests);
      ("fail --- эффект Fail", fail_tests);
    ]
