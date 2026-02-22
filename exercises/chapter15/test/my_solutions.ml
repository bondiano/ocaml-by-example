(** Здесь вы можете писать свои решения упражнений. *)

open Chapter15.Brain_games

(* ===== Brain Games ===== *)

(* Среднее *)
(** Упражнение 1: balance_game — игра "угадай оператор".

    Создать игру, где пользователю показывается уравнение вида "a ? b = c",
    и нужно угадать оператор (?, может быть +, -, *, /).

    Тип game:
    {[
      type round = { question : string; correct_answer : string }
      type game = {
        description : string;
        generate_round : unit -> round;
      }
    ]}

    Примеры раундов:
    {[
      { question = "5 ? 3 = 8"; correct_answer = "+" }
      { question = "10 ? 2 = 5"; correct_answer = "/" }
      { question = "7 ? 4 = 3"; correct_answer = "-" }
    ]}

    Подсказки:
    1. Random.int для генерации случайных чисел
    2. Случайно выбрать оператор: [|"+"; "-"; "*"; "/"|].(Random.int 4)
    3. Вычислить результат: match op with "+" -> a + b | ...
    4. Для деления: убедитесь что b <> 0 и a mod b = 0 (без остатка)
    5. generate_round возвращает новый раунд при каждом вызове
    6. description: "Guess the operator"

    Связанные темы: Game design, random generation, pattern matching
    Время: ~15 минут *)
let balance_game : game =
  ignore (fun () -> { question = ""; correct_answer = "" });
  { description = "todo";
    generate_round = (fun () -> failwith "todo") }

(* Среднее *)
(** Упражнение 2: run_game_result — чистая логика игры без I/O.

    Запустить игру rounds раундов, принимая ответы из списка answers,
    и вернуть true если все ответы правильные.

    Это чистая функция (без побочных эффектов) для тестирования логики игры.

    Параметры:
    - game: игра с generate_round
    - rounds: количество раундов
    - answers: список ответов пользователя

    Возвращает:
    - true если все ответы правильные
    - false если хотя бы один неправильный

    Примеры:
    {[
      let mock_game = {
        description = "test";
        generate_round = (fun () -> { question = "2+2=?"; correct_answer = "4" })
      }

      run_game_result mock_game ~rounds:3 ["4"; "4"; "4"] = true
      run_game_result mock_game ~rounds:3 ["4"; "5"; "4"] = false
    ]}

    Подсказки:
    1. Используйте List.fold_left или for loop
    2. Для каждого раунда:
       - Сгенерировать раунд: game.generate_round ()
       - Взять ответ из списка: List.nth answers i
       - Сравнить с correct_answer
    3. Накапливайте результат: все ли ответы правильные
    4. List.for_all для проверки всех элементов

    Связанные темы: Pure functions, game logic, testing
    Время: ~15 минут *)
let run_game_result (game : game) ~(rounds : int) (answers : string list) : bool =
  ignore game; ignore rounds; ignore answers;
  failwith "todo"

(* Лёгкое *)
(** Упражнение 3: make_game — конструктор игры.

    Создать игру из description и функции генерации.

    Параметры:
    - description: описание игры
    - generate: функция () -> (question, answer)

    Возвращает:
    - game с generate_round обёрнутой в нужный тип

    Примеры:
    {[
      let my_game = make_game
        ~description:"Simple addition"
        ~generate:(fun () -> ("2+2=?", "4"))

      my_game.description = "Simple addition"
      let round = my_game.generate_round ()
      round = { question = "2+2=?"; correct_answer = "4" }
    ]}

    Подсказки:
    1. Простая конструкция record:
       {
         description;
         generate_round = (fun () ->
           let (q, a) = generate () in
           { question = q; correct_answer = a }
         )
       }

    Связанные темы: Constructors, abstraction, function composition
    Время: ~8 минут *)
let make_game ~(description : string) ~(generate : unit -> string * string) : game =
  ignore description; ignore generate;
  failwith "todo"

(* Среднее *)
(** Упражнение 4: factor_game — игра на разложение на простые множители.

    Создать игру, где нужно разложить число на простые множители.

    Примеры раундов:
    {[
      { question = "Разложите 12 на простые множители"; correct_answer = "2 2 3" }
      { question = "Разложите 15 на простые множители"; correct_answer = "3 5" }
      { question = "Разложите 7 на простые множители"; correct_answer = "7" }
    ]}

    Подсказки:
    1. Генерация случайного числа 2..100
    2. Функция факторизации:
       {[
         let rec factors n d acc =
           if n = 1 then List.rev acc
           else if n mod d = 0 then factors (n / d) d (d :: acc)
           else factors n (d + 1) acc
       ]}
    3. Начать с d = 2
    4. Преобразовать список в строку: String.concat " " (List.map string_of_int factors)
    5. generate_round генерирует число и его факторы

    Связанные темы: Prime factorization, algorithms, game generation
    Время: ~20 минут *)
let factor_game : game =
  ignore (fun () -> { question = ""; correct_answer = "" });
  { description = "todo";
    generate_round = (fun () -> failwith "todo") }

(* ===== Cmdliner CLI ===== *)

(* Среднее *)
(** Упражнение 5: todo_add_cmd — команда добавления задачи.

    Реализовать команду CLI для добавления задачи в todo список.

    Использование:
    {[
      todo add "Buy groceries"
    ]}

    Структура:
    1. Определить term для аргумента (текст задачи)
    2. Создать Cmd.v с info и term

    Подсказки:
    1. Позиционный аргумент:
       {[
         let task_arg = Cmdliner.Arg.(
           required & pos 0 (some string) None & info [] ~docv:"TASK"
         )
       ]}
    2. Term для действия:
       {[
         let add_term = Cmdliner.Term.(
           const (fun task -> Chapter15.Cli_tools.add_todo task) $ task_arg
         )
       ]}
    3. Создать команду:
       {[
         Cmdliner.Cmd.v
           (Cmdliner.Cmd.info "add" ~doc:"Add a new task")
           add_term
       ]}

    Связанные темы: Cmdliner, CLI design, argument parsing
    Время: ~15 минут *)
let todo_add_cmd : unit Cmdliner.Cmd.t =
  failwith "todo"

(* Лёгкое *)
(** Упражнение 6: todo_list_cmd — команда вывода задач.

    Реализовать команду CLI для вывода всех задач.

    Использование:
    {[
      todo list
    ]}

    Не принимает аргументов, просто вызывает Cli_tools.list_todos.

    Подсказки:
    1. Term без аргументов:
       {[
         let list_term = Cmdliner.Term.(
           const (fun () -> Chapter15.Cli_tools.list_todos ())
         )
       ]}
    2. Создать команду:
       {[
         Cmdliner.Cmd.v
           (Cmdliner.Cmd.info "list" ~doc:"List all tasks")
           list_term
       ]}

    Связанные темы: Cmdliner, simple commands
    Время: ~8 минут *)
let todo_list_cmd : unit Cmdliner.Cmd.t =
  failwith "todo"

(* Среднее *)
(** Упражнение 7: calculator_cmd — калькулятор CLI.

    Реализовать простой калькулятор с операциями через флаг.

    Использование:
    {[
      calculator 5 3 --op add    # 8
      calculator 10 2 --op div   # 5
    ]}

    Операции: add, sub, mul, div

    Подсказки:
    1. Два позиционных аргумента (числа):
       {[
         let x_arg = Cmdliner.Arg.(required & pos 0 (some int) None & info [])
         let y_arg = Cmdliner.Arg.(required & pos 1 (some int) None & info [])
       ]}
    2. Флаг для операции:
       {[
         let op_arg = Cmdliner.Arg.(
           required & opt (some (enum ["add",`Add; "sub",`Sub; "mul",`Mul; "div",`Div])) None
           & info ["op"] ~docv:"OP"
         )
       ]}
    3. Term:
       {[
         let calc x y op =
           let result = match op with
             | `Add -> x + y
             | `Sub -> x - y
             | `Mul -> x * y
             | `Div -> x / y
           in
           print_endline (string_of_int result)
       ]}
    4. Cmdliner.Term.(const calc $ x_arg $ y_arg $ op_arg)

    Связанные темы: Cmdliner, flags, enums, command-line calculators
    Время: ~18 минут *)
let calculator_cmd : unit Cmdliner.Cmd.t =
  failwith "todo"

(* ===== Утилиты ===== *)

(* Лёгкое *)
(** Упражнение 8: grep — простой поиск строк.

    Реализовать функцию поиска строк, содержащих паттерн.

    Параметры:
    - case_insensitive: игнорировать регистр
    - pattern: строка для поиска
    - lines: список строк

    Возвращает: строки, содержащие паттерн

    Примеры:
    {[
      grep ~case_insensitive:false "hello" ["hello world"; "hi there"; "HELLO"]
        = ["hello world"]

      grep ~case_insensitive:true "hello" ["hello world"; "hi there"; "HELLO"]
        = ["hello world"; "HELLO"]
    ]}

    Подсказки:
    1. Если case_insensitive:
       - String.lowercase_ascii для преобразования в нижний регистр
       - Сравнивать lowercase версии
    2. String.contains_s или Str.string_match
    3. Простой способ: String.lowercase_ascii line |> fun s -> String.mem pattern s
    4. Или Re для регулярных выражений
    5. List.filter для фильтрации строк

    Связанные темы: String matching, case-insensitive search, grep utilities
    Время: ~10 минут *)
let grep ~case_insensitive _pattern _lines : string list =
  ignore case_insensitive;
  failwith "todo"
