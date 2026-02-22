(** Конфигурация проекта из .ocaml-by-example.toml *)

type exercise_info = {
  name : string;
  difficulty : string;
  total_exercises : int;
}

type config = {
  project_root : string;
  exercises_order : string list;
  exercises : (string * exercise_info) list;
  progress_file : string;
  daily_streak_target : int;
  total_target : int;
}

(** Найти корень проекта (директорию с .ocaml-by-example.toml).
    Начинает с текущей директории и идёт вверх. *)
let find_project_root () : (string, string) result =
  let rec go dir =
    let config_path = Filename.concat dir ".ocaml-by-example.toml" in
    if Sys.file_exists config_path then Ok dir
    else
      let parent = Filename.dirname dir in
      (* Проверка что мы не достигли корня файловой системы *)
      if parent = dir then
        Error "Не найден файл .ocaml-by-example.toml в родительских директориях"
      else go parent
  in
  let start_dir = Sys.getcwd () in
  go start_dir

(** Прочитать и распарсить конфиг. *)
let load_config (root : string) : (config, string) result =
  try
    let config_path = Filename.concat root ".ocaml-by-example.toml" in
    let toml_result = Toml.Parser.from_filename config_path in
    let toml =
      match toml_result with
      | `Ok t -> t
      | `Error (msg, _) -> failwith ("Ошибка парсинга TOML: " ^ msg)
    in

    (* Вспомогательные функции для извлечения значений *)
    let get_value path = Toml.Lenses.(get toml (key path)) in

    let get_table path =
      match get_value path with
      | Some (Toml.Types.TTable t) -> Some t
      | _ -> None
    in

    let get_string_from_table tbl key =
      match Toml.Types.Table.find_opt (Toml.Min.key key) tbl with
      | Some (Toml.Types.TString s) -> s
      | _ -> ""
    in

    let get_int_from_table tbl key =
      match Toml.Types.Table.find_opt (Toml.Min.key key) tbl with
      | Some (Toml.Types.TInt i) -> i
      | _ -> 0
    in

    (* Извлекаем exercises table *)
    let exercises_tbl = match get_table "exercises" with
      | Some t -> t
      | None -> failwith "Не найдена секция exercises"
    in

    (* Извлекаем порядок глав из exercises.order *)
    let exercises_order =
      match Toml.Types.Table.find_opt (Toml.Min.key "order") exercises_tbl with
      | Some (Toml.Types.TArray (Toml.Types.NodeString arr)) -> arr
      | _ -> failwith "exercises.order должен быть массивом строк"
    in

    (* Извлекаем информацию о главах *)
    let exercises =
      List.filter_map
        (fun chapter_name ->
          match Toml.Types.Table.find_opt (Toml.Min.key chapter_name) exercises_tbl with
          | Some (Toml.Types.TTable chapter_tbl) ->
              let name =
                let s = get_string_from_table chapter_tbl "name" in
                if s = "" then chapter_name else s
              in
              let difficulty =
                let s = get_string_from_table chapter_tbl "difficulty" in
                if s = "" then "medium" else s
              in
              let total_exercises = get_int_from_table chapter_tbl "total_exercises" in
              Some (chapter_name, { name; difficulty; total_exercises })
          | _ -> None)
        exercises_order
    in

    (* Извлекаем настройки прогресса *)
    let progress_file =
      match get_table "progress" with
      | Some tbl -> (
          let s = get_string_from_table tbl "file" in
          if s = "" then ".obe-progress.json" else s)
      | None -> ".obe-progress.json"
    in

    (* Извлекаем цели *)
    let daily_streak_target, total_target =
      match get_table "goals" with
      | Some tbl ->
          let dst = get_int_from_table tbl "daily_streak_target" in
          let tt = get_int_from_table tbl "total_exercises_target" in
          ((if dst = 0 then 7 else dst), (if tt = 0 then 100 else tt))
      | None -> (7, 100)
    in

    Ok
      {
        project_root = root;
        exercises_order;
        exercises;
        progress_file = Filename.concat root progress_file;
        daily_streak_target;
        total_target;
      }
  with
  | Sys_error msg -> Error ("Ошибка чтения файла: " ^ msg)
  | e -> Error ("Неизвестная ошибка: " ^ Printexc.to_string e)
