(** Форматирование статистики в разных форматах *)

open Stats

(** Форматировать progress bar для одной главы. *)
let format_progress_bar (stats : chapter_stats) ~(width : int) : string =
  let filled = (stats.percentage * width) / 100 in
  let empty = width - filled in
  String.concat "" (List.init filled (fun _ -> "█"))
  ^ String.concat "" (List.init empty (fun _ -> "░"))

(** Форматировать как таблицу (ASCII box-drawing). *)
let format_table (stats : global_stats) : string =
  let buf = Buffer.create 1024 in

  (* Заголовок таблицы *)
  Buffer.add_string buf "┌──────────────┬────────┬────────┬─────────┬──────────┐\n";
  Buffer.add_string buf "│ Глава        │ Всего  │ Сделано│ Осталось│ Прогресс │\n";
  Buffer.add_string buf "├──────────────┼────────┼────────┼─────────┼──────────┤\n";

  (* Строки для каждой главы *)
  List.iter
    (fun ch ->
      let progress_bar = format_progress_bar ch ~width:8 in
      Buffer.add_string buf
        (Printf.sprintf "│ %-12s │ %6d │ %6d │ %7d │ %s │\n" ch.chapter ch.total
           ch.completed ch.pending progress_bar))
    stats.chapters;

  (* Подвал таблицы *)
  Buffer.add_string buf "└──────────────┴────────┴────────┴─────────┴──────────┘\n";
  Buffer.add_string buf
    (Printf.sprintf "\nИТОГО: %d/%d упражнений (%d%%)\n" stats.total_completed
       stats.total_exercises stats.global_percentage);

  Buffer.contents buf

(** Форматировать как JSON. *)
let format_json (stats : global_stats) : string =
  let chapters_json =
    List.map
      (fun ch ->
        Printf.sprintf
          {|{"chapter": "%s", "total": %d, "completed": %d, "pending": %d, "percentage": %d}|}
          ch.chapter ch.total ch.completed ch.pending ch.percentage)
      stats.chapters
    |> String.concat ", "
  in

  Printf.sprintf
    {|{"chapters": [%s], "total": %d, "completed": %d, "pending": %d, "percentage": %d}|}
    chapters_json stats.total_exercises stats.total_completed stats.total_pending
    stats.global_percentage
