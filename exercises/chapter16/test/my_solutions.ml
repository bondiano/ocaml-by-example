(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Тип color с ppx-деривацией. *)
type color = Red | Green | Blue
[@@deriving show, eq]

let all_colors : color list =
  [] (* todo: заполните список всех цветов *)

let color_to_string (c : color) : string =
  ignore c;
  failwith "todo"

(** Упражнение 2: Запись с дедупликацией через equal. *)
type person = { name : string; age : int }
[@@deriving show, eq]

let dedup_persons (lst : person list) : person list =
  ignore lst;
  failwith "todo"

(** Упражнение 3: Реализовать функцию [make_pair], возвращающую строковое представление пары. *)
let make_pair (a : 'a) (b : 'b) (show_a : 'a -> string) (show_b : 'b -> string) : string =
  ignore a; ignore b; ignore show_a; ignore show_b;
  failwith "todo"

(** Упражнение 4: Реализовать [enumerate] для простых вариантов вручную
    (аналог того, что мог бы генерировать ppx). *)
type suit = Hearts | Diamonds | Clubs | Spades
[@@deriving show, eq]

let all_suits : suit list =
  [] (* todo: заполните список всех мастей *)

let next_suit (s : suit) : suit option =
  ignore s;
  failwith "todo"
