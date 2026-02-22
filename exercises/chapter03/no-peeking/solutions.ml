(* Решения для упражнений главы 03 *)

(* Упражнение 1: Високосный год *)
let is_leap_year year =
  (year mod 4 = 0 && year mod 100 <> 0) || year mod 400 = 0

(* Упражнение 2: Треугольник *)
let triangle a b c =
  if a <= 0 || b <= 0 || c <= 0 || a + b <= c || a + c <= b || b + c <= a then
    "invalid"
  else if a = b && b = c then "equilateral"
  else if a = b || b = c || a = c then "isosceles"
  else "scalene"

(* Упражнение 3: Raindrops *)
let raindrops n =
  let result =
    (if n mod 3 = 0 then "Pling" else "")
    ^ (if n mod 5 = 0 then "Plang" else "")
    ^ (if n mod 7 = 0 then "Plong" else "")
  in
  if result = "" then string_of_int n else result

(* Упражнение 4: Форматирование имени *)
let format_name first last =
  let capitalize s =
    let s_lower = String.lowercase_ascii s in
    String.mapi (fun i c -> if i = 0 then Char.uppercase_ascii c else c) s_lower
  in
  capitalize last ^ ", " ^ capitalize first

(* Упражнение 5: Сумма списка *)
let rec sum_list = function
  | [] -> 0
  | x :: xs -> x + sum_list xs

(* Упражнение 6: Фибоначчи *)
let rec fib n =
  if n <= 1 then n else fib (n - 1) + fib (n - 2)
