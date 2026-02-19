(** Brain Games --- 5 математических мини-игр как CLI-приложение. *)

(** Описание одного раунда. *)
type round = { question : string; correct_answer : string }

(** Описание игры. *)
type game = { description : string; generate_round : unit -> round }

(** Генератор случайных чисел в диапазоне [lo, hi]. *)
let random_int lo hi =
  lo + Random.int (hi - lo + 1)

(** Наибольший общий делитель. *)
let rec gcd a b =
  if b = 0 then a else gcd b (a mod b)

(** Проверка на простоту. *)
let is_prime n =
  if n < 2 then false
  else
    let rec check i =
      if i * i > n then true
      else if n mod i = 0 then false
      else check (i + 1)
    in
    check 2

(** Запуск игры: интерактивный цикл с stdin/stdout. *)
let run_game name game ~rounds =
  Printf.printf "Добро пожаловать в %s!\n" name;
  Printf.printf "%s\n" game.description;
  Printf.printf "Как вас зовут? ";
  let user_name = read_line () in
  Printf.printf "Привет, %s!\n" user_name;
  let rec loop i =
    if i > rounds then (
      Printf.printf "Поздравляю, %s!\n" user_name;
      true)
    else
      let r = game.generate_round () in
      Printf.printf "Вопрос: %s\n" r.question;
      Printf.printf "Ваш ответ: ";
      let answer = read_line () in
      if String.lowercase_ascii answer = String.lowercase_ascii r.correct_answer then (
        Printf.printf "Верно!\n";
        loop (i + 1))
      else (
        Printf.printf "'%s' --- неправильный ответ ;(. Правильный ответ: '%s'.\n"
          answer r.correct_answer;
        Printf.printf "Попробуем ещё раз, %s!\n" user_name;
        false)
  in
  loop 1

(** Игра: чётное ли число? *)
let even_game : game =
  { description = "Ответьте 'yes', если число чётное, иначе --- 'no'.";
    generate_round = (fun () ->
      let n = random_int 1 100 in
      { question = string_of_int n;
        correct_answer = if n mod 2 = 0 then "yes" else "no" })
  }

(** Игра: вычислить выражение. *)
let calc_game : game =
  let ops = [| "+"; "-"; "*" |] in
  { description = "Вычислите результат выражения.";
    generate_round = (fun () ->
      let a = random_int 1 50 in
      let b = random_int 1 50 in
      let op = ops.(Random.int 3) in
      let result = match op with
        | "+" -> a + b
        | "-" -> a - b
        | "*" -> a * b
        | _ -> assert false
      in
      { question = Printf.sprintf "%d %s %d" a op b;
        correct_answer = string_of_int result })
  }

(** Игра: НОД двух чисел. *)
let gcd_game : game =
  { description = "Найдите наибольший общий делитель.";
    generate_round = (fun () ->
      let a = random_int 2 100 in
      let b = random_int 2 100 in
      { question = Printf.sprintf "%d %d" a b;
        correct_answer = string_of_int (gcd a b) })
  }

(** Игра: найти пропущенный элемент арифметической прогрессии. *)
let progression_game : game =
  { description = "Какое число пропущено в прогрессии?";
    generate_round = (fun () ->
      let start = random_int 1 50 in
      let step = random_int 2 10 in
      let len = 10 in
      let hidden_idx = Random.int len in
      let hidden_value = start + hidden_idx * step in
      let seq = List.init len (fun i ->
        if i = hidden_idx then ".."
        else string_of_int (start + i * step))
      in
      { question = String.concat " " seq;
        correct_answer = string_of_int hidden_value })
  }

(** Игра: простое ли число? *)
let prime_game : game =
  { description = "Ответьте 'yes', если число простое, иначе --- 'no'.";
    generate_round = (fun () ->
      let n = random_int 2 100 in
      { question = string_of_int n;
        correct_answer = if is_prime n then "yes" else "no" })
  }
