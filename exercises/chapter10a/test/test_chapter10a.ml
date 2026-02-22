open Chapter10a.Payment

(* --- Вспомогательные testable для Alcotest --- *)

let result_string (type a) (ok_t : a Alcotest.testable) =
  Alcotest.(result ok_t string)

(* --- Тесты библиотеки: Money --- *)

let money_tests =
  let open Alcotest in
  [
    test_case "при amount=100.0 возвращает Ok \"100.00\"" `Quick (fun () ->
      match Money.make 100.0 with
      | Ok m -> check string "amount" "100.00" (Money.to_string m)
      | Error _ -> fail "ожидался Ok");
    test_case "при amount=0.0 возвращает Error" `Quick (fun () ->
      check (result_string string) "zero"
        (Error "сумма должна быть положительной")
        (Money.make 0.0 |> Result.map Money.to_string));
    test_case "при отрицательном amount возвращает Error" `Quick (fun () ->
      check (result_string string) "negative"
        (Error "сумма должна быть положительной")
        (Money.make (-5.0) |> Result.map Money.to_string));
    test_case "при сложении 100.0 и 50.0 возвращает \"150.00\"" `Quick (fun () ->
      match Money.make 100.0, Money.make 50.0 with
      | Ok a, Ok b ->
        check string "sum" "150.00" (Money.to_string (Money.add a b))
      | _ -> fail "ожидались Ok");
  ]

(* --- Тесты библиотеки: CardNumber --- *)

let card_number_tests =
  let open Alcotest in
  [
    test_case "при валидном номере возвращает Ok" `Quick (fun () ->
      match CardNumber.make "4111111111111111" with
      | Ok _ -> ()
      | Error e -> fail e);
    test_case "при номере с пробелами возвращает Ok" `Quick (fun () ->
      match CardNumber.make "4111 1111 1111 1111" with
      | Ok _ -> ()
      | Error e -> fail e);
    test_case "при номере с дефисами возвращает Ok" `Quick (fun () ->
      match CardNumber.make "4111-1111-1111-1111" with
      | Ok _ -> ()
      | Error e -> fail e);
    test_case "при слишком коротком номере возвращает Error" `Quick (fun () ->
      match CardNumber.make "1234" with
      | Error _ -> ()
      | Ok _ -> fail "ожидалась ошибка");
    test_case "при номере с буквами возвращает Error" `Quick (fun () ->
      match CardNumber.make "4111ABCD11111111" with
      | Error _ -> ()
      | Ok _ -> fail "ожидалась ошибка");
    test_case "при маскировании возвращает \"************1111\"" `Quick (fun () ->
      match CardNumber.make "4111111111111111" with
      | Ok card ->
        check string "masked" "************1111" (CardNumber.to_masked card)
      | Error e -> fail e);
  ]

(* --- Тесты библиотеки: PaymentState --- *)

let payment_state_tests =
  let open Alcotest in
  [
    test_case "при полном цикле возвращает shipped" `Quick (fun () ->
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
    test_case "при n=42 возвращает Ok 42" `Quick (fun () ->
      match My_solutions.PositiveInt.make 42 with
      | Ok n -> check int "value" 42 (My_solutions.PositiveInt.value n)
      | Error _ -> fail "ожидался Ok");
    test_case "при n=0 возвращает Error" `Quick (fun () ->
      check (result_string int) "zero"
        (Error "число должно быть положительным")
        (My_solutions.PositiveInt.make 0
         |> Result.map My_solutions.PositiveInt.value));
    test_case "при n=-5 возвращает Error" `Quick (fun () ->
      check (result_string int) "negative"
        (Error "число должно быть положительным")
        (My_solutions.PositiveInt.make (-5)
         |> Result.map My_solutions.PositiveInt.value));
    test_case "при сложении 10 и 20 возвращает 30" `Quick (fun () ->
      match My_solutions.PositiveInt.make 10, My_solutions.PositiveInt.make 20 with
      | Ok a, Ok b ->
        check int "sum" 30
          (My_solutions.PositiveInt.value (My_solutions.PositiveInt.add a b))
      | _ -> fail "ожидались Ok");
    test_case "при n=42 to_string возвращает \"42\"" `Quick (fun () ->
      match My_solutions.PositiveInt.make 42 with
      | Ok n -> check string "str" "42" (My_solutions.PositiveInt.to_string n)
      | Error _ -> fail "ожидался Ok");
  ]

(* Упражнение 2: Email *)

let email_tests =
  let open Alcotest in
  [
    test_case "при валидном email возвращает Ok" `Quick (fun () ->
      match My_solutions.Email.make "user@example.com" with
      | Ok e ->
        check string "email" "user@example.com" (My_solutions.Email.to_string e)
      | Error e -> fail e);
    test_case "при пустой строке возвращает Error" `Quick (fun () ->
      check (result_string string) "empty"
        (Error "email не может быть пустым")
        (My_solutions.Email.make ""
         |> Result.map My_solutions.Email.to_string));
    test_case "при строке без @ возвращает Error" `Quick (fun () ->
      check (result_string string) "no at"
        (Error "email должен содержать @")
        (My_solutions.Email.make "user"
         |> Result.map My_solutions.Email.to_string));
    test_case "при отсутствии точки в домене возвращает Error" `Quick (fun () ->
      check (result_string string) "no dot"
        (Error "некорректный домен")
        (My_solutions.Email.make "user@host"
         |> Result.map My_solutions.Email.to_string));
  ]

(* Упражнение 3: NonEmptyList *)

let non_empty_list_tests =
  let open Alcotest in
  [
    test_case "при [1;2;3] возвращает Ok с head=1" `Quick (fun () ->
      match My_solutions.NonEmptyList.make [1; 2; 3] with
      | Ok nel ->
        check int "head" 1 (My_solutions.NonEmptyList.head nel);
        check (list int) "tail" [2; 3] (My_solutions.NonEmptyList.tail nel);
        check (list int) "to_list" [1; 2; 3]
          (My_solutions.NonEmptyList.to_list nel);
        check int "length" 3 (My_solutions.NonEmptyList.length nel)
      | Error _ -> fail "ожидался Ok");
    test_case "при пустом списке возвращает Error" `Quick (fun () ->
      match My_solutions.NonEmptyList.make ([] : int list) with
      | Error _ -> ()
      | Ok _ -> fail "ожидалась ошибка");
    test_case "при singleton 42 возвращает head=42 tail=[]" `Quick (fun () ->
      let nel = My_solutions.NonEmptyList.singleton 42 in
      check int "head" 42 (My_solutions.NonEmptyList.head nel);
      check (list int) "tail" [] (My_solutions.NonEmptyList.tail nel);
      check int "length" 1 (My_solutions.NonEmptyList.length nel));
    test_case "при map (*2) [1;2;3] возвращает [2;4;6]" `Quick (fun () ->
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
    test_case "при старте возвращает \"red\"" `Quick (fun () ->
      check string "red"
        "red" (My_solutions.TrafficLight.show My_solutions.TrafficLight.start));
    test_case "при полном цикле red->green->yellow->red возвращает корректные состояния" `Quick (fun () ->
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

let () =
  Alcotest.run "Chapter 10a"
    [
      ("Money --- умный конструктор", money_tests);
      ("CardNumber --- умный конструктор", card_number_tests);
      ("PaymentState --- конечный автомат", payment_state_tests);
      ("PositiveInt --- упражнение 1", positive_int_tests);
      ("Email --- упражнение 2", email_tests);
      ("NonEmptyList --- упражнение 3", non_empty_list_tests);
      ("TrafficLight --- упражнение 4", traffic_light_tests);
    ]
