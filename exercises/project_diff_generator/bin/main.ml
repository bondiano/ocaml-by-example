open Cmdliner
open Diff_generator

let read_lines (filename : string) : Diff_types.line array =
  (* TODO: реализуйте чтение файла построчно
     См. GUIDE.md этап 5

     Шаги:
     1. Открыть файл: open_in filename
     2. Читать строки в цикле: input_line
     3. Нумеровать строки (начиная с 1)
     4. Обработать End_of_file
     5. Закрыть файл и вернуть массив строк
  *)
  let _ic = open_in filename in
  failwith "todo"

let diff_cmd =
  let diff file1 file2 context_lines =
    (* TODO: реализуйте команду diff
       1. Прочитать оба файла: read_lines
       2. Создать diff: Diff.create_diff
       3. Отформатировать: Formatter.format_diff
       4. Вывести результат
    *)
    Printf.printf "TODO: diff %s %s (context: %d)\n" file1 file2 context_lines;

    try
      let _old_lines = read_lines file1 in
      let _new_lines = read_lines file2 in
      (* TODO: создать и вывести diff *)
      Printf.printf "Diff not implemented yet\n"
    with
    | Sys_error msg ->
        Printf.eprintf "Error: %s\n" msg;
        exit 1
  in
  let file1_arg =
    Arg.(required & pos 0 (some file) None & info [] ~docv:"FILE1")
  in
  let file2_arg =
    Arg.(required & pos 1 (some file) None & info [] ~docv:"FILE2")
  in
  let context_arg =
    Arg.(
      value & opt int 3
      & info [ "u"; "unified" ] ~docv:"NUM"
          ~doc:"Number of context lines (default: 3)")
  in
  let doc = "Compare two files line by line" in
  Cmd.v (Cmd.info "diff" ~doc)
    Term.(const diff $ file1_arg $ file2_arg $ context_arg)

let () =
  let doc = "Diff Generator — compare files line by line" in
  let info = Cmd.info "diff-gen" ~doc ~version:"0.1.0" in
  exit (Cmd.eval (Cmd.group info [ diff_cmd ]))
