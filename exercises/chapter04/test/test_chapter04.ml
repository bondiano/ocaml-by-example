open Chapter04.Address_book

(* ---- Тестовые данные ---- *)

let address_moscow =
  { street = "ул. Пушкина, 10"; city = "Москва"; state = "Москва" }

let address_spb =
  { street = "Невский пр., 28"; city = "Санкт-Петербург"; state = "Санкт-Петербург" }

let ivan =
  { first_name = "Иван"; last_name = "Петров"; address = address_moscow }

let anna =
  { first_name = "Анна"; last_name = "Сидорова"; address = address_spb }

let ivan_dup =
  { first_name = "Иван"; last_name = "Петров"; address = address_spb }

let book =
  empty_book |> insert_entry anna |> insert_entry ivan

let book_with_dup =
  book |> insert_entry ivan_dup

(* ---- Вспомогательные функции для Alcotest ---- *)

let entry_testable : entry Alcotest.testable =
  Alcotest.testable
    (fun fmt e -> Format.fprintf fmt "%s" (show_entry e))
    ( = )

let entry_option_testable : entry option Alcotest.testable =
  Alcotest.option entry_testable

let entry_list_testable : entry list Alcotest.testable =
  Alcotest.list entry_testable

(* ---- Тесты библиотеки (show_address, show_entry, find_entry) ---- *)

let show_address_tests =
  let open Alcotest in
  [
    test_case "форматирует адрес" `Quick (fun () ->
      check string "show_address"
        "ул. Пушкина, 10, Москва, Москва"
        (show_address address_moscow));
    test_case "форматирует другой адрес" `Quick (fun () ->
      check string "show_address spb"
        "Невский пр., 28, Санкт-Петербург, Санкт-Петербург"
        (show_address address_spb));
  ]

let show_entry_tests =
  let open Alcotest in
  [
    test_case "форматирует запись" `Quick (fun () ->
      check string "show_entry"
        "Петров, Иван: ул. Пушкина, 10, Москва, Москва"
        (show_entry ivan));
  ]

let find_entry_tests =
  [
    Alcotest.test_case "находит существующую запись" `Quick (fun () ->
      Alcotest.check entry_option_testable "find_entry Иван Петров"
        (Some ivan)
        (find_entry "Иван" "Петров" book));
    Alcotest.test_case "возвращает None для несуществующей записи" `Quick (fun () ->
      Alcotest.check entry_option_testable "find_entry Пётр Иванов"
        None
        (find_entry "Пётр" "Иванов" book));
  ]

let insert_entry_tests =
  let open Alcotest in
  [
    test_case "добавляет запись в книгу" `Quick (fun () ->
      check int "length after insert" 2 (List.length book));
    test_case "новая запись в начале" `Quick (fun () ->
      check entry_testable "head is ivan"
        ivan (List.hd book));
  ]

(* ---- Тесты упражнений ---- *)

let find_entry_by_street_tests =
  [
    Alcotest.test_case "находит запись по улице" `Quick (fun () ->
      Alcotest.check entry_option_testable "find by Невский"
        (Some anna)
        (My_solutions.find_entry_by_street "Невский пр., 28" book));
    Alcotest.test_case "возвращает None для несуществующей улицы" `Quick (fun () ->
      Alcotest.check entry_option_testable "find by unknown street"
        None
        (My_solutions.find_entry_by_street "ул. Ленина, 1" book));
  ]

let entry_exists_tests =
  let open Alcotest in
  [
    test_case "возвращает true для существующей записи" `Quick (fun () ->
      check bool "exists Анна Сидорова" true
        (My_solutions.entry_exists ~first_name:"Анна" ~last_name:"Сидорова" book));
    test_case "возвращает false для несуществующей записи" `Quick (fun () ->
      check bool "not exists Пётр Иванов" false
        (My_solutions.entry_exists ~first_name:"Пётр" ~last_name:"Иванов" book));
    test_case "работает с именованными аргументами в произвольном порядке" `Quick (fun () ->
      check bool "exists with swapped labels" true
        (My_solutions.entry_exists ~last_name:"Петров" ~first_name:"Иван" book));
  ]

let remove_duplicates_tests =
  [
    Alcotest.test_case "удаляет дубликаты по имени и фамилии" `Quick (fun () ->
      Alcotest.check Alcotest.int "length after dedup"
        2
        (List.length (My_solutions.remove_duplicates book_with_dup)));
    Alcotest.test_case "сохраняет первую запись из дубликатов" `Quick (fun () ->
      let deduped = My_solutions.remove_duplicates book_with_dup in
      (* book_with_dup = [ivan_dup; ivan; anna], первый Иван Петров — ivan_dup *)
      let ivan_entry =
        deduped |> List.find_opt (fun e ->
          e.first_name = "Иван" && e.last_name = "Петров")
      in
      Alcotest.check entry_option_testable "first Ivan is ivan_dup"
        (Some ivan_dup)
        ivan_entry);
    Alcotest.test_case "не меняет книгу без дубликатов" `Quick (fun () ->
      Alcotest.check entry_list_testable "no change"
        book
        (My_solutions.remove_duplicates book));
  ]

let two_fer_tests =
  let open Alcotest in
  [
    test_case "без имени" `Quick (fun () ->
      check string "default" "One for you, one for me."
        (My_solutions.two_fer ()));
    test_case "с именем" `Quick (fun () ->
      check string "alice" "One for Alice, one for me."
        (My_solutions.two_fer ~name:"Alice" ()));
  ]

let grade_school_tests =
  let open Alcotest in
  [
    test_case "add и grade" `Quick (fun () ->
      let school = My_solutions.GradeSchool.empty in
      let school = My_solutions.GradeSchool.add "Иван" 2 school in
      let school = My_solutions.GradeSchool.add "Мария" 2 school in
      let school = My_solutions.GradeSchool.add "Пётр" 3 school in
      check (list string) "grade 2" ["Иван"; "Мария"]
        (My_solutions.GradeSchool.grade 2 school));
    test_case "sorted" `Quick (fun () ->
      let school = My_solutions.GradeSchool.empty in
      let school = My_solutions.GradeSchool.add "Мария" 2 school in
      let school = My_solutions.GradeSchool.add "Иван" 2 school in
      let school = My_solutions.GradeSchool.add "Пётр" 1 school in
      let sorted = My_solutions.GradeSchool.sorted school in
      check int "2 класса" 2 (List.length sorted));
  ]

(* ---- Запуск ---- *)

let () =
  Alcotest.run "Chapter 03"
    [
      ("show_address — форматирование адреса", show_address_tests);
      ("show_entry — форматирование записи", show_entry_tests);
      ("find_entry — поиск по имени", find_entry_tests);
      ("insert_entry — добавление записи", insert_entry_tests);
      ("find_entry_by_street — поиск по улице", find_entry_by_street_tests);
      ("entry_exists — проверка существования", entry_exists_tests);
      ("remove_duplicates — удаление дубликатов", remove_duplicates_tests);
      ("Two-Fer", two_fer_tests);
      ("Grade School — школа", grade_school_tests);
    ]
