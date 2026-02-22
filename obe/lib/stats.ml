(** Вычисление статистики по упражнениям *)

type chapter_stats = {
  chapter : string;
  total : int;
  completed : int;
  pending : int;
  percentage : int;  (* 0-100 *)
}

type global_stats = {
  chapters : chapter_stats list;
  total_exercises : int;
  total_completed : int;
  total_pending : int;
  global_percentage : int;
}

(** Разбить название главы на компоненты для natural sort. *)
let parse_chapter_name (name : string) : string * int * string =
  (* Извлечь префикс (chapter или appendix_) *)
  let prefix, rest =
    if String.starts_with ~prefix:"chapter" name then
      ("chapter", String.sub name 7 (String.length name - 7))
    else if String.starts_with ~prefix:"appendix_" name then
      ("appendix_", String.sub name 9 (String.length name - 9))
    else ("", name)
  in

  (* Извлечь числовую часть и суффикс (например, "10a" -> 10, "a") *)
  let num_part = ref 0 in
  let suffix_start = ref 0 in
  String.iteri
    (fun i ch ->
      if ch >= '0' && ch <= '9' then (
        num_part := (!num_part * 10) + (Char.code ch - Char.code '0');
        suffix_start := i + 1)
      else ())
    rest;

  let suffix = String.sub rest !suffix_start (String.length rest - !suffix_start) in
  (prefix, !num_part, suffix)

(** Отсортировать главы в естественном порядке. *)
let sort_chapters (chapters : chapter_stats list) : chapter_stats list =
  (* Natural sort: chapter02 < chapter10 < chapter10a < appendix_a *)
  List.sort
    (fun a b ->
      let prefix_a, num_a, suffix_a = parse_chapter_name a.chapter in
      let prefix_b, num_b, suffix_b = parse_chapter_name b.chapter in

      (* Сначала по префиксу (chapter идут перед appendix_) *)
      if prefix_a = "chapter" && prefix_b = "appendix_" then -1
      else if prefix_a = "appendix_" && prefix_b = "chapter" then 1
      else if prefix_a <> prefix_b then String.compare prefix_a prefix_b
      else
        (* Если префиксы одинаковы, сравниваем по номеру *)
        match Int.compare num_a num_b with
        | 0 -> String.compare suffix_a suffix_b (* Затем по суффиксу *)
        | c -> c)
    chapters

(** Собрать статистику из списка файлов. *)
let compute_stats (files : Scanner.exercise_file list) :
    (global_stats, string) result =
  let chapter_results =
    List.filter_map
      (fun (file : Scanner.exercise_file) ->
        match Scanner.read_file file.path with
        | Error _ -> None
        | Ok content -> (
            match Parser.analyze_file content with
            | Error _ -> None
            | Ok info ->
                let percentage =
                  if info.total = 0 then 0
                  else (info.completed * 100) / info.total
                in
                Some
                  {
                    chapter = file.chapter;
                    total = info.total;
                    completed = info.completed;
                    pending = info.pending;
                    percentage;
                  }))
      files
  in

  (* Вычислить глобальную статистику *)
  let total_exercises, total_completed, total_pending =
    List.fold_left
      (fun (tot, compl, pend) ch ->
        (tot + ch.total, compl + ch.completed, pend + ch.pending))
      (0, 0, 0) chapter_results
  in

  let global_percentage =
    if total_exercises = 0 then 0 else (total_completed * 100) / total_exercises
  in

  (* Отсортировать главы в естественном порядке *)
  let sorted_chapters = sort_chapters chapter_results in

  Ok
    {
      chapters = sorted_chapters;
      total_exercises;
      total_completed;
      total_pending;
      global_percentage;
    }
