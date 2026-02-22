(** Интеграционные тесты для OBE CLI *)

open Obe_lib

(* ========== Тесты для Scanner модуля ========== *)

let test_read_file_existing () =
  (* Создаём временный файл *)
  let tmp_file = Filename.temp_file "obe_test" ".ml" in
  let content = "let test = 42" in
  let oc = open_out tmp_file in
  output_string oc content;
  close_out oc;

  match Scanner.read_file tmp_file with
  | Error msg -> Alcotest.fail ("Ошибка чтения файла: " ^ msg)
  | Ok read_content ->
      Alcotest.(check string) "содержимое файла совпадает" content read_content;
      Sys.remove tmp_file

let test_read_file_nonexistent () =
  match Scanner.read_file "/nonexistent/path/file.ml" with
  | Error _ -> Alcotest.(check bool) "ожидается ошибка" true true
  | Ok _ -> Alcotest.fail "должна быть ошибка для несуществующего файла"

(* ========== Тесты для Progress модуля с файлами ========== *)

let test_progress_save_and_load () =
  let tmp_file = Filename.temp_file "obe_progress" ".json" in

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

  (* Сохраняем *)
  (match Progress.save tmp_file progress with
  | Error msg -> Alcotest.fail ("Ошибка сохранения: " ^ msg)
  | Ok () -> ());

  (* Загружаем *)
  (match Progress.load tmp_file with
  | Error msg -> Alcotest.fail ("Ошибка загрузки: " ^ msg)
  | Ok loaded ->
      Alcotest.(check int) "streak сохранён" 1 loaded.current_streak;
      Alcotest.(check int) "total сохранён" 1 loaded.total_exercises_done;
      Alcotest.(check int) "marks сохранены" 1 (List.length loaded.marks));

  Sys.remove tmp_file

let test_progress_load_nonexistent () =
  (* Несуществующий файл должен вернуть пустой прогресс *)
  match Progress.load "/nonexistent/progress.json" with
  | Error _ -> Alcotest.fail "не должно быть ошибки для несуществующего файла"
  | Ok progress ->
      Alcotest.(check int) "пустой прогресс: marks" 0 (List.length progress.marks);
      Alcotest.(check int) "пустой прогресс: streak" 0 progress.current_streak;
      Alcotest.(check int) "пустой прогресс: total" 0 progress.total_exercises_done

(* ========== Тесты для Stats модуля ========== *)

let test_stats_compute_with_files () =
  (* Создаём временные файлы упражнений *)
  let tmp_dir = Filename.temp_file "obe_ex" "" in
  Sys.remove tmp_dir;
  Unix.mkdir tmp_dir 0o755;

  let file1 =
    {
      Scanner.chapter = "chapter01";
      path = Filename.concat tmp_dir "file1.ml";
    }
  in

  let content1 =
    {|
let ex1 = failwith "todo"
let ex2 = failwith "todo"
let ex3 = 42
|}
  in

  let oc = open_out file1.path in
  output_string oc content1;
  close_out oc;

  (* Вычисляем статистику *)
  (match Stats.compute_stats [ file1 ] with
  | Error msg -> Alcotest.fail ("Ошибка вычисления статистики: " ^ msg)
  | Ok stats ->
      Alcotest.(check int) "всего глав" 1 (List.length stats.chapters);
      Alcotest.(check int) "всего упражнений" 3 stats.total_exercises;
      Alcotest.(check int) "завершено" 1 stats.total_completed;
      Alcotest.(check int) "ожидается" 2 stats.total_pending);

  Sys.remove file1.path;
  Unix.rmdir tmp_dir

(* ========== Тесты для Config модуля ========== *)

let test_config_find_project_root () =
  (* Создаём временную структуру директорий *)
  let tmp_root = Filename.temp_file "obe_root" "" in
  Sys.remove tmp_root;
  Unix.mkdir tmp_root 0o755;

  let config_file = Filename.concat tmp_root ".ocaml-by-example.toml" in
  let oc = open_out config_file in
  output_string oc "[project]\n";
  close_out oc;

  (* Создаём поддиректорию *)
  let subdir = Filename.concat tmp_root "subdir" in
  Unix.mkdir subdir 0o755;

  (* Сохраняем текущую директорию *)
  let old_cwd = Sys.getcwd () in

  (* Переходим в поддиректорию *)
  Sys.chdir subdir;

  (* Ищем корень проекта *)
  (match Config.find_project_root () with
  | Error msg -> Alcotest.fail ("Ошибка поиска корня: " ^ msg)
  | Ok root ->
      (* Корень должен указывать на tmp_root *)
      Alcotest.(check bool)
        "найден корень проекта" true
        (String.ends_with ~suffix:(Filename.basename tmp_root) root));

  (* Возвращаемся в исходную директорию *)
  Sys.chdir old_cwd;

  (* Очищаем *)
  Sys.remove config_file;
  Unix.rmdir subdir;
  Unix.rmdir tmp_root

(* ========== Запуск тестов ========== *)

let scanner_tests =
  [
    ("read_file: существующий файл", `Quick, test_read_file_existing);
    ("read_file: несуществующий файл", `Quick, test_read_file_nonexistent);
  ]

let progress_io_tests =
  [
    ("save + load: сохранение и загрузка", `Quick, test_progress_save_and_load);
    ( "load: несуществующий файл = пустой прогресс",
      `Quick,
      test_progress_load_nonexistent );
  ]

let stats_tests =
  [ ("compute_stats: с реальными файлами", `Quick, test_stats_compute_with_files) ]

let config_tests =
  [ ("find_project_root: поиск из поддиректории", `Quick, test_config_find_project_root) ]

let () =
  Alcotest.run "OBE Integration Tests"
    [
      ("Scanner I/O", scanner_tests);
      ("Progress I/O", progress_io_tests);
      ("Stats Integration", stats_tests);
      ("Config Integration", config_tests);
    ]
