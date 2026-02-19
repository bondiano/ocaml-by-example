open Chapter11.Expr

(* --- Тесты библиотеки --- *)

let variant_tests =
  let open Alcotest in
  let open Variant in
  [
    test_case "eval: целое число" `Quick (fun () ->
      check int "eval Int" 42 (eval (Int 42)));
    test_case "eval: сложение" `Quick (fun () ->
      check int "eval Add" 6
        (eval (Add (Int 1, Add (Int 2, Int 3)))));
    test_case "show: целое число" `Quick (fun () ->
      check string "show Int" "42" (show (Int 42)));
    test_case "show: сложение" `Quick (fun () ->
      check string "show Add" "(1 + (2 + 3))"
        (show (Add (Int 1, Add (Int 2, Int 3)))));
  ]

let tagless_final_tests =
  let open Alcotest in
  [
    test_case "TF_Eval: целое число" `Quick (fun () ->
      check int "int_" 42 (TF_Eval.int_ 42));
    test_case "TF_Eval: сложение" `Quick (fun () ->
      check int "add" 6
        (TF_Eval.add (TF_Eval.int_ 1) (TF_Eval.add (TF_Eval.int_ 2) (TF_Eval.int_ 3))));
    test_case "TF_Show: целое число" `Quick (fun () ->
      check string "int_" "42" (TF_Show.int_ 42));
    test_case "TF_Show: сложение" `Quick (fun () ->
      check string "add" "(1 + (2 + 3))"
        (TF_Show.add (TF_Show.int_ 1) (TF_Show.add (TF_Show.int_ 2) (TF_Show.int_ 3))));
    test_case "TF_EvalMul: умножение" `Quick (fun () ->
      check int "mul" 14
        (TF_EvalMul.mul (TF_EvalMul.int_ 2) (TF_EvalMul.add (TF_EvalMul.int_ 3) (TF_EvalMul.int_ 4))));
    test_case "TF_ShowMul: умножение" `Quick (fun () ->
      check string "mul" "(2 * (3 + 4))"
        (TF_ShowMul.mul (TF_ShowMul.int_ 2) (TF_ShowMul.add (TF_ShowMul.int_ 3) (TF_ShowMul.int_ 4))));
  ]

let polyvar_tests =
  let open Alcotest in
  [
    test_case "PolyVar.eval: целое число" `Quick (fun () ->
      check int "Int" 42 (PolyVar.eval (`Int 42)));
    test_case "PolyVar.eval: сложение" `Quick (fun () ->
      check int "Add" 6
        (PolyVar.eval (`Add (`Int 1, `Add (`Int 2, `Int 3)))));
    test_case "PolyVar.show: целое число" `Quick (fun () ->
      check string "Int" "42" (PolyVar.show (`Int 42)));
    test_case "PolyVar.show: сложение" `Quick (fun () ->
      check string "Add" "(1 + (2 + 3))"
        (PolyVar.show (`Add (`Int 1, `Add (`Int 2, `Int 3)))));
    test_case "PolyVar.eval_mul: умножение" `Quick (fun () ->
      check int "Mul" 14
        (PolyVar.eval_mul (`Mul (`Int 2, `Add (`Int 3, `Int 4)))));
    test_case "PolyVar.show_mul: умножение" `Quick (fun () ->
      check string "Mul" "(2 * (3 + 4))"
        (PolyVar.show_mul (`Mul (`Int 2, `Add (`Int 3, `Int 4)))));
  ]

(* --- Тесты упражнений --- *)

(* Упражнение 1: VariantMul *)
let variant_mul_tests =
  let open Alcotest in
  let open My_solutions.VariantMul in
  [
    test_case "eval: Int" `Quick (fun () ->
      check int "eval Int" 42 (eval (Int 42)));
    test_case "eval: Add" `Quick (fun () ->
      check int "eval Add" 3 (eval (Add (Int 1, Int 2))));
    test_case "eval: Mul" `Quick (fun () ->
      check int "eval Mul" 14
        (eval (Mul (Int 2, Add (Int 3, Int 4)))));
    test_case "eval: вложенные Mul" `Quick (fun () ->
      check int "eval nested" 24
        (eval (Mul (Mul (Int 2, Int 3), Int 4))));
    test_case "show: Int" `Quick (fun () ->
      check string "show Int" "42" (show (Int 42)));
    test_case "show: Add" `Quick (fun () ->
      check string "show Add" "(1 + 2)" (show (Add (Int 1, Int 2))));
    test_case "show: Mul" `Quick (fun () ->
      check string "show Mul" "(2 * (3 + 4))"
        (show (Mul (Int 2, Add (Int 3, Int 4)))));
  ]

(* Упражнение 2: TF_Pretty *)
let tf_pretty_tests =
  let open Alcotest in
  let open My_solutions.TF_Pretty in
  [
    test_case "int_" `Quick (fun () ->
      check string "int_" "42" (int_ 42));
    test_case "add двух чисел" `Quick (fun () ->
      check string "add" "(1 + 2)" (add (int_ 1) (int_ 2)));
    test_case "вложенный add" `Quick (fun () ->
      check string "nested" "(1 + (2 + 3))"
        (add (int_ 1) (add (int_ 2) (int_ 3))));
    test_case "глубокая вложенность" `Quick (fun () ->
      check string "deep" "((1 + 2) + (3 + 4))"
        (add (add (int_ 1) (int_ 2)) (add (int_ 3) (int_ 4))));
  ]

(* Упражнение 3: Полиморфные варианты с Neg *)
let poly_neg_tests =
  let open Alcotest in
  [
    test_case "eval_neg: Int" `Quick (fun () ->
      check int "Int" 42 (My_solutions.eval_neg (`Int 42)));
    test_case "eval_neg: Add" `Quick (fun () ->
      check int "Add" 3
        (My_solutions.eval_neg (`Add (`Int 1, `Int 2))));
    test_case "eval_neg: Neg" `Quick (fun () ->
      check int "Neg" (-5)
        (My_solutions.eval_neg (`Neg (`Int 5))));
    test_case "eval_neg: Neg Add" `Quick (fun () ->
      check int "Neg Add" (-3)
        (My_solutions.eval_neg (`Neg (`Add (`Int 1, `Int 2)))));
    test_case "show_neg: Int" `Quick (fun () ->
      check string "Int" "42"
        (My_solutions.show_neg (`Int 42)));
    test_case "show_neg: Neg" `Quick (fun () ->
      check string "Neg" "(-5)"
        (My_solutions.show_neg (`Neg (`Int 5))));
    test_case "show_neg: Neg Add" `Quick (fun () ->
      check string "Neg Add" "(-(1 + 2))"
        (My_solutions.show_neg (`Neg (`Add (`Int 1, `Int 2)))));
  ]

(* Упражнение 4: Tagless Final для булевых выражений *)
let bool_eval_tests =
  let open Alcotest in
  let open My_solutions.Bool_Eval in
  [
    test_case "bool_ true" `Quick (fun () ->
      check bool "true" true (bool_ true));
    test_case "bool_ false" `Quick (fun () ->
      check bool "false" false (bool_ false));
    test_case "and_ true true" `Quick (fun () ->
      check bool "and tt" true (and_ (bool_ true) (bool_ true)));
    test_case "and_ true false" `Quick (fun () ->
      check bool "and tf" false (and_ (bool_ true) (bool_ false)));
    test_case "or_ false true" `Quick (fun () ->
      check bool "or ft" true (or_ (bool_ false) (bool_ true)));
    test_case "or_ false false" `Quick (fun () ->
      check bool "or ff" false (or_ (bool_ false) (bool_ false)));
    test_case "not_ true" `Quick (fun () ->
      check bool "not t" false (not_ (bool_ true)));
    test_case "not_ false" `Quick (fun () ->
      check bool "not f" true (not_ (bool_ false)));
    test_case "сложное выражение" `Quick (fun () ->
      check bool "complex" true
        (and_ (bool_ true) (or_ (bool_ false) (bool_ true))));
  ]

let bool_show_tests =
  let open Alcotest in
  let open My_solutions.Bool_Show in
  [
    test_case "bool_ true" `Quick (fun () ->
      check string "true" "true" (bool_ true));
    test_case "bool_ false" `Quick (fun () ->
      check string "false" "false" (bool_ false));
    test_case "and_" `Quick (fun () ->
      check string "and" "(true && false)"
        (and_ (bool_ true) (bool_ false)));
    test_case "or_" `Quick (fun () ->
      check string "or" "(false || true)"
        (or_ (bool_ false) (bool_ true)));
    test_case "not_" `Quick (fun () ->
      check string "not" "(!true)"
        (not_ (bool_ true)));
    test_case "сложное выражение" `Quick (fun () ->
      check string "complex" "(true && (false || true))"
        (and_ (bool_ true) (or_ (bool_ false) (bool_ true))));
  ]

(* Упражнение 5: Объединённый DSL *)
let combined_show_tests =
  let open Alcotest in
  let open My_solutions.Combined_Show in
  [
    test_case "int_" `Quick (fun () ->
      check string "int_" "42" (int_ 42));
    test_case "add" `Quick (fun () ->
      check string "add" "(1 + 2)" (add (int_ 1) (int_ 2)));
    test_case "bool_" `Quick (fun () ->
      check string "bool_" "true" (bool_ true));
    test_case "and_" `Quick (fun () ->
      check string "and" "(true && false)"
        (and_ (bool_ true) (bool_ false)));
    test_case "eq int" `Quick (fun () ->
      check string "eq int" "((1 + 2) == 3)"
        (eq (add (int_ 1) (int_ 2)) (int_ 3)));
    test_case "eq в and_" `Quick (fun () ->
      check string "eq in and" "(true && (1 == 1))"
        (and_ (bool_ true) (eq (int_ 1) (int_ 1))));
    test_case "not_ с eq" `Quick (fun () ->
      check string "not eq" "(!(1 == 2))"
        (not_ (eq (int_ 1) (int_ 2))));
    test_case "or_ с eq" `Quick (fun () ->
      check string "or eq" "((1 == 1) || (2 == 3))"
        (or_ (eq (int_ 1) (int_ 1)) (eq (int_ 2) (int_ 3))));
  ]

let () =
  Alcotest.run "Chapter 10"
    [
      ("Variant --- вариантный калькулятор", variant_tests);
      ("Tagless Final --- модульный калькулятор", tagless_final_tests);
      ("PolyVar --- полиморфные варианты", polyvar_tests);
      ("Упр. 1: VariantMul --- добавить Mul", variant_mul_tests);
      ("Упр. 2: TF_Pretty --- pretty_print", tf_pretty_tests);
      ("Упр. 3: PolyVar Neg --- унарное отрицание", poly_neg_tests);
      ("Упр. 4: Bool_Eval --- булев DSL (eval)", bool_eval_tests);
      ("Упр. 4: Bool_Show --- булев DSL (show)", bool_show_tests);
      ("Упр. 5: Combined_Show --- объединённый DSL", combined_show_tests);
    ]
