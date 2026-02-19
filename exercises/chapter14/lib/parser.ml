(** Примеры парсер-комбинаторов и GADT. *)

open Angstrom

(** --- Парсеры --- *)

(** Пропустить пробелы. *)
let ws = skip_while (fun c -> c = ' ' || c = '\t' || c = '\n' || c = '\r')

(** Парсер целого числа. *)
let integer =
  ws *> take_while1 (fun c -> c >= '0' && c <= '9') >>| int_of_string

(** Парсер строки в кавычках. *)
let quoted_string =
  ws *> char '"' *> take_while (fun c -> c <> '"') <* char '"'

(** Парсер булевого значения. *)
let boolean =
  ws *> (string "true" *> return true <|> string "false" *> return false)

(** --- Простой JSON-подобный парсер --- *)

type json_value =
  | JNull
  | JBool of bool
  | JInt of int
  | JString of string
  | JArray of json_value list
  | JObject of (string * json_value) list

let json_value =
  fix (fun json_value ->
    let jnull = ws *> string "null" *> return JNull in
    let jbool = boolean >>| fun b -> JBool b in
    let jint = integer >>| fun n -> JInt n in
    let jstring = quoted_string >>| fun s -> JString s in
    let jarray =
      ws *> char '[' *>
      sep_by (ws *> char ',') json_value
      <* ws <* char ']' >>| fun items -> JArray items
    in
    let key_value =
      lift2 (fun k v -> (k, v))
        (quoted_string <* ws <* char ':')
        json_value
    in
    let jobject =
      ws *> char '{' *>
      sep_by (ws *> char ',') key_value
      <* ws <* char '}' >>| fun pairs -> JObject pairs
    in
    jnull <|> jbool <|> jint <|> jstring <|> jarray <|> jobject
  )

(** Парсить JSON-строку. *)
let parse_json str =
  parse_string ~consume:All (ws *> json_value <* ws) str

(** --- GADT для типобезопасных выражений --- *)

type _ expr =
  | Int : int -> int expr
  | Bool : bool -> bool expr
  | Add : int expr * int expr -> int expr
  | Mul : int expr * int expr -> int expr
  | Eq : int expr * int expr -> bool expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr

(** Типобезопасное вычисление выражения. *)
let rec eval : type a. a expr -> a = function
  | Int n -> n
  | Bool b -> b
  | Add (a, b) -> eval a + eval b
  | Mul (a, b) -> eval a * eval b
  | Eq (a, b) -> eval a = eval b
  | If (cond, then_, else_) ->
    if eval cond then eval then_ else eval else_

(** Показать выражение в виде строки. *)
let rec show_expr : type a. a expr -> string = function
  | Int n -> string_of_int n
  | Bool b -> string_of_bool b
  | Add (a, b) -> Printf.sprintf "(%s + %s)" (show_expr a) (show_expr b)
  | Mul (a, b) -> Printf.sprintf "(%s * %s)" (show_expr a) (show_expr b)
  | Eq (a, b) -> Printf.sprintf "(%s = %s)" (show_expr a) (show_expr b)
  | If (c, t, e) -> Printf.sprintf "(if %s then %s else %s)" (show_expr c) (show_expr t) (show_expr e)
