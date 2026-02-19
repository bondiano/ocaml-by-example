open Chapter14.Game

let float_eps = 1e-6

let check_vec2 msg expected actual =
  let open Alcotest in
  check bool (msg ^ " x") true (Float.abs (expected.x -. actual.x) < float_eps);
  check bool (msg ^ " y") true (Float.abs (expected.y -. actual.y) < float_eps)

(* --- Тесты библиотеки --- *)

let vec2_tests =
  let open Alcotest in
  [
    test_case "vec2_add" `Quick (fun () ->
      check_vec2 "add" { x = 3.0; y = 5.0 }
        (vec2_add { x = 1.0; y = 2.0 } { x = 2.0; y = 3.0 }));
    test_case "vec2_sub" `Quick (fun () ->
      check_vec2 "sub" { x = 1.0; y = 1.0 }
        (vec2_sub { x = 3.0; y = 4.0 } { x = 2.0; y = 3.0 }));
    test_case "vec2_scale" `Quick (fun () ->
      check_vec2 "scale" { x = 6.0; y = 9.0 }
        (vec2_scale 3.0 { x = 2.0; y = 3.0 }));
    test_case "vec2_length" `Quick (fun () ->
      let len = vec2_length { x = 3.0; y = 4.0 } in
      check bool "len 5" true (Float.abs (len -. 5.0) < float_eps));
    test_case "vec2_normalize" `Quick (fun () ->
      let n = vec2_normalize { x = 3.0; y = 4.0 } in
      let len = vec2_length n in
      check bool "unit" true (Float.abs (len -. 1.0) < float_eps));
    test_case "vec2_normalize zero" `Quick (fun () ->
      check_vec2 "zero" { x = 0.0; y = 0.0 }
        (vec2_normalize { x = 0.0; y = 0.0 }));
    test_case "vec2_dot" `Quick (fun () ->
      let d = vec2_dot { x = 1.0; y = 2.0 } { x = 3.0; y = 4.0 } in
      check bool "dot 11" true (Float.abs (d -. 11.0) < float_eps));
  ]

let collision_tests =
  let open Alcotest in
  [
    test_case "point_in_rect inside" `Quick (fun () ->
      check bool "inside" true
        (point_in_rect { x = 5.0; y = 5.0 }
           { rx = 0.0; ry = 0.0; rw = 10.0; rh = 10.0 }));
    test_case "point_in_rect outside" `Quick (fun () ->
      check bool "outside" false
        (point_in_rect { x = 15.0; y = 5.0 }
           { rx = 0.0; ry = 0.0; rw = 10.0; rh = 10.0 }));
    test_case "circles_collide yes" `Quick (fun () ->
      check bool "collide" true
        (circles_collide
           { center = { x = 0.0; y = 0.0 }; radius = 5.0 }
           { center = { x = 8.0; y = 0.0 }; radius = 5.0 }));
    test_case "circles_collide no" `Quick (fun () ->
      check bool "no collide" false
        (circles_collide
           { center = { x = 0.0; y = 0.0 }; radius = 3.0 }
           { center = { x = 10.0; y = 0.0 }; radius = 3.0 }));
  ]

let ball_tests =
  let open Alcotest in
  [
    test_case "update_ball no bounce" `Quick (fun () ->
      let b = { pos = { x = 50.0; y = 50.0 }; vel = { x = 1.0; y = 1.0 }; radius = 5.0 } in
      let b' = update_ball 100.0 100.0 b in
      check bool "moved right" true (b'.pos.x > b.pos.x);
      check bool "moved down" true (b'.pos.y > b.pos.y));
    test_case "update_ball bounce right" `Quick (fun () ->
      let b = { pos = { x = 96.0; y = 50.0 }; vel = { x = 5.0; y = 0.0 }; radius = 5.0 } in
      let b' = update_ball 100.0 100.0 b in
      check bool "vel reversed" true (b'.vel.x < 0.0));
  ]

(* --- Тесты упражнений --- *)

let reflect_tests =
  let open Alcotest in
  [
    test_case "reflect_horizontal" `Quick (fun () ->
      let v = My_solutions.reflect_horizontal { x = 3.0; y = 4.0 } in
      check_vec2 "reflected" { x = 3.0; y = -4.0 } v);
    test_case "reflect_vertical" `Quick (fun () ->
      let v = My_solutions.reflect_vertical { x = 3.0; y = 4.0 } in
      check_vec2 "reflected" { x = -3.0; y = 4.0 } v);
    test_case "reflect_horizontal zero" `Quick (fun () ->
      let v = My_solutions.reflect_horizontal { x = 0.0; y = 0.0 } in
      check_vec2 "zero" { x = 0.0; y = 0.0 } v);
  ]

let circle_rect_tests =
  let open Alcotest in
  [
    test_case "circle_rect overlap" `Quick (fun () ->
      check bool "overlap" true
        (My_solutions.circle_rect_collide
           { center = { x = 5.0; y = 5.0 }; radius = 3.0 }
           { rx = 0.0; ry = 0.0; rw = 10.0; rh = 10.0 }));
    test_case "circle_rect no overlap" `Quick (fun () ->
      check bool "no overlap" false
        (My_solutions.circle_rect_collide
           { center = { x = 20.0; y = 20.0 }; radius = 2.0 }
           { rx = 0.0; ry = 0.0; rw = 10.0; rh = 10.0 }));
    test_case "circle_rect edge" `Quick (fun () ->
      check bool "edge touch" true
        (My_solutions.circle_rect_collide
           { center = { x = 13.0; y = 5.0 }; radius = 3.0 }
           { rx = 0.0; ry = 0.0; rw = 10.0; rh = 10.0 }));
  ]

let entity_tests =
  let open Alcotest in
  [
    test_case "update_entity with gravity" `Quick (fun () ->
      let e = My_solutions.{
        pos = { x = 0.0; y = 0.0 };
        vel = { x = 10.0; y = 0.0 };
        gravity = 9.8;
      } in
      let e' = My_solutions.update_entity 1.0 e in
      check bool "moved right" true (e'.pos.x > 0.0);
      check bool "moved down" true (e'.pos.y > 0.0);
      check bool "vel_y increased" true (e'.vel.y > 0.0));
    test_case "update_entity no gravity" `Quick (fun () ->
      let e = My_solutions.{
        pos = { x = 0.0; y = 0.0 };
        vel = { x = 5.0; y = -3.0 };
        gravity = 0.0;
      } in
      let e' = My_solutions.update_entity 2.0 e in
      check bool "x" true (Float.abs (e'.pos.x -. 10.0) < float_eps);
      check bool "y" true (Float.abs (e'.pos.y -. (-6.0)) < float_eps));
  ]

let () =
  Alcotest.run "Chapter 12"
    [
      ("vec2 --- операции с векторами", vec2_tests);
      ("collision --- столкновения", collision_tests);
      ("ball --- физика мяча", ball_tests);
      ("reflect --- отражения", reflect_tests);
      ("circle_rect --- круг и прямоугольник", circle_rect_tests);
      ("entity --- обновление с гравитацией", entity_tests);
    ]
