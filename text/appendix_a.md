# Графика с raylib: Арканоид

## Цели главы

В этом приложении мы построим классическую игру **Арканоид** на OCaml с библиотекой [raylib-ocaml](https://github.com/tjammer/raylib-ocaml). Вы будете реализовывать куски реальной игровой логики, и сразу видеть результат запустив `dune exec ./bin/main.exe`.

Архитектурный принцип: **чистая логика отделена от рендеринга**. Функции обновления состояния — чистые, тестируются через Alcotest без запуска окна. Raylib появляется только в `bin/main.ml`.

## Установка raylib-ocaml

```text
$ opam install raylib
```

В `dune` исполняемого приложения:

```text
(executable
 (name main)
 (libraries appendix_a raylib))
```

> Упражнения этой главы — **чистые функции** из `lib/game.ml` и `test/my_solutions.ml`. Raylib нужен только для запуска готовой игры. Тесты (`dune test`) работают без графики.

## Структура проекта

```text
exercises/appendix_a/
├── lib/
│   └── game.ml       ← типы, утилиты (vec2, clamp, rect_hits_ball…)
├── bin/
│   └── main.ml       ← полная raylib-игра (уже реализована)
├── test/
│   ├── my_solutions.ml  ← вы реализуете логику здесь
│   └── test_appendix_a.ml
└── no-peeking/
    └── solutions.ml
```

Запустите готовую игру до начала упражнений, чтобы понять, что будете строить:

```text
$ cd exercises/appendix_a
$ dune exec ./bin/main.exe
```

Управление: **← / →** — двигать ракетку, **R** — рестарт.

## Игра Арканоид

Арканоид — классика жанра: мяч летает по экрану, ракетка его отбивает, кирпичи разбиваются. Потерял мяч — теряешь жизнь. Разбил все кирпичи — победа.

Состояние игры описывается записью:

```ocaml
type state = {
  ball     : ball;
  paddle   : paddle;
  bricks   : brick list;
  score    : int;
  lives    : int;
  phase    : phase;     (* Playing | Won | Lost *)
  screen_w : float;
  screen_h : float;
}
```

Каждый кадр: читаем ввод → вычисляем новое `state` → рисуем. Функция обновления — чистая:

```ocaml
let step_game (st : state) (dx : float) : state = …
```

## Игровой цикл в raylib

Raylib строится вокруг классического **game loop**:

```ocaml
open Raylib

let () =
  init_window 800 600 "Мой первый raylib";
  set_target_fps 60;

  while not (window_should_close ()) do
    (* 1. Ввод *)
    let dx =
      (if is_key_down Key.Right then 6.0 else 0.0) +.
      (if is_key_down Key.Left  then -6.0 else 0.0)
    in

    (* 2. Обновление состояния (чистая функция) *)
    state := step_game !state dx;

    (* 3. Отрисовка *)
    begin_drawing ();
    clear_background Color.black;
    (* draw_* вызовы *)
    end_drawing ()
  done;

  close_window ()
```

`init_window` создаёт окно. `set_target_fps 60` ограничивает частоку кадров. `window_should_close` возвращает `true` при нажатии Escape или закрытии окна.

## Координаты и примитивы

Начало координат — **левый верхний** угол, ось Y направлена вниз:

```text
(0,0) ──────────► X
  │
  │
  ▼ Y
```

Рисование фигур (только внутри `begin_drawing` / `end_drawing`):

```ocaml
(* Прямоугольник: x, y, ширина, высота, цвет *)
draw_rectangle 100 200 80 20 Color.white;

(* Контур прямоугольника *)
draw_rectangle_lines 100 200 80 20 Color.gray;

(* Круг: cx, cy, радиус, цвет *)
draw_circle 400 300 8.0 Color.raywhite;

(* Текст: строка, x, y, размер, цвет *)
draw_text "Счёт: 42" 10 10 20 Color.white;
```

## Ввод с клавиатуры

```ocaml
(* Клавиша удерживается — для плавного движения *)
if is_key_down Key.Right then …

(* Клавиша нажата в этом кадре — для разовых действий *)
if is_key_pressed Key.R then …
```

`is_key_down` срабатывает каждый кадр пока клавиша зажата. `is_key_pressed` — только в первый кадр.

## Детекция столкновений: AABB vs круг

В библиотеке `lib/game.ml` есть функция:

```ocaml
val rect_hits_ball : bx:float -> by:float -> bw:float -> bh:float -> ball -> bool
```

Алгоритм: находим ближайшую к центру мяча точку на прямоугольнике через `clamp`, проверяем расстояние:

```ocaml
let rect_hits_ball ~bx ~by ~bw ~bh (ball : ball) =
  let cx = clamp ball.pos.x bx (bx +. bw) in
  let cy = clamp ball.pos.y by (by +. bh) in
  let dx = ball.pos.x -. cx in
  let dy = ball.pos.y -. cy in
  dx *. dx +. dy *. dy <= ball.radius *. ball.radius
```

Сравниваем квадраты расстояний — чтобы не вычислять корень.

## Пример: движущийся мяч

Простейший пример — мяч, отражающийся от стен. Логика отделена от рендеринга:

```ocaml
(* Чистая функция — не зависит от raylib *)
let bounce_ball (width : float) (height : float) (b : ball) : ball =
  let np = vec2_add b.pos b.vel in
  let vx = if np.x -. b.radius < 0.0 || np.x +. b.radius > width
           then -. b.vel.x else b.vel.x in
  let vy = if np.y -. b.radius < 0.0 || np.y +. b.radius > height
           then -. b.vel.y else b.vel.y in
  { b with pos = vec2_add b.pos { x = vx; y = vy }; vel = { x = vx; y = vy } }

(* Побочный эффект — только отрисовка *)
let draw_ball (b : ball) =
  Raylib.draw_circle
    (int_of_float b.pos.x) (int_of_float b.pos.y)
    b.radius Raylib.Color.raywhite
```

```admonish tip title="Для Python/TS-разработчиков"
В Pygame состояние обычно хранится в объектах класса, а обновление — метод `update()`. В TypeScript/React это напоминает `useReducer`: `(state, action) -> state`. В OCaml мы используем `ref` только на верхнем уровне игрового цикла, а все функции обновления — чистые. Это делает логику тестируемой без запуска графики.
```

## Структура проекта упражнений

Откройте `exercises/appendix_a`. Ваши решения — в `test/my_solutions.ml`. Каждая функция — кусочек реальной игры из `bin/main.ml`. После реализации:

```text
$ dune test              # проверка логики
$ dune exec ./bin/main.exe  # видите игру
```

## Упражнения

Решения пишите в `test/my_solutions.ml`. Все нужные типы открыты через `open Appendix_a.Game`.

---

### 1. Движение ракетки (лёгкое)

```ocaml
val move_paddle : state -> float -> state
```

Прибавьте `dx` к `paddle.x`, затем ограничьте через `clamp` так, чтобы ракетка не выходила за экран:

```text
0 ≤ paddle.x ≤ screen_w − paddle.w
```

```text
# move_paddle state 20.0 |> fun st -> st.paddle.x > state.paddle.x;;
- : bool = true
# move_paddle state 9999.0 |> fun st -> st.paddle.x <= state.screen_w -. state.paddle.w;;
- : bool = true
```

---

### 2. Шаг мяча (среднее)

```ocaml
val step_ball : state -> ball * bool
```

Вычислите новую позицию: `pos + vel`. Обработайте отражения:

- **Левая/правая стена** (`x ± radius` выходит за [0; screen_w]): инвертируйте `vel.x`.
- **Потолок** (`y − radius < 0`): инвертируйте `vel.y`.
- **Дно** (`y + radius > screen_h`): верните `fell = true`.

```text
# step_ball (make_ball_near_left_wall) |> fun (b, _) -> b.vel.x > 0.0;;
- : bool = true   (* отразился вправо *)

# step_ball (make_ball_below_screen) |> snd;;
- : bool = true   (* fell *)
```

*Подсказка:* используйте `vec2_add` из библиотеки для вычисления новой позиции.

---

### 3. Ракетка отбивает мяч (среднее)

```ocaml
val paddle_deflects_ball : state -> ball option
```

Если мяч касается ракетки (`rect_hits_ball`) И летит вниз (`vel.y > 0.0`):
- верните `Some new_ball` с инвертированным `vel.y` (делайте `−|vel.y|`).

Иначе верните `None`.

```text
# paddle_deflects_ball state_ball_hits_paddle;;
- : ball option = Some {…; vel = {…; y = -5.0}}

# paddle_deflects_ball state_ball_above_paddle;;
- : ball option = None
```

*Подсказка:* `rect_hits_ball ~bx:p.x ~by:p.y ~bw:p.w ~bh:p.h st.ball`.

---

### 4. Убираем разбитые кирпичи (среднее)

```ocaml
val remove_hit_bricks : state -> brick list * int
```

Для каждого кирпича из `st.bricks` проверьте столкновение с `st.ball` через `rect_hits_ball`. Задетые кирпичи уберите, подсчитайте сумму их `points`.

```text
# remove_hit_bricks state_ball_hits_one_5pt_brick;;
- : brick list * int = ([…остальные…], 5)
```

*Подсказка:* используйте `List.fold_left` — аккумулятором служит пара `(remaining, total_pts)`.

---

### 5. Полный игровой шаг (сложное)

```ocaml
val step_game : state -> float -> state
```

Используя функции 1–4, реализуйте один кадр игры:

1. Если `st.phase ≠ Playing` — вернуть без изменений.
2. Двинуть ракетку на `dx` (`move_paddle`).
3. Двинуть мяч (`step_ball`), запомнить `fell`.
4. Применить отражение от ракетки (`paddle_deflects_ball`).
5. Убрать разбитые кирпичи, прибавить очки (`remove_hit_bricks`).
6. Если `fell`:
   - `lives − 1`.
   - Если `lives ≤ 0` → `phase = Lost`.
   - Иначе → сбросить мяч в начало через `initial_state`.
7. Если `bricks = []` → `phase = Won`.

Когда тесты проходят — запустите игру и убедитесь, что она работает:

```text
$ dune exec ./bin/main.exe
```

## Идеи для расширения

После того как базовая игра заработает, можно добавить:

- **Ускорение мяча** — с каждым ударом о кирпич увеличивайте `|vel|` на 0.5%.
- **Угол отражения от ракетки** — как в `bin/main.ml`: угол зависит от точки удара (края дают больший угол).
- **Бонусы** — с некоторых кирпичей падают powerup-шары: расширение ракетки, дополнительная жизнь.
- **Многоуровневость** — после победы загружать новую сетку кирпичей.
- **Звук** — `Raylib.play_sound` для звука удара.

Все эти фичи реализуются в `bin/main.ml` поверх уже написанной логики.

```admonish info title="Real World OCaml"
О работе с внешними C-библиотеками (что используется под капотом raylib-ocaml) — глава [Foreign Function Interface](https://dev.realworldocaml.org/foreign-function-interface.html) книги Real World OCaml.
```

## Заключение

- Построили реальную игру Арканоид, разделив логику и рендеринг.
- Чистые функции (`move_paddle`, `step_ball`, `paddle_deflects_ball`, `remove_hit_bricks`, `step_game`) тестируются без запуска окна.
- Raylib — тонкая прослойка: игровой цикл, `begin_drawing`/`end_drawing`, примитивы.
- Паттерн применим к любой игре: state, update (чистая), draw (эффект).
