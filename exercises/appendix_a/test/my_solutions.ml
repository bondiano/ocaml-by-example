(** Здесь вы пишете решения упражнений.

    Каждая функция — это кусочек логики реальной игры Арканоид.
    После реализации запустите [dune test], а затем [dune exec ./bin/main.exe]
    чтобы увидеть свой код в действии. *)

open Appendix_a.Game

(* ===== Базовая физика ===== *)

(* Лёгкое *)
(** Упражнение 1: move_paddle — движение паддла.

    Переместить паддл на dx пикселей, ограничивая его в пределах экрана.

    Правила:
    - Новая позиция: paddle.x + dx
    - Ограничение: [0, screen_w - paddle.w]
    - Паддл не должен выходить за края

    Примеры:
    {[
      (* screen_w = 800, paddle.w = 100 *)
      move_paddle st 50.0     (* двигает вправо на 50 *)
      move_paddle st (-30.0)  (* двигает влево на 30 *)
      move_paddle st 1000.0   (* ограничивается правым краем: 800-100=700 *)
    ]}

    Подсказки:
    1. Вычислить новый x: st.paddle.x +. dx
    2. Float.max для нижней границы: max 0.0 new_x
    3. Float.min для верхней границы: min (screen_w - paddle.w) new_x
    4. Или использовать clamp функцию:
       {[
         let clamp min_v max_v v = Float.max min_v (Float.min max_v v)
       ]}
    5. Вернуть state с обновлённым paddle:
       {[
         { st with paddle = { st.paddle with x = clamped_x } }
       ]}

    Связанные темы: Bounds checking, clamping, game physics
    Время: ~8 минут *)
let move_paddle (_st : state) (_dx : float) : state =
  failwith "todo"

(* Среднее *)
(** Упражнение 2: step_ball — физика мяча.

    Обновить позицию мяча и обработать столкновения со стенами и потолком.

    Правила:
    - Новая позиция: pos + vel
    - Левая/правая стена: если x ± radius выходит за [0, screen_w] → инвертировать vel.x
    - Потолок: если y - radius < 0 → инвертировать vel.y
    - Пол: если y + radius > screen_h → fell = true (мяч упал)

    Примеры:
    {[
      (* Мяч летит вправо к стене *)
      step_ball st → (ball с инвертированным vel.x, false)

      (* Мяч упал вниз *)
      step_ball st → (ball, true)
    ]}

    Подсказки:
    1. Используйте vec2_add из библиотеки:
       {[
         let new_pos = vec2_add st.ball.pos st.ball.vel in
       ]}
    2. Проверка стен:
       {[
         let new_vel_x =
           if new_pos.x -. st.ball.radius < 0.0 ||
              new_pos.x +. st.ball.radius > st.screen_w
           then -. st.ball.vel.x
           else st.ball.vel.x
       ]}
    3. Проверка потолка:
       {[
         let new_vel_y =
           if new_pos.y -. st.ball.radius < 0.0
           then -. st.ball.vel.y
           else st.ball.vel.y
       ]}
    4. Проверка пола:
       {[
         let fell = new_pos.y +. st.ball.radius > st.screen_h in
       ]}
    5. Вернуть обновлённый мяч и флаг:
       {[
         ({ st.ball with pos = new_pos; vel = { x = new_vel_x; y = new_vel_y } }, fell)
       ]}

    Связанные темы: Vector math, collision detection, physics simulation
    Время: ~15 минут *)
let step_ball (_st : state) : ball * bool =
  failwith "todo"

(* Среднее *)
(** Упражнение 3: paddle_deflects_ball — отражение мяча от паддла.

    Проверить столкновение мяча с паддлом и отразить мяч вверх.

    Правила:
    - Используйте rect_hits_ball для проверки столкновения
    - Если мяч касается И летит вниз (vel.y > 0) → отразить вверх
    - Отражение: vel.y = -|vel.y| (всегда отрицательное)
    - vel.x не меняется

    Примеры:
    {[
      (* Мяч касается паддла и летит вниз *)
      paddle_deflects_ball st = Some ball_с_отражённым_vel_y

      (* Мяч не касается *)
      paddle_deflects_ball st = None

      (* Мяч касается но уже летит вверх *)
      paddle_deflects_ball st = None
    ]}

    Подсказки:
    1. Проверка столкновения:
       {[
         let hits = rect_hits_ball
           ~bx:st.paddle.x ~by:st.paddle.y
           ~bw:st.paddle.w ~bh:st.paddle.h
           st.ball
       ]}
    2. Проверка направления:
       {[
         if hits && st.ball.vel.y > 0.0 then
           Some { st.ball with vel = { st.ball.vel with y = -. Float.abs st.ball.vel.y } }
         else None
       ]}
    3. Float.abs для получения абсолютного значения

    Связанные темы: Collision response, paddle mechanics
    Время: ~12 минут *)
let paddle_deflects_ball (_st : state) : ball option =
  failwith "todo"

(* Среднее *)
(** Упражнение 4: remove_hit_bricks — удаление разбитых кирпичей.

    Проверить столкновения мяча с кирпичами и удалить разбитые.

    Правила:
    - Для каждого кирпича проверить столкновение с мячом
    - Удалить задетые кирпичи из списка
    - Суммировать очки за разбитые кирпичи

    Примеры:
    {[
      (* Мяч задел 2 кирпича с points=10 каждый *)
      remove_hit_bricks st = (remaining_bricks, 20)

      (* Мяч ничего не задел *)
      remove_hit_bricks st = (st.bricks, 0)
    ]}

    Подсказки:
    1. List.partition для разделения на hit/not_hit:
       {[
         let (hit, remaining) = List.partition (fun brick ->
           rect_hits_ball ~bx:brick.x ~by:brick.y ~bw:brick.w ~bh:brick.h st.ball
         ) st.bricks
       ]}
    2. List.fold_left для суммы очков:
       {[
         let total_points = List.fold_left (fun acc brick -> acc + brick.points) 0 hit in
       ]}
    3. Вернуть: (remaining, total_points)

    Связанные темы: List operations, collision detection, scoring
    Время: ~15 минут *)
let remove_hit_bricks (_st : state) : brick list * int =
  failwith "todo"

(* ===== Игровой цикл ===== *)

(* Сложное *)
(** Упражнение 5: step_game — полный шаг игры.

    Реализовать один игровой кадр, интегрируя все предыдущие функции.

    Логика:
    1. Если phase <> Playing → вернуть состояние без изменений
    2. Двигать паддл на dx (move_paddle)
    3. Двигать мяч (step_ball)
    4. Применить отражение от паддла (paddle_deflects_ball)
    5. Удалить разбитые кирпичи, прибавить очки (remove_hit_bricks)
    6. Если мяч упал:
       - Уменьшить lives на 1
       - Если lives <= 0 → phase = Lost
       - Иначе сбросить мяч в начальную позицию
    7. Если bricks = [] → phase = Won

    Примеры:
    {[
      (* Обычный кадр *)
      step_game st 5.0  (* двигает паддл и мяч *)

      (* Мяч упал, остались жизни *)
      step_game st 0.0  (* lives -= 1, мяч сброшен *)

      (* Все кирпичи разбиты *)
      step_game st 0.0  (* phase = Won *)
    ]}

    Подсказки:
    1. Проверка фазы:
       {[
         if st.phase <> Playing then st else ...
       ]}
    2. Последовательность обновлений:
       {[
         let st1 = move_paddle st dx in
         let (new_ball, fell) = step_ball st1 in
         let st2 = { st1 with ball = new_ball } in
         let st3 = match paddle_deflects_ball st2 with
           | Some deflected -> { st2 with ball = deflected }
           | None -> st2
         in
         let (remaining_bricks, points) = remove_hit_bricks st3 in
         let st4 = { st3 with bricks = remaining_bricks; score = st3.score + points } in
       ]}
    3. Обработка падения мяча:
       {[
         if fell then
           let new_lives = st4.lives - 1 in
           if new_lives <= 0 then
             { st4 with lives = 0; phase = Lost }
           else
             let init_ball = initial_state.ball in  (* из lib *)
             { st4 with lives = new_lives; ball = init_ball }
         else st4
       ]}
    4. Проверка победы:
       {[
         if st5.bricks = [] then { st5 with phase = Won } else st5
       ]}

    Связанные темы: Game loop, state machine, composition of updates
    Время: ~35 минут *)
let step_game (_st : state) (_dx : float) : state =
  failwith "todo"
