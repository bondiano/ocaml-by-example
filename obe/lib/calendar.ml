(** Визуализация календаря прогресса *)

open Progress
open Config

(** Форматировать календарь в GitHub-style. *)
let format_calendar (progress : progress) : string =
  let buf = Buffer.create 512 in

  (* Получить текущую дату *)
  let now = Unix.time () in
  let today_tm = Unix.localtime now in

  (* Получить даты с отметками Pass *)
  let marked_dates =
    List.filter_map
      (fun mark ->
        if mark.status = Progress.Pass then Some mark.date else None)
      progress.marks
    |> List.sort_uniq String.compare
  in

  (* Преобразовать дату в строку YYYY-MM-DD *)
  let date_to_string tm =
    Printf.sprintf "%04d-%02d-%02d" (tm.Unix.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday
  in

  (* Создать массив 7x7 для календаря (7 дней недели x 7 недель) *)
  let grid = Array.make_matrix 7 7 "░" in

  (* Заполнить календарь *)
  for week = 0 to 6 do
    for day = 0 to 6 do
      let days_ago = ((6 - week) * 7) + (6 - day) in
      let timestamp = now -. (float_of_int days_ago *. 86400.0) in
      let tm = Unix.localtime timestamp in
      let date_str = date_to_string tm in
      if List.mem date_str marked_dates then grid.(day).(week) <- "█"
    done
  done;

  (* Получить название месяца и год *)
  let month_names =
    [|
      "Январь";
      "Февраль";
      "Март";
      "Апрель";
      "Май";
      "Июнь";
      "Июль";
      "Август";
      "Сентябрь";
      "Октябрь";
      "Ноябрь";
      "Декабрь";
    |]
  in
  let month_name = month_names.(today_tm.tm_mon) in
  let year = today_tm.tm_year + 1900 in

  Buffer.add_string buf (Printf.sprintf "    %s %d\n" month_name year);

  (* Вывести календарь *)
  let day_names = [| "Пн"; "Вт"; "Ср"; "Чт"; "Пт"; "Сб"; "Вс" |] in
  Array.iteri
    (fun day_idx day_name ->
      Buffer.add_string buf (Printf.sprintf "%s  " day_name);
      Array.iter (fun cell -> Buffer.add_string buf cell) grid.(day_idx);
      Buffer.add_char buf '\n')
    day_names;

  Buffer.contents buf

(** Форматировать статистику. *)
let format_stats (progress : progress) ~(config : config) : string =
  let goal_progress =
    if config.daily_streak_target > 0 then
      (progress.current_streak * 100) / config.daily_streak_target
    else 0
  in

  let total_progress =
    if config.total_target > 0 then
      (progress.total_exercises_done * 100) / config.total_target
    else 0
  in

  Printf.sprintf
    "🔥 Текущая серия: %d дней\n\
     🏆 Лучшая серия: %d дней\n\
     📊 Всего: %d/%d упражнений (%d%%)\n\
     🎯 Цель: %d дней серия (%d%% выполнено)"
    progress.current_streak progress.longest_streak progress.total_exercises_done
    config.total_target total_progress config.daily_streak_target goal_progress
