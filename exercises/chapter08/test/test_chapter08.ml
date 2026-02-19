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
    test_case "при непустой строке возвращает Ok" `Quick (fun () ->
      check (result unit string) "result"
        (Ok ()) (non_empty "Поле" "hello"));
    test_case "при пустой строке возвращает Error" `Quick (fun () ->
      check (result unit string) "result"
        (Error "Поле не может быть пустым") (non_empty "Поле" ""));
    test_case "при строке из пробелов возвращает Error" `Quick (fun () ->
      check (result unit string) "result"
        (Error "Поле не может быть пустым") (non_empty "Поле" "   "));
  ]

let validate_all_tests =
  let open Alcotest in
  [
    test_case "при прохождении всех проверок возвращает Ok" `Quick (fun () ->
      check (result string string_list) "result"
        (Ok "hello")
        (validate_all [non_empty "F"] "hello"));
    test_case "при нескольких нарушениях накапливает ошибки" `Quick (fun () ->
      check (result string string_list) "result"
        (Error ["Поле не может быть пустым";
                "Поле должен быть не короче 3 символов"])
        (validate_all [non_empty "Поле"; min_length "Поле" 3] ""));
  ]

let validate_address_tests =
  let open Alcotest in
  [
    test_case "при валидных полях возвращает Ok с адресом" `Quick (fun () ->
      check (result address_testable string_list) "result"
        (Ok { street = "ул. Пушкина"; city = "Москва"; state = "Москва" })
        (validate_address "ул. Пушкина" "Москва" "Москва"));
    test_case "при трёх пустых полях возвращает 3 ошибки" `Quick (fun () ->
      match validate_address "" "" "" with
      | Error es -> check int "result" 3 (List.length es)
      | Ok _ -> fail "ожидалась ошибка");
  ]

let conversion_tests =
  let open Alcotest in
  [
    test_case "при Some 42 возвращает Ok 42" `Quick (fun () ->
      check (result int string) "result"
        (Ok 42) (option_to_result ~error:"err" (Some 42)));
    test_case "при None возвращает Error" `Quick (fun () ->
      check (result int string) "result"
        (Error "err") (option_to_result ~error:"err" None));
    test_case "при Ok 42 возвращает Some 42" `Quick (fun () ->
      check (option int) "result"
        (Some 42) (result_to_option (Ok 42)));
    test_case "при Error возвращает None" `Quick (fun () ->
      check (option int) "result"
        None (result_to_option (Error "err")));
  ]

(* --- Тесты упражнений --- *)

let validate_phone_tests =
  let open Alcotest in
  [
    test_case "при \"1234567\" возвращает Ok" `Quick (fun () ->
      check (result_string_errors string) "result"
        (Ok "1234567")
        (My_solutions.validate_phone "1234567"));
    test_case "при пустой строке возвращает Error" `Quick (fun () ->
      match My_solutions.validate_phone "" with
      | Error es ->
        check bool "result" true (List.length es > 0)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "при \"123abc\" возвращает Error о нецифровых символах" `Quick (fun () ->
      match My_solutions.validate_phone "123abc" with
      | Error es ->
        check bool "result" true
          (List.exists (fun e -> String.length e > 0) es)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "при \"123\" возвращает Error о недостаточной длине" `Quick (fun () ->
      match My_solutions.validate_phone "123" with
      | Error es ->
        check bool "result" true (List.length es > 0)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "при пустой строке возвращает несколько ошибок" `Quick (fun () ->
      match My_solutions.validate_phone "" with
      | Error es ->
        check bool "result" true (List.length es >= 2)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
  ]

let validate_person_tests =
  let open Alcotest in
  [
    test_case "при валидных полях возвращает Ok с персоной" `Quick (fun () ->
      check (result_string_errors person_testable) "result"
        (Ok { first_name = "Иван"; last_name = "Петров";
              address = { street = "ул. Пушкина"; city = "Москва";
                          state = "Москва" } })
        (My_solutions.validate_person
           "Иван" "Петров" "ул. Пушкина" "Москва" "Москва"));
    test_case "при пяти пустых полях возвращает не менее 5 ошибок" `Quick (fun () ->
      match My_solutions.validate_person "" "" "" "" "" with
      | Error es ->
        check bool "result" true (List.length es >= 5)
      | Ok _ -> Alcotest.fail "ожидалась ошибка");
    test_case "при пустом имени возвращает не менее 1 ошибки" `Quick (fun () ->
      match My_solutions.validate_person "" "Петров" "ул. Пушкина" "Москва" "Москва" with
      | Error es ->
        check bool "result" true (List.length es >= 1)
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
    test_case "при [\"1\";\"2\";\"3\"] возвращает Ok [1;2;3]" `Quick (fun () ->
      check (result (list int) (list string)) "result"
        (Ok [1; 2; 3])
        (My_solutions.traverse_result parse ["1"; "2"; "3"]));
    test_case "при [\"a\";\"2\";\"c\"] возвращает ошибки для нечисел" `Quick (fun () ->
      check (result (list int) (list string)) "result"
        (Error ["не число: a"; "не число: c"])
        (My_solutions.traverse_result parse ["a"; "2"; "c"]));
    test_case "при пустом списке возвращает Ok []" `Quick (fun () ->
      check (result (list int) (list string)) "result"
        (Ok [])
        (My_solutions.traverse_result parse []));
  ]

let option_result_tests =
  let open Alcotest in
  [
    test_case "при Some 42 возвращает Ok 42" `Quick (fun () ->
      check (result int string) "result"
        (Ok 42)
        (My_solutions.option_to_result ~error:"err" (Some 42)));
    test_case "при None возвращает Error" `Quick (fun () ->
      check (result int string) "result"
        (Error "err")
        (My_solutions.option_to_result ~error:"err" None));
    test_case "при Ok 42 возвращает Some 42" `Quick (fun () ->
      check (option int) "result"
        (Some 42)
        (My_solutions.result_to_option (Ok 42)));
    test_case "при Error возвращает None" `Quick (fun () ->
      check (option int) "result"
        None
        (My_solutions.result_to_option (Error "err")));
  ]

let isbn_tests =
  let open Alcotest in
  [
    test_case "при \"3-598-21508-8\" возвращает true" `Quick (fun () ->
      check bool "result" true
        (My_solutions.isbn_verifier "3-598-21508-8"));
    test_case "при \"3-598-21508-9\" возвращает false" `Quick (fun () ->
      check bool "result" false
        (My_solutions.isbn_verifier "3-598-21508-9"));
    test_case "при ISBN с X на последней позиции возвращает true" `Quick (fun () ->
      check bool "result" true
        (My_solutions.isbn_verifier "3-598-21507-X"));
  ]

let luhn_tests =
  let open Alcotest in
  [
    test_case "при \"4539 3195 0343 6467\" возвращает true" `Quick (fun () ->
      check bool "result" true (My_solutions.luhn "4539 3195 0343 6467"));
    test_case "при \"8273 1232 7352 0569\" возвращает false" `Quick (fun () ->
      check bool "result" false (My_solutions.luhn "8273 1232 7352 0569"));
    test_case "при одной цифре \"0\" возвращает false" `Quick (fun () ->
      check bool "result" false (My_solutions.luhn "0"));
    test_case "при \"0 0 0\" возвращает true" `Quick (fun () ->
      check bool "result" true (My_solutions.luhn "0 0 0"));
  ]

let composable_error_tests =
  let open Alcotest in
  let open Chapter08.Validation in
  [
    test_case "при \"hello\" возвращает Ok" `Quick (fun () ->
      match process_input "hello" with
      | Ok _ -> ()
      | Error _ -> fail "ожидался Ok");
    test_case "при пустой строке возвращает SyntaxError" `Quick (fun () ->
      match process_input "" with
      | Error (`SyntaxError _) -> ()
      | _ -> fail "ожидалась SyntaxError");
    test_case "при \"x\" возвращает TooShort" `Quick (fun () ->
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
