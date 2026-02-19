(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)
open Chapter21.Hashcons_ast

(** Упражнение 1: Unboxed-тип для положительных float.
    [@@unboxed] гарантирует, что Pos x имеет то же представление, что и x. *)
type positive_float = Pos of float [@@unboxed]

let mk_positive (x : float) : positive_float option =
  if x > 0.0 then Some (Pos x) else None

let get_value (Pos x : positive_float) : float = x

(** Упражнение 2: Hash-consing для бинарных деревьев. *)
type tree_node = Leaf | Node of hc_tree * hc_tree
and hc_tree = tree_node hcons

let tree_next_id = ref 0
let tree_table : (tree_node, hc_tree) Hashtbl.t = Hashtbl.create 251

let tree_hashcons (node : tree_node) : hc_tree =
  match Hashtbl.find_opt tree_table node with
  | Some existing -> existing
  | None ->
    let id = !tree_next_id in
    incr tree_next_id;
    let hkey = Hashtbl.hash node in
    let hc = { node; id; hkey } in
    Hashtbl.add tree_table node hc;
    hc

let mk_leaf () = tree_hashcons Leaf
let mk_node l r = tree_hashcons (Node (l, r))

(** Подсчёт уникальных узлов в дереве (каждый узел считается один раз). *)
let tree_size (t : hc_tree) : int =
  let visited = Hashtbl.create 16 in
  let rec go (t : hc_tree) =
    if Hashtbl.mem visited t.id then ()
    else begin
      Hashtbl.add visited t.id true;
      match t.node with
      | Leaf -> ()
      | Node (l, r) -> go l; go r
    end
  in
  go t;
  Hashtbl.length visited

(** Упражнение 3: Упрощение hash-consed выражений.
    Правила:
    - 0 + x = x, x + 0 = x
    - 0 * x = 0, x * 0 = 0
    - 1 * x = x, x * 1 = x *)
let rec simplify (e : hc_expr) : hc_expr =
  match e.node with
  | HNum _ | HVar _ -> e
  | HAdd (a, b) ->
    let a' = simplify a in
    let b' = simplify b in
    (match a'.node, b'.node with
     | HNum 0, _ -> b'
     | _, HNum 0 -> a'
     | _ -> hc_add a' b')
  | HMul (a, b) ->
    let a' = simplify a in
    let b' = simplify b in
    (match a'.node, b'.node with
     | HNum 0, _ -> hc_num 0
     | _, HNum 0 -> hc_num 0
     | HNum 1, _ -> b'
     | _, HNum 1 -> a'
     | _ -> hc_mul a' b')

(** Упражнение 4: Подсчёт уникальных узлов в hash-consed выражении. *)
let count_unique_nodes (e : hc_expr) : int =
  let visited = Hashtbl.create 16 in
  let rec go (e : hc_expr) =
    if Hashtbl.mem visited e.id then ()
    else begin
      Hashtbl.add visited e.id true;
      match e.node with
      | HNum _ | HVar _ -> ()
      | HAdd (a, b) | HMul (a, b) -> go a; go b
    end
  in
  go e;
  Hashtbl.length visited

(** Подсчёт всех узлов в обычном AST (считая повторы). *)
let rec count_nodes_regular (e : expr) : int =
  match e with
  | Num _ | Var _ -> 1
  | Add (a, b) | Mul (a, b) -> 1 + count_nodes_regular a + count_nodes_regular b

(** Упражнение 5: Hash-consed формулы пропозициональной логики. *)
type prop_node =
  | PVar of string
  | PAnd of hc_prop * hc_prop
  | POr of hc_prop * hc_prop
  | PNot of hc_prop
  | PTrue
  | PFalse
and hc_prop = prop_node hcons

let prop_next_id = ref 0
let prop_table : (prop_node, hc_prop) Hashtbl.t = Hashtbl.create 251

let prop_hashcons (node : prop_node) : hc_prop =
  match Hashtbl.find_opt prop_table node with
  | Some existing -> existing
  | None ->
    let id = !prop_next_id in
    incr prop_next_id;
    let hkey = Hashtbl.hash node in
    let hc = { node; id; hkey } in
    Hashtbl.add prop_table node hc;
    hc

let mk_pvar x = prop_hashcons (PVar x)
let mk_pand a b = prop_hashcons (PAnd (a, b))
let mk_por a b = prop_hashcons (POr (a, b))
let mk_pnot a = prop_hashcons (PNot a)
let mk_ptrue () = prop_hashcons PTrue
let mk_pfalse () = prop_hashcons PFalse

(** Преобразование в негативную нормальную форму (NNF).
    Отрицания «проталкиваются» вниз до переменных. *)
let rec nnf (p : hc_prop) : hc_prop =
  match p.node with
  | PVar _ | PTrue | PFalse -> p
  | PAnd (a, b) -> mk_pand (nnf a) (nnf b)
  | POr (a, b) -> mk_por (nnf a) (nnf b)
  | PNot inner ->
    (match inner.node with
     | PVar _ -> p  (* Not(Var x) --- уже NNF *)
     | PTrue -> mk_pfalse ()
     | PFalse -> mk_ptrue ()
     | PNot a -> nnf a  (* двойное отрицание *)
     | PAnd (a, b) -> mk_por (nnf (mk_pnot a)) (nnf (mk_pnot b))  (* Де Морган *)
     | POr (a, b) -> mk_pand (nnf (mk_pnot a)) (nnf (mk_pnot b))  (* Де Морган *))

(** Вычисление формулы при данном назначении переменных. *)
let rec eval_prop (env : string -> bool) (p : hc_prop) : bool =
  match p.node with
  | PVar x -> env x
  | PAnd (a, b) -> eval_prop env a && eval_prop env b
  | POr (a, b) -> eval_prop env a || eval_prop env b
  | PNot a -> not (eval_prop env a)
  | PTrue -> true
  | PFalse -> false
