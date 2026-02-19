(** Типы и утилиты для игры Арканоид.

    Эта библиотека не зависит от raylib — только стандартная библиотека OCaml.
    Чистая игровая логика живёт здесь и тестируется через Alcotest.
    Рендеринг — в [bin/main.ml]. *)

(** {2 Вектор} *)

type vec2 = { x : float; y : float }

let vec2_add a b = { x = a.x +. b.x; y = a.y +. b.y }
let vec2_scale s v = { x = v.x *. s; y = v.y *. s }

(** {2 Утилиты} *)

(** Ограничивает [v] отрезком [\[lo; hi\]]. *)
let clamp v lo hi = Float.max lo (Float.min hi v)

(** {2 Игровые объекты} *)

(** Мяч. *)
type ball = {
  pos : vec2;
  vel : vec2;
  radius : float;
}

(** Паддл (ракетка) игрока. *)
type paddle = {
  x : float;  (** Левый край. *)
  y : float;  (** Верхний край (фиксирован). *)
  w : float;  (** Ширина. *)
  h : float;  (** Высота. *)
}

(** Кирпич. *)
type brick = {
  x : float;
  y : float;
  w : float;
  h : float;
  points : int;  (** Очки за разбитие. *)
}

(** Фаза игры. *)
type phase = Playing | Won | Lost

(** Полное состояние игры. *)
type state = {
  ball     : ball;
  paddle   : paddle;
  bricks   : brick list;
  score    : int;
  lives    : int;
  phase    : phase;
  screen_w : float;
  screen_h : float;
}

(** {2 Служебные функции} *)

(** Проверяет пересечение AABB-прямоугольника с кругом (мячом).
    Используется для детекции столкновений кирпичей и паддла с мячом. *)
let rect_hits_ball ~bx ~by ~bw ~bh (ball : ball) =
  let cx = clamp ball.pos.x bx (bx +. bw) in
  let cy = clamp ball.pos.y by (by +. bh) in
  let dx = ball.pos.x -. cx in
  let dy = ball.pos.y -. cy in
  dx *. dx +. dy *. dy <= ball.radius *. ball.radius

(** Индекс цвета кирпича по количеству очков (1–5 → 4–0). *)
let brick_color_id (b : brick) =
  match b.points with
  | 5 -> 0
  | 4 -> 1
  | 3 -> 2
  | 2 -> 3
  | _ -> 4

(** Создаёт начальную сетку кирпичей (5 рядов × 10 столбцов). *)
let make_bricks ~screen_w =
  let cols = 10 in
  let rows = 5 in
  let bw = screen_w /. float_of_int cols in
  let bh = 24.0 in
  let points_by_row = [| 5; 4; 3; 2; 1 |] in
  List.init (rows * cols) (fun i ->
    let row = i / cols in
    let col = i mod cols in
    { x      = float_of_int col *. bw;
      y      = 60.0 +. float_of_int row *. (bh +. 4.0);
      w      = bw -. 2.0;
      h      = bh;
      points = points_by_row.(row) })

(** Возвращает начальное состояние игры для окна [screen_w × screen_h]. *)
let initial_state ~screen_w ~screen_h =
  let pw = 100.0 in
  let ph = 14.0 in
  { ball    = { pos    = { x = screen_w /. 2.0; y = screen_h -. 80.0 };
                vel    = { x = 3.0; y = -5.0 };
                radius = 8.0 };
    paddle  = { x = (screen_w -. pw) /. 2.0;
                y = screen_h -. 40.0;
                w = pw; h = ph };
    bricks  = make_bricks ~screen_w;
    score   = 0;
    lives   = 3;
    phase   = Playing;
    screen_w;
    screen_h }
