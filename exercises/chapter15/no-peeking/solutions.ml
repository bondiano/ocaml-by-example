(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Chapter15.Brain_games

(** Упражнение 1: Игра "угадай оператор". *)
let balance_game : game =
  let ops = [| ("+", ( + )); ("-", ( - )); ("*", ( * )) |] in
  { description = "Дано 'a ? b = c'. Какой оператор?";
    generate_round = (fun () ->
      let a = random_int 1 20 in
      let b = random_int 1 20 in
      let idx = Random.int 3 in
      let (op_str, op_fn) = ops.(idx) in
      let c = op_fn a b in
      { question = Printf.sprintf "%d ? %d = %d" a b c;
        correct_answer = op_str })
  }

(** Упражнение 2: Чистая логика игры. *)
let run_game_result (game : game) ~(rounds : int) (answers : string list) : bool =
  let rec loop i answers =
    if i > rounds then true
    else match answers with
      | [] -> false
      | answer :: rest ->
        let r = game.generate_round () in
        if String.lowercase_ascii answer = String.lowercase_ascii r.correct_answer
        then loop (i + 1) rest
        else false
  in
  loop 1 answers

(** Упражнение 3: Обобщённый конструктор игры. *)
let make_game ~(description : string) ~(generate : unit -> string * string) : game =
  { description;
    generate_round = (fun () ->
      let (question, correct_answer) = generate () in
      { question; correct_answer })
  }

(** Упражнение 4: Разложение на простые множители. *)
let factor_game : game =
  { description = "Разложите число на простые множители.";
    generate_round = (fun () ->
      let n = random_int 4 100 in
      let rec factorize n d =
        if n <= 1 then []
        else if n mod d = 0 then d :: factorize (n / d) d
        else factorize n (d + 1)
      in
      let factors = factorize n 2 in
      { question = string_of_int n;
        correct_answer = String.concat " " (List.map string_of_int factors) })
  }
