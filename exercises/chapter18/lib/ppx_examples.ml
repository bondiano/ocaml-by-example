(** Примеры использования ppx-деривации. *)

(** Тип направления с автоматическими show и equal. *)
type direction = North | South | East | West
[@@deriving show, eq]

(** Тип точки с автоматическими show и equal. *)
type point = { x : float; y : float }
[@@deriving show, eq]

(** Тип фигуры с ppx-деривацией. *)
type shape =
  | Circle of float
  | Rect of float * float
[@@deriving show, eq]

(** Расстояние от начала координат. *)
let distance p =
  Float.sqrt (p.x *. p.x +. p.y *. p.y)

(** Площадь фигуры. *)
let area = function
  | Circle r -> Float.pi *. r *. r
  | Rect (w, h) -> w *. h

(** Описать направление (вручную --- для сравнения с ppx). *)
let describe_direction = function
  | North -> "North"
  | South -> "South"
  | East -> "East"
  | West -> "West"

(** Список всех направлений (вручную). *)
let all_directions = [North; South; East; West]

(** Убрать дубликаты из списка, используя equal. *)
let dedup_points (lst : point list) : point list =
  List.fold_left (fun acc p ->
    if List.exists (equal_point p) acc then acc
    else acc @ [p]
  ) [] lst
