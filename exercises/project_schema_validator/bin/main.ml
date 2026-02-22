open Cmdliner
open Schema_validator

let validate_cmd =
  let validate schema_file data_file =
    (* TODO:
       1. Прочитать schema_file (JSON со схемой)
       2. Распарсить в Schema.schema (нужна функция parse_schema)
       3. Прочитать data_file (JSON с данными)
       4. Вызвать Validator.validate
       5. Вывести результат

       См. GUIDE.md этап 4 для деталей
    *)
    Printf.printf "TODO: validate %s against %s\n" data_file schema_file;

    (* Подсказка: используйте Yojson.Safe.from_file для чтения *)
    try
      let _schema_json = Yojson.Safe.from_file schema_file in
      let _data_json = Yojson.Safe.from_file data_file in
      (* TODO: распарсить schema_json в Schema.schema *)
      let _ = Schema.from_json in  (* используем модуль чтобы подавить warning *)
      (* TODO: валидировать data_json против схемы *)
      (* TODO: вывести результаты *)
      Printf.printf "Validation not implemented yet\n"
    with
    | Yojson.Json_error msg ->
        Printf.eprintf "JSON parse error: %s\n" msg;
        exit 1
    | Sys_error msg ->
        Printf.eprintf "File error: %s\n" msg;
        exit 1
  in
  let schema_arg =
    Arg.(required & pos 0 (some file) None & info [] ~docv:"SCHEMA_FILE")
  in
  let data_arg =
    Arg.(required & pos 1 (some file) None & info [] ~docv:"DATA_FILE")
  in
  let doc = "Validate JSON data against schema" in
  Cmd.v (Cmd.info "validate" ~doc)
    Term.(const validate $ schema_arg $ data_arg)

let () =
  let doc = "JSON Schema Validator" in
  let info = Cmd.info "schema-validator" ~doc ~version:"0.1.0" in
  exit (Cmd.eval (Cmd.group info [ validate_cmd ]))
