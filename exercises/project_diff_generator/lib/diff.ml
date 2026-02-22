open Diff_types

(* Сгруппировать операции в hunks с контекстом *)
let group_into_hunks (ops : edit_op list) (context_lines : int) : hunk list =
  (* TODO: реализуйте группировку в hunks
     См. GUIDE.md этап 3 для деталей

     Алгоритм:
     1. Найти все операции Delete/Insert
     2. Для каждой добавить context_lines строк Keep до и после
     3. Объединить перекрывающиеся hunks
     4. Вычислить old_start, old_count, new_start, new_count для каждого hunk

     Подсказка: можно использовать индексы и окна для группировки
  *)
  let _ = context_lines in
  let _ = ops in
  failwith "todo"

(* Создать diff для двух файлов *)
let create_diff ~(old_file : string) ~(new_file : string)
    ~(old_lines : line array) ~(new_lines : line array) : diff =
  (* TODO: реализуйте создание diff
     См. GUIDE.md этап 3

     Шаги:
     1. Построить таблицу LCS: Lcs.build_lcs_table
     2. Сделать backtrack: Lcs.backtrack
     3. Сгруппировать в hunks: group_into_hunks
     4. Вернуть { old_file; new_file; hunks }
  *)
  let _ = old_lines in
  let _ = new_lines in
  { old_file; new_file; hunks = [] }  (* TODO: заменить на реальную реализацию *)
