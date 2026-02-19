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
    test_case "при московском адресе возвращает строку" `Quick (fun () ->
      check string "show_address"
        "ул. Пушкина, 10, Москва, Москва"
        (show_address address_moscow));
    test_case "при петербургском адресе возвращает строку" `Quick (fun () ->
      check string "show_address"
        "Невский пр., 28, Санкт-Петербург, Санкт-Петербург"
        (show_address address_spb));
  ]

let show_entry_tests =
  let open Alcotest in
  [
    test_case "при записи Иван Петров возвращает строку" `Quick (fun () ->
      check string "show_entry"
        "Петров, Иван: ул. Пушкина, 10, Москва, Москва"
        (show_entry ivan));
  ]

let find_entry_tests =
  [
    Alcotest.test_case "при существующем имени возвращает Some" `Quick (fun () ->
      Alcotest.check entry_option_testable "find_entry"
        (Some ivan)
        (find_entry "Иван" "Петров" book));
    Alcotest.test_case "при несуществующем имени возвращает None" `Quick (fun () ->
      Alcotest.check entry_option_testable "find_entry"
        None
        (find_entry "Пётр" "Иванов" book));
  ]

let insert_entry_tests =
  let open Alcotest in
  [
    test_case "при добавлении записи возвращает книгу длиной 2" `Quick (fun () ->
      check int "length" 2 (List.length book));
    test_case "при добавлении записи возвращает её первой" `Quick (fun () ->
      check entry_testable "head"
        ivan (List.hd book));
  ]

(* ---- Тесты упражнений ---- *)

let find_entry_by_street_tests =
  [
    Alcotest.test_case "при существующей улице возвращает Some" `Quick (fun () ->
      Alcotest.check entry_option_testable "find_entry_by_street"
        (Some anna)
        (My_solutions.find_entry_by_street "Невский пр., 28" book));
    Alcotest.test_case "при несуществующей улице возвращает None" `Quick (fun () ->
      Alcotest.check entry_option_testable "find_entry_by_street"
        None
        (My_solutions.find_entry_by_street "ул. Ленина, 1" book));
  ]

let entry_exists_tests =
  let open Alcotest in
  [
    test_case "при существующей записи возвращает true" `Quick (fun () ->
      check bool "entry_exists" true
        (My_solutions.entry_exists ~first_name:"Анна" ~last_name:"Сидорова" book));
    test_case "при несуществующей записи возвращает false" `Quick (fun () ->
      check bool "entry_exists" false
        (My_solutions.entry_exists ~first_name:"Пётр" ~last_name:"Иванов" book));
    test_case "при перестановке именованных аргументов возвращает true" `Quick (fun () ->
      check bool "entry_exists" true
        (My_solutions.entry_exists ~last_name:"Петров" ~first_name:"Иван" book));
  ]

let remove_duplicates_tests =
  [
    Alcotest.test_case "при наличии дубликатов возвращает список длиной 2" `Quick (fun () ->
      Alcotest.check Alcotest.int "remove_duplicates"
        2
        (List.length (My_solutions.remove_duplicates book_with_dup)));
    Alcotest.test_case "при дубликатах сохраняет первую запись" `Quick (fun () ->
      let deduped = My_solutions.remove_duplicates book_with_dup in
      (* book_with_dup = [ivan_dup; ivan; anna], первый Иван Петров — ivan_dup *)
      let ivan_entry =
        deduped |> List.find_opt (fun e ->
          e.first_name = "Иван" && e.last_name = "Петров")
      in
      Alcotest.check entry_option_testable "remove_duplicates"
        (Some ivan_dup)
        ivan_entry);
    Alcotest.test_case "при отсутствии дубликатов возвращает исходный список" `Quick (fun () ->
      Alcotest.check entry_list_testable "remove_duplicates"
        book
        (My_solutions.remove_duplicates book));
  ]

let two_fer_tests =
  let open Alcotest in
  [
    test_case "при вызове без имени возвращает строку с you" `Quick (fun () ->
      check string "two_fer" "One for you, one for me."
        (My_solutions.two_fer ()));
    test_case "при имени Alice возвращает строку с Alice" `Quick (fun () ->
      check string "two_fer" "One for Alice, one for me."
        (My_solutions.two_fer ~name:"Alice" ()));
  ]

let grade_school_tests =
  let open Alcotest in
  [
    test_case "при добавлении учеников возвращает список класса" `Quick (fun () ->
      let school = My_solutions.GradeSchool.empty in
      let school = My_solutions.GradeSchool.add "Иван" 2 school in
      let school = My_solutions.GradeSchool.add "Мария" 2 school in
      let school = My_solutions.GradeSchool.add "Пётр" 3 school in
      check (list string) "grade" ["Иван"; "Мария"]
        (My_solutions.GradeSchool.grade 2 school));
    test_case "при сортировке возвращает два класса" `Quick (fun () ->
      let school = My_solutions.GradeSchool.empty in
      let school = My_solutions.GradeSchool.add "Мария" 2 school in
      let school = My_solutions.GradeSchool.add "Иван" 2 school in
      let school = My_solutions.GradeSchool.add "Пётр" 1 school in
      let sorted = My_solutions.GradeSchool.sorted school in
      check int "sorted" 2 (List.length sorted));
  ]

(* ---- Запуск ---- *)

let () =
  Alcotest.run "Chapter 04"
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
