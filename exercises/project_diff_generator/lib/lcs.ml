open Diff_types

(* Матрица для динамического программирования *)
type lcs_table = int array array

(* Построить таблицу LCS *)
let build_lcs_table (_old_lines : line array) (_new_lines : line array) : lcs_table =
  let m = Array.length _old_lines in
  let n = Array.length _new_lines in
  let table = Array.make_matrix (m + 1) (n + 1) 0 in

  (* TODO: заполнить таблицу
     Для каждой пары (i, j):
     - Если old_lines[i-1] = new_lines[j-1], то table[i][j] = table[i-1][j-1] + 1
     - Иначе table[i][j] = max(table[i-1][j], table[i][j-1])

     См. GUIDE.md этап 2 для деталей

     Подсказка: используйте вложенные циклы for для заполнения таблицы
  *)
  (* for i = 1 to m do
    for j = 1 to n do
      if line_equal old_lines.(i - 1) new_lines.(j - 1) then
        table.(i).(j) <- table.(i - 1).(j - 1) + 1
      else
        table.(i).(j) <- max table.(i - 1).(j) table.(i).(j - 1)
    done
  done; *)
  table

(* Восстановить последовательность операций из таблицы *)
let backtrack (_table : lcs_table) (_old_lines : line array) (_new_lines : line array)
    : edit_op list =
  (* let m = Array.length old_lines in
  let n = Array.length new_lines in *)

  (* TODO: реализуйте backtracking
     См. GUIDE.md этап 2 для псевдокода

     Базовые случаи:
     - i = 0 и j = 0: вернуть acc
     - i = 0: все оставшиеся строки new_lines — Insert
     - j = 0: все оставшиеся строки old_lines — Delete

     Рекурсивные случаи:
     - Если строки равны: Keep и двигаться диагонально
     - Если table[i-1][j] >= table[i][j-1]: Delete и двигаться вверх
     - Иначе: Insert и двигаться влево

     Подсказка: используйте рекурсивную вспомогательную функцию go
  *)
  (* let rec go i j acc =
    if i = 0 && j = 0 then acc
    else if i = 0 then go 0 (j - 1) (Insert new_lines.(j - 1) :: acc)
    else if j = 0 then go (i - 1) 0 (Delete old_lines.(i - 1) :: acc)
    else if line_equal old_lines.(i - 1) new_lines.(j - 1) then
      go (i - 1) (j - 1) (Keep old_lines.(i - 1) :: acc)
    else if table.(i - 1).(j) >= table.(i).(j - 1) then
      go (i - 1) j (Delete old_lines.(i - 1) :: acc)
    else go i (j - 1) (Insert new_lines.(j - 1) :: acc)
  in
  go m n [] *)
  []
