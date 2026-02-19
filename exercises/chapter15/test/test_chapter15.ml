open Chapter15.Brain_games

(* --- Вспомогательная функция --- *)

let string_contains haystack needle =
  let nlen = String.length needle in
  let hlen = String.length haystack in
  if nlen > hlen then false
  else
    let rec check i =
      if i > hlen - nlen then false
      else if String.sub haystack i nlen = needle then true
      else check (i + 1)
    in
    check 0

(* --- Тесты библиотеки --- *)

let helper_tests =
  let open Alcotest in
  [
    test_case "gcd 12 8" `Quick (fun () ->
      check int "gcd" 4 (gcd 12 8));
    test_case "gcd 7 3" `Quick (fun () ->
      check int "gcd" 1 (gcd 7 3));
    test_case "gcd 100 25" `Quick (fun () ->
      check int "gcd" 25 (gcd 100 25));
    test_case "is_prime 2" `Quick (fun () ->
      check bool "prime" true (is_prime 2));
    test_case "is_prime 7" `Quick (fun () ->
      check bool "prime" true (is_prime 7));
    test_case "is_prime 4" `Quick (fun () ->
      check bool "not prime" false (is_prime 4));
    test_case "is_prime 1" `Quick (fun () ->
      check bool "not prime" false (is_prime 1));
    test_case "random_int range" `Quick (fun () ->
      Random.self_init ();
      let n = random_int 5 10 in
      check bool "in range" true (n >= 5 && n <= 10));
  ]

let game_structure_tests =
  let open Alcotest in
  [
    test_case "even_game generates round" `Quick (fun () ->
      Random.self_init ();
      let r = even_game.generate_round () in
      check bool "answer is yes or no" true
        (r.correct_answer = "yes" || r.correct_answer = "no"));
    test_case "calc_game generates round" `Quick (fun () ->
      Random.self_init ();
      let r = calc_game.generate_round () in
      check bool "answer is a number" true
        (match int_of_string_opt r.correct_answer with Some _ -> true | None -> false));
    test_case "gcd_game generates round" `Quick (fun () ->
      Random.self_init ();
      let r = gcd_game.generate_round () in
      check bool "answer is a number" true
        (match int_of_string_opt r.correct_answer with Some _ -> true | None -> false));
    test_case "progression_game generates round" `Quick (fun () ->
      Random.self_init ();
      let r = progression_game.generate_round () in
      check bool "question has .." true
        (string_contains r.question ".."));
    test_case "prime_game generates round" `Quick (fun () ->
      Random.self_init ();
      let r = prime_game.generate_round () in
      check bool "answer is yes or no" true
        (r.correct_answer = "yes" || r.correct_answer = "no"));
  ]

(* --- Тесты упражнений --- *)

let balance_game_tests =
  let open Alcotest in
  [
    test_case "balance_game generates round" `Quick (fun () ->
      Random.self_init ();
      let r = My_solutions.balance_game.generate_round () in
      check bool "answer is +, - or *" true
        (r.correct_answer = "+" || r.correct_answer = "-" || r.correct_answer = "*"));
    test_case "balance_game answer is correct" `Quick (fun () ->
      Random.self_init ();
      for _ = 1 to 20 do
        let r = My_solutions.balance_game.generate_round () in
        let parts = String.split_on_char ' ' r.question in
        match parts with
        | [a_s; "?"; b_s; "="; c_s] ->
          let a = int_of_string a_s and b = int_of_string b_s and c = int_of_string c_s in
          let expected = match r.correct_answer with
            | "+" -> a + b | "-" -> a - b | "*" -> a * b | _ -> -99999
          in
          check int "correct" c expected
        | _ -> fail (Printf.sprintf "bad question format: %s" r.question)
      done);
  ]

let run_game_result_tests =
  let open Alcotest in
  let simple_game = {
    description = "test";
    generate_round = (fun () -> { question = "2 + 2"; correct_answer = "4" })
  } in
  [
    test_case "all correct" `Quick (fun () ->
      check bool "win" true
        (My_solutions.run_game_result simple_game ~rounds:3 ["4"; "4"; "4"]));
    test_case "wrong answer" `Quick (fun () ->
      check bool "lose" false
        (My_solutions.run_game_result simple_game ~rounds:3 ["4"; "5"; "4"]));
    test_case "not enough answers" `Quick (fun () ->
      check bool "lose" false
        (My_solutions.run_game_result simple_game ~rounds:3 ["4"]));
  ]

let make_game_tests =
  let open Alcotest in
  [
    test_case "make_game creates game" `Quick (fun () ->
      let g = My_solutions.make_game
        ~description:"test game"
        ~generate:(fun () -> ("what is 1+1?", "2"))
      in
      check string "description" "test game" g.description;
      let r = g.generate_round () in
      check string "question" "what is 1+1?" r.question;
      check string "answer" "2" r.correct_answer);
  ]

let factor_game_tests =
  let open Alcotest in
  [
    test_case "factor_game generates round" `Quick (fun () ->
      Random.self_init ();
      let r = My_solutions.factor_game.generate_round () in
      let n = int_of_string r.question in
      let factors = String.split_on_char ' ' r.correct_answer
        |> List.map int_of_string in
      let product = List.fold_left ( * ) 1 factors in
      check int "product equals n" n product;
      check bool "all prime" true
        (List.for_all is_prime factors));
    test_case "factor_game various" `Quick (fun () ->
      Random.self_init ();
      for _ = 1 to 20 do
        let r = My_solutions.factor_game.generate_round () in
        let n = int_of_string r.question in
        let factors = String.split_on_char ' ' r.correct_answer
          |> List.map int_of_string in
        let product = List.fold_left ( * ) 1 factors in
        check int "product" n product
      done);
  ]

let () =
  Alcotest.run "Chapter 15"
    [
      ("helpers --- вспомогательные функции", helper_tests);
      ("games --- структура игр", game_structure_tests);
      ("balance --- угадай оператор", balance_game_tests);
      ("run_game_result --- чистая логика", run_game_result_tests);
      ("make_game --- конструктор игры", make_game_tests);
      ("factor --- разложение на множители", factor_game_tests);
    ]
