open Cmdliner
open Obe_lib

(** OBE - Единая CLI-утилита для OCaml by Example *)

(* ========== КОМАНДА: obe check ========== *)
let check_cmd =
  let check () =
    Printf.printf "🧪 Проверка текущего упражнения...\n\n";

    match Config.find_project_root () with
    | Error msg ->
        Printf.eprintf "Ошибка: %s\n" msg;
        exit 1
    | Ok root -> (
        match Config.load_config root with
        | Error msg ->
            Printf.eprintf "Ошибка загрузки конфигурации: %s\n" msg;
            exit 1
        | Ok config -> (
            match Progress.load config.progress_file with
            | Error msg ->
                Printf.eprintf "Ошибка загрузки прогресса: %s\n" msg;
                exit 1
            | Ok progress -> (
                match Next_exercise.current_chapter () with
                | Error msg ->
                    Printf.eprintf "Ошибка: %s\n" msg;
                    exit 1
                | Ok chapter -> (
                    (* Запустить тесты *)
                    match Checker.run_tests () with
                    | Checker.Failure output ->
                        Printf.printf "%s\n" output;
                        Printf.printf "\n❌ Тесты не прошли\n";
                        exit 1
                    | Checker.Success output ->
                        Printf.printf "%s\n" output;
                        Printf.printf "\n✅ Все тесты прошли!\n";

                        (* Отметить в прогрессе *)
                        let exercise_num =
                          List.filter
                            (fun m ->
                              m.Progress.chapter = chapter
                              && m.status = Progress.Pass)
                            progress.marks
                          |> List.length
                          |> ( + ) 1
                        in
                        let new_progress =
                          Checker.mark_exercise ~progress ~chapter ~exercise_num
                            ~status:Progress.Pass
                        in

                        (* Сохранить прогресс *)
                        (match Progress.save config.progress_file new_progress with
                        | Error msg -> Printf.eprintf "Предупреждение: не удалось сохранить прогресс: %s\n" msg
                        | Ok () -> ());

                        let today =
                          let tm = Unix.localtime (Unix.time ()) in
                          Printf.sprintf "%04d-%02d-%02d" (tm.tm_year + 1900)
                            (tm.tm_mon + 1) tm.tm_mday
                        in
                        Printf.printf "✓ Отмечено в календаре (%s)\n" today;
                        Printf.printf "%s\n"
                          (Checker.motivation_message new_progress.current_streak)))))
  in
  let doc = "Check current exercise and run tests" in
  Cmd.v (Cmd.info "check" ~doc) Term.(const check $ const ())

(* ========== КОМАНДА: obe progress ========== *)
let progress_cmd =
  let progress format =
    Printf.printf "📊 OCaml by Example — Прогресс упражнений\n";
    Printf.printf "═══════════════════════════════════════════\n\n";

    match Config.find_project_root () with
    | Error msg ->
        Printf.eprintf "Ошибка: %s\n" msg;
        exit 1
    | Ok root ->
        (* Сканировать файлы упражнений *)
        let scan_result = Scanner.scan_exercises ~base_dir:root in

        (* Вывести ошибки, если есть *)
        List.iter
          (fun err -> Printf.eprintf "Предупреждение: %s\n" err)
          scan_result.errors;

        (* Вычислить статистику *)
        (match Stats.compute_stats scan_result.files with
        | Error msg ->
            Printf.eprintf "Ошибка: %s\n" msg;
            exit 1
        | Ok stats -> (
            match format with
            | "table" -> Printf.printf "%s" (Formatter.format_table stats)
            | "json" -> Printf.printf "%s\n" (Formatter.format_json stats)
            | _ ->
                Printf.eprintf "Неизвестный формат: %s\n" format;
                exit 1))
  in
  let format_arg =
    Arg.(
      value
      & opt string "table"
      & info [ "f"; "format" ] ~docv:"FORMAT"
          ~doc:"Output format: table or json")
  in
  let doc = "Show progress across all chapters" in
  Cmd.v (Cmd.info "progress" ~doc) Term.(const progress $ format_arg)

(* ========== КОМАНДА: obe show ========== *)
let show_cmd =
  let show () =
    Printf.printf "📅 OCaml by Example — Calendar\n\n";

    match Config.find_project_root () with
    | Error msg ->
        Printf.eprintf "Ошибка: %s\n" msg;
        exit 1
    | Ok root -> (
        match Config.load_config root with
        | Error msg ->
            Printf.eprintf "Ошибка загрузки конфигурации: %s\n" msg;
            exit 1
        | Ok config -> (
            match Progress.load config.progress_file with
            | Error msg ->
                Printf.eprintf "Ошибка загрузки прогресса: %s\n" msg;
                exit 1
            | Ok progress ->
                (* Показать календарь *)
                Printf.printf "%s\n" (Calendar.format_calendar progress);
                Printf.printf "%s\n" (Calendar.format_stats progress ~config)))
  in
  let doc = "Show progress calendar (streak)" in
  Cmd.v (Cmd.info "show" ~doc) Term.(const show $ const ())

(* ========== КОМАНДА: obe skip ========== *)
let skip_cmd =
  let skip () =
    match Config.find_project_root () with
    | Error msg ->
        Printf.eprintf "Ошибка: %s\n" msg;
        exit 1
    | Ok root -> (
        match Config.load_config root with
        | Error msg ->
            Printf.eprintf "Ошибка загрузки конфигурации: %s\n" msg;
            exit 1
        | Ok config -> (
            match Progress.load config.progress_file with
            | Error msg ->
                Printf.eprintf "Ошибка загрузки прогресса: %s\n" msg;
                exit 1
            | Ok progress -> (
                match Next_exercise.current_chapter () with
                | Error msg ->
                    Printf.eprintf "Ошибка: %s\n" msg;
                    exit 1
                | Ok chapter ->
                    (* Получить номер текущего упражнения *)
                    let exercise_num =
                      List.filter
                        (fun m ->
                          m.Progress.chapter = chapter
                          && (m.status = Progress.Pass
                             || m.status = Progress.Skipped))
                        progress.marks
                      |> List.length
                      |> ( + ) 1
                    in

                    (* Отметить как Skipped *)
                    let new_progress =
                      Checker.mark_exercise ~progress ~chapter ~exercise_num
                        ~status:Progress.Skipped
                    in

                    (* Сохранить прогресс *)
                    (match Progress.save config.progress_file new_progress with
                    | Error msg ->
                        Printf.eprintf
                          "Предупреждение: не удалось сохранить прогресс: %s\n"
                          msg
                    | Ok () -> ());

                    Printf.printf "⏭️  Текущее упражнение пропущено\n";

                    (* Показать следующее упражнение *)
                    (match Next_exercise.find_next config new_progress with
                    | Error _ -> Printf.printf "Все упражнения завершены! 🎉\n"
                    | Ok next_info ->
                        Printf.printf "Следующее: %s (%d/%d)\n" next_info.chapter
                          next_info.exercise_num next_info.total_in_chapter))))
  in
  let doc = "Skip current exercise" in
  Cmd.v (Cmd.info "skip" ~doc) Term.(const skip $ const ())

(* ========== КОМАНДА: obe stats ========== *)
let stats_cmd =
  let stats detailed =
    Printf.printf "📈 Статистика по уровням сложности\n";
    Printf.printf "═══════════════════════════════════\n\n";

    match Config.find_project_root () with
    | Error msg ->
        Printf.eprintf "Ошибка: %s\n" msg;
        exit 1
    | Ok root -> (
        match Config.load_config root with
        | Error msg ->
            Printf.eprintf "Ошибка загрузки конфигурации: %s\n" msg;
            exit 1
        | Ok config ->
            (* Подсчитать упражнения по уровням сложности *)
            let easy, medium, hard =
              List.fold_left
                (fun (e, m, h) (_, info) ->
                  match info.Config.difficulty with
                  | "easy" -> (e + info.Config.total_exercises, m, h)
                  | "medium" -> (e, m + info.Config.total_exercises, h)
                  | "hard" -> (e, m, h + info.Config.total_exercises)
                  | _ -> (e, m, h))
                (0, 0, 0) config.exercises
            in

            Printf.printf "Лёгкое:  %d упражнений\n" easy;
            Printf.printf "Среднее: %d упражнения\n" medium;
            Printf.printf "Сложное: %d упражнений\n\n" hard;
            Printf.printf "Всего: %d упражнений\n" (easy + medium + hard);

            if detailed then begin
              Printf.printf "\nДетальная разбивка:\n";
              List.iter
                (fun (chapter_name, info) ->
                  let difficulty_ru =
                    match info.Config.difficulty with
                    | "easy" -> "Лёгкое"
                    | "medium" -> "Среднее"
                    | "hard" -> "Сложное"
                    | _ -> info.Config.difficulty
                  in
                  Printf.printf "  %s (%s): %d\n" chapter_name difficulty_ru
                    info.Config.total_exercises)
                config.exercises
            end)
  in
  let detailed_arg =
    Arg.(
      value & flag
      & info [ "d"; "detailed" ] ~doc:"Show detailed breakdown by chapter")
  in
  let doc = "Show statistics by difficulty level" in
  Cmd.v (Cmd.info "stats" ~doc) Term.(const stats $ detailed_arg)

(* ========== КОМАНДА: obe reset ========== *)
let reset_cmd =
  let reset chapter_opt confirm =
    if not confirm then begin
      Printf.eprintf "⚠️  Эта операция сбросит все решения!\n";
      Printf.eprintf "Используйте --confirm для подтверждения\n";
      exit 1
    end;

    match Config.find_project_root () with
    | Error msg ->
        Printf.eprintf "Ошибка: %s\n" msg;
        exit 1
    | Ok root ->
        let reset_chapter chapter_name =
          let solutions_path =
            Filename.concat root
              (Filename.concat "exercises"
                 (Filename.concat chapter_name
                    (Filename.concat "test" "my_solutions.ml")))
          in
          let backup_path = solutions_path ^ ".backup" in

          if not (Sys.file_exists solutions_path) then
            Printf.eprintf "Предупреждение: файл %s не найден\n" solutions_path
          else
            try
              (* Создать backup *)
              let content =
                let ic = open_in solutions_path in
                let rec read_all acc =
                  try read_all (input_line ic :: acc)
                  with End_of_file ->
                    close_in ic;
                    List.rev acc
                in
                String.concat "\n" (read_all [])
              in
              let oc = open_out backup_path in
              output_string oc content;
              close_out oc;

              (* Сбросить к failwith "todo" *)
              let oc = open_out solutions_path in
              output_string oc "(* Все решения сброшены к заглушкам *)\n";
              output_string oc "let _ = failwith \"todo\"\n";
              close_out oc;

              Printf.printf "✅ Backup сохранён: %s\n" backup_path;
              Printf.printf "✅ Решения сброшены: %s\n" solutions_path
            with e ->
              Printf.eprintf "Ошибка при сбросе %s: %s\n" chapter_name
                (Printexc.to_string e)
        in

        match chapter_opt with
        | Some chapter ->
            Printf.printf "🧹 Сброс решений для %s...\n" chapter;
            reset_chapter chapter
        | None -> (
            Printf.printf "🧹 Сброс всех решений...\n";
            match Config.load_config root with
            | Error msg ->
                Printf.eprintf "Ошибка загрузки конфигурации: %s\n" msg;
                exit 1
            | Ok config ->
                List.iter (fun (chapter_name, _) -> reset_chapter chapter_name)
                  config.exercises;
                Printf.printf "✅ Все решения сброшены (backup в *.backup)\n")
  in
  let chapter_arg =
    Arg.(
      value & pos 0 (some string) None
      & info [] ~docv:"CHAPTER"
          ~doc:"Chapter to reset (optional, resets all if not specified)")
  in
  let confirm_arg =
    Arg.(value & flag & info [ "y"; "confirm" ] ~doc:"Confirm reset operation")
  in
  let doc = "Reset solutions to stubs (creates backup)" in
  Cmd.v (Cmd.info "reset" ~doc) Term.(const reset $ chapter_arg $ confirm_arg)

(* ========== КОМАНДА: obe test ========== *)
let test_cmd =
  let test chapter_opt =
    match Config.find_project_root () with
    | Error msg ->
        Printf.eprintf "Ошибка: %s\n" msg;
        exit 1
    | Ok root ->
        let run_chapter_test chapter_name =
          let chapter_dir =
            Filename.concat root (Filename.concat "exercises" chapter_name)
          in
          if not (Sys.file_exists chapter_dir) then (
            Printf.eprintf "Ошибка: директория %s не найдена\n" chapter_dir;
            false)
          else
            try
              Printf.printf "🧪 Запуск тестов для %s...\n" chapter_name;
              let cmd = Printf.sprintf "cd %s && dune test 2>&1" chapter_dir in
              let ic = Unix.open_process_in cmd in
              let rec read_output () =
                try
                  let line = input_line ic in
                  Printf.printf "%s\n" line;
                  read_output ()
                with End_of_file -> ()
              in
              read_output ();
              let status = Unix.close_process_in ic in
              match status with
              | Unix.WEXITED 0 ->
                  Printf.printf "✅ Тесты для %s прошли\n\n" chapter_name;
                  true
              | _ ->
                  Printf.printf "❌ Тесты для %s не прошли\n\n" chapter_name;
                  false
            with e ->
              Printf.eprintf "Ошибка при запуске тестов для %s: %s\n"
                chapter_name (Printexc.to_string e);
              false
        in

        (match chapter_opt with
        | Some chapter ->
            let success = run_chapter_test chapter in
            if not success then exit 1
        | None -> (
            Printf.printf "🧪 Запуск всех тестов...\n\n";
            match Config.load_config root with
            | Error msg ->
                Printf.eprintf "Ошибка загрузки конфигурации: %s\n" msg;
                exit 1
            | Ok config ->
                let results =
                  List.map
                    (fun (chapter_name, _) -> run_chapter_test chapter_name)
                    config.exercises
                in
                let total = List.length results in
                let passed = List.filter (fun x -> x) results |> List.length in
                Printf.printf "═══════════════════════════════════\n";
                Printf.printf "Результаты: %d/%d глав прошли тесты\n" passed
                  total;
                if passed < total then exit 1))
  in
  let chapter_arg =
    Arg.(value & pos 0 (some string) None & info [] ~docv:"CHAPTER")
  in
  let doc = "Run tests for a chapter (or all)" in
  Cmd.v (Cmd.info "test" ~doc) Term.(const test $ chapter_arg)

(* ========== ГЛАВНАЯ КОМАНДА ========== *)
let () =
  let doc = "OCaml by Example — Unified CLI Tool" in
  let version = "2.0.0" in
  let man = [
    `S Manpage.s_description;
    `P "Единая утилита для работы с упражнениями OCaml by Example.";
    `P "Объединяет функциональность проверки упражнений, \
        отслеживания прогресса, календаря streak'ов и управления решениями.";
    `S "ПРИМЕРЫ";
    `P "Проверить текущее упражнение:";
    `Pre "  obe check";
    `P "Показать прогресс по всем главам:";
    `Pre "  obe progress";
    `P "Показать календарь streak'ов:";
    `Pre "  obe show";
    `P "Сбросить решения главы:";
    `Pre "  obe reset chapter04 --confirm";
  ] in

  let info = Cmd.info "obe" ~version ~doc ~man in

  let cmds = [
    check_cmd;
    progress_cmd;
    show_cmd;
    skip_cmd;
    stats_cmd;
    reset_cmd;
    test_cmd;
  ] in

  let group_cmd = Cmd.group info cmds in

  exit (Cmd.eval group_cmd)
