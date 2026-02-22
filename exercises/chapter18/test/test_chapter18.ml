open Chapter18.Todo_api

(* --- Тесты библиотеки --- *)

let store_tests =
  let open Alcotest in
  [
    test_case "при создании задачи возвращает корректные поля" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Buy milk" in
      check string "title" "Buy milk" todo.title;
      check bool "completed" false todo.completed;
      check int "id" 1 todo.id);
    test_case "при двух задачах возвращает список из двух" `Quick (fun () ->
      reset_store ();
      ignore (create_todo ~title:"A");
      ignore (create_todo ~title:"B");
      check int "count" 2 (List.length (list_todos ())));
    test_case "при поиске по id находит задачу" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Find me" in
      match find_todo todo.id with
      | Some t -> check string "title" "Find me" t.title
      | None -> fail "not found");
    test_case "при обновлении возвращает изменённую задачу" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Old" in
      match update_todo todo.id ~title:"New" ~completed:true () with
      | Some t ->
        check string "title" "New" t.title;
        check bool "completed" true t.completed
      | None -> fail "not found");
    test_case "при удалении задача исчезает из списка" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Delete me" in
      ignore (delete_todo todo.id);
      check int "count" 0 (List.length (list_todos ())));
    test_case "при поиске несуществующего id возвращает None" `Quick (fun () ->
      reset_store ();
      check bool "none" true (find_todo 999 = None));
  ]

let json_tests =
  let open Alcotest in
  [
    test_case "при todo_to_yojson возвращает непустую строку" `Quick (fun () ->
      let todo = { id = 1; title = "Test"; completed = false } in
      let json = Yojson.Safe.to_string (todo_to_yojson todo) in
      check bool "has content" true (String.length json > 0));
    test_case "при roundtrip сохраняет все поля" `Quick (fun () ->
      let todo = { id = 1; title = "Test"; completed = true } in
      match todo_of_yojson (todo_to_yojson todo) with
      | Ok t ->
        check string "title" "Test" t.title;
        check bool "completed" true t.completed;
        check int "id" 1 t.id
      | Error msg -> fail msg);
    test_case "при create_todo_of_yojson разбирает title" `Quick (fun () ->
      let json = Yojson.Safe.from_string {|{"title":"New task"}|} in
      match create_todo_of_yojson json with
      | Ok { title } -> check string "title" "New task" title
      | Error msg -> fail msg);
  ]

(* --- Тесты упражнений --- *)

let health_tests =
  let lwt_tc name f =
    Alcotest.test_case name `Quick (fun () -> Lwt_main.run (f ()))
  in
  [
    lwt_tc "при GET / возвращает статус 200 и {\"status\":\"ok\"}" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/" "" in
      let* resp = My_solutions.health_handler req in
      let* body = Dream.body resp in
      Lwt.return (Alcotest.(check string) "body" {|{"status":"ok"}|} body));
  ]

let paginate_tests =
  let open Alcotest in
  [
    test_case "при offset=0 limit=2 возвращает первые два элемента" `Quick (fun () ->
      check (list int) "result" [1; 2]
        (My_solutions.paginate ~offset:0 ~limit:2 [1; 2; 3; 4; 5]));
    test_case "при offset=2 limit=2 возвращает средние элементы" `Quick (fun () ->
      check (list int) "result" [3; 4]
        (My_solutions.paginate ~offset:2 ~limit:2 [1; 2; 3; 4; 5]));
    test_case "при offset за пределами списка возвращает пустой список" `Quick (fun () ->
      check (list int) "result" []
        (My_solutions.paginate ~offset:10 ~limit:2 [1; 2; 3]));
    test_case "при пустом списке возвращает пустой список" `Quick (fun () ->
      check (list int) "result" []
        (My_solutions.paginate ~offset:0 ~limit:5 []));
  ]

let search_tests =
  let open Alcotest in
  let todos = [
    { id = 1; title = "Buy milk"; completed = false };
    { id = 2; title = "Buy bread"; completed = false };
    { id = 3; title = "Clean house"; completed = true };
  ] in
  [
    test_case "при запросе \"Buy\" находит два совпадения" `Quick (fun () ->
      check int "count" 2
        (List.length (My_solutions.search_todos "Buy" todos)));
    test_case "при запросе \"Clean\" находит одно совпадение" `Quick (fun () ->
      check int "count" 1
        (List.length (My_solutions.search_todos "Clean" todos)));
    test_case "при несуществующем запросе возвращает пустой список" `Quick (fun () ->
      check int "count" 0
        (List.length (My_solutions.search_todos "xyz" todos)));
    test_case "при пустом запросе возвращает все задачи" `Quick (fun () ->
      check int "count" 3
        (List.length (My_solutions.search_todos "" todos)));
  ]

let auth_tests =
  let lwt_tc name f =
    Alcotest.test_case name `Quick (fun () -> Lwt_main.run (f ()))
  in
  let secret = "my-secret-token" in
  let handler _req = Dream.json {|{"data":"ok"}|} in
  let app = My_solutions.auth_middleware secret handler in
  [
    lwt_tc "при верном токене возвращает 200" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/"
        ~headers:["Authorization", "Bearer my-secret-token"] "" in
      let* resp = app req in
      let status = Dream.status resp in
      Lwt.return (Alcotest.(check int) "status" 200 (Dream.status_to_int status)));

    lwt_tc "при отсутствующем токене возвращает 401" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/" "" in
      let* resp = app req in
      let status = Dream.status resp in
      Lwt.return (Alcotest.(check int) "status" 401 (Dream.status_to_int status)));

    lwt_tc "при неверном токене возвращает 401" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/"
        ~headers:["Authorization", "Bearer wrong-token"] "" in
      let* resp = app req in
      let status = Dream.status resp in
      Lwt.return (Alcotest.(check int) "status" 401 (Dream.status_to_int status)));
  ]

let cors_tests =
  let lwt_tc name f =
    Alcotest.test_case name `Quick (fun () -> Lwt_main.run (f ()))
  in
  let handler _req = Dream.json {|{"data":"ok"}|} in
  let app = My_solutions.cors_middleware handler in
  [
    lwt_tc "при ответе добавляет CORS заголовки" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/" "" in
      let* resp = app req in
      let origin = Dream.header resp "Access-Control-Allow-Origin" in
      Lwt.return (Alcotest.(check (option string)) "origin" (Some "*") origin));
  ]

let json_error_tests =
  let lwt_tc name f =
    Alcotest.test_case name `Quick (fun () -> Lwt_main.run (f ()))
  in
  [
    lwt_tc "при ошибке возвращает JSON с полем error" (fun () ->
      let open Lwt.Syntax in
      let* resp = My_solutions.json_error `Bad_Request "invalid input" in
      let* body = Dream.body resp in
      Lwt.return (Alcotest.(check bool) "has error" true
                    (String.length body > 0 && Str.string_match (Str.regexp ".*error.*") body 0)));
  ]

let filter_tests =
  let open Alcotest in
  let todos = [
    { id = 1; title = "A"; completed = true };
    { id = 2; title = "B"; completed = false };
    { id = 3; title = "C"; completed = true };
  ] in
  [
    test_case "при None возвращает все задачи" `Quick (fun () ->
      check int "count" 3
        (List.length (My_solutions.filter_todos None todos)));
    test_case "при Some true возвращает только completed" `Quick (fun () ->
      let result = My_solutions.filter_todos (Some true) todos in
      check int "count" 2 (List.length result);
      check bool "all completed" true
        (List.for_all (fun (t : todo) -> t.completed) result));
    test_case "при Some false возвращает только не completed" `Quick (fun () ->
      let result = My_solutions.filter_todos (Some false) todos in
      check int "count" 1 (List.length result);
      check bool "none completed" true
        (List.for_all (fun (t : todo) -> not t.completed) result));
  ]

let () =
  Alcotest.run "Chapter 18"
    [
      ("store --- хранилище задач", store_tests);
      ("json --- JSON сериализация", json_tests);
      ("health --- health check", health_tests);
      ("paginate --- пагинация", paginate_tests);
      ("search --- поиск задач", search_tests);
      ("auth --- аутентификация", auth_tests);
      ("cors --- CORS middleware", cors_tests);
      ("json_error --- JSON ошибки", json_error_tests);
      ("filter --- фильтрация по completed", filter_tests);
    ]
