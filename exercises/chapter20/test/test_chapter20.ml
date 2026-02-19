open Chapter20.Hashcons_ast

(* --- Тесты библиотеки --- *)

let hc_expr_tests =
  let open Alcotest in
  [
    test_case "при hc_num 42 создаёт узел с repr \"42\"" `Quick (fun () ->
      hc_reset ();
      let e = hc_num 42 in
      check int "id" 0 e.id;
      check string "repr" "42" (string_of_hc_expr e));

    test_case "при hc_var \"x\" создаёт узел с repr \"x\"" `Quick (fun () ->
      hc_reset ();
      let e = hc_var "x" in
      check string "repr" "x" (string_of_hc_expr e));

    test_case "при hc_add строит сумму с repr \"(1 + 2)\"" `Quick (fun () ->
      hc_reset ();
      let a = hc_num 1 in
      let b = hc_num 2 in
      let s = hc_add a b in
      check string "repr" "(1 + 2)" (string_of_hc_expr s));

    test_case "при hc_mul строит произведение с repr \"(x * 3)\"" `Quick (fun () ->
      hc_reset ();
      let a = hc_var "x" in
      let b = hc_num 3 in
      let p = hc_mul a b in
      check string "repr" "(x * 3)" (string_of_hc_expr p));

    test_case "при одинаковых значениях hash-consing разделяет объекты" `Quick (fun () ->
      hc_reset ();
      let a = hc_num 1 in
      let b = hc_num 1 in
      check int "same id" a.id b.id;
      check bool "physical eq" true (a == b));

    test_case "при разных значениях hash-consing создаёт разные id" `Quick (fun () ->
      hc_reset ();
      let a = hc_num 1 in
      let b = hc_num 2 in
      check bool "different id" true (a.id <> b.id));

    test_case "при одинаковых составных выражениях hash-consing разделяет объекты" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let y = hc_var "y" in
      let s1 = hc_add x y in
      let s2 = hc_add x y in
      check int "same id" s1.id s2.id;
      check bool "physical eq" true (s1 == s2));

    test_case "при build_shared_hc 10 создаёт ровно 11 уникальных узлов" `Quick (fun () ->
      hc_reset ();
      let _tree = build_shared_hc 10 in
      (* Для глубины 10 должно быть ровно 11 уникальных узлов *)
      check int "table size" 11 (Hashtbl.length hc_table));
  ]

let eval_tests =
  let open Alcotest in
  [
    test_case "при eval_expr числа возвращает само число" `Quick (fun () ->
      check int "value" 42 (eval_expr [] (Num 42)));

    test_case "при eval_expr переменной из окружения возвращает её значение" `Quick (fun () ->
      check int "value" 5 (eval_expr [("x", 5)] (Var "x")));

    test_case "при eval_expr неизвестной переменной возвращает 0" `Quick (fun () ->
      check int "value" 0 (eval_expr [] (Var "y")));

    test_case "при eval_expr сложения возвращает сумму" `Quick (fun () ->
      check int "value" 5 (eval_expr [] (Add (Num 2, Num 3))));

    test_case "при eval_expr умножения возвращает произведение" `Quick (fun () ->
      check int "value" 20 (eval_expr [] (Mul (Num 4, Num 5))));

    test_case "при eval_expr сложного выражения возвращает корректный результат" `Quick (fun () ->
      (* (x + 2) * (y + 3), x=1, y=4 => 3 * 7 = 21 *)
      let e = Mul (Add (Var "x", Num 2), Add (Var "y", Num 3)) in
      check int "value" 21
        (eval_expr [("x", 1); ("y", 4)] e));

    test_case "при eval_hc_expr числа возвращает само число" `Quick (fun () ->
      hc_reset ();
      check int "value" 42 (eval_hc_expr [] (hc_num 42)));

    test_case "при eval_hc_expr переменной возвращает значение из окружения" `Quick (fun () ->
      hc_reset ();
      check int "value" 10 (eval_hc_expr [("x", 10)] (hc_var "x")));

    test_case "при eval_hc_expr сложного выражения возвращает корректный результат" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul (hc_add x (hc_num 1)) (hc_add x (hc_num 1)) in
      (* (x+1)*(x+1) при x=3 => 4*4 = 16 *)
      check int "value" 16
        (eval_hc_expr [("x", 3)] e));

    test_case "при одинаковом выражении обычный и hash-consed дают одинаковый результат" `Quick (fun () ->
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
    test_case "при положительном числе mk_positive возвращает Some" `Quick (fun () ->
      match My_solutions.mk_positive 3.14 with
      | Some pf -> check bool "value" true (Float.equal (My_solutions.get_value pf) 3.14)
      | None -> fail "Ожидался Some");

    test_case "при нуле mk_positive возвращает None" `Quick (fun () ->
      check bool "None" true (Option.is_none (My_solutions.mk_positive 0.0)));

    test_case "при отрицательном числе mk_positive возвращает None" `Quick (fun () ->
      check bool "None" true (Option.is_none (My_solutions.mk_positive (-1.0))));

    test_case "при малом положительном числе mk_positive возвращает Some" `Quick (fun () ->
      match My_solutions.mk_positive 0.001 with
      | Some pf -> check bool "value" true (Float.equal (My_solutions.get_value pf) 0.001)
      | None -> fail "Ожидался Some");

    test_case "при Some get_value извлекает исходное значение" `Quick (fun () ->
      match My_solutions.mk_positive 42.0 with
      | Some pf -> check bool "value" true (Float.equal (My_solutions.get_value pf) 42.0)
      | None -> fail "Ожидался Some");
  ]

let exercise2_tests =
  let open Alcotest in
  [
    test_case "при mk_leaf два вызова возвращают один объект" `Quick (fun () ->
      let l1 = My_solutions.mk_leaf () in
      let l2 = My_solutions.mk_leaf () in
      check int "same id" l1.id l2.id);

    test_case "при mk_node создаёт узел с id отличным от листа" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n = My_solutions.mk_node l l in
      check bool "different from leaf" true (n.id <> l.id));

    test_case "при одинаковых детях mk_node разделяет объекты" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n1 = My_solutions.mk_node l l in
      let n2 = My_solutions.mk_node l l in
      check int "same id" n1.id n2.id;
      check bool "physical eq" true (n1 == n2));

    test_case "при листе tree_size возвращает 1" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      check int "size" 1 (My_solutions.tree_size l));

    test_case "при простом дереве tree_size возвращает 2 уникальных узла" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n = My_solutions.mk_node l l in
      check int "size" 2 (My_solutions.tree_size n));

    test_case "при глубоком разделяемом дереве tree_size считает уникальные узлы" `Quick (fun () ->
      let l = My_solutions.mk_leaf () in
      let n1 = My_solutions.mk_node l l in
      let n2 = My_solutions.mk_node n1 n1 in
      let n3 = My_solutions.mk_node n2 n2 in
      (* l, n1, n2, n3 --- 4 уникальных узла *)
      check int "size" 4 (My_solutions.tree_size n3));
  ]

let exercise3_tests =
  let open Alcotest in
  [
    test_case "при 0 + x simplify возвращает x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_add (hc_num 0) x in
      let s = My_solutions.simplify e in
      check string "repr" "x" (string_of_hc_expr s));

    test_case "при x + 0 simplify возвращает x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_add x (hc_num 0) in
      let s = My_solutions.simplify e in
      check string "repr" "x" (string_of_hc_expr s));

    test_case "при 0 * x simplify возвращает 0" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul (hc_num 0) x in
      let s = My_solutions.simplify e in
      check string "repr" "0" (string_of_hc_expr s));

    test_case "при x * 0 simplify возвращает 0" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul x (hc_num 0) in
      let s = My_solutions.simplify e in
      check string "repr" "0" (string_of_hc_expr s));

    test_case "при 1 * x simplify возвращает x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul (hc_num 1) x in
      let s = My_solutions.simplify e in
      check string "repr" "x" (string_of_hc_expr s));

    test_case "при x * 1 simplify возвращает x" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_mul x (hc_num 1) in
      let s = My_solutions.simplify e in
      check string "repr" "x" (string_of_hc_expr s));

    test_case "при вложенном выражении simplify упрощает рекурсивно" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      (* (0 + x) * (1 * x) => x * x *)
      let e = hc_mul (hc_add (hc_num 0) x) (hc_mul (hc_num 1) x) in
      let s = My_solutions.simplify e in
      check string "repr" "(x * x)" (string_of_hc_expr s));

    test_case "при выражении без упрощений simplify возвращает исходное" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let y = hc_var "y" in
      let e = hc_add x y in
      let s = My_solutions.simplify e in
      check string "repr" "(x + y)" (string_of_hc_expr s));

    test_case "при упрощении 0 + x результат физически равен x" `Quick (fun () ->
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
    test_case "при одном числе count_unique_nodes возвращает 1" `Quick (fun () ->
      hc_reset ();
      let e = hc_num 5 in
      check int "count" 1 (My_solutions.count_unique_nodes e));

    test_case "при x + x count_unique_nodes считает 2 уникальных узла" `Quick (fun () ->
      hc_reset ();
      let x = hc_var "x" in
      let e = hc_add x x in
      (* x и add(x,x) --- 2 уникальных узла *)
      check int "count" 2 (My_solutions.count_unique_nodes e));

    test_case "при build_shared_hc 5 count_unique_nodes возвращает 6" `Quick (fun () ->
      hc_reset ();
      let e = build_shared_hc 5 in
      (* Уровни 0..5 --- 6 уникальных узлов *)
      check int "count" 6 (My_solutions.count_unique_nodes e));

    test_case "при одном числе count_nodes_regular возвращает 1" `Quick (fun () ->
      check int "count" 1 (My_solutions.count_nodes_regular (Num 5)));

    test_case "при Add(1,2) count_nodes_regular возвращает 3" `Quick (fun () ->
      let e = Add (Num 1, Num 2) in
      check int "count" 3 (My_solutions.count_nodes_regular e));

    test_case "при build_shared_tree 3 count_nodes_regular считает все узлы с повторами" `Quick (fun () ->
      let e = build_shared_tree 3 in
      (* 2^0 + 2^1 + 2^2 + 2^3 = 1+2+4+8 = 15 *)
      check int "count" 15 (My_solutions.count_nodes_regular e));

    test_case "при глубоком дереве обычный AST имеет значительно больше узлов чем hash-consed" `Quick (fun () ->
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
    test_case "при двух mk_pvar с одним именем hash-consing разделяет объекты" `Quick (fun () ->
      let p1 = My_solutions.mk_pvar "p" in
      let p2 = My_solutions.mk_pvar "p" in
      check int "same id" p1.id p2.id);

    test_case "при разных именах mk_pvar создаёт разные id" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      check bool "different" true (p.id <> q.id));

    test_case "при переменной nnf возвращает её без изменений" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let result = My_solutions.nnf p in
      check int "same id" p.id result.id);

    test_case "при двойном отрицании nnf устраняет оба отрицания" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let nn = My_solutions.mk_pnot (My_solutions.mk_pnot p) in
      let result = My_solutions.nnf nn in
      check int "same id as p" p.id result.id);

    test_case "при Not(And(p,q)) nnf применяет закон Де Моргана" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      (* Not(And(p, q)) => Or(Not p, Not q) *)
      let e = My_solutions.mk_pnot (My_solutions.mk_pand p q) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_por (My_solutions.mk_pnot p) (My_solutions.mk_pnot q) in
      check int "De Morgan And" expected.id result.id);

    test_case "при Not(Or(p,q)) nnf применяет закон Де Моргана" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      (* Not(Or(p, q)) => And(Not p, Not q) *)
      let e = My_solutions.mk_pnot (My_solutions.mk_por p q) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_pand (My_solutions.mk_pnot p) (My_solutions.mk_pnot q) in
      check int "De Morgan Or" expected.id result.id);

    test_case "при Not True nnf возвращает False" `Quick (fun () ->
      let e = My_solutions.mk_pnot (My_solutions.mk_ptrue ()) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_pfalse () in
      check int "id" expected.id result.id);

    test_case "при Not False nnf возвращает True" `Quick (fun () ->
      let e = My_solutions.mk_pnot (My_solutions.mk_pfalse ()) in
      let result = My_solutions.nnf e in
      let expected = My_solutions.mk_ptrue () in
      check int "id" expected.id result.id);

    test_case "при сложной формуле nnf преобразует корректно" `Quick (fun () ->
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
      check int "id" expected.id result.id);

    test_case "при True eval_prop возвращает true" `Quick (fun () ->
      let e = My_solutions.mk_ptrue () in
      check bool "value" true (My_solutions.eval_prop (fun _ -> false) e));

    test_case "при False eval_prop возвращает false" `Quick (fun () ->
      let e = My_solutions.mk_pfalse () in
      check bool "value" false (My_solutions.eval_prop (fun _ -> true) e));

    test_case "при переменной eval_prop берёт значение из окружения" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let env x = x = "p" in
      check bool "value" true (My_solutions.eval_prop env p));

    test_case "при And eval_prop возвращает конъюнкцию" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      let e = My_solutions.mk_pand p q in
      let env x = x = "p" || x = "q" in
      check bool "p&q=true" true (My_solutions.eval_prop env e);
      let env2 x = x = "p" in
      check bool "p&!q=false" false (My_solutions.eval_prop env2 e));

    test_case "при Or eval_prop возвращает дизъюнкцию" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let q = My_solutions.mk_pvar "q" in
      let e = My_solutions.mk_por p q in
      let env x = x = "p" in
      check bool "p=true => true" true (My_solutions.eval_prop env e);
      let env2 _ = false in
      check bool "both false => false" false (My_solutions.eval_prop env2 e));

    test_case "при Not eval_prop инвертирует значение" `Quick (fun () ->
      let p = My_solutions.mk_pvar "p" in
      let e = My_solutions.mk_pnot p in
      let env _ = true in
      check bool "value" false (My_solutions.eval_prop env e));

    test_case "при NNF преобразовании eval_prop сохраняет семантику" `Quick (fun () ->
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
