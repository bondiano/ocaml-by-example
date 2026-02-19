(** Здесь вы можете писать свои решения упражнений. *)
open Chapter14.Game

(** Упражнение 1: Отражение вектора от горизонтальной поверхности. *)
let reflect_horizontal (_v : vec2) : vec2 =
  failwith "todo"

(** Упражнение 2: Отражение вектора от вертикальной поверхности. *)
let reflect_vertical (_v : vec2) : vec2 =
  failwith "todo"

(** Упражнение 3: Проверка столкновения круга и прямоугольника. *)
let circle_rect_collide (_c : circle) (_r : rect) : bool =
  failwith "todo"

(** Упражнение 4: Обновление позиции с гравитацией. *)
type entity = {
  pos : vec2;
  vel : vec2;
  gravity : float;
}

let update_entity (dt : float) (e : entity) : entity =
  ignore dt;
  ignore e;
  failwith "todo"
