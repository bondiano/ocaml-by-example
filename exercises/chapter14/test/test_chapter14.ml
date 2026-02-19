open Chapter14.Ffi_json

(* ------------------------------------------------------------------ *)
(*  Тесты библиотеки                                                   *)
(* ------------------------------------------------------------------ *)

let c_sin_tests =
  let open Alcotest in
  [ test_case "при 0.0 возвращает ~0" `Quick (fun () ->
      check bool "~0" true (Float.abs (c_sin 0.0) < 1e-10));
    test_case "при pi/2 возвращает ~1" `Quick (fun () ->
      check bool "~1" true (Float.abs (c_sin (Float.pi /. 2.0) -. 1.0) < 1e-10)) ]

let c_stubs_lib_tests =
  let open Alcotest in
  [ test_case "count_char: 'l' в \"hello\" = 2" `Quick (fun () ->
      check int "result" 2 (count_char "hello" 'l'));
    test_case "count_char: пустая строка = 0" `Quick (fun () ->
      check int "result" 0 (count_char "" 'a'));
    test_case "raw_str_repeat: \"ab\" × 3 = \"ababab\"" `Quick (fun () ->
      check string "result" "ababab" (raw_str_repeat "ab" 3));
    test_case "raw_str_repeat: n=0 = \"\"" `Quick (fun () ->
      check string "result" "" (raw_str_repeat "x" 0));
    test_case "sum_int_array: [1;2;3] = 6" `Quick (fun () ->
      check int "result" 6 (sum_int_array [| 1; 2; 3 |]));
    test_case "sum_int_array: [] = 0" `Quick (fun () ->
      check int "result" 0 (sum_int_array [||])) ]

let contact_json_tests =
  let alice = {
    name = "Alice"; age = 30; email = Some "alice@example.com";
    address = { street = "Main St"; city = "Moscow"; zip = "101000" }
  } in
  let open Alcotest in
  [ test_case "при roundtrip возвращает исходный контакт" `Quick (fun () ->
      let json = contact_to_json alice in
      match contact_of_json json with
      | Ok c -> check string "name" "Alice" c.name
      | Error e -> fail e);
    test_case "при невалидном JSON возвращает Error" `Quick (fun () ->
      match contact_of_json (`String "bad") with
      | Error _ -> ()
      | Ok _ -> fail "expected error");
    test_case "при наличии поля возвращает строковое значение" `Quick (fun () ->
      let json = `Assoc [("key", `String "val")] in
      check (option string) "found" (Some "val") (json_string_field "key" json));
    test_case "при наличии поля возвращает целочисленное значение" `Quick (fun () ->
      let json = `Assoc [("n", `Int 42)] in
      check (option int) "found" (Some 42) (json_int_field "n" json));
    test_case "при ppx roundtrip возвращает исходный контакт" `Quick (fun () ->
      let json = contact_to_yojson alice in
      match contact_of_yojson json with
      | Ok c -> check string "name" "Alice" c.name
      | Error e -> fail e) ]

(* ------------------------------------------------------------------ *)
(*  Тесты JSON-упражнений (1–4)                                        *)
(* ------------------------------------------------------------------ *)

let product_json_tests =
  let open Alcotest in
  let book = My_solutions.{ title = "OCaml Book"; price = 29.99; in_stock = true } in
  [ test_case "при сериализации возвращает объект с полем title" `Quick (fun () ->
      let json = My_solutions.product_to_json book in
      match json with
      | `Assoc fields ->
        check (option string) "title"
          (Some "OCaml Book")
          (match List.assoc_opt "title" fields with Some (`String s) -> Some s | _ -> None)
      | _ -> fail "expected object");
    test_case "при валидном JSON возвращает продукт" `Quick (fun () ->
      let json = `Assoc [
        ("title", `String "Pen");
        ("price", `Float 1.50);
        ("in_stock", `Bool false);
      ] in
      match My_solutions.product_of_json json with
      | Ok p ->
        check string "title" "Pen" p.title;
        check bool "stock" false p.in_stock
      | Error e -> fail e);
    test_case "при невалидном JSON возвращает Error" `Quick (fun () ->
      match My_solutions.product_of_json (`Int 42) with
      | Error _ -> ()
      | Ok _ -> fail "expected error");
    test_case "при roundtrip возвращает исходный продукт" `Quick (fun () ->
      let json = My_solutions.product_to_json book in
      match My_solutions.product_of_json json with
      | Ok p -> check string "title" "OCaml Book" p.title
      | Error e -> fail e) ]

let extract_names_tests =
  let open Alcotest in
  [ test_case "при массиве с объектами возвращает имена" `Quick (fun () ->
      let json = `List [
        `Assoc [("name", `String "Alice"); ("age", `Int 30)];
        `Assoc [("name", `String "Bob")];
        `Assoc [("age", `Int 25)];
      ] in
      check (list string) "names" ["Alice"; "Bob"]
        (My_solutions.extract_names json));
    test_case "при пустом массиве возвращает пустой список" `Quick (fun () ->
      check (list string) "empty" []
        (My_solutions.extract_names (`List [])));
    test_case "при не-массиве возвращает пустой список" `Quick (fun () ->
      check (list string) "not list" []
        (My_solutions.extract_names (`String "bad"))) ]

let config_ppx_tests =
  let open Alcotest in
  let cfg = My_solutions.{ host = "localhost"; port = 8080; debug = true } in
  [ test_case "при roundtrip возвращает исходный конфиг" `Quick (fun () ->
      let json = My_solutions.config_to_yojson cfg in
      match My_solutions.config_of_yojson json with
      | Ok c ->
        check string "host" "localhost" c.host;
        check int "port" 8080 c.port;
        check bool "debug" true c.debug
      | Error e -> fail e) ]

(* ------------------------------------------------------------------ *)
(*  Тесты FFI-упражнений (5–7)                                        *)
(* ------------------------------------------------------------------ *)

let ffi_count_char_tests =
  let open Alcotest in
  [ test_case "'l' в \"hello\" = 2" `Quick (fun () ->
      check int "result" 2 (My_solutions.count_char "hello" 'l'));
    test_case "символ отсутствует → 0" `Quick (fun () ->
      check int "result" 0 (My_solutions.count_char "hello" 'z'));
    test_case "пустая строка → 0" `Quick (fun () ->
      check int "result" 0 (My_solutions.count_char "" 'a'));
    test_case "'a' в \"aaa\" = 3" `Quick (fun () ->
      check int "result" 3 (My_solutions.count_char "aaa" 'a'));
    test_case "учитывает регистр: 'A' ≠ 'a'" `Quick (fun () ->
      check int "result" 1 (My_solutions.count_char "Hello" 'H')) ]

let ffi_str_repeat_tests =
  let open Alcotest in
  [ test_case "\"ab\" × 3 = \"ababab\"" `Quick (fun () ->
      check string "result" "ababab" (My_solutions.str_repeat "ab" 3));
    test_case "\"x\" × 1 = \"x\"" `Quick (fun () ->
      check string "result" "x" (My_solutions.str_repeat "x" 1));
    test_case "любая строка × 0 = \"\"" `Quick (fun () ->
      check string "result" "" (My_solutions.str_repeat "hello" 0));
    test_case "безопасная обёртка: n < 0 → \"\"" `Quick (fun () ->
      check string "result" "" (My_solutions.str_repeat "abc" (-5)));
    test_case "пустая строка × любое n = \"\"" `Quick (fun () ->
      check string "result" "" (My_solutions.str_repeat "" 10)) ]

let ffi_mean_tests =
  let open Alcotest in
  [ test_case "[1;2;3] → Some 2.0" `Quick (fun () ->
      match My_solutions.mean [| 1; 2; 3 |] with
      | Some v -> check bool "~2.0" true (Float.abs (v -. 2.0) < 1e-9)
      | None -> fail "expected Some");
    test_case "[5] → Some 5.0" `Quick (fun () ->
      match My_solutions.mean [| 5 |] with
      | Some v -> check bool "~5.0" true (Float.abs (v -. 5.0) < 1e-9)
      | None -> fail "expected Some");
    test_case "пустой массив → None" `Quick (fun () ->
      check bool "None" true (My_solutions.mean [||] = None));
    test_case "[0;0;0] → Some 0.0" `Quick (fun () ->
      match My_solutions.mean [| 0; 0; 0 |] with
      | Some v -> check bool "~0.0" true (Float.abs v < 1e-9)
      | None -> fail "expected Some") ]

(* ------------------------------------------------------------------ *)

let () =
  Alcotest.run "Chapter 14 — FFI и JSON"
    [ ("c_sin --- FFI libm",              c_sin_tests);
      ("c_stubs --- lib/stubs.c",         c_stubs_lib_tests);
      ("contact_json --- ручной JSON",    contact_json_tests);
      ("product_json --- упр. 1–2",       product_json_tests);
      ("extract_names --- упр. 3",        extract_names_tests);
      ("config_ppx --- упр. 4",           config_ppx_tests);
      ("ffi_count_char --- упр. 5",       ffi_count_char_tests);
      ("ffi_str_repeat --- упр. 6",       ffi_str_repeat_tests);
      ("ffi_mean --- упр. 7",             ffi_mean_tests) ]
