open Chapter17.Parser

(* --- Тесты библиотеки --- *)

let parser_tests =
  let open Alcotest in
  let parse p s = Angstrom.parse_string ~consume:All p s in
  [
    test_case "при '42' возвращает Int 42" `Quick (fun () ->
      check (result int string) "42" (Ok 42) (parse integer "42"));
    test_case "при '  7' с пробелами возвращает Int 7" `Quick (fun () ->
      check (result int string) "  7" (Ok 7) (parse integer "  7"));
    test_case "при строке в кавычках возвращает содержимое" `Quick (fun () ->
      check (result string string) "hello" (Ok "hello")
        (parse quoted_string "\"hello\""));
    test_case "при 'true' возвращает Bool true" `Quick (fun () ->
      check (result bool string) "true" (Ok true) (parse boolean "true"));
    test_case "при 'false' возвращает Bool false" `Quick (fun () ->
      check (result bool string) "false" (Ok false) (parse boolean "false"));
  ]

let json_tests =
  let open Alcotest in
  [
    test_case "при 'null' возвращает JNull" `Quick (fun () ->
      match parse_json "null" with
      | Ok JNull -> ()
      | _ -> fail "expected JNull");
    test_case "при '42' возвращает JInt 42" `Quick (fun () ->
      match parse_json "42" with
      | Ok (JInt 42) -> ()
      | _ -> fail "expected JInt 42");
    test_case "при строке в кавычках возвращает JString" `Quick (fun () ->
      match parse_json "\"hello\"" with
      | Ok (JString "hello") -> ()
      | _ -> fail "expected JString");
    test_case "при '[1, 2, 3]' возвращает JArray" `Quick (fun () ->
      match parse_json "[1, 2, 3]" with
      | Ok (JArray [JInt 1; JInt 2; JInt 3]) -> ()
      | _ -> fail "expected array");
    test_case "при объекте возвращает JObject" `Quick (fun () ->
      match parse_json "{\"a\": 1, \"b\": 2}" with
      | Ok (JObject [("a", JInt 1); ("b", JInt 2)]) -> ()
      | _ -> fail "expected object");
    test_case "при вложенной структуре возвращает JObject" `Quick (fun () ->
      match parse_json "{\"items\": [1, 2], \"ok\": true}" with
      | Ok (JObject _) -> ()
      | _ -> fail "expected nested object");
  ]

let gadt_tests =
  let open Alcotest in
  [
    test_case "при Int 5 возвращает 5" `Quick (fun () ->
      check int "5" 5 (eval (Int 5)));
    test_case "при Add (Int 3, Int 4) возвращает 7" `Quick (fun () ->
      check int "3+4" 7 (eval (Add (Int 3, Int 4))));
    test_case "при Mul (Int 3, Int 4) возвращает 12" `Quick (fun () ->
      check int "3*4" 12 (eval (Mul (Int 3, Int 4))));
    test_case "при Eq (Int 5, Int 5) возвращает true" `Quick (fun () ->
      check bool "5=5" true (eval (Eq (Int 5, Int 5))));
    test_case "при Eq (Int 3, Int 5) возвращает false" `Quick (fun () ->
      check bool "3=5" false (eval (Eq (Int 3, Int 5))));
    test_case "при If с true возвращает then-ветку" `Quick (fun () ->
      check int "if true then 1 else 2" 1
        (eval (If (Bool true, Int 1, Int 2))));
    test_case "при сложном выражении возвращает 42" `Quick (fun () ->
      let expr = If (Eq (Add (Int 2, Int 3), Int 5), Mul (Int 6, Int 7), Int 0) in
      check int "complex" 42 (eval expr));
    test_case "при Add (Int 3, Int 4) show_expr возвращает '(3 + 4)'" `Quick (fun () ->
      check string "show" "(3 + 4)" (show_expr (Add (Int 3, Int 4))));
  ]

(* --- Тесты упражнений --- *)

let int_list_tests =
  let open Alcotest in
  let parse s = Angstrom.parse_string ~consume:All My_solutions.int_list_parser s in
  [
    test_case "при '[1, 2, 3]' возвращает [1; 2; 3]" `Quick (fun () ->
      check (result (list int) string) "parsed" (Ok [1; 2; 3])
        (parse "[1, 2, 3]"));
    test_case "при '[]' возвращает пустой список" `Quick (fun () ->
      check (result (list int) string) "empty" (Ok [])
        (parse "[]"));
    test_case "при '[42]' возвращает [42]" `Quick (fun () ->
      check (result (list int) string) "single" (Ok [42])
        (parse "[42]"));
  ]

let key_value_tests =
  let open Alcotest in
  let parse s = Angstrom.parse_string ~consume:All My_solutions.key_value_parser s in
  [
    test_case "при 'host=localhost' возвращает пару (host, localhost)" `Quick (fun () ->
      check (result (pair string string) string) "kv" (Ok ("host", "localhost"))
        (parse "host=localhost"));
    test_case "при 'port=8080' возвращает пару (port, 8080)" `Quick (fun () ->
      check (result (pair string string) string) "kv" (Ok ("port", "8080"))
        (parse "port=8080"));
  ]

let extended_expr_tests =
  let open Alcotest in
  [
    test_case "при Int 5 возвращает 5" `Quick (fun () ->
      check int "5" 5 (My_solutions.eval_extended (My_solutions.Int 5)));
    test_case "при Add (Int 3, Int 4) возвращает 7" `Quick (fun () ->
      check int "3+4" 7
        (My_solutions.eval_extended (My_solutions.Add (My_solutions.Int 3, My_solutions.Int 4))));
    test_case "при Not (Bool true) возвращает false" `Quick (fun () ->
      check bool "not true" false
        (My_solutions.eval_extended (My_solutions.Not (My_solutions.Bool true))));
    test_case "при Gt (Int 5, Int 3) возвращает true" `Quick (fun () ->
      check bool "5>3" true
        (My_solutions.eval_extended (My_solutions.Gt (My_solutions.Int 5, My_solutions.Int 3))));
    test_case "при Gt (Int 3, Int 5) возвращает false" `Quick (fun () ->
      check bool "3>5" false
        (My_solutions.eval_extended (My_solutions.Gt (My_solutions.Int 3, My_solutions.Int 5))));
  ]

let arith_tests =
  let open Alcotest in
  let parse s = Angstrom.parse_string ~consume:All My_solutions.arith_parser s in
  [
    test_case "при '42' возвращает 42" `Quick (fun () ->
      check (result int string) "42" (Ok 42) (parse "42"));
    test_case "при '1 + 2' возвращает 3" `Quick (fun () ->
      check (result int string) "1+2" (Ok 3) (parse "1 + 2"));
    test_case "при '3 * 4' возвращает 12" `Quick (fun () ->
      check (result int string) "3*4" (Ok 12) (parse "3 * 4"));
    test_case "при '2 + 3 * 4' учитывает приоритет и возвращает 14" `Quick (fun () ->
      check (result int string) "2+3*4" (Ok 14) (parse "2 + 3 * 4"));
    test_case "при '(2 + 3) * 4' учитывает скобки и возвращает 20" `Quick (fun () ->
      check (result int string) "(2+3)*4" (Ok 20) (parse "(2 + 3) * 4"));
  ]

let matching_brackets_tests =
  let open Alcotest in
  [
    test_case "при пустой строке возвращает true" `Quick (fun () ->
      check bool "empty" true (My_solutions.matching_brackets ""));
    test_case "при простых скобках возвращает true" `Quick (fun () ->
      check bool "simple" true (My_solutions.matching_brackets "[]{}()"));
    test_case "при вложенных скобках возвращает true" `Quick (fun () ->
      check bool "nested" true (My_solutions.matching_brackets "{[()]}"));
    test_case "при неправильном порядке скобок возвращает false" `Quick (fun () ->
      check bool "wrong" false (My_solutions.matching_brackets "{[}]"));
    test_case "при незакрытой скобке возвращает false" `Quick (fun () ->
      check bool "unclosed" false (My_solutions.matching_brackets "["));
    test_case "при строке с текстом и скобками возвращает true" `Quick (fun () ->
      check bool "with text" true
        (My_solutions.matching_brackets "let f (x) = { g [x] }"));
  ]

let word_count_tests =
  let open Alcotest in
  let pair = Alcotest.(pair string int) in
  [
    test_case "при простом тексте возвращает подсчёт слов" `Quick (fun () ->
      let result = My_solutions.word_count "one fish two fish red fish blue fish"
        |> List.sort (fun (a, _) (b, _) -> String.compare a b) in
      check (list pair) "words"
        [("blue", 1); ("fish", 4); ("one", 1); ("red", 1); ("two", 1)]
        result);
    test_case "при тексте с пунктуацией возвращает корректные слова" `Quick (fun () ->
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
