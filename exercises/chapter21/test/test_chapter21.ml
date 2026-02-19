open Chapter21.Hashcons_ast

(* --- Тесты библиотеки --- *)

let hc_expr_tests =
  let open Alcotest in
  [
    test_case "hc_num создаёт число" `Quick (fun () ->
      hc_reset ();
      let e = hc_num 42 in
      check int "id" 0 e.id;
      check string "repr" "42" (string_of_hc_expr e));

    test_case "hc_var создаёт переменную" `Quick (fun () ->
      hc_reset ();
      let e = hc_var "x" in
      check string "repr" "x" (string_of_hc_expr e));

    test_case "hc_add строит сумму" `Quick (fun () ->
      hc_reset ();
      let a = hc_num 1 in
      let b = hc_num 2 in
      let s = hc_add a b in
      check string "repr" "(1 + 2)" (string_of_hc_expr s));

    test_case "hc_mul строит произведение" `Quick (fun () ->
      hc_reset ();
      let a = hc_var "x" in
      let b = hc_num 3 in
      let p = hc_mul a b in
      check string "repr" "(x * 3)" (string_of_hc_expr p));

    test_case "hash-consing разделяет одинаковые значения" `Quick (fun () ->
      hc_reset ();
      let a = hc_num 1 in
      let b = hc_num 1 in
      check int "same id" a.id b.id;
      check bool "physical eq" true (a == b));

    test_case "hash-consing: разные значения --- разные id" `Quick (fun () ->
      hc_reset ();
      let a = hc_num 1 in
      let b = hc_num 2 in
      check bool "different id" true (a.id <> b.id));

    test_case "hash-consing: составные выражения разделяются" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let y = hc_var "y" in
      let s1 = hc_add x y in
      let s2 = hc_add x y in
      check int "same id" s1.id s2.id;
      check bool "physical eq" true (s1 == s2));

    test_case "hash-consing: build_shared_hc создаёт мало узлов" `Quick (fun () ->
      hc_reset ();
      let _tree = build_shared_hc 10 in
      (* Для глубины 10 должно быть ровно 11 уникальных узлов *)
      check int "table size" 11 (Hashtbl.length hc_table));
  ]

let eval_tests =
  let open Alcotest in
  [
    test_case "eval_expr: числа" `Quick (fun () ->
      check int "42" 42 (eval_expr [] (Num 42)));

    test_case "eval_expr: переменная" `Quick (fun () ->
      check int "x=5" 5 (eval_expr [("x", 5)] (Var "x")));

    test_case "eval_expr: неизвестная переменная = 0" `Quick (fun () ->
      check int "unknown=0" 0 (eval_expr [] (Var "y")));

    test_case "eval_expr: сложение" `Quick (fun () ->
      check int "2+3" 5 (eval_expr [] (Add (Num 2, Num 3))));

    test_case "eval_expr: умножение" `Quick (fun () ->
      check int "4*5" 20 (eval_expr [] (Mul (Num 4, Num 5))));

    test_case "eval_expr: сложное выражение" `Quick (fun () ->
      (* (x + 2) * (y + 3), x=1, y=4 => 3 * 7 = 21 *)
      let e = Mul (Add (Var "x", Num 2), Add (Var "y", Num 3)) in
      check int "(1+2)*(4+3)=21" 21
        (eval_expr [("x", 1); ("y", 4)] e));

    test_case "eval_hc_expr: числа" `Quick (fun () ->
      hc_reset ();
      check int "42" 42 (eval_hc_expr [] (hc_num 42)));

    test_case "eval_hc_expr: переменная" `Quick (fun () ->
      hc_reset ();
      check int "x=10" 10 (eval_hc_expr [("x", 10)] (hc_var "x")));

    test_case "eval_hc_expr: сложное выражение" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul (hc_add x (hc_num 1)) (hc_add x (hc_num 1)) in
      (* (x+1)*(x+1) при x=3 => 4*4 = 16 *)
      check int "(3+1)*(3+1)=16" 16
        (eval_hc_expr [("x", 3)] e));

    test_case "eval: обычный и hash-consed дают одинаковый результат" `Quick (fun () ->
      hc_reset ();
      let regular = build_shared_tree 5 in
      let hconsed = build_shared_hc 5 in
      let r1 = eval_expr [] regular in
      let r2 = eval_hc_expr [] hconsed in
      check int "same result" r1 r2);
  ]

(* --- Тесты упражнений --- *)

let exercise1_tests =
  let open Alcotest in
  [
    test_case "mk_positive: положительное число" `Quick (fun () ->
      match My_solutions.mk_positive 3.14 with
      | Some pf -> check bool "value" true (Float.equal (My_solutions.get_value pf) 3.14)
      | None -> fail "Ожидался Some");

    test_case "mk_positive: ноль" `Quick (fun () ->
      check bool "None" true (Option.is_none (My_solutions.mk_positive 0.0)));

    test_case "mk_positive: отрицательное" `Quick (fun () ->
      check bool "None" true (Option.is_none (My_solutions.mk_positive (-1.0))));

    test_case "mk_positive: маленькое положительное" `Quick (fun () ->
      match My_solutions.mk_positive 0.001 with
      | Some pf -> check bool "value" true (Float.equal (My_solutions.get_value pf) 0.001)
      | None -> fail "Ожидался Some");

    test_case "get_value извлекает значение" `Quick (fun () ->
      match My_solutions.mk_positive 42.0 with
      | Some pf -> check bool "42.0" true (Float.equal (My_solutions.get_value pf) 42.0)
      | None -> fail "Ожидался Some");
  ]

let exercise2_tests =
  let open Alcotest in
  [
    test_case "mk_leaf: создаёт лист" `Quick (fun () ->
      let l1 = My_solutions.mk_leaf () in
      let l2 = My_solutions.mk_leaf () in
      check int "same id" l1.id l2.id);

    test_case "mk_node: создаёт узел" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n = My_solutions.mk_node l l in
      check bool "different from leaf" true (n.id <> l.id));

    test_case "mk_node: hash-consing работает" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n1 = My_solutions.mk_node l l in
      let n2 = My_solutions.mk_node l l in
      check int "same id" n1.id n2.id;
      check bool "physical eq" true (n1 == n2));

    test_case "tree_size: лист" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      check int "1 node" 1 (My_solutions.tree_size l));

    test_case "tree_size: простое дерево" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n = My_solutions.mk_node l l in
      check int "2 unique" 2 (My_solutions.tree_size n));

    test_case "tree_size: глубокое разделяемое дерево" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n1 = My_solutions.mk_node l l in
      let n2 = My_solutions.mk_node n1 n1 in
      let n3 = My_solutions.mk_node n2 n2 in
      (* l, n1, n2, n3 --- 4 уникальных узла *)
      check int "4 unique" 4 (My_solutions.tree_size n3));
  ]

let exercise3_tests =
  let open Alcotest in
  [
    test_case "simplify: 0 + x = x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_add (hc_num 0) x in
      let s = My_solutions.simplify e in
      check string "x" "x" (string_of_hc_expr s));

    test_case "simplify: x + 0 = x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_add x (hc_num 0) in
      let s = My_solutions.simplify e in
      check string "x" "x" (string_of_hc_expr s));

    test_case "simplify: 0 * x = 0" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul (hc_num 0) x in
      let s = My_solutions.simplify e in
      check string "0" "0" (string_of_hc_expr s));

    test_case "simplify: x * 0 = 0" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul x (hc_num 0) in
      let s = My_solutions.simplify e in
      check string "0" "0" (string_of_hc_expr s));

    test_case "simplify: 1 * x = x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul (hc_num 1) x in
      let s = My_solutions.simplify e in
      check string "x" "x" (string_of_hc_expr s));

    test_case "simplify: x * 1 = x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul x (hc_num 1) in
      let s = My_solutions.simplify e in
      check string "x" "x" (string_of_hc_expr s));

    test_case "simplify: вложенное упрощение" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      (* (0 + x) * (1 * x) => x * x *)
      let e = hc_mul (hc_add (hc_num 0) x) (hc_mul (hc_num 1) x) in
      let s = My_solutions.simplify e in
      check string "(x * x)" "(x * x)" (string_of_hc_expr s));

    test_case "simplify: ничего не упрощается" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let y = hc_var "y" in
      let e = hc_add x y in
      let s = My_solutions.simplify e in
      check string "(x + y)" "(x + y)" (string_of_hc_expr s));

    test_case "simplify: результат hash-consed" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_add (hc_num 0) x in
      let s = My_solutions.simplify e in
      (* Упрощённый результат должен быть тем же объектом, что и x *)
      check bool "physical eq" true (s == x));
  ]

let exercise4_tests =
  let open Alcotest in
  [
    test_case "count_unique_nodes: число" `Quick (fun () ->
      hc_reset ();
      let e = hc_num 5 in
      check int "1" 1 (My_solutions.count_unique_nodes e));

    test_case "count_unique_nodes: простое выражение" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_add x x in
      (* x и add(x,x) --- 2 уникальных узла *)
      check int "2" 2 (My_solutions.count_unique_nodes e));

    test_case "count_unique_nodes: build_shared_hc" `Quick (fun () ->
      hc_reset ();
      let e = build_shared_hc 5 in
      (* Уровни 0..5 --- 6 уникальных узлов *)
      check int "6" 6 (My_solutions.count_unique_nodes e));

    test_case "count_nodes_regular: число" `Quick (fun () ->
      check int "1" 1 (My_solutions.count_nodes_regular (Num 5)));

    test_case "count_nodes_regular: простое выражение" `Quick (fun () ->
      let e = Add (Num 1, Num 2) in
      check int "3" 3 (My_solutions.count_nodes_regular e));

    test_case "count_nodes_regular: build_shared_tree" `Quick (fun () ->
      let e = build_shared_tree 3 in
      (* 2^0 + 2^1 + 2^2 + 2^3 = 1+2+4+8 = 15 *)
      check int "15" 15 (My_solutions.count_nodes_regular e));

    test_case "count: shared tree гораздо больше в обычном AST" `Quick (fun () ->
      hc_reset ();
      let n = 10 in
      let regular = build_shared_tree n in
      let hconsed = build_shared_hc n in
      let regular_count = My_solutions.count_nodes_regular regular in
      let unique_count = My_solutions.count_unique_nodes hconsed in
      check bool "regular >> unique" true (regular_count > unique_count * 10));
  ]

let exercise5_tests =
  let open Alcotest in
  [
    test_case "prop: hash-consing работает" `Quick (fun () ->
      let p1 = My_solutions.mk_pvar "p" in
      let p2 = My_solutions.mk_pvar "p" in
      check int "same id" p1.id p2.id);

    test_case "prop: разные переменные --- разные id" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      check bool "different" true (p.id <> q.id));

    test_case "nnf: переменная без изменений" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let result = My_solutions.nnf p in
      check int "same id" p.id result.id);

    test_case "nnf: двойное отрицание" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let nn = My_solutions.mk_pnot (My_solutions.mk_pnot p) in
      let result = My_solutions.nnf nn in
      check int "p" p.id result.id);

    test_case "nnf: Де Морган для And" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      (* Not(And(p, q)) => Or(Not p, Not q) *)
      let e = My_solutions.mk_pnot (My_solutions.mk_pand p q) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_por (My_solutions.mk_pnot p) (My_solutions.mk_pnot q) in
      check int "De Morgan And" expected.id result.id);

    test_case "nnf: Де Морган для Or" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      (* Not(Or(p, q)) => And(Not p, Not q) *)
      let e = My_solutions.mk_pnot (My_solutions.mk_por p q) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_pand (My_solutions.mk_pnot p) (My_solutions.mk_pnot q) in
      check int "De Morgan Or" expected.id result.id);

    test_case "nnf: Not True = False" `Quick (fun () ->
      let e = My_solutions.mk_pnot (My_solutions.mk_ptrue ()) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_pfalse () in
      check int "Not True = False" expected.id result.id);

    test_case "nnf: Not False = True" `Quick (fun () ->
      let e = My_solutions.mk_pnot (My_solutions.mk_pfalse ()) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_ptrue () in
      check int "Not False = True" expected.id result.id);

    test_case "nnf: сложная формула" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      (* Not(And(Not p, Or(q, Not q))) *)
      let inner = My_solutions.mk_pand
        (My_solutions.mk_pnot p)
        (My_solutions.mk_por q (My_solutions.mk_pnot q))
      in
      let e = My_solutions.mk_pnot inner in
      let result = My_solutions.nnf e in
      (* => Or(p, And(Not q, q)) *)
      let expected = My_solutions.mk_por p
        (My_solutions.mk_pand (My_solutions.mk_pnot q) q)
      in
      check int "complex nnf" expected.id result.id);

    test_case "eval_prop: True" `Quick (fun () ->
      let e = My_solutions.mk_ptrue () in
      check bool "true" true (My_solutions.eval_prop (fun _ -> false) e));

    test_case "eval_prop: False" `Quick (fun () ->
      let e = My_solutions.mk_pfalse () in
      check bool "false" false (My_solutions.eval_prop (fun _ -> true) e));

    test_case "eval_prop: переменная" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let env x = x = "p" in
      check bool "p=true" true (My_solutions.eval_prop env p));

    test_case "eval_prop: And" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      let e = My_solutions.mk_pand p q in
      let env x = x = "p" || x = "q" in
      check bool "p&q=true" true (My_solutions.eval_prop env e);
      let env2 x = x = "p" in
      check bool "p&!q=false" false (My_solutions.eval_prop env2 e));

    test_case "eval_prop: Or" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      let e = My_solutions.mk_por p q in
      let env x = x = "p" in
      check bool "p|q when p=true" true (My_solutions.eval_prop env e);
      let env2 _ = false in
      check bool "p|q when both false" false (My_solutions.eval_prop env2 e));

    test_case "eval_prop: Not" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let e = My_solutions.mk_pnot p in
      let env _ = true in
      check bool "not true" false (My_solutions.eval_prop env e));

    test_case "eval_prop: NNF сохраняет семантику" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      let formula = My_solutions.mk_pnot (My_solutions.mk_pand p q) in
      let nnf_formula = My_solutions.nnf formula in
      (* Проверяем для всех комбинаций *)
      let check_eq pv qv =
        let env x = if x = "p" then pv else if x = "q" then qv else false in
        let v1 = My_solutions.eval_prop env formula in
        let v2 = My_solutions.eval_prop env nnf_formula in
        check bool
          (Printf.sprintf "p=%b,q=%b" pv qv)
          true (v1 = v2)
      in
      check_eq true true;
      check_eq true false;
      check_eq false true;
      check_eq false false);
  ]

let () =
  Alcotest.run "Chapter 21"
    [
      ("hash-consed AST --- smart-конструкторы", hc_expr_tests);
      ("eval --- вычисление выражений", eval_tests);
      ("упр. 1 --- positive_float [@@unboxed]", exercise1_tests);
      ("упр. 2 --- hash-consing бинарных деревьев", exercise2_tests);
      ("упр. 3 --- simplify hash-consed выражений", exercise3_tests);
      ("упр. 4 --- подсчёт узлов", exercise4_tests);
      ("упр. 5 --- пропозициональная логика + NNF", exercise5_tests);
    ]
