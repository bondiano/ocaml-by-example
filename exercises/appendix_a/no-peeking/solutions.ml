(** Референсные решения — не подсматривайте, пока не попробуете сами! *)

open Appendix_a.Game

(** Упражнение 1: двигаем паддл с ограничением по экрану. *)
let move_paddle (st : state) (dx : float) : state =
  let new_x = clamp (st.paddle.x +. dx) 0.0 (st.screen_w -. st.paddle.w) in
  { st with paddle = { st.paddle with x = new_x } }

(** Упражнение 2: шаг мяча — движение и отражение от стен. *)
let step_ball (st : state) : ball * bool =
  let b = st.ball in
  let np = vec2_add b.pos b.vel in
  let vx =
    if np.x -. b.radius < 0.0 || np.x +. b.radius > st.screen_w
    then -. b.vel.x
    else b.vel.x
  in
  let vy =
    if np.y -. b.radius < 0.0
    then -. b.vel.y
    else b.vel.y
  in
  let fell = np.y +. b.radius > st.screen_h in
  let new_ball = { b with pos = vec2_add b.pos { x = vx; y = vy }; vel = { x = vx; y = vy } } in
  (new_ball, fell)

(** Упражнение 3: простое отражение от паддла (инвертируем vy). *)
let paddle_deflects_ball (st : state) : ball option =
  let p = st.paddle in
  let b = st.ball in
  if rect_hits_ball ~bx:p.x ~by:p.y ~bw:p.w ~bh:p.h b && b.vel.y > 0.0 then
    Some { b with vel = { b.vel with y = -. Float.abs b.vel.y } }
  else
    None

(** Упражнение 4: убираем кирпичи, задетые мячом. *)
let remove_hit_bricks (st : state) : brick list * int =
  List.fold_left
    (fun (acc, pts) br ->
      if rect_hits_ball ~bx:br.x ~by:br.y ~bw:br.w ~bh:br.h st.ball
      then (acc, pts + br.points)
      else (br :: acc, pts))
    ([], 0)
    st.bricks

(** Упражнение 5: полный игровой шаг. *)
let step_game (st : state) (dx : float) : state =
  if st.phase <> Playing then st
  else
    let st = move_paddle st dx in
    let (new_ball, fell) = step_ball st in
    let st = { st with ball = new_ball } in
    let st =
      match paddle_deflects_ball st with
      | Some b -> { st with ball = b }
      | None -> st
    in
    let (new_bricks, pts) = remove_hit_bricks st in
    let st = { st with bricks = new_bricks; score = st.score + pts } in
    if fell then
      let lives = st.lives - 1 in
      if lives <= 0 then
        { st with lives = 0; phase = Lost }
      else
        let reset = initial_state ~screen_w:st.screen_w ~screen_h:st.screen_h in
        { st with lives; ball = reset.ball }
    else if st.bricks = [] then
      { st with phase = Won }
    else
      st
