open Chapter11.Expr

(* --- Тесты библиотеки --- *)

let variant_tests =
  let open Alcotest in
  let open Variant in
  [
    test_case "при Int 42 eval возвращает 42" `Quick (fun () ->
      check int "eval" 42 (eval (Int 42)));
    test_case "при Add (Int 1, Add (Int 2, Int 3)) eval возвращает 6" `Quick (fun () ->
      check int "eval" 6
        (eval (Add (Int 1, Add (Int 2, Int 3)))));
    test_case "при Int 42 show возвращает \"42\"" `Quick (fun () ->
      check string "show" "42" (show (Int 42)));
    test_case "при Add (Int 1, Add (Int 2, Int 3)) show возвращает \"(1 + (2 + 3))\"" `Quick (fun () ->
      check string "show" "(1 + (2 + 3))"
        (show (Add (Int 1, Add (Int 2, Int 3)))));
  ]

let tagless_final_tests =
  let open Alcotest in
  [
    test_case "TF_Eval: при int_ 42 возвращает 42" `Quick (fun () ->
      check int "int_" 42 (TF_Eval.int_ 42));
    test_case "TF_Eval: при add (int_ 1) (add (int_ 2) (int_ 3)) возвращает 6" `Quick (fun () ->
      check int "add" 6
        (TF_Eval.add (TF_Eval.int_ 1) (TF_Eval.add (TF_Eval.int_ 2) (TF_Eval.int_ 3))));
    test_case "TF_Show: при int_ 42 возвращает \"42\"" `Quick (fun () ->
      check string "int_" "42" (TF_Show.int_ 42));
    test_case "TF_Show: при add вложенных возвращает \"(1 + (2 + 3))\"" `Quick (fun () ->
      check string "add" "(1 + (2 + 3))"
        (TF_Show.add (TF_Show.int_ 1) (TF_Show.add (TF_Show.int_ 2) (TF_Show.int_ 3))));
    test_case "TF_EvalMul: при mul (int_ 2) (add (int_ 3) (int_ 4)) возвращает 14" `Quick (fun () ->
      check int "mul" 14
        (TF_EvalMul.mul (TF_EvalMul.int_ 2) (TF_EvalMul.add (TF_EvalMul.int_ 3) (TF_EvalMul.int_ 4))));
    test_case "TF_ShowMul: при mul (int_ 2) (add (int_ 3) (int_ 4)) возвращает \"(2 * (3 + 4))\"" `Quick (fun () ->
      check string "mul" "(2 * (3 + 4))"
        (TF_ShowMul.mul (TF_ShowMul.int_ 2) (TF_ShowMul.add (TF_ShowMul.int_ 3) (TF_ShowMul.int_ 4))));
  ]

let polyvar_tests =
  let open Alcotest in
  [
    test_case "PolyVar.eval: при `Int 42 возвращает 42" `Quick (fun () ->
      check int "eval" 42 (PolyVar.eval (`Int 42)));
    test_case "PolyVar.eval: при `Add вложенных возвращает 6" `Quick (fun () ->
      check int "eval" 6
        (PolyVar.eval (`Add (`Int 1, `Add (`Int 2, `Int 3)))));
    test_case "PolyVar.show: при `Int 42 возвращает \"42\"" `Quick (fun () ->
      check string "show" "42" (PolyVar.show (`Int 42)));
    test_case "PolyVar.show: при `Add вложенных возвращает \"(1 + (2 + 3))\"" `Quick (fun () ->
      check string "show" "(1 + (2 + 3))"
        (PolyVar.show (`Add (`Int 1, `Add (`Int 2, `Int 3)))));
    test_case "PolyVar.eval_mul: при `Mul (`Int 2, `Add ...) возвращает 14" `Quick (fun () ->
      check int "eval_mul" 14
        (PolyVar.eval_mul (`Mul (`Int 2, `Add (`Int 3, `Int 4)))));
    test_case "PolyVar.show_mul: при `Mul (`Int 2, `Add ...) возвращает \"(2 * (3 + 4))\"" `Quick (fun () ->
      check string "show_mul" "(2 * (3 + 4))"
        (PolyVar.show_mul (`Mul (`Int 2, `Add (`Int 3, `Int 4)))));
  ]

(* --- Тесты упражнений --- *)

(* Упражнение 1: VariantMul *)
let variant_mul_tests =
  let open Alcotest in
  let open My_solutions.VariantMul in
  [
    test_case "при Int 42 eval возвращает 42" `Quick (fun () ->
      check int "eval" 42 (eval (Int 42)));
    test_case "при Add (Int 1, Int 2) eval возвращает 3" `Quick (fun () ->
      check int "eval" 3 (eval (Add (Int 1, Int 2))));
    test_case "при Mul (Int 2, Add (Int 3, Int 4)) eval возвращает 14" `Quick (fun () ->
      check int "eval" 14
        (eval (Mul (Int 2, Add (Int 3, Int 4)))));
    test_case "при Mul (Mul (Int 2, Int 3), Int 4) eval возвращает 24" `Quick (fun () ->
      check int "eval" 24
        (eval (Mul (Mul (Int 2, Int 3), Int 4))));
    test_case "при Int 42 show возвращает \"42\"" `Quick (fun () ->
      check string "show" "42" (show (Int 42)));
    test_case "при Add (Int 1, Int 2) show возвращает \"(1 + 2)\"" `Quick (fun () ->
      check string "show" "(1 + 2)" (show (Add (Int 1, Int 2))));
    test_case "при Mul (Int 2, Add (Int 3, Int 4)) show возвращает \"(2 * (3 + 4))\"" `Quick (fun () ->
      check string "show" "(2 * (3 + 4))"
        (show (Mul (Int 2, Add (Int 3, Int 4)))));
  ]

(* Упражнение 2: TF_Pretty *)
let tf_pretty_tests =
  let open Alcotest in
  let open My_solutions.TF_Pretty in
  [
    test_case "при int_ 42 возвращает \"42\"" `Quick (fun () ->
      check string "int_" "42" (int_ 42));
    test_case "при add (int_ 1) (int_ 2) возвращает \"(1 + 2)\"" `Quick (fun () ->
      check string "add" "(1 + 2)" (add (int_ 1) (int_ 2)));
    test_case "при add (int_ 1) (add (int_ 2) (int_ 3)) возвращает \"(1 + (2 + 3))\"" `Quick (fun () ->
      check string "nested" "(1 + (2 + 3))"
        (add (int_ 1) (add (int_ 2) (int_ 3))));
    test_case "при двух уровнях вложенности возвращает \"((1 + 2) + (3 + 4))\"" `Quick (fun () ->
      check string "deep" "((1 + 2) + (3 + 4))"
        (add (add (int_ 1) (int_ 2)) (add (int_ 3) (int_ 4))));
  ]

(* Упражнение 3: Полиморфные варианты с Neg *)
let poly_neg_tests =
  let open Alcotest in
  [
    test_case "при `Int 42 eval_neg возвращает 42" `Quick (fun () ->
      check int "eval_neg" 42 (My_solutions.eval_neg (`Int 42)));
    test_case "при `Add (`Int 1, `Int 2) eval_neg возвращает 3" `Quick (fun () ->
      check int "eval_neg" 3
        (My_solutions.eval_neg (`Add (`Int 1, `Int 2))));
    test_case "при `Neg (`Int 5) eval_neg возвращает -5" `Quick (fun () ->
      check int "eval_neg" (-5)
        (My_solutions.eval_neg (`Neg (`Int 5))));
    test_case "при `Neg (`Add (`Int 1, `Int 2)) eval_neg возвращает -3" `Quick (fun () ->
      check int "eval_neg" (-3)
        (My_solutions.eval_neg (`Neg (`Add (`Int 1, `Int 2)))));
    test_case "при `Int 42 show_neg возвращает \"42\"" `Quick (fun () ->
      check string "show_neg" "42"
        (My_solutions.show_neg (`Int 42)));
    test_case "при `Neg (`Int 5) show_neg возвращает \"(-5)\"" `Quick (fun () ->
      check string "show_neg" "(-5)"
        (My_solutions.show_neg (`Neg (`Int 5))));
    test_case "при `Neg (`Add ...) show_neg возвращает \"(-(1 + 2))\"" `Quick (fun () ->
      check string "show_neg" "(-(1 + 2))"
        (My_solutions.show_neg (`Neg (`Add (`Int 1, `Int 2)))));
  ]

(* Упражнение 4: Tagless Final для булевых выражений *)
let bool_eval_tests =
  let open Alcotest in
  let open My_solutions.Bool_Eval in
  [
    test_case "при bool_ true возвращает true" `Quick (fun () ->
      check bool "bool_" true (bool_ true));
    test_case "при bool_ false возвращает false" `Quick (fun () ->
      check bool "bool_" false (bool_ false));
    test_case "при and_ true true возвращает true" `Quick (fun () ->
      check bool "and_" true (and_ (bool_ true) (bool_ true)));
    test_case "при and_ true false возвращает false" `Quick (fun () ->
      check bool "and_" false (and_ (bool_ true) (bool_ false)));
    test_case "при or_ false true возвращает true" `Quick (fun () ->
      check bool "or_" true (or_ (bool_ false) (bool_ true)));
    test_case "при or_ false false возвращает false" `Quick (fun () ->
      check bool "or_" false (or_ (bool_ false) (bool_ false)));
    test_case "при not_ true возвращает false" `Quick (fun () ->
      check bool "not_" false (not_ (bool_ true)));
    test_case "при not_ false возвращает true" `Quick (fun () ->
      check bool "not_" true (not_ (bool_ false)));
    test_case "при and_ true (or_ false true) возвращает true" `Quick (fun () ->
      check bool "complex" true
        (and_ (bool_ true) (or_ (bool_ false) (bool_ true))));
  ]

let bool_show_tests =
  let open Alcotest in
  let open My_solutions.Bool_Show in
  [
    test_case "при bool_ true возвращает \"true\"" `Quick (fun () ->
      check string "bool_" "true" (bool_ true));
    test_case "при bool_ false возвращает \"false\"" `Quick (fun () ->
      check string "bool_" "false" (bool_ false));
    test_case "при and_ true false возвращает \"(true && false)\"" `Quick (fun () ->
      check string "and_" "(true && false)"
        (and_ (bool_ true) (bool_ false)));
    test_case "при or_ false true возвращает \"(false || true)\"" `Quick (fun () ->
      check string "or_" "(false || true)"
        (or_ (bool_ false) (bool_ true)));
    test_case "при not_ true возвращает \"(!true)\"" `Quick (fun () ->
      check string "not_" "(!true)"
        (not_ (bool_ true)));
    test_case "при and_ true (or_ false true) возвращает \"(true && (false || true))\"" `Quick (fun () ->
      check string "complex" "(true && (false || true))"
        (and_ (bool_ true) (or_ (bool_ false) (bool_ true))));
  ]

(* Упражнение 5: Объединённый DSL *)
let combined_show_tests =
  let open Alcotest in
  let open My_solutions.Combined_Show in
  [
    test_case "при int_ 42 возвращает \"42\"" `Quick (fun () ->
      check string "int_" "42" (int_ 42));
    test_case "при add (int_ 1) (int_ 2) возвращает \"(1 + 2)\"" `Quick (fun () ->
      check string "add" "(1 + 2)" (add (int_ 1) (int_ 2)));
    test_case "при bool_ true возвращает \"true\"" `Quick (fun () ->
      check string "bool_" "true" (bool_ true));
    test_case "при and_ true false возвращает \"(true && false)\"" `Quick (fun () ->
      check string "and_" "(true && false)"
        (and_ (bool_ true) (bool_ false)));
    test_case "при eq (add (int_ 1) (int_ 2)) (int_ 3) возвращает \"((1 + 2) == 3)\"" `Quick (fun () ->
      check string "eq" "((1 + 2) == 3)"
        (eq (add (int_ 1) (int_ 2)) (int_ 3)));
    test_case "при and_ true (eq (int_ 1) (int_ 1)) возвращает \"(true && (1 == 1))\"" `Quick (fun () ->
      check string "eq in and" "(true && (1 == 1))"
        (and_ (bool_ true) (eq (int_ 1) (int_ 1))));
    test_case "при not_ (eq (int_ 1) (int_ 2)) возвращает \"(!(1 == 2))\"" `Quick (fun () ->
      check string "not eq" "(!(1 == 2))"
        (not_ (eq (int_ 1) (int_ 2))));
    test_case "при or_ двух eq возвращает \"((1 == 1) || (2 == 3))\"" `Quick (fun () ->
      check string "or eq" "((1 == 1) || (2 == 3))"
        (or_ (eq (int_ 1) (int_ 1)) (eq (int_ 2) (int_ 3))));
  ]

let () =
  Alcotest.run "Chapter 11"
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
