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
    test_case "при создании хранилища возвращает count=0" `Quick (fun () ->
      let s = create_store () in
      check int "result" 0 (count s));
    test_case "при добавлении двух записей возвращает корректные id и count" `Quick (fun () ->
      let s = create_store () in
      let r1 = add_record s ~name:"host" ~value:"localhost" in
      let r2 = add_record s ~name:"port" ~value:"8080" in
      check int "r1.id" 1 r1.id;
      check int "r2.id" 2 r2.id;
      check int "count" 2 (count s));
    test_case "при поиске по id=1 возвращает запись, по id=99 — None" `Quick (fun () ->
      let s = create_store () in
      let _ = add_record s ~name:"key" ~value:"val" in
      check (option record_testable) "result"
        (Some { id = 1; name = "key"; value = "val" })
        (find_record s 1);
      check (option record_testable) "result"
        None (find_record s 99));
    test_case "при удалении записи возвращает count=1 и None для удалённой" `Quick (fun () ->
      let s = create_store () in
      let _ = add_record s ~name:"a" ~value:"1" in
      let _ = add_record s ~name:"b" ~value:"2" in
      remove_record s 1;
      check int "result" 1 (count s);
      check (option record_testable) "result"
        None (find_record s 1));
    test_case "при двух записях возвращает their в порядке добавления" `Quick (fun () ->
      let s = create_store () in
      let _ = add_record s ~name:"first" ~value:"1" in
      let _ = add_record s ~name:"second" ~value:"2" in
      let names = all_records s |> List.map (fun r -> r.name) in
      check (list string) "result" ["first"; "second"] names);
    test_case "при id=1 name=\"host\" value=\"localhost\" возвращает \"[1] host = localhost\"" `Quick (fun () ->
      let r = { id = 1; name = "host"; value = "localhost" } in
      check string "result" "[1] host = localhost" (show_record r));
  ]

(* --- Тесты упражнений --- *)

let counter_tests =
  let open Alcotest in
  [
    test_case "при counter_create 0 возвращает 0" `Quick (fun () ->
      let c = My_solutions.counter_create 0 in
      check int "result" 0 (My_solutions.counter_value c));
    test_case "при counter_create 10 возвращает 10" `Quick (fun () ->
      let c = My_solutions.counter_create 10 in
      check int "result" 10 (My_solutions.counter_value c));
    test_case "при трёх increment возвращает 3" `Quick (fun () ->
      let c = My_solutions.counter_create 0 in
      My_solutions.counter_increment c;
      My_solutions.counter_increment c;
      My_solutions.counter_increment c;
      check int "result" 3 (My_solutions.counter_value c));
    test_case "при двух decrement из 5 возвращает 3" `Quick (fun () ->
      let c = My_solutions.counter_create 5 in
      My_solutions.counter_decrement c;
      My_solutions.counter_decrement c;
      check int "result" 3 (My_solutions.counter_value c));
    test_case "при reset после двух increment возвращает 0" `Quick (fun () ->
      let c = My_solutions.counter_create 0 in
      My_solutions.counter_increment c;
      My_solutions.counter_increment c;
      My_solutions.counter_reset c;
      check int "result" 0 (My_solutions.counter_value c));
  ]

let logger_tests =
  let open Alcotest in
  [
    test_case "при создании логгера возвращает count=0" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      check int "result" 0 (My_solutions.logger_count l));
    test_case "при двух сообщениях возвращает их в порядке добавления" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      My_solutions.logger_log l "first";
      My_solutions.logger_log l "second";
      check (list string) "result"
        ["first"; "second"]
        (My_solutions.logger_messages l));
    test_case "при трёх сообщениях возвращает count=3" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      My_solutions.logger_log l "a";
      My_solutions.logger_log l "b";
      My_solutions.logger_log l "c";
      check int "result" 3 (My_solutions.logger_count l));
    test_case "при clear возвращает count=0 и пустой список" `Quick (fun () ->
      let l = My_solutions.logger_create () in
      My_solutions.logger_log l "msg";
      My_solutions.logger_clear l;
      check int "result" 0 (My_solutions.logger_count l);
      check (list string) "result" []
        (My_solutions.logger_messages l));
  ]

let format_table_tests =
  let open Alcotest in
  [
    test_case "при двух строках возвращает две строки с разделителем" `Quick (fun () ->
      let result = My_solutions.format_table
        [("Имя", "Иван"); ("Город", "Москва")] in
      let lines = String.split_on_char '\n' result in
      check int "result" 2 (List.length lines);
      check bool "result" true
        (List.exists (fun l -> String.contains l '|') lines));
    test_case "при одной записи возвращает строку с '|'" `Quick (fun () ->
      let result = My_solutions.format_table
        [("key", "value")] in
      check bool "result" true
        (String.contains result '|'));
    test_case "при пустом списке возвращает \"\"" `Quick (fun () ->
      check string "result" "" (My_solutions.format_table []));
    test_case "при разных длинах ключей возвращает выровненные столбцы" `Quick (fun () ->
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
        check bool "result" true
          (List.for_all (fun x -> x = p) rest));
  ]

let array_sum_tests =
  let open Alcotest in
  [
    test_case "при [|1;2;3;4;5|] возвращает 15" `Quick (fun () ->
      check int "result" 15
        (My_solutions.array_sum_imperative [| 1; 2; 3; 4; 5 |]));
    test_case "при пустом массиве возвращает 0" `Quick (fun () ->
      check int "result" 0
        (My_solutions.array_sum_imperative [| |]));
    test_case "при [|42|] возвращает 42" `Quick (fun () ->
      check int "result" 42
        (My_solutions.array_sum_imperative [| 42 |]));
    test_case "при [|1;-2;3;-4;-1|] возвращает -3" `Quick (fun () ->
      check int "result" (-3)
        (My_solutions.array_sum_imperative [| 1; -2; 3; -4; -1 |]));
  ]

let gc_stats_tests =
  let open Alcotest in
  [
    test_case "при вызове gc_stats возвращает непустую строку" `Quick (fun () ->
      let stats = Chapter09.Records.gc_stats () in
      check bool "result" true
        (String.length stats > 0));
  ]

let weak_cache_tests =
  let open Alcotest in
  let open Chapter09.Records.WeakCache in
  [
    test_case "при set 0 42 и get 0 возвращает Some 42" `Quick (fun () ->
      let cache = create 10 in
      set cache 0 42;
      check (option int) "result" (Some 42) (get cache 0));
    test_case "при get из пустого слота возвращает None" `Quick (fun () ->
      let cache = create 10 in
      check (option int) "result" None (get cache 0));
    test_case "при clear возвращает None для очищенного слота" `Quick (fun () ->
      let cache = create 10 in
      set cache 0 42;
      clear cache;
      check (option int) "result" None (get cache 0));
  ]

let robot_tests =
  let open Alcotest in
  [
    test_case "при create возвращает имя длиной 5" `Quick (fun () ->
      let robot = My_solutions.Robot.create () in
      let name = My_solutions.Robot.name robot in
      check bool "result" true (String.length name = 5));
    test_case "при create первые два символа имени — заглавные буквы" `Quick (fun () ->
      let robot = My_solutions.Robot.create () in
      let name = My_solutions.Robot.name robot in
      check bool "result" true (name.[0] >= 'A' && name.[0] <= 'Z');
      check bool "result" true (name.[1] >= 'A' && name.[1] <= 'Z'));
    test_case "при create последние три символа имени — цифры" `Quick (fun () ->
      let robot = My_solutions.Robot.create () in
      let name = My_solutions.Robot.name robot in
      check bool "result" true (name.[2] >= '0' && name.[2] <= '9');
      check bool "result" true (name.[3] >= '0' && name.[3] <= '9');
      check bool "result" true (name.[4] >= '0' && name.[4] <= '9'));
    test_case "при двух create возвращает разные имена" `Quick (fun () ->
      let r1 = My_solutions.Robot.create () in
      let r2 = My_solutions.Robot.create () in
      check bool "result" true
        (My_solutions.Robot.name r1 <> My_solutions.Robot.name r2));
  ]

let lru_tests =
  let open Alcotest in
  [
    test_case "при put \"a\" 1 и get \"a\" возвращает Some 1" `Quick (fun () ->
      let cache = My_solutions.LRU.create 3 in
      My_solutions.LRU.put cache "a" 1;
      check (option int) "result" (Some 1) (My_solutions.LRU.get cache "a"));
    test_case "при переполнении вытесняет наименее используемый элемент" `Quick (fun () ->
      let cache = My_solutions.LRU.create 2 in
      My_solutions.LRU.put cache "a" 1;
      My_solutions.LRU.put cache "b" 2;
      My_solutions.LRU.put cache "c" 3;
      check (option int) "result" None (My_solutions.LRU.get cache "a");
      check (option int) "result" (Some 3) (My_solutions.LRU.get cache "c"));
    test_case "при двух элементах возвращает size=2" `Quick (fun () ->
      let cache = My_solutions.LRU.create 3 in
      My_solutions.LRU.put cache "a" 1;
      My_solutions.LRU.put cache "b" 2;
      check int "result" 2 (My_solutions.LRU.size cache));
  ]

let logger_fcis_tests =
  let open Alcotest in
  [
    test_case "при LoggerPure.add [] \"hello\" возвращает [\"hello\"]" `Quick (fun () ->
      let msgs = My_solutions.LoggerPure.add [] "hello" in
      check (list string) "result" ["hello"]
        (My_solutions.LoggerPure.messages msgs));
    test_case "при двух добавлениях LoggerPure.count возвращает 2" `Quick (fun () ->
      let msgs = My_solutions.LoggerPure.add
          (My_solutions.LoggerPure.add [] "a") "b" in
      check int "result" 2 (My_solutions.LoggerPure.count msgs));
    test_case "при LoggerShell.log двух сообщений возвращает их в порядке добавления" `Quick (fun () ->
      let l = My_solutions.LoggerShell.create () in
      My_solutions.LoggerShell.log l "first";
      My_solutions.LoggerShell.log l "second";
      check (list string) "result" ["first"; "second"]
        (My_solutions.LoggerShell.messages l));
    test_case "при LoggerShell.clear возвращает count=0" `Quick (fun () ->
      let l = My_solutions.LoggerShell.create () in
      My_solutions.LoggerShell.log l "a";
      My_solutions.LoggerShell.log l "b";
      check int "result" 2 (My_solutions.LoggerShell.count l);
      My_solutions.LoggerShell.clear l;
      check int "result" 0 (My_solutions.LoggerShell.count l));
  ]

let bowling_tests =
  let open Alcotest in
  [
    test_case "при 20 бросках по 0 возвращает score=0" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      for _ = 1 to 20 do
        ignore (My_solutions.Bowling.roll game 0)
      done;
      check int "result" 0 (My_solutions.Bowling.score game));
    test_case "при 20 бросках по 1 возвращает score=20" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      for _ = 1 to 20 do
        ignore (My_solutions.Bowling.roll game 1)
      done;
      check int "result" 20 (My_solutions.Bowling.score game));
    test_case "при spare 5+5 и следующем броске 3 возвращает score=16" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      ignore (My_solutions.Bowling.roll game 5);
      ignore (My_solutions.Bowling.roll game 5);
      ignore (My_solutions.Bowling.roll game 3);
      for _ = 1 to 17 do
        ignore (My_solutions.Bowling.roll game 0)
      done;
      check int "result" 16 (My_solutions.Bowling.score game));
    test_case "при strike и следующих бросках 3+4 возвращает score=24" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      ignore (My_solutions.Bowling.roll game 10);
      ignore (My_solutions.Bowling.roll game 3);
      ignore (My_solutions.Bowling.roll game 4);
      for _ = 1 to 16 do
        ignore (My_solutions.Bowling.roll game 0)
      done;
      check int "result" 24 (My_solutions.Bowling.score game));
    test_case "при 12 страйках возвращает score=300" `Quick (fun () ->
      let game = My_solutions.Bowling.create () in
      for _ = 1 to 12 do
        ignore (My_solutions.Bowling.roll game 10)
      done;
      check int "result" 300 (My_solutions.Bowling.score game));
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
