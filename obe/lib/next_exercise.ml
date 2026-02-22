(** Определение следующего упражнения *)

open Config
open Progress

type next_info = {
  chapter : string;
  exercise_num : int;
  total_in_chapter : int;
  is_chapter_complete : bool;
}

(** Определить следующее незавершённое упражнение. *)
let find_next (config : config) (progress : progress) :
    (next_info, string) result =
  (* Функция для получения информации о главе *)
  let get_chapter_info chapter_name =
    List.find_opt (fun (name, _) -> name = chapter_name) config.exercises
    |> Option.map snd
  in

  (* Функция для подсчёта завершённых упражнений в главе *)
  let count_completed_in_chapter chapter_name =
    List.filter
      (fun mark ->
        mark.Progress.chapter = chapter_name && mark.status = Progress.Pass)
      progress.marks
    |> List.length
  in

  (* Ищем первую главу с незавершёнными упражнениями *)
  let rec find_chapter = function
    | [] -> Error "Все упражнения завершены! 🎉"
    | chapter_name :: rest -> (
        match get_chapter_info chapter_name with
        | None -> find_chapter rest
        | Some chapter_info ->
            let completed = count_completed_in_chapter chapter_name in
            if completed < chapter_info.total_exercises then
              Ok
                {
                  chapter = chapter_name;
                  exercise_num = completed + 1;
                  total_in_chapter = chapter_info.total_exercises;
                  is_chapter_complete = false;
                }
            else find_chapter rest)
  in

  find_chapter config.exercises_order

(** Проверить завершена ли глава полностью. *)
let is_chapter_complete (chapter : string) (progress : progress)
    (config : config) : bool =
  (* Получить информацию о главе *)
  match List.find_opt (fun (name, _) -> name = chapter) config.exercises with
  | None -> false
  | Some (_, chapter_info) ->
      (* Подсчитать упражнения со статусом Pass или Skipped *)
      let completed_count =
        List.filter
          (fun mark ->
            mark.Progress.chapter = chapter
            && (mark.status = Progress.Pass || mark.status = Progress.Skipped))
          progress.marks
        |> List.length
      in
      completed_count >= chapter_info.total_exercises

(** Получить текущую главу из pwd. *)
let current_chapter () : (string, string) result =
  (* 1. Получить текущую рабочую директорию *)
  let cwd = Sys.getcwd () in
  (* 2. Извлечь basename (имя последней компоненты пути) *)
  let basename = Filename.basename cwd in
  (* 3. Проверить что это директория упражнения (chapter или appendix_) *)
  if
    String.starts_with ~prefix:"chapter" basename
    || String.starts_with ~prefix:"appendix_" basename
  then Ok basename
  else Error "Not in an exercise directory"
