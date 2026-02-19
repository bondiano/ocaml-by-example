# CLI-приложения с Cmdliner

## Цели главы

В этой главе мы научимся создавать полноценные **CLI-приложения** (Command-Line Interface) на OCaml с помощью библиотеки **Cmdliner**. Мы изучим:

- **Декларативное определение** аргументов, опций и подкоманд.
- **Интерактивный ввод** --- чтение данных от пользователя через `read_line`.
- **Модульную архитектуру** игры --- типы `round` и `game`, движок с циклом раундов.
- **Проект Brain Games** --- 5 математических мини-игр, объединённых в одно CLI-приложение с подкомандами.

## Подготовка проекта

Код этой главы находится в `exercises/chapter15`. Для работы потребуется библиотека Cmdliner:

```text
$ opam install cmdliner
$ cd exercises/chapter15
$ dune build
```

В `dune`-файле библиотеки указана зависимость от `cmdliner`:

```text
(library
 (name chapter17)
 (libraries cmdliner))
```

## Cmdliner: декларативные CLI

[Cmdliner](https://erratique.ch/software/cmdliner) --- библиотека для построения CLI-приложений в декларативном стиле. Вместо ручного разбора `Sys.argv` вы описываете **что** ваша программа принимает, а Cmdliner берёт на себя парсинг, валидацию, генерацию справки (`--help`) и обработку ошибок.

Три ключевых понятия Cmdliner:

- **`Arg`** --- описание одного аргумента или опции (тип, значение по умолчанию, имя, документация).
- **`Term`** --- комбинация функции и её аргументов. Term связывает чистую функцию с аргументами командной строки.
- **`Cmd`** --- команда с именем, документацией и привязанным Term. Команды можно группировать в подкоманды.

Философия Cmdliner --- **аппликативный стиль**: вы описываете аргументы как отдельные значения, а затем комбинируете их с функцией через оператор `$`. Это похоже на аппликативные парсеры в Haskell.

```admonish tip title="Для Python/TS-разработчиков"
В Python для CLI обычно используют `argparse` (стандартная библиотека) или `click`. В TypeScript --- `commander` или `yargs`. Cmdliner ближе всего к `click` по духу: вы декларативно описываете аргументы, а фреймворк берёт на себя парсинг и генерацию справки. Ключевое отличие --- Cmdliner использует аппликативный стиль (`Term.(const f $ a $ b)`), что обеспечивает статическую типобезопасность: если вы забыли аргумент или перепутали типы, ошибка будет на этапе компиляции, а не в рантайме.
```

## Простая команда

Начнём с минимального примера --- программы, которая приветствует пользователя по имени:

```ocaml
open Cmdliner

let name =
  let doc = "Name to greet." in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"NAME" ~doc)

let hello name =
  Printf.printf "Hello, %s!\n" name

let cmd =
  let doc = "Say hello" in
  let info = Cmd.info "hello" ~doc in
  Cmd.v info Term.(const hello $ name)

let () = exit (Cmd.eval cmd)
```

Разберём по частям:

- `Arg.(required & pos 0 (some string) None & info [] ~docv:"NAME" ~doc)` --- позиционный аргумент на позиции 0, тип `string`, обязательный (`required`). `~docv:"NAME"` задаёт имя аргумента в справке.
- `Term.(const hello $ name)` --- применяем функцию `hello` к аргументу `name`. Оператор `$` --- это аппликативное применение: левая часть --- функция в контексте Term, правая --- аргумент в контексте Term.
- `Cmd.v info term` --- создаёт команду из метаинформации и терма.
- `Cmd.eval cmd` --- запускает команду, парсит аргументы, вызывает функцию и возвращает код выхода.

Запуск:

```text
$ ./hello World
Hello, World!

$ ./hello --help
NAME
       hello - Say hello

SYNOPSIS
       hello [OPTION]... NAME

ARGUMENTS
       NAME (required)
           Name to greet.
```

Cmdliner автоматически генерирует справку, обрабатывает `--help` и `--version`, и выдаёт понятные сообщения об ошибках при неправильных аргументах.

## Аргументы и опции

Cmdliner различает **позиционные аргументы** и **именованные опции**:

### Позиционные аргументы

```ocaml
(* Обязательный строковый аргумент на позиции 0 *)
let name =
  Arg.(required & pos 0 (some string) None & info [] ~docv:"NAME" ~doc:"Name")

(* Необязательный аргумент с значением по умолчанию *)
let greeting =
  Arg.(value & pos 1 string "Hello" & info [] ~docv:"GREETING" ~doc:"Greeting word")
```

- `required` --- аргумент обязателен, программа завершится с ошибкой, если его не указать.
- `value` --- аргумент необязателен, используется значение по умолчанию.
- `pos N type default` --- позиционный аргумент на позиции N.

### Флаги (булевы опции)

```ocaml
let verbose =
  let doc = "Enable verbose output." in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)
```

Флаг --- опция без значения. `info ["v"; "verbose"]` означает, что опция принимается как `-v` или `--verbose`. Если флаг указан, значение --- `true`, иначе --- `false`.

### Опции со значениями

```ocaml
let rounds =
  let doc = "Number of rounds." in
  Arg.(value & opt int 3 & info ["r"; "rounds"] ~doc ~docv:"N")
```

`opt int 3` --- опция типа `int` со значением по умолчанию `3`. Пользователь может указать `-r 5` или `--rounds=5`.

### Комбинирование аргументов

Несколько аргументов комбинируются через оператор `$`:

```ocaml
let greet verbose rounds name =
  if verbose then Printf.printf "[DEBUG] Starting with %d rounds\n" rounds;
  for _ = 1 to rounds do
    Printf.printf "Hello, %s!\n" name
  done

let cmd =
  let info = Cmd.info "greet" ~doc:"Greet someone multiple times" in
  Cmd.v info Term.(const greet $ verbose $ rounds $ name)
```

Порядок аргументов в `const f $ a $ b $ c` должен соответствовать порядку параметров функции `f`. Это аппликативный стиль: `const f $ a $ b` эквивалентно `f a b`, но каждый аргумент парсится из командной строки.

## Подкоманды

Для приложений с несколькими режимами работы (как `git commit`, `git push`) Cmdliner поддерживает **подкоманды** через `Cmd.group`:

```ocaml
let even_cmd =
  let info = Cmd.info "even" ~doc:"Is the number even?" in
  Cmd.v info Term.(const run_even $ rounds)

let calc_cmd =
  let info = Cmd.info "calc" ~doc:"Calculate the expression" in
  Cmd.v info Term.(const run_calc $ rounds)

let gcd_cmd =
  let info = Cmd.info "gcd" ~doc:"Find the GCD" in
  Cmd.v info Term.(const run_gcd $ rounds)

let group =
  let doc = "Brain Games --- математические мини-игры" in
  let info = Cmd.info "brain-games" ~doc in
  Cmd.group info [even_cmd; calc_cmd; gcd_cmd]

let () = exit (Cmd.eval group)
```

Теперь программа поддерживает подкоманды:

```text
$ brain-games even --rounds 5
$ brain-games calc
$ brain-games gcd -r 10
$ brain-games --help
```

`Cmd.group` принимает метаинформацию и список подкоманд. При запуске без подкоманды выводится справка со списком доступных подкоманд.

```admonish tip title="Для Python/TS-разработчиков"
Подкоманды в Cmdliner работают как в `click.group()` (Python) или `commander.command()` (TypeScript). Например, `git commit`, `git push` --- это подкоманды. В Python `click` вы пишете `@cli.command()`, а в Cmdliner --- `Cmd.group info [cmd1; cmd2]`. Принцип одинаков: группа объединяет несколько команд под общим именем.
```

## Генерация случайных чисел

Для генерации вопросов в мини-играх нам понадобятся случайные числа. Стандартная библиотека OCaml предоставляет модуль `Random`:

```ocaml
(* Инициализация генератора *)
Random.self_init ()

(* Случайное число от 0 до n-1 *)
Random.int 100   (* 0..99 *)

(* Случайное число в диапазоне [lo, hi] *)
let random_int lo hi =
  lo + Random.int (hi - lo + 1)
```

Функция `Random.self_init ()` инициализирует генератор системным источником энтропии. Без инициализации генератор будет выдавать одну и ту же последовательность при каждом запуске.

Вспомогательная функция `random_int lo hi` генерирует случайное целое число в **замкнутом** диапазоне `[lo, hi]`. Мы используем её во всех играх для генерации чисел, операторов и индексов.

## Взаимодействие с пользователем

CLI-игра требует диалога с пользователем: задать вопрос, прочитать ответ, проверить и вывести результат.

Для чтения ввода используем `read_line`:

```ocaml
Printf.printf "Как вас зовут? ";
let name = read_line () in
Printf.printf "Привет, %s!\n" name
```

`read_line ()` читает одну строку из `stdin` (до символа новой строки). Если ввод закончился (EOF), функция бросает исключение `End_of_file`.

Паттерн "вопрос --- ответ --- проверка" выглядит так:

```ocaml
let ask_question question correct_answer =
  Printf.printf "Вопрос: %s\n" question;
  Printf.printf "Ваш ответ: ";
  let answer = read_line () in
  if String.lowercase_ascii answer = String.lowercase_ascii correct_answer then (
    Printf.printf "Верно!\n";
    true)
  else (
    Printf.printf "'%s' --- неправильный ответ ;(. Правильный ответ: '%s'.\n"
      answer correct_answer;
    false)
```

Сравнение через `String.lowercase_ascii` делает проверку нечувствительной к регистру --- пользователь может ввести "Yes", "YES" или "yes".

## Модульная архитектура игры

Все пять игр следуют одному и тому же паттерну: задай вопрос, получи ответ, проверь. Отличаются только способ генерации вопроса и правильный ответ. Этот паттерн удобно выразить через типы:

```ocaml
type round = { question : string; correct_answer : string }
type game = { description : string; generate_round : unit -> round }
```

- `round` --- один раунд: вопрос и правильный ответ.
- `game` --- игра: текстовое описание правил и функция генерации раунда.

Тип `game` --- по сути, **стратегия**: он инкапсулирует поведение (генерацию вопросов), не фиксируя конкретную логику. Каждая мини-игра --- это значение типа `game` с собственным `generate_round`.

### Движок игры

Движок --- функция `run_game`, которая принимает имя игры, описание и количество раундов, а затем проводит интерактивную сессию:

```ocaml
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
```

Логика движка:

1. Приветствие и запрос имени.
2. Цикл из `rounds` раундов. В каждом раунде:
   - Генерируем раунд через `game.generate_round ()`.
   - Показываем вопрос и читаем ответ.
   - Если ответ верный --- переходим к следующему раунду.
   - Если неверный --- игра заканчивается поражением.
3. Если все раунды пройдены --- поздравляем игрока.

Функция возвращает `bool`: `true` --- победа, `false` --- поражение. Это позволяет использовать результат для кода выхода программы.

## Проект: Brain Games

Теперь построим полноценное CLI-приложение --- **Brain Games** --- с пятью мини-играми, каждая из которых доступна как подкоманда.

### Вспомогательные функции

Прежде чем описывать игры, определим две полезные функции --- НОД и проверку на простоту:

```ocaml
let rec gcd a b =
  if b = 0 then a else gcd b (a mod b)
```

Алгоритм Евклида: рекурсивно заменяем пару `(a, b)` на `(b, a mod b)`, пока `b` не станет `0`. Результат --- `a`.

```ocaml
let is_prime n =
  if n < 2 then false
  else
    let rec check i =
      if i * i > n then true
      else if n mod i = 0 then false
      else check (i + 1)
    in
    check 2
```

Простое пробное деление: проверяем делимость на все числа от 2 до `sqrt(n)`. Если ни одно не делит `n` --- число простое.

### Игра 1: brain-even

Задача: определить, является ли число чётным. Ответ --- "yes" или "no".

```ocaml
let even_game : game =
  { description = "Ответьте 'yes', если число чётное, иначе --- 'no'.";
    generate_round = (fun () ->
      let n = random_int 1 100 in
      { question = string_of_int n;
        correct_answer = if n mod 2 = 0 then "yes" else "no" })
  }
```

Пример сессии:

```text
$ brain-games even
Добро пожаловать в Brain Even!
Ответьте 'yes', если число чётное, иначе --- 'no'.
Как вас зовут? Алексей
Привет, Алексей!
Вопрос: 42
Ваш ответ: yes
Верно!
Вопрос: 17
Ваш ответ: no
Верно!
Вопрос: 88
Ваш ответ: yes
Верно!
Поздравляю, Алексей!
```

### Игра 2: brain-calc

Задача: вычислить результат арифметического выражения с операторами `+`, `-`, `*`.

```ocaml
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
```

Массив `ops` содержит строковые представления операторов. Конструкция `ops.(Random.int 3)` выбирает случайный оператор. `match op with` вычисляет результат. Ветка `| _ -> assert false` нужна для полноты сопоставления --- на практике она недостижима.

### Игра 3: brain-gcd

Задача: найти наибольший общий делитель двух чисел.

```ocaml
let gcd_game : game =
  { description = "Найдите наибольший общий делитель.";
    generate_round = (fun () ->
      let a = random_int 2 100 in
      let b = random_int 2 100 in
      { question = Printf.sprintf "%d %d" a b;
        correct_answer = string_of_int (gcd a b) })
  }
```

Вопрос --- два числа через пробел, ответ --- их НОД. Используем функцию `gcd`, определённую выше.

### Игра 4: brain-progression

Задача: найти пропущенный элемент в арифметической прогрессии.

```ocaml
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
```

`List.init len f` создаёт список длины `len`, где элемент с индексом `i` вычисляется как `f i`. Скрытый элемент заменяется на `".."`. `String.concat " "` объединяет элементы через пробел.

Пример:

```text
Вопрос: 5 8 11 .. 17 20 23 26 29 32
Ваш ответ: 14
Верно!
```

### Игра 5: brain-prime

Задача: определить, является ли число простым.

```ocaml
let prime_game : game =
  { description = "Ответьте 'yes', если число простое, иначе --- 'no'.";
    generate_round = (fun () ->
      let n = random_int 2 100 in
      { question = string_of_int n;
        correct_answer = if is_prime n then "yes" else "no" })
  }
```

Аналогична `even_game`, но вместо проверки на чётность используется `is_prime`.

### Сборка CLI-приложения

Объединим все игры в одно приложение с подкомандами:

```ocaml
open Cmdliner

let rounds =
  let doc = "Number of rounds." in
  Arg.(value & opt int 3 & info ["r"; "rounds"] ~doc ~docv:"N")

let make_cmd name game =
  let run rounds =
    Random.self_init ();
    let ok = Brain_games.run_game name game ~rounds in
    if not ok then exit 1
  in
  let info = Cmd.info (String.lowercase_ascii name) ~doc:game.description in
  Cmd.v info Term.(const run $ rounds)

let () =
  let doc = "Brain Games --- математические мини-игры" in
  let info = Cmd.info "brain-games" ~doc ~version:"1.0.0" in
  let cmds = [
    make_cmd "Brain Even" Brain_games.even_game;
    make_cmd "Brain Calc" Brain_games.calc_game;
    make_cmd "Brain GCD" Brain_games.gcd_game;
    make_cmd "Brain Progression" Brain_games.progression_game;
    make_cmd "Brain Prime" Brain_games.prime_game;
  ] in
  exit (Cmd.eval (Cmd.group info cmds))
```

Функция `make_cmd` --- фабрика: она принимает имя и значение типа `game`, а возвращает `Cmd.t`. Это устраняет дублирование --- без неё пришлось бы писать пять почти одинаковых определений команд.

Запуск:

```text
$ brain-games --help
NAME
       brain-games - Brain Games --- математические мини-игры

COMMANDS
       brain-calc
           Вычислите результат выражения.
       brain-even
           Ответьте 'yes', если число чётное, иначе --- 'no'.
       brain-gcd
           Найдите наибольший общий делитель.
       brain-prime
           Ответьте 'yes', если число простое, иначе --- 'no'.
       brain-progression
           Какое число пропущено в прогрессии?

$ brain-games brain-even -r 5
```

## Конвертеры аргументов

Cmdliner поддерживает собственные конвертеры типов для аргументов. Встроенные конвертеры --- `string`, `int`, `float`, `bool`, `file`. Можно создать свой:

```ocaml
let difficulty_conv =
  let parse s = match String.lowercase_ascii s with
    | "easy" -> Ok 3
    | "medium" -> Ok 5
    | "hard" -> Ok 10
    | _ -> Error (`Msg (Printf.sprintf "unknown difficulty: %s" s))
  in
  let pp fmt n = Format.fprintf fmt "%d rounds" n in
  Arg.conv (parse, pp)

let rounds =
  let doc = "Difficulty level: easy, medium, hard." in
  Arg.(value & opt difficulty_conv 3 & info ["d"; "difficulty"] ~doc ~docv:"LEVEL")
```

`Arg.conv (parse, pp)` создаёт конвертер из пары функций:
- `parse : string -> ('a, [`Msg of string]) result` --- парсинг строки.
- `pp : Format.formatter -> 'a -> unit` --- отображение значения (для справки).

Теперь пользователь может писать `--difficulty easy` вместо `--rounds 3`.

## Обработка ошибок в Cmdliner

Cmdliner различает несколько типов ошибок:

```ocaml
(* Cmd.eval возвращает int --- код выхода:
   0 --- успех
   124 --- ошибка командной строки (неверные аргументы)
   125 --- внутренняя ошибка
   По конвенции, 1 --- ошибка приложения *)

let run rounds name =
  if rounds <= 0 then (
    Printf.eprintf "Error: rounds must be positive\n";
    1)  (* код выхода 1 --- ошибка приложения *)
  else (
    Printf.printf "Playing %d rounds with %s\n" rounds name;
    0)  (* код выхода 0 --- успех *)

let cmd =
  let info = Cmd.info "game" in
  Cmd.v info Term.(const run $ rounds $ name)

let () = exit (Cmd.eval cmd)
```

Для ошибок валидации аргументов (до запуска основной функции) Cmdliner автоматически выводит сообщение и возвращает код 124. Для ошибок приложения (внутри основной функции) используйте ненулевой код выхода.

## Сравнение с Haskell

В Haskell для построения CLI используется библиотека **optparse-applicative**. Оба подхода основаны на аппликативном стиле, но есть различия:

| Аспект | OCaml (Cmdliner) | Haskell (optparse-applicative) |
|--------|-------------------|-------------------------------|
| Стиль определения | Термы и аргументы: `Term.(const f $ a $ b)` | Аппликативные парсеры: `f <$> a <*> b` |
| Подкоманды | `Cmd.group info [cmd1; cmd2]` | `subparser (command "name" info)` |
| Позиционные аргументы | `Arg.(pos 0 string "")` | `argument str (metavar "NAME")` |
| Опции | `Arg.(opt int 3 & info ["r"])` | `option auto (long "rounds" <> value 3)` |
| Автокомплит | Встроен (bash/zsh/fish) | Через `completer` |
| Генерация man pages | Встроена | Через `optparse-applicative` |
| Типобезопасность | Полная --- типы выводятся из аргументов | Полная --- типы выводятся из парсера |
| Мутация состояния | Через `ref` или аргументы | Через `IO` |

Общий паттерн одинаков: **определить чистую функцию, описать аргументы декларативно, связать их аппликативным стилем**. Разница --- в синтаксисе и именах комбинаторов.

В Haskell:

```haskell
greet :: Bool -> Int -> String -> IO ()
greet verbose rounds name = ...

opts :: Parser (IO ())
opts = greet
  <$> switch (long "verbose" <> short 'v' <> help "Verbose output")
  <*> option auto (long "rounds" <> short 'r' <> value 3 <> help "Rounds")
  <*> argument str (metavar "NAME")
```

В OCaml:

```ocaml
let greet verbose rounds name = ...

let cmd =
  Cmd.v info Term.(const greet $ verbose $ rounds $ name)
```

Структура идентична: `const/pure` оборачивает функцию, `$/<*>` применяет аргументы.

```admonish info title="Real World OCaml"
Подробнее о построении CLI-приложений на OCaml --- в главе [Command-Line Parsing](https://dev.realworldocaml.org/command-line-parsing.html) книги Real World OCaml. Там рассматривается библиотека `Command` от Jane Street, но принципы те же.
```

## Структура проекта упражнений

Откройте директорию `exercises/chapter15`:

```text
chapter17/
├── dune-project
├── lib/
│   ├── dune
│   └── brain_games.ml         <- типы, движок, 5 игр, вспомогательные функции
├── test/
│   ├── dune
│   ├── test_chapter17.ml      <- тесты
│   └── my_solutions.ml        <- ваши решения
└── no-peeking/
    └── solutions.ml            <- эталонные решения
```

Библиотека `lib/brain_games.ml` содержит типы `round` и `game`, функцию `run_game`, вспомогательные функции (`random_int`, `gcd`, `is_prime`) и все пять игр. Тесты проверяют как библиотечный код, так и ваши решения упражнений.

## Упражнения

Решения пишите в файле `test/my_solutions.ml`. После каждого упражнения запускайте `dune runtest`, чтобы проверить ответ.

1. **(Лёгкое)** Реализуйте игру `balance_game` --- "угадай оператор". Даётся выражение вида `a ? b = c`, где `?` --- неизвестный оператор (`+`, `-` или `*`). Игрок должен угадать оператор.

    ```ocaml
    val balance_game : game
    ```

    Генерация раунда: выберите случайные `a` и `b`, случайный оператор, вычислите `c`. Вопрос --- строка `"a ? b = c"`, ответ --- строка оператора (`"+"`, `"-"` или `"*"`).

    *Подсказка:* храните операторы в массиве пар `(string * (int -> int -> int))`, чтобы связать строковое представление с функцией вычисления.

2. **(Среднее)** Реализуйте функцию `run_game_result` --- **чистую** версию игрового цикла, которая не использует ввод-вывод.

    ```ocaml
    val run_game_result : game -> rounds:int -> string list -> bool
    ```

    Вместо `read_line` функция принимает список ответов. Если ответов не хватает --- это поражение. Если все ответы верные --- победа. Если хотя бы один неверный --- поражение.

    *Подсказка:* используйте рекурсию по списку ответов и счётчику раундов.

3. **(Среднее)** Реализуйте обобщённый конструктор `make_game`, который создаёт значение типа `game` из описания и функции-генератора.

    ```ocaml
    val make_game : description:string -> generate:(unit -> string * string) -> game
    ```

    Функция `generate` возвращает пару `(question, correct_answer)`. `make_game` оборачивает её в запись `game`.

    *Подсказка:* это простая функция-адаптер. Создайте запись `{ description; generate_round }`, где `generate_round` вызывает `generate` и конструирует `round`.

4. **(Сложное)** Реализуйте игру `factor_game` --- "разложи на множители". Даётся число, игрок должен ввести его разложение на простые множители через пробел (в порядке возрастания).

    ```ocaml
    val factor_game : game
    ```

    Пример:

    ```text
    Вопрос: 60
    Ваш ответ: 2 2 3 5
    Верно!
    ```

    Генерация: выберите случайное число от 4 до 100. Разложите его на простые множители. Вопрос --- число, ответ --- множители через пробел.

    *Подсказка:* напишите рекурсивную функцию `factorize n d`, которая делит `n` на `d`, пока делится, затем увеличивает `d`.

## Заключение

В этой главе мы:

- Познакомились с библиотекой Cmdliner и её аппликативным подходом к определению CLI.
- Изучили три ключевых понятия: `Arg` (аргументы), `Term` (термы), `Cmd` (команды).
- Научились создавать позиционные аргументы, флаги, опции со значениями и подкоманды.
- Реализовали модульную архитектуру игры с типами `round` и `game`.
- Построили проект Brain Games с пятью мини-играми: brain-even, brain-calc, brain-gcd, brain-progression, brain-prime.
- Научились работать с интерактивным вводом через `read_line`.
- Сравнили подходы OCaml (Cmdliner) и Haskell (optparse-applicative).

Главный урок этой главы --- **декларативное описание интерфейса**. Вместо ручного разбора аргументов мы описываем **что** программа принимает, а библиотека берёт на себя парсинг, валидацию и генерацию справки. Тот же принцип --- отделение описания от реализации --- мы видели в парсер-комбинаторах (глава 17) и модульных сигнатурах (глава 7). Это сквозная тема функционального программирования: **описывай что, а не как**.
