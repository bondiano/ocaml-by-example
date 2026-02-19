open Chapter09.Records

(* --- Пользовательские testable --- *)

let record_testable : record Alcotest.testable =
  Alcotest.testable
    (fun fmt r -> Format.pp_print_string fmt (show_record r))
    ( = )

(* --- Тесты библиотеки --- *)

let store_tests =
  let open Alcotest in
  [
    test_case "создание пустого хранилища" `Quick (fun () ->
      let s = create_store () in
      check int "count" 0 (count s));
    test_case "добавление записей" `Quick (fun () ->
      let s = create_store () in
      let r1 = add_record s ~name:"host" ~value:"localhost" in
      let r2 = add_record s ~name:"port" ~value:"8080" in
      check int "r1.id" 1 r1.id;
      check int "r2.id" 2 r2.id;
      check int "count" 2 (count s));
    test_case "поиск записи" `Quick (fun () ->
      let s = create_store () in
      let _ = add_record s ~name:"key" ~value:"val" in
      check (option record_testable) "found"
        (Some { id = 1; name = "key"; value = "val" })
        (find_record s 1);
      check (option record_testable) "not found"
        None (find_record s 99));
    test_case "удаление записи" `Quick (fun () ->
      let s = create_store () in
      let _ = add_record s ~name:"a" ~value:"1" in
      let _ = add_record s ~name:"b" ~value:"2" in
      remove_record s 1;
      check int "count after remove" 1 (count s);
      check (option record_testable) "removed"
        None (find_record s 1));
    test_case "all_records в порядке добавления" `Quick (fun () ->
      let s = create_store () in
      let _ = add_record s ~name:"first" ~value:"1" in
      let _ = add_record s ~name:"second" ~value:"2" in
      let names = all_records s |> List.map (fun r -> r.name) in
      check (list string) "order" ["first"; "second"] names);
    test_case "show_record" `Quick (fun () ->
      let r = { id = 1; name = "host"; value = "localhost" } in
      check string "show" "[1] host = localhost" (show_record r));
  ]

(* --- Тесты упражнений --- *)

let counter_tests =
  let open Alcotest in
  [
    test_case "создание счётчика" `Quick (fun () ->
      let c = My_solutions.counter_create 0 in
      check int "init" 0 (My_solutions.counter_value c));
    test_case "создание с начальным значением" `Quick (fun () ->
      let c = My_solutions.counter_create 10 in
      check int "init 10" 10 (My_solutions.counter_value c));
    test_case "increment" `Quick (fun () ->
      let c = My_solutions.counter_create 0 in
      My_solutions.counter_increment c;
      My_solutions.counter_increment c;
      My_solutions.counter_increment c;
      check int "after 3 increments" 3 (My_solutions.counter_value c));
    test_case "decrement" `Quick (fun () ->
      let c = My_solutions.counter_create 5 in
      My_solutions.counter_decrement c;
      My_solutions.counter_decrement c;
      check int "after 2 decrements" 3 (My_solutions.counter_value c));
    test_case "reset" `Quick (fun () ->
      let c = My_solutions.counter_create 0 in
      My_solutions.counter_increment c;
      My_solutions.counter_increment c;
      My_solutions.counter_reset c;
      check int "after reset" 0 (My_solutions.counter_value c));
  ]

let logger_tests =
  let open Alcotest in
  [
    test_case "создание логгера" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      check int "empty" 0 (My_solutions.logger_count l));
    test_case "добавление сообщений" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      My_solutions.logger_log l "first";
      My_solutions.logger_log l "second";
      check (list string) "messages"
        ["first"; "second"]
        (My_solutions.logger_messages l));
    test_case "count" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      My_solutions.logger_log l "a";
      My_solutions.logger_log l "b";
      My_solutions.logger_log l "c";
      check int "count" 3 (My_solutions.logger_count l));
    test_case "clear" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      My_solutions.logger_log l "msg";
      My_solutions.logger_clear l;
      check int "after clear" 0 (My_solutions.logger_count l);
      check (list string) "empty messages" []
        (My_solutions.logger_messages l));
  ]

let format_table_tests =
  let open Alcotest in
  [
    test_case "таблица из двух строк" `Quick (fun () ->
      let result = My_solutions.format_table
        [("Имя", "Иван"); ("Город", "Москва")] in
      let lines = String.split_on_char '\n' result in
      check int "две строки" 2 (List.length lines);
      check bool "содержит Иван" true
        (List.exists (fun l -> String.contains l '|') lines));
    test_case "содержит разделитель |" `Quick (fun () ->
      let result = My_solutions.format_table
        [("key", "value")] in
      check bool "has |" true
        (String.contains result '|'));
    test_case "пустой список" `Quick (fun () ->
      check string "empty" "" (My_solutions.format_table []));
    test_case "выравнивание" `Quick (fun () ->
      let result = My_solutions.format_table
        [("a", "1"); ("longer_key", "2")] in
      let lines = String.split_on_char '\n' result in
      let pipe_positions = List.filter_map (fun l ->
        match String.index_opt l '|' with
        | Some i -> Some i
        | None -> None
      ) lines in
      match pipe_positions with
      | [] -> Alcotest.fail "нет разделителей"
      | p :: rest ->
        check bool "все | на одной позиции" true
          (List.for_all (fun x -> x = p) rest));
  ]

let array_sum_tests =
  let open Alcotest in
  [
    test_case "сумма массива" `Quick (fun () ->
      check int "sum" 15
        (My_solutions.array_sum_imperative [| 1; 2; 3; 4; 5 |]));
    test_case "пустой массив" `Quick (fun () ->
      check int "empty" 0
        (My_solutions.array_sum_imperative [| |]));
    test_case "один элемент" `Quick (fun () ->
      check int "single" 42
        (My_solutions.array_sum_imperative [| 42 |]));
    test_case "отрицательные числа" `Quick (fun () ->
      check int "negative" (-3)
        (My_solutions.array_sum_imperative [| 1; -2; 3; -4; -1 |]));
  ]

let gc_stats_tests =
  let open Alcotest in
  [
    test_case "gc_stats возвращает строку" `Quick (fun () ->
      let stats = Chapter09.Records.gc_stats () in
      check bool "содержит Minor" true
        (String.length stats > 0));
  ]

let weak_cache_tests =
  let open Alcotest in
  let open Chapter09.Records.WeakCache in
  [
    test_case "set и get" `Quick (fun () ->
      let cache = create 10 in
      set cache 0 42;
      check (option int) "get 0" (Some 42) (get cache 0));
    test_case "пустой слот" `Quick (fun () ->
      let cache = create 10 in
      check (option int) "get empty" None (get cache 0));
    test_case "clear" `Quick (fun () ->
      let cache = create 10 in
      set cache 0 42;
      clear cache;
      check (option int) "cleared" None (get cache 0));
  ]

let robot_tests =
  let open Alcotest in
  [
    test_case "робот имеет имя" `Quick (fun () ->
      let robot = My_solutions.Robot.create () in
      let name = My_solutions.Robot.name robot in
      check bool "длина имени 5" true (String.length name = 5));
    test_case "имя начинается с 2 букв" `Quick (fun () ->
      let robot = My_solutions.Robot.create () in
      let name = My_solutions.Robot.name robot in
      check bool "буква 0" true (name.[0] >= 'A' && name.[0] <= 'Z');
      check bool "буква 1" true (name.[1] >= 'A' && name.[1] <= 'Z'));
    test_case "имя заканчивается 3 цифрами" `Quick (fun () ->
      let robot = My_solutions.Robot.create () in
      let name = My_solutions.Robot.name robot in
      check bool "цифра 2" true (name.[2] >= '0' && name.[2] <= '9');
      check bool "цифра 3" true (name.[3] >= '0' && name.[3] <= '9');
      check bool "цифра 4" true (name.[4] >= '0' && name.[4] <= '9'));
    test_case "два робота — разные имена" `Quick (fun () ->
      let r1 = My_solutions.Robot.create () in
      let r2 = My_solutions.Robot.create () in
      check bool "different" true
        (My_solutions.Robot.name r1 <> My_solutions.Robot.name r2));
  ]

let lru_tests =
  let open Alcotest in
  [
    test_case "put и get" `Quick (fun () ->
      let cache = My_solutions.LRU.create 3 in
      My_solutions.LRU.put cache "a" 1;
      check (option int) "get a" (Some 1) (My_solutions.LRU.get cache "a"));
    test_case "вытеснение" `Quick (fun () ->
      let cache = My_solutions.LRU.create 2 in
      My_solutions.LRU.put cache "a" 1;
      My_solutions.LRU.put cache "b" 2;
      My_solutions.LRU.put cache "c" 3;
      check (option int) "a вытеснена" None (My_solutions.LRU.get cache "a");
      check (option int) "c есть" (Some 3) (My_solutions.LRU.get cache "c"));
    test_case "size" `Quick (fun () ->
      let cache = My_solutions.LRU.create 3 in
      My_solutions.LRU.put cache "a" 1;
      My_solutions.LRU.put cache "b" 2;
      check int "size" 2 (My_solutions.LRU.size cache));
  ]

let logger_fcis_tests =
  let open Alcotest in
  [
    test_case "LoggerPure.add" `Quick (fun () ->
      let msgs = My_solutions.LoggerPure.add [] "hello" in
      check (list string) "one msg" ["hello"]
        (My_solutions.LoggerPure.messages msgs));
    test_case "LoggerPure.count" `Quick (fun () ->
      let msgs = My_solutions.LoggerPure.add
          (My_solutions.LoggerPure.add [] "a") "b" in
      check int "count" 2 (My_solutions.LoggerPure.count msgs));
    test_case "LoggerShell create и log" `Quick (fun () ->
      let l = My_solutions.LoggerShell.create () in
      My_solutions.LoggerShell.log l "first";
      My_solutions.LoggerShell.log l "second";
      check (list string) "messages" ["first"; "second"]
        (My_solutions.LoggerShell.messages l));
    test_case "LoggerShell count и clear" `Quick (fun () ->
      let l = My_solutions.LoggerShell.create () in
      My_solutions.LoggerShell.log l "a";
      My_solutions.LoggerShell.log l "b";
      check int "count" 2 (My_solutions.LoggerShell.count l);
      My_solutions.LoggerShell.clear l;
      check int "after clear" 0 (My_solutions.LoggerShell.count l));
  ]

let bowling_tests =
  let open Alcotest in
  [
    test_case "все нули" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      for _ = 1 to 20 do
        ignore (My_solutions.Bowling.roll game 0)
      done;
      check int "score" 0 (My_solutions.Bowling.score game));
    test_case "все единицы" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      for _ = 1 to 20 do
        ignore (My_solutions.Bowling.roll game 1)
      done;
      check int "score" 20 (My_solutions.Bowling.score game));
    test_case "один spare" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      ignore (My_solutions.Bowling.roll game 5);
      ignore (My_solutions.Bowling.roll game 5);
      ignore (My_solutions.Bowling.roll game 3);
      for _ = 1 to 17 do
        ignore (My_solutions.Bowling.roll game 0)
      done;
      check int "score" 16 (My_solutions.Bowling.score game));
    test_case "один strike" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      ignore (My_solutions.Bowling.roll game 10);
      ignore (My_solutions.Bowling.roll game 3);
      ignore (My_solutions.Bowling.roll game 4);
      for _ = 1 to 16 do
        ignore (My_solutions.Bowling.roll game 0)
      done;
      check int "score" 24 (My_solutions.Bowling.score game));
    test_case "perfect game" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      for _ = 1 to 12 do
        ignore (My_solutions.Bowling.roll game 10)
      done;
      check int "score" 300 (My_solutions.Bowling.score game));
  ]

let () =
  Alcotest.run "Chapter 08"
    [
      ("store --- хранилище записей", store_tests);
      ("counter --- счётчик на ref", counter_tests);
      ("logger --- логгер", logger_tests);
      ("format_table --- форматирование таблицы", format_table_tests);
      ("array_sum_imperative --- сумма массива", array_sum_tests);
      ("gc_stats", gc_stats_tests);
      ("WeakCache --- кеш на слабых ссылках", weak_cache_tests);
      ("Robot --- уникальные имена", robot_tests);
      ("LRU кеш", lru_tests);
      ("Logger FC/IS", logger_fcis_tests);
      ("Bowling --- боулинг", bowling_tests);
    ]
