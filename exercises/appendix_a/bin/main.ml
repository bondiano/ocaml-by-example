(** Арканоид — полная реализация на raylib-ocaml.

    Запуск из директории exercises/appendix_a:
    {[ dune exec ./bin/main.exe ]}

    Управление:
    - ← / → — двигать паддл
    - R — перезапустить игру *)

open Raylib
open Appendix_a.Game

(* ------------------------------------------------------------------ *)
(*  Чистая игровая логика                                              *)
(*  Это те функции, которые студент реализует в test/my_solutions.ml  *)
(* ------------------------------------------------------------------ *)

let move_paddle (st : state) (dx : float) : state =
  let new_x = clamp (st.paddle.x +. dx) 0.0 (st.screen_w -. st.paddle.w) in
  { st with paddle = { st.paddle with x = new_x } }

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
  let new_ball = { b with
    pos = vec2_add b.pos { x = vx; y = vy };
    vel = { x = vx; y = vy } } in
  (new_ball, fell)

let paddle_deflects_ball (st : state) : ball option =
  let p = st.paddle in
  let b = st.ball in
  if rect_hits_ball ~bx:p.x ~by:p.y ~bw:p.w ~bh:p.h b && b.vel.y > 0.0 then begin
    (* Угол зависит от точки контакта: края паддла дают больший угол *)
    let offset = (b.pos.x -. (p.x +. p.w /. 2.0)) /. (p.w /. 2.0) in
    let angle  = offset *. 1.1 in
    let speed  = Float.sqrt (b.vel.x *. b.vel.x +. b.vel.y *. b.vel.y) in
    let new_vel = { x = speed *. Float.sin angle;
                    y = -. Float.abs (speed *. Float.cos angle) } in
    Some { b with
      vel = new_vel;
      pos = { b.pos with y = p.y -. b.radius -. 1.0 } }
  end else
    None

let remove_hit_bricks (st : state) : brick list * int =
  List.fold_left
    (fun (acc, pts) br ->
      if rect_hits_ball ~bx:br.x ~by:br.y ~bw:br.w ~bh:br.h st.ball
      then (acc, pts + br.points)
      else (br :: acc, pts))
    ([], 0)
    st.bricks

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
      if lives <= 0 then { st with lives = 0; phase = Lost }
      else
        let reset = initial_state ~screen_w:st.screen_w ~screen_h:st.screen_h in
        { st with lives; ball = reset.ball }
    else if st.bricks = [] then { st with phase = Won }
    else st

(* ------------------------------------------------------------------ *)
(*  Рендеринг                                                          *)
(* ------------------------------------------------------------------ *)

let brick_colors =
  [| Color.red; Color.orange; Color.yellow; Color.lime; Color.skyblue |]

let draw_bricks (bricks : brick list) =
  List.iter (fun (b : brick) ->
    let ci = brick_color_id b in
    draw_rectangle
      (int_of_float b.x) (int_of_float b.y)
      (int_of_float b.w) (int_of_float b.h)
      brick_colors.(ci);
    draw_rectangle_lines
      (int_of_float b.x) (int_of_float b.y)
      (int_of_float b.w) (int_of_float b.h)
      Color.black
  ) bricks

let draw (st : state) =
  begin_drawing ();
  clear_background Color.black;

  draw_bricks st.bricks;

  (* Паддл *)
  draw_rectangle
    (int_of_float st.paddle.x) (int_of_float st.paddle.y)
    (int_of_float st.paddle.w) (int_of_float st.paddle.h)
    Color.white;

  (* Мяч *)
  draw_circle
    (int_of_float st.ball.pos.x) (int_of_float st.ball.pos.y)
    st.ball.radius Color.raywhite;

  (* HUD *)
  draw_text
    (Printf.sprintf "Счёт: %d" st.score)
    10 10 20 Color.white;
  draw_text
    (Printf.sprintf "Жизни: %d" st.lives)
    (int_of_float st.screen_w - 130) 10 20 Color.white;

  (match st.phase with
   | Won ->
     draw_text "ПОБЕДА!"
       (int_of_float st.screen_w / 2 - 70)
       (int_of_float st.screen_h / 2 - 25)
       48 Color.gold;
     draw_text "Нажмите R для рестарта"
       (int_of_float st.screen_w / 2 - 140)
       (int_of_float st.screen_h / 2 + 35)
       20 Color.lightgray
   | Lost ->
     draw_text "КОНЕЦ ИГРЫ"
       (int_of_float st.screen_w / 2 - 100)
       (int_of_float st.screen_h / 2 - 25)
       48 Color.red;
     draw_text "Нажмите R для рестарта"
       (int_of_float st.screen_w / 2 - 140)
       (int_of_float st.screen_h / 2 + 35)
       20 Color.lightgray
   | Playing -> ());

  end_drawing ()

(* ------------------------------------------------------------------ *)
(*  Главный цикл                                                       *)
(* ------------------------------------------------------------------ *)

let () =
  let sw = 800.0 in
  let sh = 600.0 in
  init_window (int_of_float sw) (int_of_float sh) "Арканоид — OCaml + raylib";
  set_target_fps 60;

  let state = ref (initial_state ~screen_w:sw ~screen_h:sh) in

  while not (window_should_close ()) do
    if is_key_pressed Key.R then
      state := initial_state ~screen_w:sw ~screen_h:sh;

    let speed = 6.0 in
    let dx =
      (if is_key_down Key.Right then speed  else 0.0) +.
      (if is_key_down Key.Left  then -.speed else 0.0)
    in

    state := step_game !state dx;
    draw !state
  done;

  close_window ()
