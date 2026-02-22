open Diff_generator

let make_line num content = { Diff_types.num; content }

let lcs_tests =
  let open Alcotest in
  [
    test_case "LCS пустых массивов" `Quick (fun () ->
        let old_lines = [||] in
        let new_lines = [||] in
        let table = Lcs.build_lcs_table old_lines new_lines in
        check int "length" 0 table.(0).(0));
    test_case "LCS идентичных файлов" `Quick (fun () ->
        let lines = [| make_line 1 "line1"; make_line 2 "line2" |] in
        let table = Lcs.build_lcs_table lines lines in
        check int "length" 2 table.(2).(2));
    (* TODO: добавьте больше тестов *)
  ]

let diff_tests =
  let open Alcotest in
  [
    test_case "diff идентичных файлов пуст" `Quick (fun () ->
        let lines = [| make_line 1 "same" |] in
        let diff =
          Diff.create_diff ~old_file:"a.txt" ~new_file:"b.txt" ~old_lines:lines
            ~new_lines:lines
        in
        (* TODO: проверить, что hunks содержат только Keep операции *)
        check int "some hunks" 0 (List.length diff.hunks));
    (* TODO: добавьте тесты для:
       - Добавление строк
       - Удаление строк
       - Замена строк
       - Множественные hunks
    *)
  ]

let formatter_tests =
  let open Alcotest in
  [
    test_case "форматирование Keep операции" `Quick (fun () ->
        let op = Diff_types.Keep (make_line 1 "test") in
        let _formatted = Formatter.format_op op in
        (* TODO: проверить формат *)
        ());
    (* TODO: добавьте тесты для Delete, Insert *)
  ]

(* Property-Based тесты *)
module PBT = struct
  open QCheck

  (* Генератор строк файла *)
  let _line_gen =
    Gen.(
      map2
        (fun num content -> { Diff_types.num; content })
        (1 -- 100)
        string)

  (* Свойство: diff(a, a) содержит только Keep операции *)
  let prop_same_files_only_keep =
    Test.make ~name:"same files have only Keep operations" ~count:100
      (list string)
      (fun lines ->
        if lines = [] then true
        else
          let lines_array =
            Array.of_list
              (List.mapi (fun i content -> make_line (i + 1) content) lines)
          in
          let diff =
            Diff.create_diff ~old_file:"a" ~new_file:"b" ~old_lines:lines_array
              ~new_lines:lines_array
          in
          (* Все операции должны быть Keep *)
          List.for_all
            (fun (hunk : Diff_types.hunk) ->
              List.for_all
                (function
                  | Diff_types.Keep _ -> true
                  | _ -> false)
                hunk.ops)
            diff.hunks)

  (* TODO: Свойства:
     - Применение diff к старому файлу даёт новый файл
     - LCS симметричен (длина LCS не зависит от порядка файлов)
     - Размер hunks соответствует количеству операций
  *)

  let all_properties = [ prop_same_files_only_keep ]
end

let () =
  Alcotest.run "Diff Generator"
    [
      ("LCS", lcs_tests);
      ("Diff", diff_tests);
      ("Formatter", formatter_tests);
    ];
  QCheck_base_runner.run_tests_main PBT.all_properties
