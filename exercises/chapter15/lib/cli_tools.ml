(** CLI-утилиты с Cmdliner --- примеры для упражнений. *)

open Cmdliner

(** === Примеры базовых аргументов === *)

(** Позиционный аргумент --- имя файла. *)
let filename_arg =
  Arg.(required & pos 0 (some string) None & info [] ~docv:"FILE")

(** Опциональный флаг --verbose. *)
let verbose_flag =
  Arg.(value & flag & info ["v"; "verbose"] ~doc:"Enable verbose output")

(** Именованный аргумент с значением по умолчанию. *)
let count_arg =
  Arg.(value & opt int 10 & info ["n"; "count"] ~docv:"N" ~doc:"Number of items")

(** === Типы для Todo-менеджера === *)

type todo_item = {
  id : int;
  text : string;
  done_ : bool;
}

(** Хранилище todo в памяти (упрощённо). *)
let todo_storage : todo_item list ref = ref []
let next_id = ref 1

(** Добавить задачу. *)
let add_todo text =
  let item = { id = !next_id; text; done_ = false } in
  todo_storage := item :: !todo_storage;
  incr next_id;
  Printf.printf "Добавлено: [%d] %s\n" item.id text

(** Показать все задачи. *)
let list_todos () =
  match List.rev !todo_storage with
  | [] -> Printf.printf "Нет задач\n"
  | items ->
    List.iter (fun item ->
      let status = if item.done_ then "[x]" else "[ ]" in
      Printf.printf "%s [%d] %s\n" status item.id item.text
    ) items

(** Отметить задачу как выполненную. *)
let mark_done id =
  todo_storage := List.map (fun item ->
    if item.id = id then { item with done_ = true }
    else item
  ) !todo_storage;
  Printf.printf "Задача [%d] отмечена как выполненная\n" id

(** Удалить задачу. *)
let remove_todo id =
  let len_before = List.length !todo_storage in
  todo_storage := List.filter (fun item -> item.id <> id) !todo_storage;
  let len_after = List.length !todo_storage in
  if len_before > len_after then
    Printf.printf "Задача [%d] удалена\n" id
  else
    Printf.printf "Задача [%d] не найдена\n" id
