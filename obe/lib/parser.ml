(** Парсинг my_solutions.ml для подсчёта упражнений *)

type exercise_info = {
  total : int;  (* всего упражнений *)
  completed : int;  (* выполнено *)
  pending : int;  (* осталось (с failwith "todo") *)
}

(** Подсчитать упражнения в файле. *)
let analyze_file (content : string) : (exercise_info, string) result =
  try
    let lines = String.split_on_char '\n' content in

    (* Регулярные выражения *)
    let let_regexp = Str.regexp "^[ \t]*let[ \t]+" in
    let module_regexp = Str.regexp "^[ \t]*module[ \t]+" in
    let todo_regexp = Str.regexp {|failwith[ \t]*"todo"|} in

    (* Подсчитать определения (let и module) *)
    let total =
      List.fold_left
        (fun count line ->
          if Str.string_match let_regexp line 0 then count + 1
          else if Str.string_match module_regexp line 0 then count + 1
          else count)
        0 lines
    in

    (* Подсчитать TODO (failwith "todo") *)
    let pending =
      List.fold_left
        (fun count line ->
          try
            ignore (Str.search_forward todo_regexp line 0);
            count + 1
          with Not_found -> count)
        0 lines
    in

    let completed = total - pending in

    Ok { total; completed; pending }
  with e -> Error (Printexc.to_string e)

(** Извлечь имена упражнений. *)
let extract_exercise_names (content : string) : string list =
  let lines = String.split_on_char '\n' content in
  let let_regexp = Str.regexp "^[ \t]*let[ \t]+\\([a-z_][a-z0-9_']*\\)" in
  let module_regexp = Str.regexp "^[ \t]*module[ \t]+\\([A-Z][a-zA-Z0-9_]*\\)" in

  List.filter_map
    (fun line ->
      if Str.string_match let_regexp line 0 then Some (Str.matched_group 1 line)
      else if Str.string_match module_regexp line 0 then
        Some (Str.matched_group 1 line)
      else None)
    lines
