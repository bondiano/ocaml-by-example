open Schema_validator

(* Базовые unit-тесты *)
let schema_tests =
  let open Alcotest in
  [
    test_case "создание строковой схемы" `Quick (fun () ->
        let _schema = Schema.string ~min_length:1 ~max_length:10 () in
        (* TODO: проверить, что схема создана корректно *)
        ());
    test_case "создание объектной схемы" `Quick (fun () ->
        let _schema =
          Schema.obj
            [
              Schema.object_field "name" (Schema.string ()) true;
              Schema.object_field "age" (Schema.number ()) false;
            ]
        in
        ());
  ]

let error_tests =
  let open Alcotest in
  [
    test_case "форматирование пути" `Quick (fun () ->
        let path = [ "user"; "address"; "zip" ] in
        let _formatted = Error.show_path path in
        (* TODO: проверить, что путь правильно отформатирован *)
        ());
  ]

let validator_tests =
  let open Alcotest in
  [
    test_case "валидная строка проходит" `Quick (fun () ->
        let schema = Schema.string ~min_length:1 () in
        let json = `String "hello" in
        match Validator.validate schema json with
        | Ok () -> ()
        | Error errs ->
            fail
              (Printf.sprintf "Expected valid, got errors: %d" (List.length errs)));
    test_case "короткая строка отклоняется" `Quick (fun () ->
        let schema = Schema.string ~min_length:5 () in
        let json = `String "hi" in
        match Validator.validate schema json with
        | Error _ -> ()
        | Ok () -> fail "Expected error for short string");
    (* TODO: добавьте больше тестов для всех типов валидации *)
  ]

(* Property-Based тесты *)
module PBT = struct
  open QCheck

  (* Генератор строк с ограничениями *)
  let string_with_constraints ~min_length ~max_length =
    Gen.(
      (min_length -- max_length)
      >>= fun len -> string_size (return len)
      |> map (fun s ->
             if String.length s < min_length then
               s ^ String.make (min_length - String.length s) 'a'
             else s))

  (* Свойство: валидные строки всегда проходят валидацию *)
  let prop_valid_strings =
    Test.make ~name:"valid strings pass validation" ~count:100
      (make (string_with_constraints ~min_length:3 ~max_length:10))
      (fun s ->
        let schema = Schema.string ~min_length:3 ~max_length:10 () in
        let json = `String s in
        match Validator.validate schema json with
        | Ok () -> true
        | Error _ -> false)

  (* TODO: добавьте больше property-based тестов:
     - Числа в диапазоне
     - Массивы с правильной длиной
     - Объекты со всеми required полями
  *)

  let all_properties = [ prop_valid_strings ]
end

let () =
  Alcotest.run "Schema Validator"
    [
      ("Schema", schema_tests);
      ("Error", error_tests);
      ("Validator", validator_tests);
    ];
  QCheck_base_runner.run_tests_main PBT.all_properties
