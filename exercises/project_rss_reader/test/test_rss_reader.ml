open Rss_reader

let validator_tests =
  let open Alcotest in
  [
    test_case "валидный HTTP URL проходит" `Quick (fun () ->
      match Validator.validate_url "http://example.com/feed" ~existing:[] with
      | Ok _ -> ()
      | Error e -> fail (Validator.show_error e));

    test_case "пустой URL отклоняется" `Quick (fun () ->
      match Validator.validate_url "" ~existing:[] with
      | Error Empty_url -> ()
      | _ -> fail "должна быть ошибка Empty_url");

    (* TODO: добавьте больше тестов *)
  ]

let storage_tests =
  let open Alcotest in
  [
    test_case "создание пустого хранилища" `Quick (fun () ->
      let storage = Storage.create () in
      check int "empty" 0 (List.length (Storage.get_feeds storage)));

    (* TODO: добавьте тесты для add_feed и get_recent_posts *)
  ]

let () =
  Alcotest.run "RSS Reader"
    [
      ("Validator", validator_tests);
      ("Storage", storage_tests);
    ]
