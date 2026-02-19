(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Angstrom

let ws = skip_while (fun c -> c = ' ' || c = '\t')

(** Парсер списка целых чисел. *)
let int_list_parser : int list t =
  let integer = ws *> take_while1 (fun c -> c >= '0' && c <= '9') >>| int_of_string in
  ws *> char '[' *> sep_by (ws *> char ',') integer <* ws <* char ']'

(** Парсер key=value. *)
let key_value_parser : (string * string) t =
  let key = take_while1 (fun c -> c <> '=' && c <> ' ') in
  let value = take_while1 (fun c -> c <> ' ' && c <> '\n') in
  lift2 (fun k v -> (k, v)) (key <* char '=') value

(** GADT с Not и Gt. *)
type _ extended_expr =
  | Int : int -> int extended_expr
  | Bool : bool -> bool extended_expr
  | Add : int extended_expr * int extended_expr -> int extended_expr
  | Not : bool extended_expr -> bool extended_expr
  | Gt : int extended_expr * int extended_expr -> bool extended_expr

let rec eval_extended : type a. a extended_expr -> a = function
  | Int n -> n
  | Bool b -> b
  | Add (a, b) -> eval_extended a + eval_extended b
  | Not e -> not (eval_extended e)
  | Gt (a, b) -> eval_extended a > eval_extended b

(** Парсер арифметических выражений. *)
let arith_parser : int t =
  let integer = ws *> take_while1 (fun c -> c >= '0' && c <= '9') >>| int_of_string in
  let parens p = ws *> char '(' *> p <* ws <* char ')' in
  fix (fun expr ->
    let atom = integer <|> parens expr in
    let rec chain_mul acc =
      (ws *> char '*' *> atom >>= fun r -> chain_mul (acc * r))
      <|> return acc
    in
    let mul_expr = atom >>= chain_mul in
    let rec chain_add acc =
      (ws *> char '+' *> mul_expr >>= fun r -> chain_add (acc + r))
      <|> return acc
    in
    mul_expr >>= chain_add
  )

(** Matching Brackets. *)
let matching_brackets s =
  let matching = function
    | ')' -> '(' | ']' -> '[' | '}' -> '{' | _ -> ' '
  in
  let rec check stack i =
    if i >= String.length s then stack = []
    else
      match s.[i] with
      | '(' | '[' | '{' -> check (s.[i] :: stack) (i + 1)
      | ')' | ']' | '}' ->
        (match stack with
         | top :: rest when top = matching s.[i] -> check rest (i + 1)
         | _ -> false)
      | _ -> check stack (i + 1)
  in
  check [] 0

(** Word Count. *)
let word_count s =
  let lower = String.lowercase_ascii s in
  let is_word_char c =
    (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c = '\''
  in
  let words = ref [] in
  let buf = Buffer.create 16 in
  String.iter (fun c ->
    if is_word_char c then Buffer.add_char buf c
    else if Buffer.length buf > 0 then begin
      let word = Buffer.contents buf in
      (* Trim leading/trailing apostrophes *)
      let word = String.trim word in
      let word =
        if String.length word > 0 && word.[0] = '\'' then String.sub word 1 (String.length word - 1)
        else word in
      let word =
        if String.length word > 0 && word.[String.length word - 1] = '\'' then
          String.sub word 0 (String.length word - 1)
        else word in
      if String.length word > 0 then words := word :: !words;
      Buffer.clear buf
    end
  ) lower;
  if Buffer.length buf > 0 then begin
    let word = Buffer.contents buf in
    let word =
      if String.length word > 0 && word.[0] = '\'' then String.sub word 1 (String.length word - 1)
      else word in
    let word =
      if String.length word > 0 && word.[String.length word - 1] = '\'' then
        String.sub word 0 (String.length word - 1)
      else word in
    if String.length word > 0 then words := word :: !words
  end;
  let table = Hashtbl.create 16 in
  List.iter (fun w ->
    let n = try Hashtbl.find table w with Not_found -> 0 in
    Hashtbl.replace table w (n + 1)
  ) !words;
  Hashtbl.fold (fun k v acc -> (k, v) :: acc) table []
