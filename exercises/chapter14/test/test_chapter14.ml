open Chapter14.Parser

(* --- Тесты библиотеки --- *)

let parser_tests =
  let open Alcotest in
  let parse p s = Angstrom.parse_string ~consume:All p s in
  [
    test_case "integer" `Quick (fun () ->
      check (result int string) "42" (Ok 42) (parse integer "42"));
    test_case "integer ws" `Quick (fun () ->
      check (result int string) "  7" (Ok 7) (parse integer "  7"));
    test_case "quoted_string" `Quick (fun () ->
      check (result string string) "hello" (Ok "hello")
        (parse quoted_string "\"hello\""));
    test_case "boolean true" `Quick (fun () ->
      check (result bool string) "true" (Ok true) (parse boolean "true"));
    test_case "boolean false" `Quick (fun () ->
      check (result bool string) "false" (Ok false) (parse boolean "false"));
  ]

let json_tests =
  let open Alcotest in
  [
    test_case "parse null" `Quick (fun () ->
      match parse_json "null" with
      | Ok JNull -> ()
      | _ -> fail "expected JNull");
    test_case "parse int" `Quick (fun () ->
      match parse_json "42" with
      | Ok (JInt 42) -> ()
      | _ -> fail "expected JInt 42");
    test_case "parse string" `Quick (fun () ->
      match parse_json "\"hello\"" with
      | Ok (JString "hello") -> ()
      | _ -> fail "expected JString");
    test_case "parse array" `Quick (fun () ->
      match parse_json "[1, 2, 3]" with
      | Ok (JArray [JInt 1; JInt 2; JInt 3]) -> ()
      | _ -> fail "expected array");
    test_case "parse object" `Quick (fun () ->
      match parse_json "{\"a\": 1, \"b\": 2}" with
      | Ok (JObject [("a", JInt 1); ("b", JInt 2)]) -> ()
      | _ -> fail "expected object");
    test_case "parse nested" `Quick (fun () ->
      match parse_json "{\"items\": [1, 2], \"ok\": true}" with
      | Ok (JObject _) -> ()
      | _ -> fail "expected nested object");
  ]

let gadt_tests =
  let open Alcotest in
  [
    test_case "eval Int" `Quick (fun () ->
      check int "5" 5 (eval (Int 5)));
    test_case "eval Add" `Quick (fun () ->
      check int "3+4" 7 (eval (Add (Int 3, Int 4))));
    test_case "eval Mul" `Quick (fun () ->
      check int "3*4" 12 (eval (Mul (Int 3, Int 4))));
    test_case "eval Eq true" `Quick (fun () ->
      check bool "5=5" true (eval (Eq (Int 5, Int 5))));
    test_case "eval Eq false" `Quick (fun () ->
      check bool "3=5" false (eval (Eq (Int 3, Int 5))));
    test_case "eval If" `Quick (fun () ->
      check int "if true then 1 else 2" 1
        (eval (If (Bool true, Int 1, Int 2))));
    test_case "eval complex" `Quick (fun () ->
      let expr = If (Eq (Add (Int 2, Int 3), Int 5), Mul (Int 6, Int 7), Int 0) in
      check int "complex" 42 (eval expr));
    test_case "show_expr" `Quick (fun () ->
      check string "show" "(3 + 4)" (show_expr (Add (Int 3, Int 4))));
  ]

(* --- Тесты упражнений --- *)

let int_list_tests =
  let open Alcotest in
  let parse s = Angstrom.parse_string ~consume:All My_solutions.int_list_parser s in
  [
    test_case "int_list [1,2,3]" `Quick (fun () ->
      check (result (list int) string) "parsed" (Ok [1; 2; 3])
        (parse "[1, 2, 3]"));
    test_case "int_list empty" `Quick (fun () ->
      check (result (list int) string) "empty" (Ok [])
        (parse "[]"));
    test_case "int_list single" `Quick (fun () ->
      check (result (list int) string) "single" (Ok [42])
        (parse "[42]"));
  ]

let key_value_tests =
  let open Alcotest in
  let parse s = Angstrom.parse_string ~consume:All My_solutions.key_value_parser s in
  [
    test_case "key=value" `Quick (fun () ->
      check (result (pair string string) string) "kv" (Ok ("host", "localhost"))
        (parse "host=localhost"));
    test_case "key=123" `Quick (fun () ->
      check (result (pair string string) string) "kv" (Ok ("port", "8080"))
        (parse "port=8080"));
  ]

let extended_expr_tests =
  let open Alcotest in
  [
    test_case "eval_extended Int" `Quick (fun () ->
      check int "5" 5 (My_solutions.eval_extended (My_solutions.Int 5)));
    test_case "eval_extended Add" `Quick (fun () ->
      check int "3+4" 7
        (My_solutions.eval_extended (My_solutions.Add (My_solutions.Int 3, My_solutions.Int 4))));
    test_case "eval_extended Not" `Quick (fun () ->
      check bool "not true" false
        (My_solutions.eval_extended (My_solutions.Not (My_solutions.Bool true))));
    test_case "eval_extended Gt" `Quick (fun () ->
      check bool "5>3" true
        (My_solutions.eval_extended (My_solutions.Gt (My_solutions.Int 5, My_solutions.Int 3))));
    test_case "eval_extended Gt false" `Quick (fun () ->
      check bool "3>5" false
        (My_solutions.eval_extended (My_solutions.Gt (My_solutions.Int 3, My_solutions.Int 5))));
  ]

let arith_tests =
  let open Alcotest in
  let parse s = Angstrom.parse_string ~consume:All My_solutions.arith_parser s in
  [
    test_case "arith simple" `Quick (fun () ->
      check (result int string) "42" (Ok 42) (parse "42"));
    test_case "arith add" `Quick (fun () ->
      check (result int string) "1+2" (Ok 3) (parse "1 + 2"));
    test_case "arith mul" `Quick (fun () ->
      check (result int string) "3*4" (Ok 12) (parse "3 * 4"));
    test_case "arith precedence" `Quick (fun () ->
      check (result int string) "2+3*4" (Ok 14) (parse "2 + 3 * 4"));
    test_case "arith parens" `Quick (fun () ->
      check (result int string) "(2+3)*4" (Ok 20) (parse "(2 + 3) * 4"));
  ]

let matching_brackets_tests =
  let open Alcotest in
  [
    test_case "пустая строка" `Quick (fun () ->
      check bool "empty" true (My_solutions.matching_brackets ""));
    test_case "простые скобки" `Quick (fun () ->
      check bool "simple" true (My_solutions.matching_brackets "[]{}()"));
    test_case "вложенные" `Quick (fun () ->
      check bool "nested" true (My_solutions.matching_brackets "{[()]}"));
    test_case "неправильный порядок" `Quick (fun () ->
      check bool "wrong" false (My_solutions.matching_brackets "{[}]"));
    test_case "незакрытые" `Quick (fun () ->
      check bool "unclosed" false (My_solutions.matching_brackets "["));
    test_case "с текстом" `Quick (fun () ->
      check bool "with text" true
        (My_solutions.matching_brackets "let f (x) = { g [x] }"));
  ]

let word_count_tests =
  let open Alcotest in
  let pair = Alcotest.(pair string int) in
  [
    test_case "простой подсчёт" `Quick (fun () ->
      let result = My_solutions.word_count "one fish two fish red fish blue fish"
        |> List.sort (fun (a, _) (b, _) -> String.compare a b) in
      check (list pair) "words"
        [("blue", 1); ("fish", 4); ("one", 1); ("red", 1); ("two", 1)]
        result);
    test_case "с пунктуацией" `Quick (fun () ->
      let result = My_solutions.word_count "car : carpet as java : javascript!!&@$%^&"
        |> List.sort (fun (a, _) (b, _) -> String.compare a b) in
      check bool "has car" true
        (List.exists (fun (w, _) -> w = "car") result));
  ]

let () =
  Alcotest.run "Chapter 14"
    [
      ("parsers --- базовые парсеры", parser_tests);
      ("json --- JSON парсер", json_tests);
      ("gadt --- типобезопасные выражения", gadt_tests);
      ("int_list --- список целых чисел", int_list_tests);
      ("key_value --- ключ-значение", key_value_tests);
      ("extended_expr --- расширенный GADT", extended_expr_tests);
      ("arith --- арифметические выражения", arith_tests);
      ("Matching Brackets — скобки", matching_brackets_tests);
      ("Word Count — подсчёт слов", word_count_tests);
    ]
