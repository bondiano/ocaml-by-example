open Chapter07.Hashable

(* --- Тесты библиотеки --- *)

let hash_tests =
  let open Alcotest in
  [
    test_case "при x=42 возвращает 42" `Quick (fun () ->
      check int "hash" 42 (IntHash.hash 42));
    test_case "при непустой строке возвращает ненулевой хэш" `Quick (fun () ->
      check bool "result" true
        (StringHash.hash "hello" <> 0));
    test_case "при одинаковых строках возвращает одинаковый хэш" `Quick (fun () ->
      check int "result"
        (StringHash.hash "test") (StringHash.hash "test"));
  ]

let hashset_tests =
  let module HS = MakeHashSet(IntHash) in
  let open Alcotest in
  [
    test_case "при пустом HashSet возвращает false для mem" `Quick (fun () ->
      check bool "result" false (HS.mem 1 HS.empty));
    test_case "при добавлении 42 возвращает true для mem 42" `Quick (fun () ->
      let s = HS.add 42 HS.empty in
      check bool "result" true (HS.mem 42 s));
    test_case "при отсутствующем элементе возвращает false" `Quick (fun () ->
      let s = HS.add 42 HS.empty in
      check bool "result" false (HS.mem 99 s));
  ]

let pair_hash_tests =
  let module PH = PairHash(IntHash)(StringHash) in
  let open Alcotest in
  [
    test_case "при паре (1, \"hello\") возвращает ненулевой хэш" `Quick (fun () ->
      check bool "result" true
        (PH.hash (1, "hello") <> 0));
    test_case "при разных парах возвращает разные хэши" `Quick (fun () ->
      check bool "result"
        true
        (PH.hash (1, "a") <> PH.hash (2, "b")));
  ]

(* --- Тесты упражнений --- *)

let int_set_tests =
  let open Alcotest in
  [
    test_case "при пустом множестве возвращает []" `Quick (fun () ->
      check (list int) "result" []
        (My_solutions.IntSet.elements My_solutions.IntSet.empty));
    test_case "при добавлении [3;1;4;1] возвращает [1;3;4]" `Quick (fun () ->
      let s =
        My_solutions.IntSet.empty
        |> My_solutions.IntSet.add 3
        |> My_solutions.IntSet.add 1
        |> My_solutions.IntSet.add 4
        |> My_solutions.IntSet.add 1
      in
      check (list int) "result" [1; 3; 4]
        (My_solutions.IntSet.elements s));
    test_case "при наличии элемента 5 возвращает true" `Quick (fun () ->
      let s =
        My_solutions.IntSet.empty
        |> My_solutions.IntSet.add 5
        |> My_solutions.IntSet.add 3
      in
      check bool "result" true (My_solutions.IntSet.mem 5 s));
    test_case "при отсутствии элемента 3 возвращает false" `Quick (fun () ->
      let s = My_solutions.IntSet.add 5 My_solutions.IntSet.empty in
      check bool "result" false (My_solutions.IntSet.mem 3 s));
    test_case "при трёх уникальных элементах возвращает 3" `Quick (fun () ->
      let s =
        My_solutions.IntSet.empty
        |> My_solutions.IntSet.add 1
        |> My_solutions.IntSet.add 2
        |> My_solutions.IntSet.add 3
      in
      check int "result" 3 (My_solutions.IntSet.size s));
  ]

let make_set_tests =
  let module SSet = My_solutions.MakeSet(String) in
  let open Alcotest in
  [
    test_case "при добавлении [\"banana\";\"apple\";\"cherry\";\"apple\"] возвращает отсортированный список" `Quick (fun () ->
      let s =
        SSet.empty
        |> SSet.add "banana"
        |> SSet.add "apple"
        |> SSet.add "cherry"
        |> SSet.add "apple"
      in
      check (list string) "result"
        ["apple"; "banana"; "cherry"]
        (SSet.elements s));
    test_case "при поиске существующей строки возвращает true, несуществующей — false" `Quick (fun () ->
      let s = SSet.add "hello" SSet.empty in
      check bool "result" true (SSet.mem "hello" s);
      check bool "result" false (SSet.mem "world" s));
  ]

let max_element_tests =
  let open Alcotest in
  [
    test_case "при [3;1;4;1;5] возвращает Some 5" `Quick (fun () ->
      check (option int) "result"
        (Some 5)
        (My_solutions.max_element (module Int) [3; 1; 4; 1; 5]));
    test_case "при [\"banana\";\"apple\";\"cherry\"] возвращает Some \"cherry\"" `Quick (fun () ->
      check (option string) "result"
        (Some "cherry")
        (My_solutions.max_element (module String)
           ["banana"; "apple"; "cherry"]));
    test_case "при пустом списке возвращает None" `Quick (fun () ->
      check (option int) "result"
        None
        (My_solutions.max_element (module Int) []));
  ]

let extended_set_tests =
  let open Alcotest in
  let module E = My_solutions.ExtendedIntSet in
  [
    test_case "при union {1;3} и {2;3;4} возвращает [1;2;3;4]" `Quick (fun () ->
      let s1 = E.empty |> E.add 1 |> E.add 3 in
      let s2 = E.empty |> E.add 2 |> E.add 3 |> E.add 4 in
      check (list int) "result"
        [1; 2; 3; 4]
        (E.elements (E.union s1 s2)));
    test_case "при inter {1;2;3} и {2;3;4} возвращает [2;3]" `Quick (fun () ->
      let s1 = E.empty |> E.add 1 |> E.add 2 |> E.add 3 in
      let s2 = E.empty |> E.add 2 |> E.add 3 |> E.add 4 in
      check (list int) "result"
        [2; 3]
        (E.elements (E.inter s1 s2)));
    test_case "при union {1;2} и {2;3} возвращает size=3" `Quick (fun () ->
      let s1 = E.empty |> E.add 1 |> E.add 2 in
      let s2 = E.empty |> E.add 2 |> E.add 3 in
      check int "result" 3 (E.size (E.union s1 s2)));
  ]

let user_tests =
  let open Alcotest in
  let open Chapter07.Hashable.User in
  [
    test_case "при name=\"Иван\" age=25 возвращает корректные поля" `Quick (fun () ->
      let u = make ~name:"Иван" ~age:25 in
      check string "name" "Иван" (name u);
      check int "age" 25 (age u));
    test_case "при name=\"Иван\" age=25 возвращает \"Иван (age 25)\"" `Quick (fun () ->
      let u = make ~name:"Иван" ~age:25 in
      check string "result" "Иван (age 25)" (to_string u));
    test_case "при age=-1 бросает Invalid_argument" `Quick (fun () ->
      check_raises "result" (Invalid_argument "User.make: age must be non-negative")
        (fun () -> ignore (make ~name:"X" ~age:(-1))));
  ]

let io_agnostic_tests =
  let open Alcotest in
  let open Chapter07.Hashable in
  [
    test_case "при \"hello\" возвращает \"processed: HELLO\"" `Quick (fun () ->
      check string "result" "processed: HELLO"
        (Sync_service.process "hello"));
    test_case "при [\"a\";\"b\"] возвращает [\"processed: A\";\"processed: B\"]" `Quick (fun () ->
      check (list string) "result"
        ["processed: A"; "processed: B"]
        (Sync_service.process_all ["a"; "b"]));
  ]

module TestCustomSet = My_solutions.MakeCustomSet(Int)

let custom_set_tests =
  let open Alcotest in
  [
    test_case "при пустом множестве возвращает true для is_empty" `Quick (fun () ->
      check bool "result" true (TestCustomSet.is_empty TestCustomSet.empty));
    test_case "при добавлении 1 и 2 возвращает true для mem, false для 3" `Quick (fun () ->
      let s = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      check bool "mem 1" true (TestCustomSet.mem 1 s);
      check bool "mem 2" true (TestCustomSet.mem 2 s);
      check bool "mem 3" false (TestCustomSet.mem 3 s));
    test_case "при добавлении [3;1;2] возвращает [1;2;3]" `Quick (fun () ->
      let s = TestCustomSet.add 3 (TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty)) in
      check (list int) "result" [1; 2; 3] (TestCustomSet.elements s));
    test_case "при добавлении дубликатов возвращает size=2" `Quick (fun () ->
      let s = TestCustomSet.add 1 (TestCustomSet.add 2 (TestCustomSet.add 1 TestCustomSet.empty)) in
      check int "result" 2 (TestCustomSet.size s));
    test_case "при union {1;2} и {2;3} возвращает [1;2;3]" `Quick (fun () ->
      let s1 = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      let s2 = TestCustomSet.add 2 (TestCustomSet.add 3 TestCustomSet.empty) in
      check (list int) "result" [1; 2; 3] (TestCustomSet.elements (TestCustomSet.union s1 s2)));
    test_case "при inter {1;2} и {2;3} возвращает [2]" `Quick (fun () ->
      let s1 = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      let s2 = TestCustomSet.add 2 (TestCustomSet.add 3 TestCustomSet.empty) in
      check (list int) "result" [2] (TestCustomSet.elements (TestCustomSet.inter s1 s2)));
    test_case "при remove 1 из {1;2} возвращает [2]" `Quick (fun () ->
      let s = TestCustomSet.add 1 (TestCustomSet.add 2 TestCustomSet.empty) in
      let s = TestCustomSet.remove 1 s in
      check (list int) "result" [2] (TestCustomSet.elements s));
  ]

let monoid_lib_tests =
  let open Alcotest in
  let open Chapter07.Monoid in
  [
    test_case "при [1;2;3;4] через IntSumMonoid возвращает 10" `Quick (fun () ->
      check int "result" 10
        (concat_all (module IntSumMonoid) [1; 2; 3; 4]));
    test_case "при [1;2;3;4] через IntProductMonoid возвращает 24" `Quick (fun () ->
      check int "result" 24
        (concat_all (module IntProductMonoid) [1; 2; 3; 4]));
    test_case "при [\"hello\";\" \";\"world\"] через StringMonoid возвращает \"hello world\"" `Quick (fun () ->
      check string "result" "hello world"
        (concat_all (module StringMonoid) ["hello"; " "; "world"]));
    test_case "при пустом списке возвращает 0" `Quick (fun () ->
      check int "result" 0
        (concat_all (module IntSumMonoid) []));
    test_case "при Some 2 и Some 3 возвращает Some 5" `Quick (fun () ->
      let module OM = OptionMonoid(struct
        type t = int
        let combine = ( + )
      end) in
      check (option int) "some+some" (Some 5)
        (OM.combine (Some 2) (Some 3));
      check (option int) "none+some" (Some 3)
        (OM.combine None (Some 3));
      check (option int) "some+none" (Some 2)
        (OM.combine (Some 2) None);
      check (option int) "none+none" None
        (OM.combine None None));
  ]

let first_semigroup_tests =
  let open Alcotest in
  [
    test_case "при combine \"a\" \"b\" возвращает \"a\"" `Quick (fun () ->
      check string "result" "a"
        (My_solutions.First.combine "a" "b"));
    test_case "при [None;Some \"a\";Some \"b\";None] возвращает Some \"a\"" `Quick (fun () ->
      let module OM = Chapter07.Monoid.OptionMonoid(My_solutions.First) in
      check (option string) "result"
        (Some "a")
        (Chapter07.Monoid.concat_all (module OM)
           [None; Some "a"; Some "b"; None]));
    test_case "при [None;None;None] возвращает None" `Quick (fun () ->
      let module OM = Chapter07.Monoid.OptionMonoid(My_solutions.First) in
      check (option string) "result"
        None
        (Chapter07.Monoid.concat_all (module OM) [None; None; None]));
  ]

let concat_all_tests =
  let open Alcotest in
  [
    test_case "при [1;2;3;4;5] через IntSumMonoid возвращает 15" `Quick (fun () ->
      check int "result" 15
        (My_solutions.concat_all
           (module Chapter07.Monoid.IntSumMonoid) [1; 2; 3; 4; 5]));
    test_case "при [\"a\";\"b\";\"c\"] через StringMonoid возвращает \"abc\"" `Quick (fun () ->
      check string "result" "abc"
        (My_solutions.concat_all
           (module Chapter07.Monoid.StringMonoid) ["a"; "b"; "c"]));
    test_case "при пустом списке возвращает 0" `Quick (fun () ->
      check int "result" 0
        (My_solutions.concat_all (module Chapter07.Monoid.IntSumMonoid) []));
  ]

let () =
  Alcotest.run "Chapter 06"
    [
      ("hash --- хэширование", hash_tests);
      ("MakeHashSet --- хэш-множество", hashset_tests);
      ("PairHash --- хэш пары", pair_hash_tests);
      ("IntSet --- множество int", int_set_tests);
      ("MakeSet --- функтор множества", make_set_tests);
      ("max_element --- модуль первого класса", max_element_tests);
      ("ExtendedIntSet --- расширенное множество", extended_set_tests);
      ("User — modules-as-types", user_tests);
      ("IO-agnostic — синхронный сервис", io_agnostic_tests);
      ("Monoid — библиотека моноидов", monoid_lib_tests);
      ("First — полугруппа", first_semigroup_tests);
      ("concat_all — свёртка через моноид", concat_all_tests);
      ("Custom Set — параметрический модуль", custom_set_tests);
    ]
