(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Chapter04.Shapes

(** Вычислить площадь фигуры. *)
let area = function
  | Circle (_, r) -> Float.pi *. r *. r
  | Rectangle (_, w, h) -> w *. h
  | Line _ -> 0.0
  | Text _ -> 0.0

(** Масштабировать фигуру на заданный множитель. *)
let scale factor = function
  | Circle (c, r) ->
    Circle ({ x = c.x *. factor; y = c.y *. factor }, r *. factor)
  | Rectangle (c, w, h) ->
    Rectangle ({ x = c.x *. factor; y = c.y *. factor },
               w *. factor, h *. factor)
  | Line (p1, p2) ->
    Line ({ x = p1.x *. factor; y = p1.y *. factor },
          { x = p2.x *. factor; y = p2.y *. factor })
  | Text (p, s) ->
    Text ({ x = p.x *. factor; y = p.y *. factor }, s)

(** Извлечь текст из фигуры Text, если она является текстом. *)
let shape_text = function
  | Text (_, s) -> Some s
  | _ -> None

(** Безопасное извлечение первого элемента списка. *)
let safe_head = function
  | [] -> None
  | x :: _ -> Some x

(** Bob. *)
let bob input =
  let trimmed = String.trim input in
  let is_question = String.length trimmed > 0 && trimmed.[String.length trimmed - 1] = '?' in
  let has_letters = String.exists (fun c -> (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) trimmed in
  let is_yelling = has_letters && String.equal trimmed (String.uppercase_ascii trimmed) in
  let is_silence = String.length trimmed = 0 in
  match is_silence, is_yelling, is_question with
  | true, _, _ -> "Fine. Be that way!"
  | _, true, true -> "Calm down, I know what I'm doing!"
  | _, true, false -> "Whoa, chill out!"
  | _, false, true -> "Sure."
  | _, false, false -> "Whatever."

(** Triangle classification. *)
type triangle = Equilateral | Isosceles | Scalene

let classify_triangle a b c =
  if a <= 0.0 || b <= 0.0 || c <= 0.0 then Error "стороны должны быть положительными"
  else if a +. b <= c || a +. c <= b || b +. c <= a then Error "нарушено неравенство треугольника"
  else if a = b && b = c then Ok Equilateral
  else if a = b || b = c || a = c then Ok Isosceles
  else Ok Scalene

(** Raindrops. *)
let raindrops n =
  let s = Buffer.create 16 in
  if n mod 3 = 0 then Buffer.add_string s "Pling";
  if n mod 5 = 0 then Buffer.add_string s "Plang";
  if n mod 7 = 0 then Buffer.add_string s "Plong";
  if Buffer.length s = 0 then string_of_int n
  else Buffer.contents s

(** Perfect Numbers. *)
type classification = Perfect | Abundant | Deficient

let classify n =
  if n <= 0 then Error "число должно быть положительным"
  else
    let sum = ref 0 in
    for i = 1 to n - 1 do
      if n mod i = 0 then sum := !sum + i
    done;
    if !sum = n then Ok Perfect
    else if !sum > n then Ok Abundant
    else Ok Deficient

(** Allergies. *)
type allergen =
  | Eggs | Peanuts | Shellfish | Strawberries
  | Tomatoes | Chocolate | Pollen | Cats

let allergen_score = function
  | Eggs -> 1 | Peanuts -> 2 | Shellfish -> 4 | Strawberries -> 8
  | Tomatoes -> 16 | Chocolate -> 32 | Pollen -> 64 | Cats -> 128

let all_allergens = [Eggs; Peanuts; Shellfish; Strawberries; Tomatoes; Chocolate; Pollen; Cats]

let is_allergic_to allergen score =
  score land allergen_score allergen <> 0

let allergies score =
  List.filter (fun a -> is_allergic_to a score) all_allergens
