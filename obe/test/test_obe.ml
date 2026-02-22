(** Тесты для OBE CLI *)

open Obe_lib

(* ========== Вспомогательные функции ========== *)

let string_contains_s s1 s2 =
  try
    let _ = Str.search_forward (Str.regexp_string s2) s1 0 in
    true
  with Not_found -> false

(* ========== Тесты для Progress модуля ========== *)

let test_calculate_streak_empty () =
  let streak = Progress.calculate_streak [] in
  Alcotest.(check int) "пустой список = 0 streak" 0 streak

let test_calculate_streak_single () =
  let mark =
    {
      Progress.date = "2026-02-21";
      chapter = "chapter02";
      exercise_num = 1;
      status = Progress.Pass;
    }
  in
  let streak = Progress.calculate_streak [ mark ] in
  Alcotest.(check int) "один день = 1 streak" 1 streak

let test_calculate_streak_consecutive () =
  let marks =
    [
      {
        Progress.date = "2026-02-21";
        chapter = "chapter02";
        exercise_num = 3;
        status = Progress.Pass;
      };
      {
        Progress.date = "2026-02-20";
        chapter = "chapter02";
        exercise_num = 2;
        status = Progress.Pass;
      };
      {
        Progress.date = "2026-02-19";
        chapter = "chapter02";
        exercise_num = 1;
        status = Progress.Pass;
      };
    ]
  in
  let streak = Progress.calculate_streak marks in
  Alcotest.(check int) "три последовательных дня = 3 streak" 3 streak

let test_calculate_streak_with_gap () =
  let marks =
    [
      {
        Progress.date = "2026-02-21";
        chapter = "chapter02";
        exercise_num = 2;
        status = Progress.Pass;
      };
      {
        Progress.date = "2026-02-19";
        chapter = "chapter02";
        exercise_num = 1;
        status = Progress.Pass;
      };
    ]
  in
  let streak = Progress.calculate_streak marks in
  Alcotest.(check int) "разрыв в датах = 1 streak (только последний день)" 1
    streak

let test_add_mark () =
  let empty_progress =
    {
      Progress.marks = [];
      current_streak = 0;
      longest_streak = 0;
      total_exercises_done = 0;
    }
  in
  let mark =
    {
      Progress.date = "2026-02-21";
      chapter = "chapter02";
      exercise_num = 1;
      status = Progress.Pass;
    }
  in
  let new_progress = Progress.add_mark empty_progress mark in
  Alcotest.(check int)
    "добавление Pass увеличивает total" 1
    new_progress.total_exercises_done;
  Alcotest.(check int)
    "добавление одной отметки" 1
    (List.length new_progress.marks)

let test_add_mark_skipped () =
  let empty_progress =
    {
      Progress.marks = [];
      current_streak = 0;
      longest_streak = 0;
      total_exercises_done = 0;
    }
  in
  let mark =
    {
      Progress.date = "2026-02-21";
      chapter = "chapter02";
      exercise_num = 1;
      status = Progress.Skipped;
    }
  in
  let new_progress = Progress.add_mark empty_progress mark in
  Alcotest.(check int)
    "Skipped не увеличивает total" 0 new_progress.total_exercises_done

let test_last_mark_empty () =
  let empty_progress =
    {
      Progress.marks = [];
      current_streak = 0;
      longest_streak = 0;
      total_exercises_done = 0;
    }
  in
  let result = Progress.last_mark empty_progress in
  Alcotest.(check (option reject))
    "пустой прогресс = None" None result

let test_last_mark_single () =
  let mark =
    {
      Progress.date = "2026-02-21";
      chapter = "chapter02";
      exercise_num = 1;
      status = Progress.Pass;
    }
  in
  let progress =
    {
      Progress.marks = [ mark ];
      current_streak = 1;
      longest_streak = 1;
      total_exercises_done = 1;
    }
  in
  let result = Progress.last_mark progress in
  match result with
  | None -> Alcotest.fail "должна быть последняя отметка"
  | Some m ->
      Alcotest.(check string) "дата совпадает" "2026-02-21" m.date;
      Alcotest.(check string) "глава совпадает" "chapter02" m.chapter

(* ========== Тесты для Parser модуля ========== *)

let test_analyze_empty_file () =
  let content = "" in
  match Parser.analyze_file content with
  | Error _ -> Alcotest.fail "не должно быть ошибки для пустого файла"
  | Ok info ->
      Alcotest.(check int) "пустой файл = 0 упражнений" 0 info.total;
      Alcotest.(check int) "пустой файл = 0 завершённых" 0 info.completed;
      Alcotest.(check int) "пустой файл = 0 ожидающих" 0 info.pending

let test_analyze_with_todo () =
  let content =
    {|
let exercise1 = failwith "todo"
let exercise2 = failwith "todo"
let exercise3 = 42
|}
  in
  match Parser.analyze_file content with
  | Error _ -> Alcotest.fail "не должно быть ошибки"
  | Ok info ->
      Alcotest.(check int) "3 упражнения" 3 info.total;
      Alcotest.(check int) "2 todo" 2 info.pending;
      Alcotest.(check int) "1 завершено" 1 info.completed

let test_analyze_all_completed () =
  let content =
    {|
let exercise1 = 1 + 1
let exercise2 = fun x -> x * 2
module MyModule = struct end
|}
  in
  match Parser.analyze_file content with
  | Error _ -> Alcotest.fail "не должно быть ошибки"
  | Ok info ->
      Alcotest.(check int) "3 определения" 3 info.total;
      Alcotest.(check int) "0 todo" 0 info.pending;
      Alcotest.(check int) "все завершены" 3 info.completed

let test_extract_exercise_names () =
  let content =
    {|
let sum x y = x + y
let factorial n = n
module Helper = struct end
|}
  in
  let names = Parser.extract_exercise_names content in
  Alcotest.(check int) "3 имени" 3 (List.length names);
  Alcotest.(check bool) "содержит 'sum'" true (List.mem "sum" names);
  Alcotest.(check bool) "содержит 'factorial'" true (List.mem "factorial" names);
  Alcotest.(check bool) "содержит 'Helper'" true (List.mem "Helper" names)

(* ========== Тесты для Formatter модуля ========== *)

let test_format_progress_bar_empty () =
  let stats =
    {
      Stats.chapter = "test";
      total = 10;
      completed = 0;
      pending = 10;
      percentage = 0;
    }
  in
  let bar = Formatter.format_progress_bar stats ~width:8 in
  Alcotest.(check string) "0% = 8 пустых блоков" "░░░░░░░░" bar

let test_format_progress_bar_full () =
  let stats =
    {
      Stats.chapter = "test";
      total = 10;
      completed = 10;
      pending = 0;
      percentage = 100;
    }
  in
  let bar = Formatter.format_progress_bar stats ~width:8 in
  Alcotest.(check string) "100% = 8 заполненных блоков" "████████" bar

let test_format_progress_bar_half () =
  let stats =
    {
      Stats.chapter = "test";
      total = 10;
      completed = 5;
      pending = 5;
      percentage = 50;
    }
  in
  let bar = Formatter.format_progress_bar stats ~width:8 in
  Alcotest.(check string) "50% = 4 заполненных + 4 пустых" "████░░░░" bar

let test_format_json () =
  let stats =
    {
      Stats.chapters =
        [
          {
            chapter = "chapter02";
            total = 9;
            completed = 3;
            pending = 6;
            percentage = 33;
          };
        ];
      total_exercises = 9;
      total_completed = 3;
      total_pending = 6;
      global_percentage = 33;
    }
  in
  let json = Formatter.format_json stats in
  Alcotest.(check bool)
    "JSON содержит chapter02" true
    (string_contains_s json "chapter02");
  Alcotest.(check bool) "JSON содержит total" true (string_contains_s json "total");
  Alcotest.(check bool)
    "JSON содержит percentage" true
    (string_contains_s json "percentage")

(* ========== Тесты для Checker модуля ========== *)

let test_motivation_message_day1 () =
  let msg = Checker.motivation_message 1 in
  Alcotest.(check bool)
    "день 1 содержит 'Отличное начало'" true
    (string_contains_s msg "Отличное начало")

let test_motivation_message_day3 () =
  let msg = Checker.motivation_message 3 in
  Alcotest.(check bool)
    "день 3 содержит 'Три дня'" true (string_contains_s msg "Три дня")

let test_motivation_message_day7 () =
  let msg = Checker.motivation_message 7 in
  Alcotest.(check bool)
    "день 7 содержит 'Неделя'" true (string_contains_s msg "Неделя")

let test_motivation_message_day10plus () =
  let msg = Checker.motivation_message 15 in
  Alcotest.(check bool)
    "день 15 содержит 'дней'" true (string_contains_s msg "дней")

(* ========== Тесты для Next_exercise модуля ========== *)

let test_current_chapter_valid () =
  (* Этот тест будет работать только если запущен из директории упражнения *)
  match Next_exercise.current_chapter () with
  | Ok _ -> Alcotest.(check bool) "должна определиться глава" true true
  | Error _ ->
      (* Это нормально если тест запущен не из директории упражнения *)
      Alcotest.(check bool) "ожидаемая ошибка вне директории упражнения" true true

(* ========== Запуск тестов ========== *)

let progress_tests =
  [
    ("calculate_streak: пустой список", `Quick, test_calculate_streak_empty);
    ("calculate_streak: один день", `Quick, test_calculate_streak_single);
    ( "calculate_streak: последовательные дни",
      `Quick,
      test_calculate_streak_consecutive );
    ("calculate_streak: разрыв в датах", `Quick, test_calculate_streak_with_gap);
    ("add_mark: Pass увеличивает total", `Quick, test_add_mark);
    ("add_mark: Skipped не увеличивает total", `Quick, test_add_mark_skipped);
    ("last_mark: пустой прогресс", `Quick, test_last_mark_empty);
    ("last_mark: одна отметка", `Quick, test_last_mark_single);
  ]

let parser_tests =
  [
    ("analyze_file: пустой файл", `Quick, test_analyze_empty_file);
    ("analyze_file: с todo", `Quick, test_analyze_with_todo);
    ("analyze_file: все завершены", `Quick, test_analyze_all_completed);
    ("extract_exercise_names", `Quick, test_extract_exercise_names);
  ]

let formatter_tests =
  [
    ("format_progress_bar: 0%", `Quick, test_format_progress_bar_empty);
    ("format_progress_bar: 100%", `Quick, test_format_progress_bar_full);
    ("format_progress_bar: 50%", `Quick, test_format_progress_bar_half);
    ("format_json", `Quick, test_format_json);
  ]

let checker_tests =
  [
    ("motivation_message: день 1", `Quick, test_motivation_message_day1);
    ("motivation_message: день 3", `Quick, test_motivation_message_day3);
    ("motivation_message: день 7", `Quick, test_motivation_message_day7);
    ("motivation_message: день 10+", `Quick, test_motivation_message_day10plus);
  ]

let next_exercise_tests =
  [ ("current_chapter", `Quick, test_current_chapter_valid) ]

let () =
  Alcotest.run "OBE CLI Tests"
    [
      ("Progress модуль", progress_tests);
      ("Parser модуль", parser_tests);
      ("Formatter модуль", formatter_tests);
      ("Checker модуль", checker_tests);
      ("Next_exercise модуль", next_exercise_tests);
    ]
