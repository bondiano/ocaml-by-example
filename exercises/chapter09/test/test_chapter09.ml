open Chapter09.Payment

(* --- Вспомогательные testable для Alcotest --- *)

let result_string (type a) (ok_t : a Alcotest.testable) =
  Alcotest.(result ok_t string)

(* --- Тесты библиотеки: Money --- *)

let money_tests =
  let open Alcotest in
  [
    test_case "Money.make положительная сумма" `Quick (fun () ->
      match Money.make 100.0 with
      | Ok m -> check string "amount" "100.00" (Money.to_string m)
      | Error _ -> fail "ожидался Ok");
    test_case "Money.make нулевая сумма" `Quick (fun () ->
      check (result_string string) "zero"
        (Error "сумма должна быть положительной")
        (Money.make 0.0 |> Result.map Money.to_string));
    test_case "Money.make отрицательная сумма" `Quick (fun () ->
      check (result_string string) "negative"
        (Error "сумма должна быть положительной")
        (Money.make (-5.0) |> Result.map Money.to_string));
    test_case "Money.add" `Quick (fun () ->
      match Money.make 100.0, Money.make 50.0 with
      | Ok a, Ok b ->
        check string "sum" "150.00" (Money.to_string (Money.add a b))
      | _ -> fail "ожидались Ok");
  ]

(* --- Тесты библиотеки: CardNumber --- *)

let card_number_tests =
  let open Alcotest in
  [
    test_case "CardNumber.make валидный номер" `Quick (fun () ->
      match CardNumber.make "4111111111111111" with
      | Ok _ -> ()
      | Error e -> fail e);
    test_case "CardNumber.make с пробелами" `Quick (fun () ->
      match CardNumber.make "4111 1111 1111 1111" with
      | Ok _ -> ()
      | Error e -> fail e);
    test_case "CardNumber.make с дефисами" `Quick (fun () ->
      match CardNumber.make "4111-1111-1111-1111" with
      | Ok _ -> ()
      | Error e -> fail e);
    test_case "CardNumber.make слишком короткий" `Quick (fun () ->
      match CardNumber.make "1234" with
      | Error _ -> ()
      | Ok _ -> fail "ожидалась ошибка");
    test_case "CardNumber.make с буквами" `Quick (fun () ->
      match CardNumber.make "4111ABCD11111111" with
      | Error _ -> ()
      | Ok _ -> fail "ожидалась ошибка");
    test_case "CardNumber.to_masked" `Quick (fun () ->
      match CardNumber.make "4111111111111111" with
      | Ok card ->
        check string "masked" "************1111" (CardNumber.to_masked card)
      | Error e -> fail e);
  ]

(* --- Тесты библиотеки: PaymentState --- *)

let payment_state_tests =
  let open Alcotest in
  [
    test_case "полный цикл платежа" `Quick (fun () ->
      match Money.make 99.99, CardNumber.make "4111111111111111" with
      | Ok amount, Ok card ->
        let p = PaymentState.create ~amount "Книга" in
        check string "draft" "draft" (PaymentState.state_name p);
        let p = PaymentState.submit p ~card in
        check string "submitted" "submitted" (PaymentState.state_name p);
        let p = PaymentState.pay p ~transaction_id:"TXN-001" in
        check string "paid" "paid" (PaymentState.state_name p);
        let p = PaymentState.ship p ~tracking:"TRACK-42" in
        check string "shipped" "shipped" (PaymentState.state_name p);
        check string "description" "Книга" (PaymentState.description p);
        check string "amount" "99.99"
          (Money.to_string (PaymentState.amount p))
      | _ -> fail "ожидались Ok");
  ]

(* --- Тесты упражнений --- *)

(* Упражнение 1: PositiveInt *)

let positive_int_tests =
  let open Alcotest in
  [
    test_case "PositiveInt.make положительное" `Quick (fun () ->
      match My_solutions.PositiveInt.make 42 with
      | Ok n -> check int "value" 42 (My_solutions.PositiveInt.value n)
      | Error _ -> fail "ожидался Ok");
    test_case "PositiveInt.make ноль" `Quick (fun () ->
      check (result_string int) "zero"
        (Error "число должно быть положительным")
        (My_solutions.PositiveInt.make 0
         |> Result.map My_solutions.PositiveInt.value));
    test_case "PositiveInt.make отрицательное" `Quick (fun () ->
      check (result_string int) "negative"
        (Error "число должно быть положительным")
        (My_solutions.PositiveInt.make (-5)
         |> Result.map My_solutions.PositiveInt.value));
    test_case "PositiveInt.add" `Quick (fun () ->
      match My_solutions.PositiveInt.make 10, My_solutions.PositiveInt.make 20 with
      | Ok a, Ok b ->
        check int "sum" 30
          (My_solutions.PositiveInt.value (My_solutions.PositiveInt.add a b))
      | _ -> fail "ожидались Ok");
    test_case "PositiveInt.to_string" `Quick (fun () ->
      match My_solutions.PositiveInt.make 42 with
      | Ok n -> check string "str" "42" (My_solutions.PositiveInt.to_string n)
      | Error _ -> fail "ожидался Ok");
  ]

(* Упражнение 2: Email *)

let email_tests =
  let open Alcotest in
  [
    test_case "Email.make валидный" `Quick (fun () ->
      match My_solutions.Email.make "user@example.com" with
      | Ok e ->
        check string "email" "user@example.com" (My_solutions.Email.to_string e)
      | Error e -> fail e);
    test_case "Email.make пустой" `Quick (fun () ->
      check (result_string string) "empty"
        (Error "email не может быть пустым")
        (My_solutions.Email.make ""
         |> Result.map My_solutions.Email.to_string));
    test_case "Email.make без @" `Quick (fun () ->
      check (result_string string) "no at"
        (Error "email должен содержать @")
        (My_solutions.Email.make "user"
         |> Result.map My_solutions.Email.to_string));
    test_case "Email.make без точки в домене" `Quick (fun () ->
      check (result_string string) "no dot"
        (Error "некорректный домен")
        (My_solutions.Email.make "user@host"
         |> Result.map My_solutions.Email.to_string));
  ]

(* Упражнение 3: NonEmptyList *)

let non_empty_list_tests =
  let open Alcotest in
  [
    test_case "NonEmptyList.make непустой" `Quick (fun () ->
      match My_solutions.NonEmptyList.make [1; 2; 3] with
      | Ok nel ->
        check int "head" 1 (My_solutions.NonEmptyList.head nel);
        check (list int) "tail" [2; 3] (My_solutions.NonEmptyList.tail nel);
        check (list int) "to_list" [1; 2; 3]
          (My_solutions.NonEmptyList.to_list nel);
        check int "length" 3 (My_solutions.NonEmptyList.length nel)
      | Error _ -> fail "ожидался Ok");
    test_case "NonEmptyList.make пустой" `Quick (fun () ->
      match My_solutions.NonEmptyList.make ([] : int list) with
      | Error _ -> ()
      | Ok _ -> fail "ожидалась ошибка");
    test_case "NonEmptyList.singleton" `Quick (fun () ->
      let nel = My_solutions.NonEmptyList.singleton 42 in
      check int "head" 42 (My_solutions.NonEmptyList.head nel);
      check (list int) "tail" [] (My_solutions.NonEmptyList.tail nel);
      check int "length" 1 (My_solutions.NonEmptyList.length nel));
    test_case "NonEmptyList.map" `Quick (fun () ->
      match My_solutions.NonEmptyList.make [1; 2; 3] with
      | Ok nel ->
        let doubled = My_solutions.NonEmptyList.map (fun x -> x * 2) nel in
        check (list int) "mapped" [2; 4; 6]
          (My_solutions.NonEmptyList.to_list doubled)
      | Error _ -> fail "ожидался Ok");
  ]

(* Упражнение 4: TrafficLight *)

let traffic_light_tests =
  let open Alcotest in
  [
    test_case "начальное состояние --- красный" `Quick (fun () ->
      check string "red"
        "red" (My_solutions.TrafficLight.show My_solutions.TrafficLight.start));
    test_case "полный цикл" `Quick (fun () ->
      let open My_solutions.TrafficLight in
      let l = start in
      check string "red" "red" (show l);
      let l = red_to_green l in
      check string "green" "green" (show l);
      let l = green_to_yellow l in
      check string "yellow" "yellow" (show l);
      let l = yellow_to_red l in
      check string "red again" "red" (show l));
  ]

(* Упражнение 5: Form *)

let form_tests =
  let open Alcotest in
  let parse_name s =
    if String.length s > 0 then Ok s
    else Error "не может быть пустым"
  in
  let parse_age s =
    match int_of_string_opt s with
    | Some n when n > 0 -> Ok n
    | _ -> Error "должен быть положительным числом"
  in
  [
    test_case "Form --- все поля валидны" `Quick (fun () ->
      let open My_solutions.Form in
      match run (map2
        (fun name age -> (name, age))
        (field "имя" "Иван" parse_name)
        (field "возраст" "25" parse_age))
      with
      | Ok (name, age) ->
        check string "name" "Иван" name;
        check int "age" 25 age
      | Error _ -> fail "ожидался Ok");
    test_case "Form --- одно поле невалидно" `Quick (fun () ->
      let open My_solutions.Form in
      match run (map2
        (fun name age -> (name, age))
        (field "имя" "" parse_name)
        (field "возраст" "25" parse_age))
      with
      | Error errors ->
        check int "одна ошибка" 1 (List.length errors);
        check string "имя поля" "имя" (fst (List.hd errors))
      | Ok _ -> fail "ожидалась ошибка");
    test_case "Form --- оба поля невалидны" `Quick (fun () ->
      let open My_solutions.Form in
      match run (map2
        (fun name age -> (name, age))
        (field "имя" "" parse_name)
        (field "возраст" "abc" parse_age))
      with
      | Error errors ->
        check int "две ошибки" 2 (List.length errors)
      | Ok _ -> fail "ожидалась ошибка");
    test_case "Form.map3 --- все валидны" `Quick (fun () ->
      let open My_solutions.Form in
      match run (map3
        (fun a b c -> (a, b, c))
        (field "a" "hello" parse_name)
        (field "b" "world" parse_name)
        (field "c" "10" parse_age))
      with
      | Ok ("hello", "world", 10) -> ()
      | Ok _ -> fail "неожиданные значения"
      | Error _ -> fail "ожидался Ok");
    test_case "Form.map3 --- все невалидны" `Quick (fun () ->
      let open My_solutions.Form in
      match run (map3
        (fun a b c -> (a, b, c))
        (field "a" "" parse_name)
        (field "b" "" parse_name)
        (field "c" "abc" parse_age))
      with
      | Error errors ->
        check int "три ошибки" 3 (List.length errors)
      | Ok _ -> fail "ожидалась ошибка");
  ]

(* Упражнение 6: FileHandle *)

let file_handle_tests =
  let open Alcotest in
  [
    test_case "FileHandle --- открытие и чтение" `Quick (fun () ->
      let h = My_solutions.FileHandle.open_file "test.txt" in
      check string "name" "test.txt" (My_solutions.FileHandle.name h);
      check string "empty content" "" (My_solutions.FileHandle.read h));
    test_case "FileHandle --- запись и чтение" `Quick (fun () ->
      let h = My_solutions.FileHandle.open_file "test.txt" in
      let h = My_solutions.FileHandle.write h "hello " in
      let h = My_solutions.FileHandle.write h "world" in
      check string "content" "hello world" (My_solutions.FileHandle.read h));
    test_case "FileHandle --- close сохраняет имя" `Quick (fun () ->
      let h = My_solutions.FileHandle.open_file "test.txt" in
      let h = My_solutions.FileHandle.write h "data" in
      let closed = My_solutions.FileHandle.close h in
      check string "name" "test.txt" (My_solutions.FileHandle.name closed));
  ]

let () =
  Alcotest.run "Chapter 09"
    [
      ("Money --- умный конструктор", money_tests);
      ("CardNumber --- умный конструктор", card_number_tests);
      ("PaymentState --- конечный автомат", payment_state_tests);
      ("PositiveInt --- упражнение 1", positive_int_tests);
      ("Email --- упражнение 2", email_tests);
      ("NonEmptyList --- упражнение 3", non_empty_list_tests);
      ("TrafficLight --- упражнение 4", traffic_light_tests);
      ("Form --- упражнение 5", form_tests);
      ("FileHandle --- упражнение 6", file_handle_tests);
    ]
