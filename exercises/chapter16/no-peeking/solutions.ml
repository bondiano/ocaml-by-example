(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

(** Упражнение 1: Тип color с ppx-деривацией. *)
type color = Red | Green | Blue
[@@deriving show, eq]

let all_colors : color list = [Red; Green; Blue]

let color_to_string (c : color) : string =
  show_color c

(** Упражнение 2: Дедупликация записей. *)
type person = { name : string; age : int }
[@@deriving show, eq]

let dedup_persons (lst : person list) : person list =
  List.fold_left (fun acc p ->
    if List.exists (equal_person p) acc then acc
    else acc @ [p]
  ) [] lst

(** Упражнение 3: Строковое представление пары. *)
let make_pair (a : 'a) (b : 'b) (show_a : 'a -> string) (show_b : 'b -> string) : string =
  Printf.sprintf "(%s, %s)" (show_a a) (show_b b)

(** Упражнение 4: Перечисление вариантов вручную. *)
type suit = Hearts | Diamonds | Clubs | Spades
[@@deriving show, eq]

let all_suits : suit list = [Hearts; Diamonds; Clubs; Spades]

let next_suit (s : suit) : suit option =
  match s with
  | Hearts -> Some Diamonds
  | Diamonds -> Some Clubs
  | Clubs -> Some Spades
  | Spades -> None
