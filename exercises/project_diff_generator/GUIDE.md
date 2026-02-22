# Проект 3: Генератор дифференциалов (Diff)

## Обзор

Создайте инструмент для сравнения файлов и генерации unified diff, аналогичный `diff -u`. Проект объединяет концепции из глав 08 (Алгоритмы), 15 (Парсинг), и 18 (CLI).

**Время выполнения:** 5-7 часов
**Сложность:** Высокая

## Архитектура

```
lib/
├── diff_types.ml    -- Типы для представления различий
├── lcs.ml           -- Longest Common Subsequence (LCS) алгоритм
├── diff.ml          -- Генерация diff из LCS
└── formatter.ml     -- Форматирование в unified diff

bin/
└── main.ml          -- CLI: diff <file1> <file2>

test/
└── test_diff.ml     -- Тесты + property-based тесты
```

## Что такое diff?

Diff показывает различия между двумя текстовыми файлами:

```diff
--- file1.txt
+++ file2.txt
@@ -1,4 +1,4 @@
 This line is the same
-This line is removed
+This line is added
 This line is also the same
-Another removed line
```

Алгоритм diff основан на поиске Longest Common Subsequence (LCS) — самой длинной подпоследовательности строк, общей для обоих файлов.

## Этап 1: Типы (30 мин)

### Задача
Определите типы для представления различий.

### Файл: `lib/diff_types.ml`

```ocaml
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
```

**TODO:**
1. Добавьте функции для работы с типами:
   - `line_equal : line -> line -> bool` — сравнение строк по содержимому
   - `hunk_size : hunk -> int` — количество операций в hunk

## Этап 2: LCS Алгоритм (90 мин)

### Задача
Реализуйте алгоритм поиска Longest Common Subsequence.

### Файл: `lib/lcs.ml`

LCS — это классическая задача динамического программирования. Для двух последовательностей строк находим самую длинную подпоследовательность, которая встречается в обеих.

```ocaml
open Diff_types

(* Матрица для динамического программирования *)
type lcs_table = int array array

(* Построить таблицу LCS *)
val build_lcs_table : line array -> line array -> lcs_table

(* Восстановить последовательность операций из таблицы *)
val backtrack : lcs_table -> line array -> line array -> edit_op list
```

**Алгоритм построения таблицы:**

```ocaml
let build_lcs_table (old_lines : line array) (new_lines : line array) : lcs_table =
  let m = Array.length old_lines in
  let n = Array.length new_lines in
  let table = Array.make_matrix (m + 1) (n + 1) 0 in

  (* TODO: заполнить таблицу
     Для каждой пары (i, j):
     - Если old_lines[i-1] = new_lines[j-1], то table[i][j] = table[i-1][j-1] + 1
     - Иначе table[i][j] = max(table[i-1][j], table[i][j-1])
  *)
  for i = 1 to m do
    for j = 1 to n do
      (* TODO: реализовать логику *)
      ()
    done
  done;
  table
```

**Backtracking:**

```ocaml
let backtrack (table : lcs_table) (old_lines : line array) (new_lines : line array)
    : edit_op list =
  let m = Array.length old_lines in
  let n = Array.length new_lines in

  let rec go i j acc =
    if i = 0 && j = 0 then acc
    else if i = 0 then
      (* TODO: все оставшиеся строки new_lines — Insert *)
      go 0 (j - 1) (Insert new_lines.(j - 1) :: acc)
    else if j = 0 then
      (* TODO: все оставшиеся строки old_lines — Delete *)
      go (i - 1) 0 (Delete old_lines.(i - 1) :: acc)
    else if line_equal old_lines.(i - 1) new_lines.(j - 1) then
      (* TODO: строки совпадают — Keep *)
      go (i - 1) (j - 1) (Keep old_lines.(i - 1) :: acc)
    else if table.(i - 1).(j) >= table.(i).(j - 1) then
      (* TODO: движемся вверх — Delete *)
      go (i - 1) j (Delete old_lines.(i - 1) :: acc)
    else
      (* TODO: движемся влево — Insert *)
      go i (j - 1) (Insert new_lines.(j - 1) :: acc)
  in
  go m n []
```

**TODO:**
1. Реализуйте `build_lcs_table`
2. Реализуйте `backtrack`
3. Добавьте тесты для LCS

### Подсказка
LCS работает так:
- Таблица `table[i][j]` хранит длину LCS для первых `i` строк старого файла и первых `j` строк нового
- Backtracking идёт от `table[m][n]` к `table[0][0]`, выбирая оптимальный путь

## Этап 3: Генерация Diff (60 мин)

### Задача
Преобразуйте список операций в структурированный diff с hunks.

### Файл: `lib/diff.ml`

```ocaml
open Diff_types

(* Сгруппировать операции в hunks с контекстом *)
val group_into_hunks : edit_op list -> int -> hunk list

(* Создать diff для двух файлов *)
val create_diff : old_file:string -> new_file:string ->
  old_lines:line array -> new_lines:line array -> diff
```

**Группировка в hunks:**

```ocaml
let group_into_hunks (ops : edit_op list) (context_lines : int) : hunk list =
  (* TODO:
     1. Разделить операции на группы (hunks)
     2. Каждый hunk содержит изменения + контекст (N строк до и после)
     3. Если расстояние между изменениями <= 2*context_lines, объединить в один hunk

     Алгоритм:
     - Найти все операции Delete/Insert
     - Для каждой добавить context_lines строк Keep до и после
     - Объединить перекрывающиеся hunks
  *)
  failwith "todo"
```

**Создание diff:**

```ocaml
let create_diff ~old_file ~new_file ~old_lines ~new_lines : diff =
  (* TODO:
     1. Построить таблицу LCS
     2. Сделать backtrack для получения операций
     3. Сгруппировать в hunks
     4. Вернуть полный diff
  *)
  let table = Lcs.build_lcs_table old_lines new_lines in
  let ops = Lcs.backtrack table old_lines new_lines in
  let hunks = group_into_hunks ops 3 in  (* 3 строки контекста *)
  { old_file; new_file; hunks }
```

**TODO:**
1. Реализуйте `group_into_hunks`
2. Реализуйте `create_diff`

## Этап 4: Форматирование (45 мин)

### Задача
Форматируйте diff в unified diff формат.

### Файл: `lib/formatter.ml`

```ocaml
open Diff_types

(* Форматировать операцию *)
let format_op (op : edit_op) : string =
  match op with
  | Keep line -> Printf.sprintf " %s" line.content
  | Delete line -> Printf.sprintf "-%s" line.content
  | Insert line -> Printf.sprintf "+%s" line.content

(* Форматировать hunk *)
let format_hunk (hunk : hunk) : string =
  (* Заголовок: @@ -old_start,old_count +new_start,new_count @@ *)
  let header =
    Printf.sprintf "@@ -%d,%d +%d,%d @@"
      hunk.old_start hunk.old_count hunk.new_start hunk.new_count
  in
  let ops_formatted = List.map format_op hunk.ops in
  String.concat "\n" (header :: ops_formatted)

(* Форматировать полный diff *)
let format_diff (diff : diff) : string =
  (* TODO:
     1. Вывести заголовок: --- old_file / +++ new_file
     2. Вывести все hunks
  *)
  let header =
    Printf.sprintf "--- %s\n+++ %s" diff.old_file diff.new_file
  in
  let hunks_formatted = List.map format_hunk diff.hunks in
  String.concat "\n" (header :: hunks_formatted)
```

**TODO:**
1. Реализуйте `format_diff`
2. Добавьте опции форматирования (цвета для терминала, опционально)

## Этап 5: CLI (30 мин)

### Задача
Создайте интерфейс командной строки.

### Файл: `bin/main.ml`

```ocaml
open Cmdliner
open Diff_generator

let read_lines (filename : string) : Diff_types.line array =
  (* TODO: прочитать файл построчно, пронумеровать строки *)
  let ic = open_in filename in
  let lines = ref [] in
  let num = ref 1 in
  try
    while true do
      let content = input_line ic in
      lines := { Diff_types.num = !num; content } :: !lines;
      incr num
    done;
    [||]  (* never reached *)
  with End_of_file ->
    close_in ic;
    Array.of_list (List.rev !lines)

let diff_cmd =
  let diff file1 file2 context_lines =
    (* TODO:
       1. Прочитать оба файла
       2. Создать diff
       3. Отформатировать и вывести
    *)
    let old_lines = read_lines file1 in
    let new_lines = read_lines file2 in
    let diff = Diff.create_diff ~old_file:file1 ~new_file:file2 ~old_lines ~new_lines in
    let formatted = Formatter.format_diff diff in
    Printf.printf "%s\n" formatted
  in
  let file1_arg = Arg.(required & pos 0 (some file) None & info []) in
  let file2_arg = Arg.(required & pos 1 (some file) None & info []) in
  let context_arg =
    Arg.(value & opt int 3 & info ["u"; "unified"] ~docv:"NUM"
           ~doc:"Context lines (default: 3)")
  in
  let doc = "Compare two files line by line" in
  Cmd.v (Cmd.info "diff" ~doc)
    Term.(const diff $ file1_arg $ file2_arg $ context_arg)

let () =
  let doc = "Diff Generator" in
  exit (Cmd.eval (Cmd.group (Cmd.info "diff-gen" ~doc) [diff_cmd]))
```

**TODO:**
1. Реализуйте `read_lines`
2. Добавьте обработку ошибок (файл не найден, ошибки чтения)
3. Опционально: добавьте флаг `--color` для цветного вывода

## Этап 6: Тестирование (60 мин)

### Задача
Напишите unit-тесты и property-based тесты.

### Файл: `test/test_diff.ml`

```ocaml
open Diff_generator

let lcs_tests =
  let open Alcotest in
  [
    test_case "LCS пустых массивов" `Quick (fun () ->
        let old_lines = [||] in
        let new_lines = [||] in
        let table = Lcs.build_lcs_table old_lines new_lines in
        check int "length" 0 table.(0).(0));

    test_case "LCS идентичных файлов" `Quick (fun () ->
        let lines = [|
          { Diff_types.num = 1; content = "line1" };
          { Diff_types.num = 2; content = "line2" };
        |] in
        let table = Lcs.build_lcs_table lines lines in
        check int "length" 2 table.(2).(2));

    (* TODO: добавьте больше тестов *)
  ]

let diff_tests =
  let open Alcotest in
  [
    test_case "diff идентичных файлов пуст" `Quick (fun () ->
        let lines = [|
          { Diff_types.num = 1; content = "same" };
        |] in
        let diff = Diff.create_diff
          ~old_file:"a.txt" ~new_file:"b.txt"
          ~old_lines:lines ~new_lines:lines
        in
        check int "no hunks" 0 (List.length diff.hunks));

    (* TODO: добавьте тесты для различных сценариев *)
  ]

(* Property-Based тесты *)
module PBT = struct
  open QCheck

  (* Свойство: diff(a, a) всегда пуст *)
  let prop_same_files_no_diff =
    Test.make ~name:"same files have no diff" ~count:100
      (list string)
      (fun lines ->
        let lines_array =
          Array.of_list (List.mapi (fun i content ->
            { Diff_types.num = i + 1; content }
          ) lines)
        in
        let diff = Diff.create_diff
          ~old_file:"a" ~new_file:"b"
          ~old_lines:lines_array ~new_lines:lines_array
        in
        List.for_all (fun hunk ->
          List.for_all (function
            | Diff_types.Keep _ -> true
            | _ -> false
          ) hunk.ops
        ) diff.hunks
      )

  (* TODO: Свойство: применение diff к файлу даёт новый файл *)
  (* TODO: Свойство: LCS симметричен *)

  let all_properties = [ prop_same_files_no_diff ]
end

let () =
  Alcotest.run "Diff Generator"
    [
      ("LCS", lcs_tests);
      ("Diff", diff_tests);
    ];
  QCheck_base_runner.run_tests_main PBT.all_properties
```

**TODO:**
1. Добавьте тесты для всех функций
2. Напишите property: применение diff преобразует старый файл в новый
3. Напишите property: LCS коммутативен (порядок файлов не важен для длины LCS)

## Этап 7: Расширения (опционально, 90+ мин)

### 7.1 Цветной вывод
Используйте ANSI escape codes:
```ocaml
let red s = Printf.sprintf "\027[31m%s\027[0m" s
let green s = Printf.sprintf "\027[32m%s\027[0m" s

let format_op_colored = function
  | Delete line -> red (Printf.sprintf "-%s" line.content)
  | Insert line -> green (Printf.sprintf "+%s" line.content)
  | Keep line -> Printf.sprintf " %s" line.content
```

### 7.2 Patience Diff
Реализуйте более продвинутый алгоритм Patience Diff (используется в Git):
- Найти уникальные строки в обоих файлах
- Построить LCS только для уникальных строк
- Рекурсивно обработать промежутки

### 7.3 Статистика
Добавьте флаг `--stat` для краткой статистики:
```
file1.txt -> file2.txt | 5 ++---
1 file changed, 2 insertions(+), 3 deletions(-)
```

## Примеры использования

### Пример 1: Простое сравнение

**old.txt:**
```
apple
banana
cherry
```

**new.txt:**
```
apple
blueberry
cherry
```

**Вывод:**
```diff
--- old.txt
+++ new.txt
@@ -1,3 +1,3 @@
 apple
-banana
+blueberry
 cherry
```

### Пример 2: Множественные hunks

**old.txt:**
```
line1
line2
line3
...много строк...
line100
line101
```

**new.txt:**
```
line1
modified2
line3
...много строк...
line100
modified101
```

**Вывод:** Два отдельных hunk (если изменения далеко друг от друга)

## Критерии успеха

- [ ] LCS алгоритм реализован корректно
- [ ] Diff корректно показывает добавления/удаления/сохранения
- [ ] Hunks правильно группируются с контекстом
- [ ] Unified diff формат совпадает с `diff -u`
- [ ] CLI работает с файлами
- [ ] Unit-тесты проходят
- [ ] Property-based тесты проходят

## Ресурсы

- [Myers Diff Algorithm](https://blog.jcoglan.com/2017/02/12/the-myers-diff-algorithm-part-1/)
- [Unified Diff Format](https://en.wikipedia.org/wiki/Diff#Unified_format)
- Глава 08: Алгоритмы и структуры данных
- Глава 15: Парсинг
- Глава 18: CLI приложения
