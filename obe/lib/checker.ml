(** Запуск тестов и отметка результата *)

open Progress

type check_result = Success of string | Failure of string

(** Запустить тесты в текущей директории. *)
let run_tests () : check_result =
  try
    let cmd = "dune test 2>&1" in
    let ic = Unix.open_process_in cmd in
    let rec read_output acc =
      try
        let line = input_line ic in
        read_output (line :: acc)
      with End_of_file -> List.rev acc
    in
    let output_lines = read_output [] in
    let output = String.concat "\n" output_lines in
    let status = Unix.close_process_in ic in

    match status with
    | Unix.WEXITED 0 -> Success output
    | Unix.WEXITED _ -> Failure output
    | Unix.WSIGNALED _ -> Failure "Процесс был убит сигналом"
    | Unix.WSTOPPED _ -> Failure "Процесс был остановлен"
  with
  | Sys_error msg -> Failure ("Ошибка запуска тестов: " ^ msg)
  | e -> Failure ("Неизвестная ошибка: " ^ Printexc.to_string e)

(** Отметить упражнение в прогрессе. *)
let mark_exercise ~(progress : progress) ~(chapter : string)
    ~(exercise_num : int) ~(status : mark_status) : progress =
  (* Получить текущую дату в формате YYYY-MM-DD *)
  let today =
    let tm = Unix.localtime (Unix.time ()) in
    Printf.sprintf "%04d-%02d-%02d" (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday
  in
  let mark = { date = today; chapter; exercise_num; status } in
  Progress.add_mark progress mark

(** Мотивационное сообщение в зависимости от streak. *)
let motivation_message (streak : int) : string =
  match streak with
  | 1 -> "🌟 Отличное начало!"
  | 2 -> "💪 Второй день подряд!"
  | 3 -> "🔥 Три дня подряд! Так держать!"
  | 5 -> "🚀 5 дней подряд! Вы на огне!"
  | 7 -> "🏆 Неделя подряд! Невероятно!"
  | n when n >= 10 -> "👑 " ^ string_of_int n ^ " дней! Вы легенда!"
  | _ -> "✅ Отлично!"
