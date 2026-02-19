(** Референсные решения — не подсматривайте, пока не попробуете сами! *)

let diagonal w h = Float.sqrt ((w *. w) +. (h *. h))

let circle_area r = Float.pi *. r *. r

let rec collatz_length n =
  if n = 1 then 0
  else if n mod 2 = 0 then 1 + collatz_length (n / 2)
  else 1 + collatz_length ((3 * n) + 1)

(** Leap Year — високосный год. *)
let is_leap_year year =
  (year mod 4 = 0 && year mod 100 <> 0) || year mod 400 = 0

(** Space Age — возраст на планетах. *)
type planet = Mercury | Venus | Earth | Mars | Jupiter | Saturn | Uranus | Neptune

let space_age planet seconds =
  let earth_year = 31557600.0 in
  let orbital_period = match planet with
    | Mercury -> 0.2408467
    | Venus -> 0.61519726
    | Earth -> 1.0
    | Mars -> 1.8808158
    | Jupiter -> 11.862615
    | Saturn -> 29.447498
    | Uranus -> 84.016846
    | Neptune -> 164.79132
  in
  seconds /. (earth_year *. orbital_period)

(** Difference of Squares. *)
let square_of_sum n =
  let s = n * (n + 1) / 2 in
  s * s

let sum_of_squares n =
  n * (n + 1) * (2 * n + 1) / 6

let difference_of_squares n =
  square_of_sum n - sum_of_squares n

(** Решето Эратосфена. *)
let sieve limit =
  let arr = Array.make (limit + 1) true in
  arr.(0) <- false;
  if limit >= 1 then arr.(1) <- false;
  for i = 2 to int_of_float (Float.sqrt (float_of_int limit)) do
    if arr.(i) then
      let j = ref (i * i) in
      while !j <= limit do
        arr.(!j) <- false;
        j := !j + i
      done
  done;
  let result = ref [] in
  for i = limit downto 2 do
    if arr.(i) then result := i :: !result
  done;
  !result
