(** Рекурсивные схемы --- реализация с нуля. *)

(* ===== Функторы (один уровень структуры) ===== *)

(** Один уровень списка. Параметр ['a] --- рекурсивная позиция. *)
type 'a list_f =
  | Nil
  | Cons of int * 'a

(** map для list_f: применяет функцию только к рекурсивной позиции. *)
let map_list_f (f : 'a -> 'b) : 'a list_f -> 'b list_f = function
  | Nil -> Nil
  | Cons (x, rest) -> Cons (x, f rest)

(** Один уровень двоичного дерева. *)
type 'a tree_f =
  | Leaf
  | Node of 'a * int * 'a

(** map для tree_f. *)
let map_tree_f (f : 'a -> 'b) : 'a tree_f -> 'b tree_f = function
  | Leaf -> Leaf
  | Node (l, x, r) -> Node (f l, x, f r)

(* ===== Fix-point типы ===== *)

(** Fix-point для list_f: рекурсивный список через обёртку. *)
type fix_list = Fix_list of fix_list list_f

(** Fix-point для tree_f: рекурсивное дерево через обёртку. *)
type fix_tree = Fix_tree of fix_tree tree_f

(** Обернуть один уровень списка в fix-point. *)
let fix_list (l : fix_list list_f) : fix_list = Fix_list l

(** Развернуть один уровень fix-point списка. *)
let unfix_list (Fix_list l) : fix_list list_f = l

(** Обернуть один уровень дерева в fix-point. *)
let fix_tree (t : fix_tree tree_f) : fix_tree = Fix_tree t

(** Развернуть один уровень fix-point дерева. *)
let unfix_tree (Fix_tree t) : fix_tree tree_f = t

(* ===== Утилиты для конструирования ===== *)

(** Построить fix_list из обычного списка int. *)
let fix_list_of_list (lst : int list) : fix_list =
  List.fold_right (fun x acc -> Fix_list (Cons (x, acc))) lst (Fix_list Nil)

(** Преобразовать fix_list обратно в обычный список int. *)
let list_of_fix_list (fl : fix_list) : int list =
  let rec go (Fix_list layer) =
    match layer with
    | Nil -> []
    | Cons (x, rest) -> x :: go rest
  in
  go fl

(* ===== Катаморфизм (обобщённый fold) ===== *)

(** Катаморфизм для списка.
    [cata_list alg fix] --- сворачивает fix_list снизу вверх по алгебре [alg]. *)
let rec cata_list (alg : 'a list_f -> 'a) (Fix_list layer : fix_list) : 'a =
  alg (map_list_f (cata_list alg) layer)

(** Катаморфизм для дерева. *)
let rec cata_tree (alg : 'a tree_f -> 'a) (Fix_tree layer : fix_tree) : 'a =
  alg (map_tree_f (cata_tree alg) layer)

(* ===== Анаморфизм (обобщённый unfold) ===== *)

(** Анаморфизм для списка.
    [ana_list coalg seed] --- строит fix_list сверху вниз по коалгебре [coalg]. *)
let rec ana_list (coalg : 'a -> 'a list_f) (seed : 'a) : fix_list =
  Fix_list (map_list_f (ana_list coalg) (coalg seed))

(** Анаморфизм для дерева. *)
let rec ana_tree (coalg : 'a -> 'a tree_f) (seed : 'a) : fix_tree =
  Fix_tree (map_tree_f (ana_tree coalg) (coalg seed))

(* ===== Гиломорфизм (unfold + fold без промежуточной структуры) ===== *)

(** Гиломорфизм для списка.
    [hylo_list alg coalg seed] --- разворачивает seed по coalg и тут же
    сворачивает по alg, не создавая промежуточную структуру. *)
let rec hylo_list
    (alg : 'b list_f -> 'b)
    (coalg : 'a -> 'a list_f)
    (seed : 'a) : 'b =
  alg (map_list_f (hylo_list alg coalg) (coalg seed))

(** Гиломорфизм для дерева. *)
let rec hylo_tree
    (alg : 'b tree_f -> 'b)
    (coalg : 'a -> 'a tree_f)
    (seed : 'a) : 'b =
  alg (map_tree_f (hylo_tree alg coalg) (coalg seed))

(* ===== Параморфизм (fold с доступом к исходной структуре) ===== *)

(** Параморфизм для списка.
    Алгебра получает пару (исходная подструктура, результат свёртки)
    в каждой рекурсивной позиции. *)
let rec para_list
    (alg : (fix_list * 'a) list_f -> 'a)
    (Fix_list layer : fix_list) : 'a =
  let mapped = map_list_f
    (fun sub -> (sub, para_list alg sub))
    layer
  in
  alg mapped

(** Параморфизм для дерева. *)
let rec para_tree
    (alg : (fix_tree * 'a) tree_f -> 'a)
    (Fix_tree layer : fix_tree) : 'a =
  let mapped = map_tree_f
    (fun sub -> (sub, para_tree alg sub))
    layer
  in
  alg mapped

(* ===== Обобщённый модульный функтор ===== *)

(** Сигнатура функтора (в категорно-теоретическом смысле). *)
module type FUNCTOR = sig
  type 'a t
  val map : ('a -> 'b) -> 'a t -> 'b t
end

(** Модульный функтор: генерирует fix-point тип и все рекурсивные схемы
    для произвольного функтора. *)
module MakeSchemes (F : FUNCTOR) = struct
  type fix = Fix of fix F.t

  let fix (layer : fix F.t) : fix = Fix layer
  let unfix (Fix layer) : fix F.t = layer

  let rec cata (alg : 'a F.t -> 'a) (Fix layer : fix) : 'a =
    alg (F.map (cata alg) layer)

  let rec ana (coalg : 'a -> 'a F.t) (seed : 'a) : fix =
    Fix (F.map (ana coalg) (coalg seed))

  let rec hylo (alg : 'b F.t -> 'b) (coalg : 'a -> 'a F.t) (seed : 'a) : 'b =
    alg (F.map (hylo alg coalg) (coalg seed))

  let rec para (alg : (fix * 'a) F.t -> 'a) (Fix layer : fix) : 'a =
    let mapped = F.map (fun sub -> (sub, para alg sub)) layer in
    alg mapped
end

(* ===== JSON функтор ===== *)

(** Один уровень JSON-структуры. *)
type 'a json_f =
  | JNull
  | JBool of bool
  | JNumber of float
  | JString of string
  | JArray of 'a list
  | JObject of (string * 'a) list

(** map для json_f. *)
let map_json_f (f : 'a -> 'b) : 'a json_f -> 'b json_f = function
  | JNull -> JNull
  | JBool b -> JBool b
  | JNumber n -> JNumber n
  | JString s -> JString s
  | JArray items -> JArray (List.map f items)
  | JObject fields -> JObject (List.map (fun (k, v) -> (k, f v)) fields)

(** Модуль JSON-функтора для использования с MakeSchemes. *)
module JsonF = struct
  type 'a t = 'a json_f
  let map = map_json_f
end

(** Рекурсивные схемы для JSON. *)
module JsonSchemes = MakeSchemes (JsonF)

(** Тип JSON --- fix-point json_f. *)
type json = JsonSchemes.fix

(* ===== Конструкторы JSON ===== *)

let jnull : json = JsonSchemes.fix JNull
let jbool (b : bool) : json = JsonSchemes.fix (JBool b)
let jnumber (n : float) : json = JsonSchemes.fix (JNumber n)
let jstring (s : string) : json = JsonSchemes.fix (JString s)
let jarray (items : json list) : json = JsonSchemes.fix (JArray items)
let jobject (fields : (string * json) list) : json = JsonSchemes.fix (JObject fields)

(* ===== Pretty-printer через cata ===== *)

(** Красивая печать JSON через катаморфизм.
    Алгебра возвращает функцию [int -> string], где аргумент --- уровень отступа. *)
let pretty_print (j : json) : string =
  let indent n s =
    let pad = String.make (n * 2) ' ' in
    pad ^ s
  in
  let alg : (int -> string) json_f -> (int -> string) = function
    | JNull -> fun _ -> "null"
    | JBool b -> fun _ -> string_of_bool b
    | JNumber n -> fun _ ->
      if Float.is_integer n then string_of_int (int_of_float n)
      else string_of_float n
    | JString s -> fun _ -> Printf.sprintf "\"%s\"" s
    | JArray items -> fun depth ->
      if items = [] then "[]"
      else
        let inner =
          List.map (fun f -> indent (depth + 1) (f (depth + 1))) items
        in
        "[\n" ^ String.concat ",\n" inner ^ "\n" ^ indent depth "]"
    | JObject fields -> fun depth ->
      if fields = [] then "{}"
      else
        let inner = List.map (fun (k, f) ->
          indent (depth + 1)
            (Printf.sprintf "\"%s\": %s" k (f (depth + 1)))
        ) fields in
        "{\n" ^ String.concat ",\n" inner ^ "\n" ^ indent depth "}"
  in
  (JsonSchemes.cata alg j) 0

(* ===== Глубина JSON через cata ===== *)

(** Вычисление глубины вложенности JSON. *)
let json_depth (j : json) : int =
  let alg : int json_f -> int = function
    | JNull | JBool _ | JNumber _ | JString _ -> 0
    | JArray items ->
      1 + List.fold_left max 0 items
    | JObject fields ->
      1 + List.fold_left (fun acc (_, d) -> max acc d) 0 fields
  in
  JsonSchemes.cata alg j

(* ===== Генерация JSON через ana ===== *)

(** Тип схемы для генерации JSON. *)
type schema =
  | SNull
  | SBool
  | SNumber
  | SString
  | SArray of schema
  | SObject of (string * schema) list

(** Генерация JSON из описания схемы через анаморфизм. *)
let schema_to_json (s : schema) : json =
  let coalg : schema -> schema json_f = function
    | SNull -> JString "null"
    | SBool -> JString "boolean"
    | SNumber -> JString "number"
    | SString -> JString "string"
    | SArray inner ->
      JObject [("type", SString); ("items", inner)]
    | SObject fields ->
      JObject (("type", SString) :: fields)
  in
  JsonSchemes.ana coalg s
