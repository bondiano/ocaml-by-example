open Chapter14.Ffi_json

(* --- Тесты библиотеки --- *)

let c_sin_tests =
  let open Alcotest in
  [
    test_case "c_sin 0" `Quick (fun () ->
      let r = Float.abs (c_sin 0.0) in
      check bool "~0" true (r < 1e-10));
    test_case "c_sin pi/2" `Quick (fun () ->
      let r = Float.abs (c_sin (Float.pi /. 2.0) -. 1.0) in
      check bool "~1" true (r < 1e-10));
  ]

let contact_json_tests =
  let alice = {
    name = "Alice"; age = 30; email = Some "alice@example.com";
    address = { street = "Main St"; city = "Moscow"; zip = "101000" }
  } in
  let open Alcotest in
  [
    test_case "contact_to_json roundtrip" `Quick (fun () ->
      let json = contact_to_json alice in
      match contact_of_json json with
      | Ok c -> check string "name" "Alice" c.name
      | Error e -> fail e);
    test_case "contact_of_json invalid" `Quick (fun () ->
      match contact_of_json (`String "bad") with
      | Error _ -> ()
      | Ok _ -> fail "expected error");
    test_case "json_string_field" `Quick (fun () ->
      let json = `Assoc [("key", `String "val")] in
      check (option string) "found" (Some "val") (json_string_field "key" json));
    test_case "json_int_field" `Quick (fun () ->
      let json = `Assoc [("n", `Int 42)] in
      check (option int) "found" (Some 42) (json_int_field "n" json));
    test_case "ppx contact_of_yojson roundtrip" `Quick (fun () ->
      let json = contact_to_yojson alice in
      match contact_of_yojson json with
      | Ok c -> check string "name" "Alice" c.name
      | Error e -> fail e);
  ]

(* --- Тесты упражнений --- *)

let product_json_tests =
  let open Alcotest in
  let book = My_solutions.{ title = "OCaml Book"; price = 29.99; in_stock = true } in
  [
    test_case "product_to_json" `Quick (fun () ->
      let json = My_solutions.product_to_json book in
      match json with
      | `Assoc fields ->
        check (option string) "title"
          (Some "OCaml Book")
          (match List.assoc_opt "title" fields with Some (`String s) -> Some s | _ -> None)
      | _ -> fail "expected object");
    test_case "product_of_json valid" `Quick (fun () ->
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
    test_case "product_of_json invalid" `Quick (fun () ->
      match My_solutions.product_of_json (`Int 42) with
      | Error _ -> ()
      | Ok _ -> fail "expected error");
    test_case "product roundtrip" `Quick (fun () ->
      let json = My_solutions.product_to_json book in
      match My_solutions.product_of_json json with
      | Ok p -> check string "title" "OCaml Book" p.title
      | Error e -> fail e);
  ]

let extract_names_tests =
  let open Alcotest in
  [
    test_case "extract_names" `Quick (fun () ->
      let json = `List [
        `Assoc [("name", `String "Alice"); ("age", `Int 30)];
        `Assoc [("name", `String "Bob")];
        `Assoc [("age", `Int 25)];
      ] in
      check (list string) "names" ["Alice"; "Bob"]
        (My_solutions.extract_names json));
    test_case "extract_names empty" `Quick (fun () ->
      check (list string) "empty" []
        (My_solutions.extract_names (`List [])));
    test_case "extract_names not list" `Quick (fun () ->
      check (list string) "not list" []
        (My_solutions.extract_names (`String "bad")));
  ]

let config_ppx_tests =
  let open Alcotest in
  let cfg = My_solutions.{ host = "localhost"; port = 8080; debug = true } in
  [
    test_case "config yojson roundtrip" `Quick (fun () ->
      let json = My_solutions.config_to_yojson cfg in
      match My_solutions.config_of_yojson json with
      | Ok c ->
        check string "host" "localhost" c.host;
        check int "port" 8080 c.port;
        check bool "debug" true c.debug
      | Error e -> fail e);
  ]

let () =
  Alcotest.run "Chapter 10"
    [
      ("c_sin --- FFI sin", c_sin_tests);
      ("contact_json --- ручной JSON", contact_json_tests);
      ("product_json --- product JSON", product_json_tests);
      ("extract_names --- извлечение имён", extract_names_tests);
      ("config_ppx --- ppx_deriving_yojson", config_ppx_tests);
    ]
