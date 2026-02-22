(* Строка файла с номером *)
type line = { num : int; content : string }

(* Операция редактирования *)
type edit_op =
  | Keep of line      (* Строка без изменений *)
  | Insert of line    (* Добавленная строка *)
  | Delete of line    (* Удалённая строка *)

(* Hunk — непрерывный блок изменений *)
type hunk = {
  old_start : int;  (* Начальная строка в старом файле *)
  old_count : int;  (* Количество строк в старом файле *)
  new_start : int;  (* Начальная строка в новом файле *)
  new_count : int;  (* Количество строк в новом файле *)
  ops : edit_op list;
}

(* Полный diff между двумя файлами *)
type diff = {
  old_file : string;   (* Имя старого файла *)
  new_file : string;   (* Имя нового файла *)
  hunks : hunk list;
}

(* Сравнение строк по содержимому *)
let line_equal (_l1 : line) (_l2 : line) : bool =
  (* TODO: реализуйте сравнение строк
     См. GUIDE.md этап 1 *)
  failwith "todo"

(* Размер hunk (количество операций) *)
let hunk_size (_hunk : hunk) : int =
  (* TODO: вернуть количество операций в hunk *)
  failwith "todo"
