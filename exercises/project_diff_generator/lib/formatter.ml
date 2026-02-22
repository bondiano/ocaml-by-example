open Diff_types

(* Форматировать операцию *)
let format_op (op : edit_op) : string =
  (* TODO: реализуйте форматирование операций
     См. GUIDE.md этап 4

     Keep: " <content>"
     Delete: "-<content>"
     Insert: "+<content>"
  *)
  match op with
  | Keep _line -> failwith "todo"
  | Delete _line -> failwith "todo"
  | Insert _line -> failwith "todo"

(* Форматировать hunk *)
let format_hunk (hunk : hunk) : string =
  (* TODO: реализуйте форматирование hunk
     Формат:
     @@ -old_start,old_count +new_start,new_count @@
     <операции>

     Пример:
     @@ -1,3 +1,3 @@
      line1
     -line2
     +line2_modified
      line3
  *)
  let _header =
    Printf.sprintf "@@ -%d,%d +%d,%d @@" hunk.old_start hunk.old_count
      hunk.new_start hunk.new_count
  in
  let _ops_formatted = List.map format_op hunk.ops in
  failwith "todo"

(* Форматировать полный diff *)
let format_diff (diff : diff) : string =
  (* TODO: реализуйте форматирование diff
     Формат:
     --- <old_file>
     +++ <new_file>
     <hunks>

     Пример:
     --- file1.txt
     +++ file2.txt
     @@ -1,3 +1,3 @@
      line1
     -line2
     +line2_modified
      line3
  *)
  let _header = Printf.sprintf "--- %s\n+++ %s" diff.old_file diff.new_file in
  let _hunks_formatted = List.map format_hunk diff.hunks in
  failwith "todo"
