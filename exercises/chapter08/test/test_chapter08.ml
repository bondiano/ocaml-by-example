open Chapter08.Validation

(* --- Пользовательские testable для Alcotest --- *)

let address_testable : address Alcotest.testable =
  Alcotest.testable
    (fun fmt a ->
      Format.fprintf fmt "{street=%s; city=%s; state=%s}"
        a.street a.city a.state)
    ( = )

let person_testable : person Alcotest.testable =
  Alcotest.testable
    (fun fmt p ->
      Format.fprintf fmt "{first=%s; last=%s; addr={%s, %s, %s}}"
        p.first_name p.last_name
        p.address.street p.address.city p.address.state)
    ( = )

let string_list = Alcotest.(list string)

let result_string_errors (type a) (ok_t : a Alcotest.testable) =
  Alcotest.(result ok_t (list string))

(* --- Тесты библиотеки --- *)

let non_empty_tests =
  let open Alcotest in
  [
    test_case "непустая строка --- Ok" `Quick (fun () ->
      check (result unit string) "ok"
        (Ok ()) (non_empty "Поле" "hello"));
    test_case "пустая строка --- Error" `Quick (fun () ->
      check (result unit string) "error"
        (Error "Поле не может быть пустым") (non_empty "Поле" ""));
    test_case "пробелы --- Error" `Quick (fun () ->
      check (result unit string) "spaces"
        (Error "Поле не может быть пустым") (non_empty "Поле" "   "));
  ]

let validate_all_tests =
  let open Alcotest in
  [
    test_case "все проверки проходят" `Quick (fun () ->
      check (result string string_list) "ok"
        (Ok "hello")
        (validate_all [non_empty "F"] "hello"));
    test_case "накопление ошибок" `Quick (fun () ->
      check (result string string_list) "errors"
        (Error ["Поле не может быть пустым";
                "Поле должен быть не короче 3 символов"])
        (validate_all [non_empty "Поле"; min_length "Поле" 3] ""));
  ]

let validate_address_tests =
  let open Alcotest in
  [
    test_case "валидный адрес" `Quick (fun () ->
      check (result address_testable string_list) "ok"
        (Ok { street = "ул. Пушкина"; city = "Москва"; state = "Москва" })
        (validate_address "ул. Пушкина" "Москва" "Москва"));
    test_case "все поля пустые" `Quick (fun () ->
      match validate_address "" "" "" with
      | Error es -> check int "3 ошибки" 3 (List.length es)
      | Ok _ -> fail "ожидалась ошибка");
  ]

let conversion_tests =
  let open Alcotest in
  [
    test_case "option_to_result Some" `Quick (fun () ->
      check (result int string) "some"
        (Ok 42) (option_to_result ~error:"err" (Some 42)));
    test_case "option_to_result None" `Quick (fun () ->
      check (result int string) "none"
        (Error "err") (option_to_result ~error:"err" None));
    test_case "result_to_option Ok" `Quick (fun () ->
      check (option int) "ok"
        (Some 42) (result_to_option (Ok 42)));
    test_case "result_to_option Error" `Quick (fun () ->
      check (option int) "error"
        None (result_to_option (Error "err")));
  ]

(* --- Тесты упражнений --- *)

let validate_phone_tests =
  let open Alcotest in
  [
    test_case "валидный телефон" `Quick (fun () ->
      check (result_string_errors string) "ok"
        (Ok "1234567")
        (My_solutions.validate_phone "1234567"));
    test_case "пустой телефон" `Quick (fun () ->
      match My_solutions.validate_phone "" with
      | Error es ->
        check bool "есть ошибки" true (List.length es > 0)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "буквы в телефоне" `Quick (fun () ->
      match My_solutions.validate_phone "123abc" with
      | Error es ->
        check bool "есть ошибка о цифрах" true
          (List.exists (fun e -> String.length e > 0) es)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "слишком короткий телефон" `Quick (fun () ->
      match My_solutions.validate_phone "123" with
      | Error es ->
        check bool "есть ошибка о длине" true (List.length es > 0)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "все ошибки сразу" `Quick (fun () ->
      match My_solutions.validate_phone "" with
      | Error es ->
        check bool "множественные ошибки" true (List.length es >= 2)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let validate_person_tests =
  let open Alcotest in
  [
    test_case "валидная персона" `Quick (fun () ->
      check (result_string_errors person_testable) "ok"
        (Ok { first_name = "Иван"; last_name = "Петров";
              address = { street = "ул. Пушкина"; city = "Москва";
                          state = "Москва" } })
        (My_solutions.validate_person
           "Иван" "Петров" "ул. Пушкина" "Москва" "Москва"));
    test_case "все поля пустые" `Quick (fun () ->
      match My_solutions.validate_person "" "" "" "" "" with
      | Error es ->
        check bool "5 ошибок" true (List.length es >= 5)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "пустое имя" `Quick (fun () ->
      match My_solutions.validate_person "" "Петров" "ул. Пушкина" "Москва" "Москва" with
      | Error es ->
        check bool "1 ошибка" true (List.length es >= 1)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let traverse_result_tests =
  let open Alcotest in
  let parse x =
    match int_of_string_opt x with
    | Some n -> Ok n
    | None -> Error ("не число: " ^ x)
  in
  [
    test_case "все Ok" `Quick (fun () ->
      check (result (list int) (list string)) "all ok"
        (Ok [1; 2; 3])
        (My_solutions.traverse_result parse ["1"; "2"; "3"]));
    test_case "есть ошибки" `Quick (fun () ->
      check (result (list int) (list string)) "errors"
        (Error ["не число: a"; "не число: c"])
        (My_solutions.traverse_result parse ["a"; "2"; "c"]));
    test_case "пустой список" `Quick (fun () ->
      check (result (list int) (list string)) "empty"
        (Ok [])
        (My_solutions.traverse_result parse []));
  ]

let option_result_tests =
  let open Alcotest in
  [
    test_case "option_to_result Some" `Quick (fun () ->
      check (result int string) "some"
        (Ok 42)
        (My_solutions.option_to_result ~error:"err" (Some 42)));
    test_case "option_to_result None" `Quick (fun () ->
      check (result int string) "none"
        (Error "err")
        (My_solutions.option_to_result ~error:"err" None));
    test_case "result_to_option Ok" `Quick (fun () ->
      check (option int) "ok"
        (Some 42)
        (My_solutions.result_to_option (Ok 42)));
    test_case "result_to_option Error" `Quick (fun () ->
      check (option int) "error"
        None
        (My_solutions.result_to_option (Error "err")));
  ]

let isbn_tests =
  let open Alcotest in
  [
    test_case "валидный ISBN" `Quick (fun () ->
      check bool "valid" true
        (My_solutions.isbn_verifier "3-598-21508-8"));
    test_case "невалидный ISBN" `Quick (fun () ->
      check bool "invalid" false
        (My_solutions.isbn_verifier "3-598-21508-9"));
    test_case "ISBN с X" `Quick (fun () ->
      check bool "with X" true
        (My_solutions.isbn_verifier "3-598-21507-X"));
  ]

let luhn_tests =
  let open Alcotest in
  [
    test_case "валидный номер" `Quick (fun () ->
      check bool "valid" true (My_solutions.luhn "4539 3195 0343 6467"));
    test_case "невалидный номер" `Quick (fun () ->
      check bool "invalid" false (My_solutions.luhn "8273 1232 7352 0569"));
    test_case "одна цифра" `Quick (fun () ->
      check bool "single" false (My_solutions.luhn "0"));
    test_case "с пробелами" `Quick (fun () ->
      check bool "spaces" true (My_solutions.luhn "0 0 0"));
  ]

let composable_error_tests =
  let open Alcotest in
  let open Chapter08.Validation in
  [
    test_case "parse и validate — Ok" `Quick (fun () ->
      match process_input "hello" with
      | Ok _ -> ()
      | Error _ -> fail "ожидался Ok");
    test_case "parse error — syntax" `Quick (fun () ->
      match process_input "" with
      | Error (`SyntaxError _) -> ()
      | _ -> fail "ожидалась SyntaxError");
    test_case "validate error — too short" `Quick (fun () ->
      match process_input "x" with
      | Error (`TooShort _) -> ()
      | _ -> fail "ожидалась TooShort");
  ]

let () =
  Alcotest.run "Chapter 07"
    [
      ("non_empty --- проверка непустоты", non_empty_tests);
      ("validate_all --- накопление ошибок", validate_all_tests);
      ("validate_address --- валидация адреса", validate_address_tests);
      ("конвертация option/result", conversion_tests);
      ("validate_phone --- валидация телефона", validate_phone_tests);
      ("validate_person --- валидация персоны", validate_person_tests);
      ("traverse_result --- траверс", traverse_result_tests);
      ("option_to_result / result_to_option", option_result_tests);
      ("ISBN Verifier", isbn_tests);
      ("Luhn — алгоритм Луна", luhn_tests);
      ("composable errors — полиморфные варианты", composable_error_tests);
    ]
