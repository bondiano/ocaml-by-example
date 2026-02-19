(** Здесь вы можете писать свои решения упражнений. *)

open Chapter17.Brain_games

(** Упражнение 1: Игра "угадай оператор" --- дано "a ? b = c", угадайте оператор. *)
let balance_game : game =
  ignore (fun () -> { question = ""; correct_answer = "" });
  { description = "todo";
    generate_round = (fun () -> failwith "todo") }

(** Упражнение 2: Чистая логика игры --- принимает список ответов, возвращает bool. *)
let run_game_result (game : game) ~(rounds : int) (answers : string list) : bool =
  ignore game; ignore rounds; ignore answers;
  failwith "todo"

(** Упражнение 3: Обобщённый конструктор игры. *)
let make_game ~(description : string) ~(generate : unit -> string * string) : game =
  ignore description; ignore generate;
  failwith "todo"

(** Упражнение 4: Игра --- разложить число на простые множители. *)
let factor_game : game =
  ignore (fun () -> { question = ""; correct_answer = "" });
  { description = "todo";
    generate_round = (fun () -> failwith "todo") }
