(** Задача Эйлера №1

    Найти сумму всех чисел, кратных 3 или 5, меньше заданного предела. *)

let answer limit =
  let rec go acc n =
    if n >= limit then acc
    else if n mod 3 = 0 || n mod 5 = 0 then go (acc + n) (n + 1)
    else go acc (n + 1)
  in
  go 0 1

(** === Хвостовая рекурсия === *)

(** Non-tail-recursive сумма списка — для сравнения. *)
let rec sum_naive = function
  | [] -> 0
  | hd :: tl -> hd + sum_naive tl

(** Tail-recursive сумма списка с аккумулятором. *)
let sum lst =
  let rec loop acc = function
    | [] -> acc
    | hd :: tl -> (loop [@tailcall]) (hd + acc) tl
  in
  loop 0 lst

(** Tail-recursive factorial. *)
let factorial n =
  let rec loop acc = function
    | 0 -> acc
    | n -> (loop [@tailcall]) (acc * n) (n - 1)
  in
  loop 1 n

(** [@tail_mod_cons] — оптимизация конструирования списков. *)
let[@tail_mod_cons] rec filter_even = function
  | [] -> []
  | hd :: tl ->
    if hd mod 2 = 0 then hd :: filter_even tl
    else filter_even tl

(** Решето Эратосфена — tail-recursive. *)
let sieve limit =
  let rec mark_multiples prime step arr =
    if prime * step <= limit then begin
      arr.(prime * step) <- false;
      mark_multiples prime (step + 1) arr
    end
  in
  let arr = Array.make (limit + 1) true in
  arr.(0) <- false;
  if limit >= 1 then arr.(1) <- false;
  let rec loop i =
    if i * i > limit then ()
    else begin
      if arr.(i) then mark_multiples i 2 arr;
      loop (i + 1)
    end
  in
  loop 2;
  let rec collect acc i =
    if i < 2 then acc
    else if arr.(i) then collect (i :: acc) (i - 1)
    else collect acc (i - 1)
  in
  collect [] limit
