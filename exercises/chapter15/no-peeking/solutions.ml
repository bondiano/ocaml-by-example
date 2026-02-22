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

(** Упражнение 5: Todo CLI --- команда add. *)
let todo_add_cmd =
  let open Cmdliner in
  let open Chapter15.Cli_tools in
  let add_term =
    let text_arg = Arg.(required & pos 0 (some string) None & info [] ~docv:"TEXT") in
    Term.(const add_todo $ text_arg)
  in
  Cmd.v (Cmd.info "add" ~doc:"Добавить задачу") add_term

(** Упражнение 6: Todo CLI --- команда list. *)
let todo_list_cmd =
  let open Cmdliner in
  let open Chapter15.Cli_tools in
  let list_term = Term.(const list_todos $ const ()) in
  Cmd.v (Cmd.info "list" ~doc:"Показать все задачи") list_term

(** Упражнение 7: Калькулятор CLI. *)
let calculator_cmd =
  let open Cmdliner in
  let calc a b op =
    let result = match op with
      | "add" -> a + b
      | "sub" -> a - b
      | "mul" -> a * b
      | "div" -> if b <> 0 then a / b else (Printf.printf "Ошибка: деление на ноль\n"; 0)
      | _ -> Printf.printf "Неизвестная операция: %s\n" op; 0
    in
    Printf.printf "%d\n" result
  in
  let calc_term =
    let a_arg = Arg.(required & pos 0 (some int) None & info [] ~docv:"A") in
    let b_arg = Arg.(required & pos 1 (some int) None & info [] ~docv:"B") in
    let op_arg = Arg.(value & opt string "add" & info ["op"] ~docv:"OP"
                       ~doc:"Operation: add, sub, mul, div") in
    Term.(const calc $ a_arg $ b_arg $ op_arg)
  in
  Cmd.v (Cmd.info "calculator" ~doc:"Простой калькулятор") calc_term

(** Упражнение 8: Grep-like утилита. *)
let grep ~case_insensitive pattern lines =
  let pattern_lower = String.lowercase_ascii pattern in
  List.filter (fun line ->
    let line_to_check = if case_insensitive
      then String.lowercase_ascii line
      else line in
    let pattern_to_find = if case_insensitive
      then pattern_lower
      else pattern in
    (* Простой поиск подстроки *)
    let rec contains s sub =
      let slen = String.length s in
      let sublen = String.length sub in
      if sublen > slen then false
      else if sublen = 0 then true
      else
        let rec check i =
          if i > slen - sublen then false
          else if String.sub s i sublen = sub then true
          else check (i + 1)
        in
        check 0
    in
    contains line_to_check pattern_to_find
  ) lines
