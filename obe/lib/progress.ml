(** Работа с прогрессом в .obe-progress.json *)

type mark_status = Pass | Fail | Skipped

type mark = {
  date : string;
  chapter : string;
  exercise_num : int;
  status : mark_status;
}

type progress = {
  marks : mark list;
  current_streak : int;
  longest_streak : int;
  total_exercises_done : int;
}

(** Загрузить прогресс из JSON файла. *)
let load (file_path : string) : (progress, string) result =
  try
    if not (Sys.file_exists file_path) then
      (* Если файл не существует, вернуть пустой прогресс *)
      Ok
        {
          marks = [];
          current_streak = 0;
          longest_streak = 0;
          total_exercises_done = 0;
        }
    else
      let open Yojson.Basic.Util in
      let json = Yojson.Basic.from_file file_path in

      let marks =
        json |> member "marks" |> to_list
        |> List.map (fun mark_json ->
               let date = mark_json |> member "date" |> to_string in
               let chapter = mark_json |> member "chapter" |> to_string in
               let exercise_num = mark_json |> member "exercise_num" |> to_int in
               let status_str = mark_json |> member "status" |> to_string in
               let status =
                 match status_str with
                 | "Pass" -> Pass
                 | "Fail" -> Fail
                 | "Skipped" -> Skipped
                 | _ -> Pass
               in
               { date; chapter; exercise_num; status })
      in

      let current_streak = json |> member "current_streak" |> to_int in
      let longest_streak = json |> member "longest_streak" |> to_int in
      let total_exercises_done = json |> member "total_exercises_done" |> to_int in

      Ok { marks; current_streak; longest_streak; total_exercises_done }
  with
  | Sys_error msg -> Error ("Ошибка чтения файла: " ^ msg)
  | Yojson.Json_error msg -> Error ("Ошибка парсинга JSON: " ^ msg)
  | e -> Error ("Неизвестная ошибка: " ^ Printexc.to_string e)

(** Сохранить прогресс в JSON файл. *)
let save (path : string) (progress : progress) : (unit, string) result =
  try
    let status_to_string = function
      | Pass -> "Pass"
      | Fail -> "Fail"
      | Skipped -> "Skipped"
    in

    let marks_json =
      `List
        (List.map
           (fun mark ->
             `Assoc
               [
                 ("date", `String mark.date);
                 ("chapter", `String mark.chapter);
                 ("exercise_num", `Int mark.exercise_num);
                 ("status", `String (status_to_string mark.status));
               ])
           progress.marks)
    in

    let json =
      `Assoc
        [
          ("marks", marks_json);
          ("current_streak", `Int progress.current_streak);
          ("longest_streak", `Int progress.longest_streak);
          ("total_exercises_done", `Int progress.total_exercises_done);
        ]
    in

    Yojson.Basic.to_file path json;
    Ok ()
  with
  | Sys_error msg -> Error ("Ошибка записи файла: " ^ msg)
  | e -> Error ("Неизвестная ошибка: " ^ Printexc.to_string e)

(** Определить текущий streak (сколько дней подряд). *)
let calculate_streak (marks : mark list) : int =
  if marks = [] then 0
  else
    (* Получить уникальные даты *)
    let dates =
      List.sort_uniq String.compare
        (List.filter_map
           (fun mark -> if mark.status = Pass then Some mark.date else None)
           marks)
    in
    (* Отсортировать от новых к старым *)
    let sorted_dates = List.rev dates in

    (* Функция для парсинга даты "YYYY-MM-DD" в Unix timestamp *)
    let parse_date date_str =
      try
        Scanf.sscanf date_str "%d-%d-%d" (fun y m d ->
            let tm =
              {
                Unix.tm_sec = 0;
                tm_min = 0;
                tm_hour = 12;
                tm_mday = d;
                tm_mon = m - 1;
                tm_year = y - 1900;
                tm_wday = 0;
                tm_yday = 0;
                tm_isdst = false;
              }
            in
            fst (Unix.mktime tm))
      with _ -> 0.0
    in

    (* Подсчитать последовательные дни *)
    let rec count_streak acc prev_timestamp = function
      | [] -> acc
      | date :: rest ->
          let curr_timestamp = parse_date date in
          if prev_timestamp = 0.0 then
            (* Первая дата *)
            count_streak 1 curr_timestamp rest
          else
            let diff_days =
              int_of_float ((prev_timestamp -. curr_timestamp) /. 86400.0)
            in
            if diff_days = 1 then
              (* Последовательный день *)
              count_streak (acc + 1) curr_timestamp rest
            else
              (* Разрыв в последовательности *)
              acc
    in

    count_streak 0 0.0 sorted_dates

(** Добавить новую отметку и обновить streak. *)
let add_mark (progress : progress) (mark : mark) : progress =
  let new_marks = mark :: progress.marks in
  let new_streak = calculate_streak new_marks in
  let new_longest_streak = max new_streak progress.longest_streak in
  let new_total =
    if mark.status = Pass then progress.total_exercises_done + 1
    else progress.total_exercises_done
  in
  {
    marks = new_marks;
    current_streak = new_streak;
    longest_streak = new_longest_streak;
    total_exercises_done = new_total;
  }

(** Получить последнюю отметку. *)
let last_mark (progress : progress) : mark option =
  match progress.marks with
  | [] -> None
  | latest :: _ -> Some latest
