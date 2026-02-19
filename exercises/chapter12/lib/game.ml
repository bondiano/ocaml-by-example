(** Чистая игровая логика без зависимости от raylib. *)

(** Двумерный вектор. *)
type vec2 = { x : float; y : float }

(** Сложение векторов. *)
let vec2_add a b = { x = a.x +. b.x; y = a.y +. b.y }

(** Вычитание векторов. *)
let vec2_sub a b = { x = a.x -. b.x; y = a.y -. b.y }

(** Масштабирование вектора. *)
let vec2_scale s v = { x = v.x *. s; y = v.y *. s }

(** Длина вектора. *)
let vec2_length v = Float.sqrt (v.x *. v.x +. v.y *. v.y)

(** Нормализация вектора. *)
let vec2_normalize v =
  let len = vec2_length v in
  if len < 1e-10 then { x = 0.0; y = 0.0 }
  else vec2_scale (1.0 /. len) v

(** Расстояние между двумя точками. *)
let vec2_distance a b = vec2_length (vec2_sub b a)

(** Скалярное произведение. *)
let vec2_dot a b = a.x *. b.x +. a.y *. b.y

(** Прямоугольник. *)
type rect = { rx : float; ry : float; rw : float; rh : float }

(** Круг. *)
type circle = { center : vec2; radius : float }

(** Проверка: точка внутри прямоугольника? *)
let point_in_rect (p : vec2) (r : rect) =
  p.x >= r.rx && p.x <= r.rx +. r.rw &&
  p.y >= r.ry && p.y <= r.ry +. r.rh

(** Проверка: два круга пересекаются? *)
let circles_collide (c1 : circle) (c2 : circle) =
  vec2_distance c1.center c2.center <= c1.radius +. c2.radius

(** Состояние мяча. *)
type ball = {
  pos : vec2;
  vel : vec2;
  radius : float;
}

(** Обновить мяч: двигаем и отражаем от стенок. *)
let update_ball (width : float) (height : float) (b : ball) : ball =
  let new_pos = vec2_add b.pos b.vel in
  let vx =
    if new_pos.x -. b.radius < 0.0 || new_pos.x +. b.radius > width
    then -. b.vel.x else b.vel.x
  in
  let vy =
    if new_pos.y -. b.radius < 0.0 || new_pos.y +. b.radius > height
    then -. b.vel.y else b.vel.y
  in
  let vel = { x = vx; y = vy } in
  let pos = vec2_add b.pos vel in
  { b with pos; vel }
