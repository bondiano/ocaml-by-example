(** Точка на плоскости. *)
type point = {
  x : float;
  y : float;
}

(** Геометрическая фигура. *)
type shape =
  | Circle of point * float
  | Rectangle of point * float * float
  | Line of point * point
  | Text of point * string

(** Картинка --- список фигур. *)
type picture = shape list

(** Ограничивающий прямоугольник. *)
type bounds = {
  min_x : float;
  min_y : float;
  max_x : float;
  max_y : float;
}

(** Отформатировать точку в строку. *)
let show_point p =
  "(" ^ string_of_float p.x ^ ", " ^ string_of_float p.y ^ ")"

(** Отформатировать фигуру в строку. *)
let show_shape = function
  | Circle (c, r) ->
    "Circle [center: " ^ show_point c ^ ", radius: " ^ string_of_float r ^ "]"
  | Rectangle (c, w, h) ->
    "Rectangle [corner: " ^ show_point c
    ^ ", width: " ^ string_of_float w
    ^ ", height: " ^ string_of_float h ^ "]"
  | Line (p1, p2) ->
    "Line [start: " ^ show_point p1 ^ ", end: " ^ show_point p2 ^ "]"
  | Text (p, s) ->
    "Text [position: " ^ show_point p ^ ", text: " ^ s ^ "]"

(** Вычислить ограничивающий прямоугольник фигуры. *)
let shape_bounds = function
  | Circle ({ x; y }, r) ->
    { min_x = x -. r; min_y = y -. r;
      max_x = x +. r; max_y = y +. r }
  | Rectangle ({ x; y }, w, h) ->
    { min_x = x; min_y = y;
      max_x = x +. w; max_y = y +. h }
  | Line (p1, p2) ->
    { min_x = Float.min p1.x p2.x; min_y = Float.min p1.y p2.y;
      max_x = Float.max p1.x p2.x; max_y = Float.max p1.y p2.y }
  | Text (p, _) ->
    { min_x = p.x; min_y = p.y;
      max_x = p.x; max_y = p.y }

(** Объединить два ограничивающих прямоугольника. *)
let union_bounds b1 b2 =
  { min_x = Float.min b1.min_x b2.min_x;
    min_y = Float.min b1.min_y b2.min_y;
    max_x = Float.max b1.max_x b2.max_x;
    max_y = Float.max b1.max_y b2.max_y }

(** Вычислить ограничивающий прямоугольник картинки. *)
let bounds = function
  | [] -> { min_x = 0.0; min_y = 0.0; max_x = 0.0; max_y = 0.0 }
  | s :: ss ->
    List.fold_left
      (fun acc shape -> union_bounds acc (shape_bounds shape))
      (shape_bounds s) ss
