open Appendix_a.Game

let sw = 800.0
let sh = 600.0

let base = initial_state ~screen_w:sw ~screen_h:sh

(** Вспомогательный конструктор состояния для тестов. *)
let make_state ?ball ?paddle ?bricks ?score ?lives ?phase () =
  { base with
    ball    = Option.value ~default:base.ball ball;
    paddle  = Option.value ~default:base.paddle paddle;
    bricks  = Option.value ~default:base.bricks bricks;
    score   = Option.value ~default:0 score;
    lives   = Option.value ~default:base.lives lives;
    phase   = Option.value ~default:Playing phase }

(* ------------------------------------------------------------------ *)
(*  Упражнение 1: move_paddle                                          *)
(* ------------------------------------------------------------------ *)

let move_paddle_tests =
  let open Alcotest in
  [ test_case "смещает паддл вправо" `Quick (fun () ->
      let st = My_solutions.move_paddle base 20.0 in
      check bool "x увеличился" true (st.paddle.x > base.paddle.x));

    test_case "смещает паддл влево" `Quick (fun () ->
      let st = My_solutions.move_paddle base (-20.0) in
      check bool "x уменьшился" true (st.paddle.x < base.paddle.x));

    test_case "паддл не уходит за правый край" `Quick (fun () ->
      let st = My_solutions.move_paddle base 9999.0 in
      check bool "x <= screen_w - paddle.w" true
        (st.paddle.x <= sw -. base.paddle.w));

    test_case "паддл не уходит за левый край" `Quick (fun () ->
      let st = My_solutions.move_paddle base (-9999.0) in
      check bool "x >= 0" true (st.paddle.x >= 0.0));

    test_case "остальные поля не изменяются" `Quick (fun () ->
      let st = My_solutions.move_paddle base 10.0 in
      check int "score" base.score st.score;
      check int "lives" base.lives st.lives) ]

(* ------------------------------------------------------------------ *)
(*  Упражнение 2: step_ball                                            *)
(* ------------------------------------------------------------------ *)

let step_ball_tests =
  let open Alcotest in
  [ test_case "мяч на открытом пространстве смещается вперёд" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = 300.0 };
                vel = { x = 3.0; y = -5.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b () in
      let (b', fell) = My_solutions.step_ball st in
      check bool "упал = false" false fell;
      check bool "x сдвинулся" true (Float.abs (b'.pos.x -. 403.0) < 1e-6);
      check bool "y сдвинулся" true (Float.abs (b'.pos.y -. 295.0) < 1e-6));

    test_case "отражение от левой стены: vx инвертируется" `Quick (fun () ->
      let b = { pos = { x = 5.0; y = 300.0 };
                vel = { x = -4.0; y = 2.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b () in
      let (b', _) = My_solutions.step_ball st in
      check bool "vx > 0" true (b'.vel.x > 0.0));

    test_case "отражение от правой стены: vx инвертируется" `Quick (fun () ->
      let b = { pos = { x = sw -. 5.0; y = 300.0 };
                vel = { x = 4.0; y = 2.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b () in
      let (b', _) = My_solutions.step_ball st in
      check bool "vx < 0" true (b'.vel.x < 0.0));

    test_case "отражение от потолка: vy инвертируется" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = 5.0 };
                vel = { x = 2.0; y = -4.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b () in
      let (b', _) = My_solutions.step_ball st in
      check bool "vy > 0" true (b'.vel.y > 0.0));

    test_case "мяч улетел за нижний край: fell = true" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = sh -. 2.0 };
                vel = { x = 0.0; y = 6.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b () in
      let (_, fell) = My_solutions.step_ball st in
      check bool "fell = true" true fell) ]

(* ------------------------------------------------------------------ *)
(*  Упражнение 3: paddle_deflects_ball                                 *)
(* ------------------------------------------------------------------ *)

let paddle_deflects_tests =
  let open Alcotest in
  let paddle = { x = 350.0; y = sh -. 40.0; w = 100.0; h = 14.0 } in
  [ test_case "мяч не касается паддла → None" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = 200.0 };
                vel = { x = 0.0; y = 5.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b ~paddle () in
      check bool "None" true (My_solutions.paddle_deflects_ball st = None));

    test_case "мяч касается паддла летя вниз → Some, vy < 0" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = sh -. 40.0 };
                vel = { x = 2.0; y = 5.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b ~paddle () in
      match My_solutions.paddle_deflects_ball st with
      | None -> fail "ожидали Some"
      | Some b' -> check bool "vy < 0" true (b'.vel.y < 0.0));

    test_case "мяч летит вверх (vel.y < 0) и касается паддла → None" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = sh -. 40.0 };
                vel = { x = 2.0; y = -5.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b ~paddle () in
      check bool "None" true (My_solutions.paddle_deflects_ball st = None)) ]

(* ------------------------------------------------------------------ *)
(*  Упражнение 4: remove_hit_bricks                                    *)
(* ------------------------------------------------------------------ *)

let remove_bricks_tests =
  let open Alcotest in
  [ test_case "мяч не касается ни одного кирпича → список не меняется, 0 очков" `Quick
      (fun () ->
        let b = { pos = { x = 400.0; y = 400.0 };
                  vel = { x = 0.0; y = 0.0 };
                  radius = 8.0 } in
        let bricks = [ { x = 0.0; y = 0.0; w = 50.0; h = 20.0; points = 3 } ] in
        let st = make_state ~ball:b ~bricks () in
        let (remaining, pts) = My_solutions.remove_hit_bricks st in
        check int "кол-во кирпичей" 1 (List.length remaining);
        check int "очки" 0 pts);

    test_case "мяч попадает в кирпич → кирпич убран, очки начислены" `Quick
      (fun () ->
        let b = { pos = { x = 25.0; y = 10.0 };
                  vel = { x = 0.0; y = 0.0 };
                  radius = 8.0 } in
        let bricks =
          [ { x = 0.0; y = 0.0; w = 50.0; h = 20.0; points = 4 };
            { x = 200.0; y = 0.0; w = 50.0; h = 20.0; points = 2 } ] in
        let st = make_state ~ball:b ~bricks () in
        let (remaining, pts) = My_solutions.remove_hit_bricks st in
        check int "кол-во кирпичей" 1 (List.length remaining);
        check int "очки" 4 pts);

    test_case "мяч попадает в два кирпича → оба убраны, сумма очков" `Quick
      (fun () ->
        let b = { pos = { x = 25.0; y = 10.0 };
                  vel = { x = 0.0; y = 0.0 };
                  radius = 30.0 } in
        let bricks =
          [ { x = 0.0; y = 0.0; w = 20.0; h = 20.0; points = 5 };
            { x = 20.0; y = 0.0; w = 20.0; h = 20.0; points = 3 } ] in
        let st = make_state ~ball:b ~bricks () in
        let (remaining, pts) = My_solutions.remove_hit_bricks st in
        check int "кол-во кирпичей" 0 (List.length remaining);
        check int "очки" 8 pts) ]

(* ------------------------------------------------------------------ *)
(*  Упражнение 5: step_game                                            *)
(* ------------------------------------------------------------------ *)

let step_game_tests =
  let open Alcotest in
  [ test_case "состояние Won не меняется" `Quick (fun () ->
      let st = make_state ~phase:Won () in
      let st' = My_solutions.step_game st 0.0 in
      check bool "phase = Won" true (st'.phase = Won));

    test_case "состояние Lost не меняется" `Quick (fun () ->
      let st = make_state ~phase:Lost () in
      let st' = My_solutions.step_game st 0.0 in
      check bool "phase = Lost" true (st'.phase = Lost));

    test_case "при dx=0 паддл не двигается" `Quick (fun () ->
      let st = My_solutions.step_game base 0.0 in
      check bool "paddle.x не изменился" true
        (Float.abs (st.paddle.x -. base.paddle.x) < 1e-6));

    test_case "мяч падает вниз → жизни уменьшаются" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = sh -. 2.0 };
                vel = { x = 0.0; y = 10.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b ~lives:3 () in
      let st' = My_solutions.step_game st 0.0 in
      check bool "lives уменьшились" true (st'.lives < 3));

    test_case "мяч падает при lives=1 → phase = Lost" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = sh -. 2.0 };
                vel = { x = 0.0; y = 10.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b ~lives:1 () in
      let st' = My_solutions.step_game st 0.0 in
      check bool "phase = Lost" true (st'.phase = Lost));

    test_case "нет кирпичей → phase = Won" `Quick (fun () ->
      let b = { pos = { x = 400.0; y = 300.0 };
                vel = { x = 1.0; y = -1.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b ~bricks:[] () in
      let st' = My_solutions.step_game st 0.0 in
      check bool "phase = Won" true (st'.phase = Won));

    test_case "счёт растёт при попадании в кирпич" `Quick (fun () ->
      let brick = { x = 395.0; y = 295.0; w = 30.0; h = 20.0; points = 5 } in
      let b = { pos = { x = 400.0; y = 300.0 };
                vel = { x = 0.0; y = -1.0 };
                radius = 8.0 } in
      let st = make_state ~ball:b ~bricks:[ brick ] ~score:0 () in
      let st' = My_solutions.step_game st 0.0 in
      check bool "score > 0" true (st'.score > 0)) ]

(* ------------------------------------------------------------------ *)

let () =
  Alcotest.run "Appendix A — Арканоид"
    [ ("move_paddle — движение паддла",  move_paddle_tests);
      ("step_ball — шаг мяча",           step_ball_tests);
      ("paddle_deflects — отбивание",    paddle_deflects_tests);
      ("remove_hit_bricks — кирпичи",   remove_bricks_tests);
      ("step_game — игровой шаг",        step_game_tests) ]
