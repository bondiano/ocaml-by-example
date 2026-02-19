(** Hash-consed AST для арифметических выражений.

    Этот модуль реализует hash-consing --- технику разделения памяти
    между структурно равными значениями. Каждому уникальному выражению
    присваивается уникальный идентификатор, что позволяет сравнивать
    выражения за O(1) по id. *)

(** {1 Обёртка hash-consing} *)

(** Обёрнутое значение с уникальным id и предвычисленным хешем. *)
type 'a hcons = {
  node : 'a;
  id : int;
  hkey : int;
}

(** {1 Обычный (не hash-consed) AST} *)

(** Арифметическое выражение без hash-consing. *)
type expr =
  | Num of int
  | Var of string
  | Add of expr * expr
  | Mul of expr * expr

(** {1 Hash-consed AST} *)

(** Узел hash-consed выражения. *)
type hc_expr_node =
  | HNum of int
  | HVar of string
  | HAdd of hc_expr * hc_expr
  | HMul of hc_expr * hc_expr
and hc_expr = hc_expr_node hcons

(** Глобальный счётчик для уникальных id. *)
let hc_next_id = ref 0

(** Hash-таблица: ключ --- узел, значение --- обёрнутый узел. *)
let hc_table : (hc_expr_node, hc_expr) Hashtbl.t = Hashtbl.create 251

(** Сбросить состояние hash-consing (полезно для тестов). *)
let hc_reset () =
  Hashtbl.clear hc_table;
  hc_next_id := 0

(** Создать или найти hash-consed значение. *)
let hc_make (node : hc_expr_node) : hc_expr =
  match Hashtbl.find_opt hc_table node with
  | Some existing -> existing
  | None ->
    let id = !hc_next_id in
    incr hc_next_id;
    let hkey = Hashtbl.hash node in
    let hc = { node; id; hkey } in
    Hashtbl.add hc_table node hc;
    hc

(** {2 Smart-конструкторы} *)

(** Создать числовую константу. *)
let hc_num n = hc_make (HNum n)

(** Создать переменную. *)
let hc_var x = hc_make (HVar x)

(** Создать сумму. *)
let hc_add a b = hc_make (HAdd (a, b))

(** Создать произведение. *)
let hc_mul a b = hc_make (HMul (a, b))

(** {1 Вычисление выражений} *)

(** Вычислить обычное выражение.
    [env] --- ассоциативный список [(имя, значение)].
    Неизвестные переменные считаются равными 0. *)
let rec eval_expr env = function
  | Num n -> n
  | Var x ->
    (match List.assoc_opt x env with Some v -> v | None -> 0)
  | Add (a, b) -> eval_expr env a + eval_expr env b
  | Mul (a, b) -> eval_expr env a * eval_expr env b

(** Вычислить hash-consed выражение. *)
let rec eval_hc_expr env (e : hc_expr) =
  match e.node with
  | HNum n -> n
  | HVar x ->
    (match List.assoc_opt x env with Some v -> v | None -> 0)
  | HAdd (a, b) -> eval_hc_expr env a + eval_hc_expr env b
  | HMul (a, b) -> eval_hc_expr env a * eval_hc_expr env b

(** {1 Построение деревьев с разделяемыми поддеревьями} *)

(** Построить дерево [Add(sub, sub)] глубины [n].
    Без hash-consing дерево выглядит как 2^n узлов (хотя
    OCaml физически разделяет через let). *)
let rec build_shared_tree n =
  if n = 0 then Num 1
  else
    let sub = build_shared_tree (n - 1) in
    Add (sub, sub)

(** Построить hash-consed дерево [Add(sub, sub)] глубины [n].
    Создаётся ровно [n+1] уникальный узел. *)
let rec build_shared_hc n =
  if n = 0 then hc_num 1
  else
    let sub = build_shared_hc (n - 1) in
    hc_add sub sub

(** {1 Статистика памяти} *)

(** Вызвать [f ()] и вернуть разницу в [live_words] до и после. *)
let measure_live_words f =
  Gc.full_major ();
  let before = Gc.stat () in
  let result = f () in
  Gc.full_major ();
  let after = Gc.stat () in
  (result, after.Gc.live_words - before.Gc.live_words)

(** Вывести сравнение потребления памяти для обычного и hash-consed AST. *)
let print_memory_comparison n =
  hc_reset ();
  let (_tree, regular_words) = measure_live_words (fun () ->
    build_shared_tree n
  ) in
  let (_hc_tree, hc_words) = measure_live_words (fun () ->
    build_shared_hc n
  ) in
  Printf.printf "Глубина: %d\n" n;
  Printf.printf "  Обычный AST: ~%d live_words\n" regular_words;
  Printf.printf "  Hash-consed: ~%d live_words\n" hc_words;
  Printf.printf "  Уникальных узлов в hash-таблице: %d\n"
    (Hashtbl.length hc_table)

(** {1 Преобразование в строку} *)

(** Строковое представление обычного выражения. *)
let rec string_of_expr = function
  | Num n -> string_of_int n
  | Var x -> x
  | Add (a, b) ->
    Printf.sprintf "(%s + %s)" (string_of_expr a) (string_of_expr b)
  | Mul (a, b) ->
    Printf.sprintf "(%s * %s)" (string_of_expr a) (string_of_expr b)

(** Строковое представление hash-consed выражения. *)
let rec string_of_hc_expr (e : hc_expr) =
  match e.node with
  | HNum n -> string_of_int n
  | HVar x -> x
  | HAdd (a, b) ->
    Printf.sprintf "(%s + %s)" (string_of_hc_expr a) (string_of_hc_expr b)
  | HMul (a, b) ->
    Printf.sprintf "(%s * %s)" (string_of_hc_expr a) (string_of_hc_expr b)
