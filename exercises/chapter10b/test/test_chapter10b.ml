(* --- Тесты упражнений --- *)

(* Упражнение 1: Form *)

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
    test_case "при всех валидных полях возвращает Ok" `Quick (fun () ->
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
    test_case "при одном невалидном поле возвращает одну ошибку" `Quick (fun () ->
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
    test_case "при двух невалидных полях возвращает две ошибки" `Quick (fun () ->
      let open My_solutions.Form in
      match run (map2
        (fun name age -> (name, age))
        (field "имя" "" parse_name)
        (field "возраст" "abc" parse_age))
      with
      | Error errors ->
        check int "две ошибки" 2 (List.length errors)
      | Ok _ -> fail "ожидалась ошибка");
    test_case "при map3 с тремя валидными полями возвращает Ok" `Quick (fun () ->
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
    test_case "при map3 с тремя невалидными полями возвращает три ошибки" `Quick (fun () ->
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

(* Упражнение 2: FileHandle *)

let file_handle_tests =
  let open Alcotest in
  [
    test_case "при открытии файла возвращает пустое содержимое" `Quick (fun () ->
      let h = My_solutions.FileHandle.open_file "test.txt" in
      check string "name" "test.txt" (My_solutions.FileHandle.name h);
      check string "empty content" "" (My_solutions.FileHandle.read h));
    test_case "при записи двух строк возвращает их конкатенацию" `Quick (fun () ->
      let h = My_solutions.FileHandle.open_file "test.txt" in
      let h = My_solutions.FileHandle.write h "hello " in
      let h = My_solutions.FileHandle.write h "world" in
      check string "content" "hello world" (My_solutions.FileHandle.read h));
    test_case "при закрытии сохраняет имя файла" `Quick (fun () ->
      let h = My_solutions.FileHandle.open_file "test.txt" in
      let h = My_solutions.FileHandle.write h "data" in
      let closed = My_solutions.FileHandle.close h in
      check string "name" "test.txt" (My_solutions.FileHandle.name closed));
  ]

let () =
  Alcotest.run "Chapter 10b"
    [
      ("Form --- упражнение 1", form_tests);
      ("FileHandle --- упражнение 2", file_handle_tests);
    ]
