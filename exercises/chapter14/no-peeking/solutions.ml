(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)
open Chapter14.Game

(** Отражение вектора от горизонтальной поверхности (инвертируем y). *)
let reflect_horizontal (v : vec2) : vec2 =
  { x = v.x; y = -. v.y }

(** Отражение вектора от вертикальной поверхности (инвертируем x). *)
let reflect_vertical (v : vec2) : vec2 =
  { x = -. v.x; y = v.y }

(** Столкновение круга с прямоугольником. *)
let circle_rect_collide (c : circle) (r : rect) : bool =
  let closest_x = Float.max r.rx (Float.min c.center.x (r.rx +. r.rw)) in
  let closest_y = Float.max r.ry (Float.min c.center.y (r.ry +. r.rh)) in
  let dx = c.center.x -. closest_x in
  let dy = c.center.y -. closest_y in
  (dx *. dx +. dy *. dy) <= c.radius *. c.radius

(** Обновление entity с гравитацией. *)
type entity = {
  pos : vec2;
  vel : vec2;
  gravity : float;
}

let update_entity (dt : float) (e : entity) : entity =
  let new_vel = { x = e.vel.x; y = e.vel.y +. e.gravity *. dt } in
  let new_pos = vec2_add e.pos (vec2_scale dt new_vel) in
  { e with pos = new_pos; vel = new_vel }
