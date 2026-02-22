(** Здесь вы можете писать свои решения упражнений. *)

(* ===== ppx_deriving ===== *)

(* Лёгкое *)
(** Упражнение 1: color с ppx-деривацией.

    Использовать ppx_deriving для автоматической генерации функций.

    Аннотация [@@deriving show, eq] генерирует:
    - show_color : color -> string (pretty printer)
    - pp_color : Format.formatter -> color -> unit (PPrint)
    - equal_color : color -> color -> bool (equality)

    Задачи:
    a) Заполнить список all_colors всеми возможными цветами
    b) Реализовать color_to_string используя сгенерированный show_color
       или вручную через pattern matching

    Примеры:
    {[
      all_colors = [Red; Green; Blue]

      color_to_string Red = "Red"  (* или "red" в нижнем регистре *)
      color_to_string Green = "Green"

      (* Сгенерированные функции *)
      show_color Red = "Red"
      equal_color Red Red = true
      equal_color Red Blue = false
    ]}

    Подсказки:
    1. all_colors = [Red; Green; Blue]
    2. color_to_string можно реализовать двумя способами:
       - Используя show_color: show_color c
       - Вручную: match c with Red -> "Red" | Green -> "Green" | Blue -> "Blue"
    3. ppx_deriving автоматически генерирует функции при компиляции

    Связанные темы: ppx_deriving, code generation, enumerations
    Время: ~10 минут *)
type color = Red | Green | Blue
[@@deriving show, eq]

let all_colors : color list =
  [] (* todo: заполните список всех цветов *)

let color_to_string (c : color) : string =
  ignore c;
  failwith "todo"

(* Лёгкое *)
(** Упражнение 2: dedup_persons — дедупликация с использованием generated equal.

    Удалить дубликаты из списка person, используя сгенерированную функцию equal_person.

    Аннотация [@@deriving show, eq] генерирует equal_person для сравнения записей.

    Примеры:
    {[
      let persons = [
        {name="Alice"; age=30};
        {name="Bob"; age=25};
        {name="Alice"; age=30}  (* дубликат *)
      ]

      dedup_persons persons = [
        {name="Alice"; age=30};
        {name="Bob"; age=25}
      ]
    ]}

    Подсказки:
    1. List.sort_uniq для дедупликации:
       {[
         List.sort_uniq (fun a b ->
           if equal_person a b then 0
           else compare a.name b.name  (* любой порядок для сортировки *)
         ) lst
       ]}
    2. Или вручную через fold с accumulator:
       {[
         List.fold_left (fun acc p ->
           if List.exists (equal_person p) acc then acc
           else p :: acc
         ) [] lst |> List.rev
       ]}
    3. equal_person сгенерирована автоматически ppx

    Связанные темы: Deduplication, generated equality, List.sort_uniq
    Время: ~8 минут *)
type person = { name : string; age : int }
[@@deriving show, eq]

let dedup_persons (lst : person list) : person list =
  ignore lst;
  failwith "todo"

(* Лёгкое *)
(** Упражнение 3: make_pair — generic pair representation.

    Создать строковое представление пары используя функции show для каждого типа.

    Параметры:
    - a, b: значения
    - show_a, show_b: функции преобразования в строку

    Примеры:
    {[
      make_pair 42 "hello" string_of_int (fun s -> s) = "(42, hello)"
      make_pair Red Blue show_color show_color = "(Red, Blue)"
      make_pair 1 2.5 string_of_int string_of_float = "(1, 2.5)"
    ]}

    Подсказки:
    1. Printf.sprintf для форматирования:
       {[
         Printf.sprintf "(%s, %s)" (show_a a) (show_b b)
       ]}
    2. Или конкатенация строк:
       {[
         "(" ^ show_a a ^ ", " ^ show_b b ^ ")"
       ]}
    3. Это демонстрирует полиморфизм: работает с любыми типами

    Связанные темы: Polymorphism, higher-order functions, string formatting
    Время: ~8 минут *)
let make_pair (a : 'a) (b : 'b) (show_a : 'a -> string) (show_b : 'b -> string) : string =
  ignore a; ignore b; ignore show_a; ignore show_b;
  failwith "todo"

(* ===== Ручная enum-генерация ===== *)

(* Лёгкое *)
(** Упражнение 4: suit — ручная реализация enumeration.

    Реализовать вручную то, что мог бы генерировать ppx_enumerate:
    - all_suits: список всех значений
    - next_suit: следующий элемент (циклически)

    Примеры:
    {[
      all_suits = [Hearts; Diamonds; Clubs; Spades]

      next_suit Hearts = Some Diamonds
      next_suit Diamonds = Some Clubs
      next_suit Clubs = Some Spades
      next_suit Spades = None  (* или Some Hearts для цикла *)
    ]}

    Подсказки:
    1. all_suits = [Hearts; Diamonds; Clubs; Spades]
    2. next_suit через pattern matching:
       {[
         match s with
         | Hearts -> Some Diamonds
         | Diamonds -> Some Clubs
         | Clubs -> Some Spades
         | Spades -> None  (* или Some Hearts *)
       ]}
    3. Альтернативный подход с List.find:
       {[
         let idx = List.find_index ((=) s) all_suits in
         match idx with
         | Some i when i < List.length all_suits - 1 ->
             Some (List.nth all_suits (i + 1))
         | _ -> None
       ]}

    Связанные темы: Enumerations, manual ppx implementation, cyclic lists
    Время: ~10 минут *)
type suit = Hearts | Diamonds | Clubs | Spades
[@@deriving show, eq]

let all_suits : suit list =
  [] (* todo: заполните список всех мастей *)

let next_suit (s : suit) : suit option =
  ignore s;
  failwith "todo"
