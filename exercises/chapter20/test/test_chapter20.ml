open Chapter20.Todo_api

(* --- Тесты библиотеки --- *)

let store_tests =
  let open Alcotest in
  [
    test_case "create todo" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Buy milk" in
      check string "title" "Buy milk" todo.title;
      check bool "not completed" false todo.completed;
      check int "id" 1 todo.id);
    test_case "list todos" `Quick (fun () ->
      reset_store ();
      ignore (create_todo ~title:"A");
      ignore (create_todo ~title:"B");
      check int "count" 2 (List.length (list_todos ())));
    test_case "find todo" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Find me" in
      match find_todo todo.id with
      | Some t -> check string "title" "Find me" t.title
      | None -> fail "not found");
    test_case "update todo" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Old" in
      match update_todo todo.id ~title:"New" ~completed:true () with
      | Some t ->
        check string "title" "New" t.title;
        check bool "completed" true t.completed
      | None -> fail "not found");
    test_case "delete todo" `Quick (fun () ->
      reset_store ();
      let todo = create_todo ~title:"Delete me" in
      ignore (delete_todo todo.id);
      check int "count" 0 (List.length (list_todos ())));
    test_case "find missing" `Quick (fun () ->
      reset_store ();
      check bool "none" true (find_todo 999 = None));
  ]

let json_tests =
  let open Alcotest in
  [
    test_case "todo_to_yojson" `Quick (fun () ->
      let todo = { id = 1; title = "Test"; completed = false } in
      let json = Yojson.Safe.to_string (todo_to_yojson todo) in
      check bool "has title" true (String.length json > 0));
    test_case "todo roundtrip" `Quick (fun () ->
      let todo = { id = 1; title = "Test"; completed = true } in
      match todo_of_yojson (todo_to_yojson todo) with
      | Ok t ->
        check string "title" "Test" t.title;
        check bool "completed" true t.completed;
        check int "id" 1 t.id
      | Error msg -> fail msg);
    test_case "create_todo_of_yojson" `Quick (fun () ->
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
    lwt_tc "health_handler returns ok" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/" "" in
      let* resp = My_solutions.health_handler req in
      let* body = Dream.body resp in
      Lwt.return (Alcotest.(check string) "body" {|{"status":"ok"}|} body));
  ]

let paginate_tests =
  let open Alcotest in
  [
    test_case "paginate offset 0 limit 2" `Quick (fun () ->
      check (list int) "first 2" [1; 2]
        (My_solutions.paginate ~offset:0 ~limit:2 [1; 2; 3; 4; 5]));
    test_case "paginate offset 2 limit 2" `Quick (fun () ->
      check (list int) "mid 2" [3; 4]
        (My_solutions.paginate ~offset:2 ~limit:2 [1; 2; 3; 4; 5]));
    test_case "paginate offset beyond" `Quick (fun () ->
      check (list int) "empty" []
        (My_solutions.paginate ~offset:10 ~limit:2 [1; 2; 3]));
    test_case "paginate empty list" `Quick (fun () ->
      check (list int) "empty" []
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
    test_case "search Buy" `Quick (fun () ->
      check int "2 matches" 2
        (List.length (My_solutions.search_todos "Buy" todos)));
    test_case "search Clean" `Quick (fun () ->
      check int "1 match" 1
        (List.length (My_solutions.search_todos "Clean" todos)));
    test_case "search nothing" `Quick (fun () ->
      check int "0 matches" 0
        (List.length (My_solutions.search_todos "xyz" todos)));
    test_case "search empty query" `Quick (fun () ->
      check int "all match" 3
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
    lwt_tc "auth valid token" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/"
        ~headers:["Authorization", "Bearer my-secret-token"] "" in
      let* resp = app req in
      let status = Dream.status resp in
      Lwt.return (Alcotest.(check int) "200" 200 (Dream.status_to_int status)));

    lwt_tc "auth missing token" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/" "" in
      let* resp = app req in
      let status = Dream.status resp in
      Lwt.return (Alcotest.(check int) "401" 401 (Dream.status_to_int status)));

    lwt_tc "auth wrong token" (fun () ->
      let open Lwt.Syntax in
      let req = Dream.request ~method_:`GET ~target:"/"
        ~headers:["Authorization", "Bearer wrong-token"] "" in
      let* resp = app req in
      let status = Dream.status resp in
      Lwt.return (Alcotest.(check int) "401" 401 (Dream.status_to_int status)));
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
    ]
