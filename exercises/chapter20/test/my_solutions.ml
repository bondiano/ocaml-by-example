(** Здесь вы можете писать свои решения упражнений. *)
open Chapter20.Hashcons_ast

(* ===== Unboxed types ===== *)

(* Лёгкое *)
(** Упражнение 1: positive_float — unboxed тип для положительных чисел.

    Использовать [@@unboxed] для эффективного представления newtype.

    Аннотация [@@unboxed] говорит компилятору не создавать обёртку,
    а использовать напрямую float в памяти.

    Задачи:
    a) mk_positive: создать положительное число (с валидацией)
    b) get_value: извлечь значение

    Примеры:
    {[
      mk_positive 5.0 = Some (Pos 5.0)
      mk_positive (-3.0) = None
      mk_positive 0.0 = None

      let x = mk_positive 5.0 |> Option.get in
      get_value x = 5.0
    ]}

    Подсказки:
    1. mk_positive:
       {[
         if x > 0.0 then Some (Pos x) else None
       ]}
    2. get_value:
       {[
         let (Pos x) = pf in x
       ]}
    3. [@@unboxed] делает Pos прозрачной обёрткой (нет runtime overhead)

    Связанные темы: Unboxed types, zero-cost abstractions, newtypes
    Время: ~10 минут *)
type positive_float = Pos of float [@@unboxed]

let mk_positive (_x : float) : positive_float option =
  failwith "todo"

let get_value (_pf : positive_float) : float =
  failwith "todo"

(* ===== Hash-consing для деревьев ===== *)

(* Среднее *)
(** Упражнение 2: tree hash-consing — структурное разделение для деревьев.

    Hash-consing обеспечивает что идентичные поддеревья представлены
    одним объектом в памяти (structural sharing).

    Задачи:
    a) mk_leaf: создать hash-consed лист
    b) mk_node: создать hash-consed узел
    c) tree_size: подсчитать общее количество узлов (с учётом sharing)

    Примеры:
    {[
      let leaf = mk_leaf () in
      let t1 = mk_node leaf leaf in
      let t2 = mk_node t1 t1 in

      (* t1 содержит два раза один и тот же leaf объект *)
      (* t2 содержит два раза один и тот же t1 объект *)

      tree_size leaf = 1
      tree_size t1 = 3  (* 1 node + 2 leaves, но leaves shared *)
      tree_size t2 = 7  (* или меньше с учётом sharing *)
    ]}

    Подсказки:
    1. Используйте hashcons из Chapter20.Hashcons_ast:
       {[
         val hashcons : 'a -> 'a hcons
       ]}
    2. mk_leaf: hashcons Leaf
    3. mk_node l r: hashcons (Node (l, r))
    4. tree_size:
       {[
         let rec size t =
           match t.node with
           | Leaf -> 1
           | Node (l, r) -> 1 + size l + size r
       ]}
    5. Hash-consing автоматически обеспечивает sharing

    Связанные темы: Hash-consing, structural sharing, memory optimization
    Время: ~20 минут *)
type tree_node = Leaf | Node of hc_tree * hc_tree
and hc_tree = tree_node hcons

let mk_leaf : unit -> hc_tree = fun () ->
  failwith "todo"

let mk_node (_l : hc_tree) (_r : hc_tree) : hc_tree =
  failwith "todo"

let tree_size (_t : hc_tree) : int =
  failwith "todo"

(* ===== Hash-consing для выражений ===== *)

(* Среднее *)
(** Упражнение 3: simplify — упрощение hash-consed выражений.

    Упростить алгебраические выражения используя hash-consing.

    Правила упрощения:
    - 0 + x = x
    - x + 0 = x
    - 0 * x = 0
    - x * 0 = 0
    - 1 * x = x
    - x * 1 = x

    Тип expr определён в Chapter20.Hashcons_ast:
    {[
      type expr_node = Int of int | Add of hc_expr * hc_expr | Mul of hc_expr * hc_expr
      and hc_expr = expr_node hcons
    ]}

    Примеры:
    {[
      simplify (0 + x) = x
      simplify (x * 0) = 0
      simplify (1 * x) = x
      simplify ((x + 0) * 1) = x
    ]}

    Подсказки:
    1. Pattern matching на e.node:
       {[
         match e.node with
         | Int n -> e  (* уже простое *)
         | Add (a, b) ->
             let a' = simplify a in
             let b' = simplify b in
             (match a'.node, b'.node with
              | Int 0, _ -> b'
              | _, Int 0 -> a'
              | _ -> mk_add a' b')  (* используйте конструктор из lib *)
         | Mul (a, b) -> ...
       ]}
    2. Используйте конструкторы из Chapter20.Hashcons_ast
    3. Рекурсивно упрощайте подвыражения

    Связанные темы: Expression simplification, pattern matching, algebraic rules
    Время: ~15 минут *)
let simplify (_e : hc_expr) : hc_expr =
  failwith "todo"

(* Среднее *)
(** Упражнение 4: count_unique_nodes — подсчёт уникальных узлов.

    Подсчитать количество уникальных узлов в hash-consed выражении.

    Благодаря hash-consing, можно использовать физическое равенство (==)
    для определения одинаковых поддеревьев.

    Также реализовать count_nodes_regular для обычных (не hash-consed) выражений
    для сравнения.

    Примеры:
    {[
      let x = mk_int 5 in
      let e = mk_add x x in  (* x используется дважды, но это один объект *)

      count_unique_nodes e = 2  (* узел Add + узел Int(5) *)

      (* Для обычного дерева без hash-consing: *)
      let e_regular = Add (Int 5, Int 5) in
      count_nodes_regular e_regular = 3  (* Add + Int + Int *)
    ]}

    Подсказки:
    1. count_unique_nodes:
       {[
         let visited = Hashtbl.create 16 in
         let rec count e =
           if Hashtbl.mem visited e.id then 0
           else begin
             Hashtbl.add visited e.id ();
             match e.node with
             | Int _ -> 1
             | Add (a, b) | Mul (a, b) -> 1 + count a + count b
           end
         in count expr
       ]}
    2. e.id — уникальный идентификатор hash-consed узла
    3. count_nodes_regular: рекурсия без memoization

    Связанные темы: Hash-consing benefits, memoization, graph traversal
    Время: ~15 минут *)
let count_unique_nodes (_e : hc_expr) : int =
  failwith "todo"

let count_nodes_regular (_e : expr) : int =
  ignore _e;
  failwith "todo"

(* ===== Пропозициональная логика ===== *)

(* Сложное *)
(** Упражнение 5: propositional logic — hash-consing для логических формул.

    Реализовать hash-consed представление пропозициональной логики:
    - Переменные: PVar "x"
    - Операции: PAnd, POr, PNot
    - Константы: PTrue, PFalse

    Задачи:
    a) Конструкторы для всех узлов (mk_pvar, mk_pand, и т.д.)
    b) nnf: преобразование в Negation Normal Form (NNF)
    c) eval_prop: вычисление формулы при заданной оценке переменных

    NNF правила:
    - Двойное отрицание: ¬¬A = A
    - Де Моргана: ¬(A ∧ B) = ¬A ∨ ¬B
    - Де Моргана: ¬(A ∨ B) = ¬A ∧ ¬B

    Примеры:
    {[
      let x = mk_pvar "x" in
      let y = mk_pvar "y" in
      let formula = mk_pand x y in

      eval_prop (function "x" -> true | "y" -> true | _ -> false) formula = true
      eval_prop (function "x" -> true | "y" -> false | _ -> false) formula = false

      (* NNF *)
      let not_and = mk_pnot (mk_pand x y) in
      nnf not_and = mk_por (mk_pnot x) (mk_pnot y)  (* ¬(x ∧ y) = ¬x ∨ ¬y *)
    ]}

    Подсказки:
    1. Конструкторы: hashcons (PVar x), hashcons (PAnd (a, b)), и т.д.
    2. nnf:
       {[
         let rec nnf p =
           match p.node with
           | PVar _ | PTrue | PFalse -> p
           | PAnd (a, b) -> mk_pand (nnf a) (nnf b)
           | POr (a, b) -> mk_por (nnf a) (nnf b)
           | PNot p' ->
               (match p'.node with
                | PNot p'' -> nnf p''  (* двойное отрицание *)
                | PAnd (a, b) -> mk_por (nnf (mk_pnot a)) (nnf (mk_pnot b))  (* Де Морган *)
                | POr (a, b) -> mk_pand (nnf (mk_pnot a)) (nnf (mk_pnot b))  (* Де Морган *)
                | PTrue -> mk_pfalse ()
                | PFalse -> mk_ptrue ()
                | PVar _ -> p  (* уже в NNF *)
                | PNot _ -> failwith "impossible")
       ]}
    3. eval_prop:
       {[
         let rec eval env p =
           match p.node with
           | PVar x -> env x
           | PTrue -> true
           | PFalse -> false
           | PAnd (a, b) -> eval env a && eval env b
           | POr (a, b) -> eval env a || eval env b
           | PNot a -> not (eval env a)
       ]}

    Связанные темы: Propositional logic, NNF transformation, SAT solving
    Время: ~40 минут *)
type prop_node =
  | PVar of string
  | PAnd of hc_prop * hc_prop
  | POr of hc_prop * hc_prop
  | PNot of hc_prop
  | PTrue
  | PFalse
and hc_prop = prop_node hcons

let mk_pvar (_x : string) : hc_prop =
  failwith "todo"

let mk_pand (_a : hc_prop) (_b : hc_prop) : hc_prop =
  failwith "todo"

let mk_por (_a : hc_prop) (_b : hc_prop) : hc_prop =
  failwith "todo"

let mk_pnot (_a : hc_prop) : hc_prop =
  failwith "todo"

let mk_ptrue : unit -> hc_prop = fun () ->
  failwith "todo"

let mk_pfalse : unit -> hc_prop = fun () ->
  failwith "todo"

let nnf (_p : hc_prop) : hc_prop =
  failwith "todo"

let eval_prop (_env : string -> bool) (_p : hc_prop) : bool =
  failwith "todo"
