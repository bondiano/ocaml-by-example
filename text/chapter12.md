# Графика с raylib

## Цели главы

В этой главе мы познакомимся с графическим программированием на OCaml, используя библиотеку **raylib-ocaml** --- привязки к популярному игровому фреймворку [Raylib](https://www.raylib.com/). Мы изучим игровой цикл, рисование примитивов, обработку ввода и анимацию. Особое внимание уделим **чистой игровой логике** --- векторной математике, обнаружению столкновений и управлению состоянием, которые можно тестировать без графической библиотеки.

## Установка raylib-ocaml

Библиотека [raylib-ocaml](https://github.com/tjammer/raylib-ocaml) устанавливается через opam:

```text
$ opam install raylib
```

В `dune`-файле исполняемого приложения добавьте зависимость:

```text
(executable
 (name main)
 (libraries raylib))
```

> Упражнения этой главы **не зависят от raylib**. Библиотечный код в `lib/` содержит чистую игровую логику (векторная математика, столкновения, физика), которая тестируется через Alcotest. Текст главы объясняет raylib для визуализации, но все упражнения --- это чистые функции.

## Игровой цикл

Любая графическая программа строится вокруг **игрового цикла** (game loop) --- бесконечного цикла, который повторяет три шага:

1. **Обработка ввода** --- считываем нажатия клавиш, позицию мыши.
2. **Обновление состояния** --- двигаем объекты, проверяем столкновения.
3. **Отрисовка** --- рисуем текущий кадр на экране.

В raylib-ocaml этот паттерн выглядит так:

```ocaml
open Raylib

let () =
  init_window 800 600 "Мой первый raylib";
  set_target_fps 60;

  while not (window_should_close ()) do
    (* 1. Обработка ввода *)
    (* 2. Обновление состояния *)

    (* 3. Отрисовка *)
    begin_drawing ();
    clear_background Color.raywhite;
    draw_text "Привет, raylib!" 300 280 20 Color.darkgray;
    end_drawing ()
  done;

  close_window ()
```

Функция `init_window` создаёт окно заданного размера с заголовком. `set_target_fps 60` ограничивает частоту кадров --- без этого цикл будет работать максимально быстро, нагружая процессор.

Цикл `while not (window_should_close ())` продолжается, пока пользователь не нажмёт Escape или не закроет окно. Внутри цикла всё рисование обрамляется парой `begin_drawing` / `end_drawing`.

## Координатная система и цвета

В raylib начало координат `(0, 0)` находится в **левом верхнем** углу экрана. Ось X направлена вправо, ось Y --- вниз:

```text
(0, 0) ---------> X
|
|
|
v
Y
```

Это отличается от математической системы координат, где Y направлена вверх. Учитывайте это при расчётах физики --- положительное ускорение по Y означает движение **вниз**.

Цвета в raylib задаются через модуль `Color`. Есть набор предопределённых цветов:

```ocaml
Color.red
Color.green
Color.blue
Color.black
Color.white
Color.raywhite  (* светло-серый фон *)
```

Можно создать свой цвет через RGBA-компоненты:

```ocaml
let my_color = Color.create 255 128 0 255  (* оранжевый, непрозрачный *)
```

## Рисование примитивов

Raylib предоставляет набор функций для рисования простых фигур. Все вызовы рисования должны находиться между `begin_drawing` и `end_drawing`:

```ocaml
(* Круг: центр (400, 300), радиус 50, красный *)
draw_circle 400 300 50.0 Color.red;

(* Прямоугольник: левый верхний угол (100, 100), ширина 200, высота 80 *)
draw_rectangle 100 100 200 80 Color.blue;

(* Линия: из (0, 0) в (400, 300), зелёная *)
draw_line 0 0 400 300 Color.green;

(* Текст: позиция (10, 10), размер шрифта 20 *)
draw_text "Счёт: 42" 10 10 20 Color.black;

(* Контур круга *)
draw_circle_lines 400 300 50.0 Color.darkgray;

(* Контур прямоугольника *)
draw_rectangle_lines 100 100 200 80 Color.darkgray;
```

## Обработка ввода

Raylib предоставляет функции для проверки состояния клавиш и мыши:

```ocaml
(* Клавиша нажата в текущем кадре *)
if is_key_pressed Key.Space then (* прыжок *)

(* Клавиша удерживается *)
if is_key_down Key.Right then (* двигаемся вправо *)

(* Позиция мыши *)
let mx = get_mouse_x () in
let my = get_mouse_y () in

(* Клик мыши *)
if is_mouse_button_pressed MouseButton.Left then (* выстрел *)
```

Различие между `is_key_pressed` и `is_key_down` важно: первая срабатывает **один раз** при нажатии, вторая --- **каждый кадр**, пока клавиша удерживается. Для движения используйте `is_key_down`, для разовых действий (прыжок, выстрел) --- `is_key_pressed`.

## Анимация: обновление состояния

Анимация --- это изменение состояния между кадрами. Простейший пример --- движущийся круг:

```ocaml
open Raylib

let () =
  init_window 800 600 "Движущийся круг";
  set_target_fps 60;

  let x = ref 400.0 in
  let y = ref 300.0 in
  let speed = 4.0 in

  while not (window_should_close ()) do
    (* Обновление *)
    if is_key_down Key.Right then x := !x +. speed;
    if is_key_down Key.Left  then x := !x -. speed;
    if is_key_down Key.Down  then y := !y +. speed;
    if is_key_down Key.Up    then y := !y -. speed;

    (* Отрисовка *)
    begin_drawing ();
    clear_background Color.raywhite;
    draw_circle (int_of_float !x) (int_of_float !y) 20.0 Color.maroon;
    end_drawing ()
  done;

  close_window ()
```

Этот пример использует `ref` для мутабельного состояния --- простой, но не очень функциональный подход. Далее мы рассмотрим более чистый паттерн.

## Чистая игровая логика

Ключевая идея функционального подхода к играм --- **отделение логики от рендеринга**. Игровое состояние описывается неизменяемой записью, а обновление --- чистой функцией:

```ocaml
type state = {
  player_x : float;
  player_y : float;
  score : int;
}

let initial_state = {
  player_x = 400.0;
  player_y = 300.0;
  score = 0;
}

(** Чистая функция обновления --- без побочных эффектов. *)
let update (input : input) (st : state) : state =
  let dx = if input.right then 4.0 else if input.left then -4.0 else 0.0 in
  let dy = if input.down then 4.0 else if input.up then -4.0 else 0.0 in
  { st with player_x = st.player_x +. dx; player_y = st.player_y +. dy }

(** Побочный эффект --- только отрисовка. *)
let draw (st : state) : unit =
  Raylib.begin_drawing ();
  Raylib.clear_background Raylib.Color.raywhite;
  Raylib.draw_circle
    (int_of_float st.player_x)
    (int_of_float st.player_y)
    20.0 Raylib.Color.maroon;
  Raylib.draw_text
    (Printf.sprintf "Счёт: %d" st.score)
    10 10 20 Raylib.Color.darkgray;
  Raylib.end_drawing ()
```

Преимущества такого подхода:

- **Тестируемость** --- функцию `update` можно тестировать без графики.
- **Воспроизводимость** --- записав последовательность `input`, можно воспроизвести игру.
- **Ясность** --- состояние явно описано типом, логика сосредоточена в одном месте.

## Векторная математика

Для работы с 2D-координатами удобно определить тип двумерного вектора и операции над ним:

```ocaml
type vec2 = { x : float; y : float }

let vec2_add a b = { x = a.x +. b.x; y = a.y +. b.y }
let vec2_sub a b = { x = a.x -. b.x; y = a.y -. b.y }
let vec2_scale s v = { x = v.x *. s; y = v.y *. s }
let vec2_length v = Float.sqrt (v.x *. v.x +. v.y *. v.y)
```

Нормализация вектора --- приведение к единичной длине --- нужна, чтобы задавать направление:

```ocaml
let vec2_normalize v =
  let len = vec2_length v in
  if len < 1e-10 then { x = 0.0; y = 0.0 }
  else vec2_scale (1.0 /. len) v
```

Проверка `len < 1e-10` защищает от деления на ноль для нулевого вектора.

Скалярное произведение (dot product) полезно для проекций и проверки направлений:

```ocaml
let vec2_dot a b = a.x *. b.x +. a.y *. b.y
```

Если `vec2_dot a b > 0`, векторы направлены примерно в одну сторону; если `< 0` --- в противоположные; если `= 0` --- перпендикулярны.

Расстояние между двумя точками --- длина вектора разности:

```ocaml
let vec2_distance a b = vec2_length (vec2_sub b a)
```

## Обнаружение столкновений

Столкновения (collisions) --- фундаментальная часть любой игры. Рассмотрим два базовых случая.

### Точка в прямоугольнике

Определим прямоугольник по левому верхнему углу, ширине и высоте:

```ocaml
type rect = { rx : float; ry : float; rw : float; rh : float }

let point_in_rect (p : vec2) (r : rect) =
  p.x >= r.rx && p.x <= r.rx +. r.rw &&
  p.y >= r.ry && p.y <= r.ry +. r.rh
```

Точка находится внутри прямоугольника, если все четыре неравенства выполняются одновременно. Эта проверка нужна, например, для определения, навёл ли пользователь курсор на кнопку.

### Столкновение двух кругов

Два круга пересекаются, если расстояние между их центрами меньше или равно сумме радиусов:

```ocaml
type circle = { center : vec2; radius : float }

let circles_collide (c1 : circle) (c2 : circle) =
  vec2_distance c1.center c2.center <= c1.radius +. c2.radius
```

Это простейшая и самая быстрая проверка столкновений. Круговые хитбоксы используются во многих играх именно из-за дешевизны проверки.

### Столкновение круга с прямоугольником

Более сложный случай --- столкновение круга с прямоугольником. Алгоритм: находим ближайшую к центру круга точку на прямоугольнике и проверяем, лежит ли она внутри круга:

```ocaml
let circle_rect_collide (c : circle) (r : rect) =
  let closest_x = Float.max r.rx (Float.min c.center.x (r.rx +. r.rw)) in
  let closest_y = Float.max r.ry (Float.min c.center.y (r.ry +. r.rh)) in
  let dx = c.center.x -. closest_x in
  let dy = c.center.y -. closest_y in
  (dx *. dx +. dy *. dy) <= c.radius *. c.radius
```

`Float.min` и `Float.max` "зажимают" (clamp) координату центра круга в пределы прямоугольника. Если расстояние от центра до этой ближайшей точки меньше радиуса --- есть столкновение. Сравниваем квадраты расстояний, чтобы избежать вычисления квадратного корня.

## Пример: прыгающий мяч

Объединим всё вышесказанное в классическом примере --- мяч, отскакивающий от стенок окна.

Состояние мяча:

```ocaml
type ball = {
  pos : vec2;     (** Позиция центра *)
  vel : vec2;     (** Скорость *)
  radius : float; (** Радиус *)
}
```

Функция обновления --- чистая, не зависит от raylib:

```ocaml
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
```

Логика проста: вычисляем новую позицию; если мяч выходит за границы по какой-либо оси --- инвертируем соответствующую компоненту скорости. Затем вычисляем финальную позицию с обновлённой скоростью.

Отрисовка --- единственное место, где нужен raylib:

```ocaml
let draw_ball (b : ball) =
  Raylib.draw_circle
    (int_of_float b.pos.x) (int_of_float b.pos.y)
    b.radius Raylib.Color.red
```

Главный цикл собирает всё вместе:

```ocaml
let () =
  let width = 800.0 in
  let height = 600.0 in
  Raylib.init_window (int_of_float width) (int_of_float height) "Bouncing Ball";
  Raylib.set_target_fps 60;

  let ball = ref {
    pos = { x = 100.0; y = 100.0 };
    vel = { x = 3.0; y = 2.0 };
    radius = 15.0;
  } in

  while not (Raylib.window_should_close ()) do
    ball := update_ball width height !ball;
    Raylib.begin_drawing ();
    Raylib.clear_background Raylib.Color.raywhite;
    draw_ball !ball;
    Raylib.end_drawing ()
  done;

  Raylib.close_window ()
```

Заметьте, что `ref` используется только для хранения состояния между кадрами. Функция `update_ball` остаётся чистой --- она принимает `ball` и возвращает новый `ball`.

## Пример: персонаж с управлением

Расширим пример --- добавим управление с клавиатуры и простую гравитацию:

```ocaml
type entity = {
  pos : vec2;
  vel : vec2;
  gravity : float;
}

let update_entity (dt : float) (e : entity) : entity =
  let new_vel = { x = e.vel.x; y = e.vel.y +. e.gravity *. dt } in
  let new_pos = vec2_add e.pos (vec2_scale dt new_vel) in
  { e with pos = new_pos; vel = new_vel }
```

Параметр `dt` (delta time) --- время, прошедшее с предыдущего кадра. Использование `dt` вместо фиксированного шага делает движение независимым от частоты кадров. В raylib `dt` получают через `Raylib.get_frame_time ()`.

## Отражение векторов

Отражение вектора скорости от поверхности --- ещё одна частая операция. Для горизонтальной поверхности (пол/потолок) инвертируем Y-компоненту:

```ocaml
let reflect_horizontal (v : vec2) : vec2 =
  { x = v.x; y = -. v.y }
```

Для вертикальной поверхности (стена) --- X-компоненту:

```ocaml
let reflect_vertical (v : vec2) : vec2 =
  { x = -. v.x; y = v.y }
```

Это упрощённая модель --- в реальных играх учитывают угол поверхности и нормаль. Но для осевых границ (стенки экрана) этого достаточно.

## Паттерн: игровое состояние

Обобщим подход к организации игры:

```ocaml
module type GAME = sig
  type state
  type input

  val initial : state
  val read_input : unit -> input  (** Побочный эффект: читаем ввод *)
  val update : input -> state -> state  (** Чистая функция *)
  val draw : state -> unit  (** Побочный эффект: рисуем *)
end

let run_game (module G : GAME) =
  let state = ref G.initial in
  while not (Raylib.window_should_close ()) do
    let input = G.read_input () in
    state := G.update input !state;
    G.draw !state
  done
```

Модульная сигнатура `GAME` чётко разделяет чистую логику (`update`) и побочные эффекты (`read_input`, `draw`). Это позволяет:

- Тестировать `update` без запуска графики.
- Заменять рендерер (например, текстовый для отладки).
- Воспроизводить игру по записи ввода.

## Сравнение с Haskell и gloss

В книге "PureScript by Example" / Haskell-версии этой книги для графики используется библиотека **gloss**. Сравним подходы:

| Аспект | Haskell + gloss | OCaml + raylib |
|--------|----------------|----------------|
| Парадигма | Чисто функциональная: `play :: ... -> (state -> Picture) -> (Event -> state -> state) -> (Float -> state -> state) -> IO ()` | Императивный цикл с чистыми функциями обновления |
| Состояние | Передаётся через аргументы `play` | Хранится в `ref`, обновляется чистой функцией |
| Ввод | Через алгебраический тип `Event` | Через функции-запросы (`is_key_down` и т.д.) |
| Рисование | Композиция значений типа `Picture` | Последовательность вызовов `draw_*` |
| Возможности | 2D, простые формы и изображения | 2D и 3D, текстуры, звук, шейдеры |
| Установка | `cabal install gloss` | `opam install raylib` |

Gloss предоставляет более декларативный API: вы описываете **картинку** как значение, а не последовательность команд. Raylib ближе к императивному стилю, но мощнее --- он поддерживает 3D, звук, шейдеры и многое другое.

Принцип, однако, одинаков: **логика игры --- чистые функции**, рендеринг --- тонкая прослойка с побочными эффектами.

## Структура проекта упражнений

Откройте директорию `exercises/chapter12`:

```text
chapter12/
├── dune-project
├── lib/
│   ├── dune
│   └── game.ml              <- чистая игровая логика (векторы, столкновения, физика)
├── test/
│   ├── dune
│   ├── test_chapter12.ml    <- тесты
│   └── my_solutions.ml      <- ваши решения
└── no-peeking/
    └── solutions.ml          <- эталонные решения
```

Библиотека `lib/game.ml` содержит типы (`vec2`, `rect`, `circle`, `ball`) и функции (векторная арифметика, обнаружение столкновений, обновление мяча). Она **не зависит от raylib** --- только стандартная библиотека OCaml.

## Упражнения

Решения пишите в файле `test/my_solutions.ml`. После каждого упражнения запускайте `dune test`, чтобы проверить ответ.

1. **(Лёгкое)** Реализуйте функцию `reflect_horizontal`, которая отражает вектор скорости от горизонтальной поверхности (пол или потолок). При таком отражении X-компонента остаётся прежней, а Y-компонента инвертируется.

    ```ocaml
    val reflect_horizontal : vec2 -> vec2
    ```

    ```text
    # reflect_horizontal { x = 3.0; y = 4.0 };;
    - : vec2 = { x = 3.0; y = -4.0 }
    ```

2. **(Лёгкое)** Реализуйте функцию `reflect_vertical`, которая отражает вектор скорости от вертикальной поверхности (стена). При таком отражении Y-компонента остаётся прежней, а X-компонента инвертируется.

    ```ocaml
    val reflect_vertical : vec2 -> vec2
    ```

    ```text
    # reflect_vertical { x = 3.0; y = 4.0 };;
    - : vec2 = { x = -3.0; y = 4.0 }
    ```

3. **(Среднее)** Реализуйте функцию `circle_rect_collide`, которая проверяет столкновение круга с прямоугольником. Алгоритм: найдите ближайшую к центру круга точку на прямоугольнике (используя `Float.min` и `Float.max` для "зажатия" координат), затем проверьте, лежит ли эта точка внутри круга.

    ```ocaml
    val circle_rect_collide : circle -> rect -> bool
    ```

    *Подсказка:* Сравнивайте квадраты расстояний, чтобы не вычислять квадратный корень.

4. **(Среднее)** Реализуйте функцию `update_entity`, которая обновляет позицию и скорость сущности с учётом гравитации. За время `dt`:
    - Новая скорость: `vel.y + gravity * dt`.
    - Новая позиция: `pos + new_vel * dt`.

    ```ocaml
    type entity = { pos : vec2; vel : vec2; gravity : float }

    val update_entity : float -> entity -> entity
    ```

    *Подсказка:* используйте `vec2_add` и `vec2_scale` из библиотеки.

## Заключение

В этой главе мы:

- Познакомились с библиотекой raylib-ocaml и игровым циклом.
- Изучили рисование примитивов, цвета и координатную систему.
- Научились обрабатывать ввод с клавиатуры и мыши.
- Разделили чистую игровую логику и рендеринг.
- Реализовали векторную математику: сложение, вычитание, масштабирование, нормализация, скалярное произведение.
- Написали функции обнаружения столкновений: точка-прямоугольник, круг-круг, круг-прямоугольник.
- Создали модели физики: прыгающий мяч, сущность с гравитацией.
- Сравнили подходы OCaml + raylib и Haskell + gloss.

Главный урок этой главы --- **отделяйте чистую логику от побочных эффектов**. Это упрощает тестирование, отладку и переиспользование кода. Графическая библиотека --- лишь тонкая обёртка для визуализации состояния, которое вычисляется чистыми функциями.
