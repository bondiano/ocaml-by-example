(** Сканирование директории exercises/ для поиска my_solutions.ml *)

type exercise_file = {
  chapter : string;  (* "chapter02", "appendix_a" *)
  path : string;  (* "exercises/chapter02/test/my_solutions.ml" *)
}

type scan_result = { files : exercise_file list; errors : string list }

(** Найти все my_solutions.ml файлы в директории. *)
let scan_exercises ~(base_dir : string) : scan_result =
  let exercises_dir = Filename.concat base_dir "exercises" in

  if not (Sys.file_exists exercises_dir && Sys.is_directory exercises_dir) then
    { files = []; errors = [ "Директория exercises/ не найдена" ] }
  else
    try
      let entries = Sys.readdir exercises_dir in
      let files, errors =
        Array.fold_left
          (fun (acc_files, acc_errors) entry ->
            (* Проверяем что это chapter* или appendix_* *)
            if
              String.starts_with ~prefix:"chapter" entry
              || String.starts_with ~prefix:"appendix_" entry
            then
              let chapter_dir = Filename.concat exercises_dir entry in
              let solutions_path =
                Filename.concat (Filename.concat chapter_dir "test") "my_solutions.ml"
              in
              if Sys.file_exists solutions_path then
                ({ chapter = entry; path = solutions_path } :: acc_files, acc_errors)
              else
                ( acc_files,
                  ("Файл my_solutions.ml не найден в " ^ entry) :: acc_errors )
            else (acc_files, acc_errors))
          ([], []) entries
      in
      { files = List.rev files; errors = List.rev errors }
    with
    | Sys_error msg -> { files = []; errors = [ "Ошибка чтения директории: " ^ msg ] }
    | e ->
        {
          files = [];
          errors = [ "Неизвестная ошибка: " ^ Printexc.to_string e ];
        }

(** Прочитать содержимое файла. *)
let read_file (path : string) : (string, string) result =
  try
    let ic = open_in path in
    let rec read_lines acc =
      try
        let line = input_line ic in
        read_lines (line :: acc)
      with End_of_file ->
        close_in ic;
        List.rev acc
    in
    let lines = read_lines [] in
    Ok (String.concat "\n" lines)
  with
  | Sys_error msg -> Error msg
  | e -> Error (Printexc.to_string e)
