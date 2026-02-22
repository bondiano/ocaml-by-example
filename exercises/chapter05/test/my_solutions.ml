(** Здесь вы можете писать свои решения упражнений. *)

open Chapter05.Shapes

(* Среднее *)
(** Упражнение: Area — площадь фигуры.

    Вычислить площадь для каждого типа фигуры:
    - Circle (center, radius): π * r²
    - Rectangle (corner, width, height): w * h
    - Line: 0 (линия не имеет площади)
    - Text: 0 (текст не имеет площади)

    Типы определены в lib/shapes.ml:
    {[
      type shape =
        | Circle of point * float
        | Rectangle of point * float * float
        | Line of point * point
        | Text of point * string
    ]}

    Подсказки:
    1. Используйте pattern matching: function | Circle ... | Rectangle ...
    2. Float.pi для константы π
    3. Деструктурируйте только нужные поля: Circle (_, r)

    Время: ~12 минут *)
let area (_shape : shape) : float =
  failwith "todo"

(* Среднее *)
(** Упражнение: Scale — масштабирование фигуры.

    Увеличить/уменьшить фигуру в factor раз:
    - Circle: масштабировать радиус
    - Rectangle: масштабировать ширину и высоту
    - Line: масштабировать обе точки относительно начала координат
    - Text: масштабировать позицию

    Примеры:
    {[
      scale 2.0 (Circle ({x=0; y=0}, 5.0)) = Circle ({x=0; y=0}, 10.0)
      scale 2.0 (Rectangle ({x=0; y=0}, 3.0, 4.0)) = Rectangle ({x=0; y=0}, 6.0, 8.0)
      scale 2.0 (Line ({x=1; y=2}, {x=3; y=4})) = Line ({x=2; y=4}, {x=6; y=8})
    ]}

    Подсказки:
    1. Для Line и Text: умножьте координаты x и y на factor
    2. Создайте новые записи point: {x = p.x *. factor; y = p.y *. factor}

    Время: ~15 минут *)
let scale (_factor : float) (_shape : shape) : shape =
  failwith "todo"

(* Лёгкое *)
(** Упражнение: Shape Text — извлечь текст из фигуры.

    Если фигура — Text, вернуть Some с содержимым.
    Иначе вернуть None.

    Примеры:
    {[
      shape_text (Text ({x=0; y=0}, "hello")) = Some "hello"
      shape_text (Circle ({x=0; y=0}, 5.0)) = None
    ]}

    Подсказка: простой pattern matching с двумя случаями
    Время: ~5 минут *)
let shape_text (_shape : shape) : string option =
  failwith "todo"

(* Лёгкое *)
(** Упражнение: Safe Head — безопасный первый элемент списка.

    Вернуть Some первого элемента или None если список пустой.

    Примеры:
    {[
      safe_head [1; 2; 3] = Some 1
      safe_head [] = None
    ]}

    Подсказка: pattern matching на [] и x :: xs
    Время: ~3 минуты *)
let safe_head (_lst : 'a list) : 'a option =
  failwith "todo"

(* Среднее *)
(** Упражнение: Bob — ответы подростка Боба.

    Боб отвечает в зависимости от того, как к нему обращаются:

    Правила:
    - Вопрос (заканчивается на '?'): "Sure."
    - Крик (все буквы заглавные, есть хотя бы одна буква): "Whoa, chill out!"
    - Кричащий вопрос (заглавные И '?'): "Calm down, I know what I'm doing!"
    - Тишина (только пробелы): "Fine. Be that way!"
    - Обычное утверждение: "Whatever."

    Примеры:
    {[
      bob "How are you?" = "Sure."
      bob "WHAT ARE YOU DOING" = "Whoa, chill out!"
      bob "WHAT?" = "Calm down, I know what I'm doing!"
      bob "   " = "Fine. Be that way!"
      bob "Hello there" = "Whatever."
    ]}

    Подсказки:
    1. String.trim для удаления пробелов
    2. String.uppercase_ascii для проверки крика
    3. Проверьте условия в правильном порядке (сложные первыми)

    Время: ~20 минут *)
let bob (_input : string) : string = failwith "todo"

(* Среднее *)
(** Упражнение: Triangle — классификация треугольника.

    Классифицировать треугольник по длинам сторон:
    - Equilateral: все три стороны равны
    - Isosceles: две стороны равны
    - Scalene: все стороны разные

    Валидация (вернуть Error если):
    - Любая сторона <= 0
    - Нарушено неравенство треугольника: a + b <= c

    Примеры:
    {[
      classify_triangle 2.0 2.0 2.0 = Ok Equilateral
      classify_triangle 3.0 3.0 4.0 = Ok Isosceles
      classify_triangle 3.0 4.0 5.0 = Ok Scalene
      classify_triangle 1.0 1.0 3.0 = Error "нарушено неравенство треугольника"
    ]}

    Подсказки:
    1. Сначала валидация, потом классификация
    2. Неравенство треугольника: a+b>c && b+c>a && a+c>b
    3. Используйте Result.Ok и Result.Error

    Время: ~18 минут *)
type triangle = Equilateral | Isosceles | Scalene

let classify_triangle (_a : float) (_b : float) (_c : float)
    : (triangle, string) result = failwith "todo"

(* Лёгкое *)
(** Упражнение: Raindrops — звуки капель дождя.

    Преобразовать число по правилам:
    - Если делится на 3: добавить "Pling"
    - Если делится на 5: добавить "Plang"
    - Если делится на 7: добавить "Plong"
    - Если ни на что не делится: вернуть само число как строку

    Примеры:
    {[
      raindrops 3 = "Pling"
      raindrops 5 = "Plang"
      raindrops 7 = "Plong"
      raindrops 15 = "PlingPlang"   (* делится на 3 и 5 *)
      raindrops 21 = "PlingPlong"   (* делится на 3 и 7 *)
      raindrops 34 = "34"           (* не делится *)
    ]}

    Подсказки:
    1. Проверьте делимость: n mod 3 = 0
    2. Конкатенируйте строки: result ^ "Pling"
    3. Если результат пустой — верните string_of_int n

    Время: ~10 минут *)
let raindrops (_n : int) : string = failwith "todo"

(* Среднее *)
(** Упражнение: Perfect Numbers — классификация чисел.

    Классифицировать число по сумме его делителей (кроме самого числа):

    - Perfect: сумма делителей = число (например, 6: 1+2+3=6)
    - Abundant: сумма делителей > число (например, 12: 1+2+3+4+6=16>12)
    - Deficient: сумма делителей < число (например, 8: 1+2+4=7<8)

    Валидация: n должно быть > 0, иначе Error.

    Примеры:
    {[
      classify 6 = Ok Perfect      (* 1+2+3 = 6 *)
      classify 12 = Ok Abundant    (* 1+2+3+4+6 = 16 > 12 *)
      classify 7 = Ok Deficient    (* 1 = 1 < 7 *)
      classify 0 = Error "число должно быть положительным"
    ]}

    Подсказки:
    1. Напишите функцию divisors n для нахождения делителей
    2. Проверяйте делители от 1 до n/2
    3. Суммируйте делители и сравните с n

    Время: ~25 минут *)
type classification = Perfect | Abundant | Deficient

let classify (_n : int) : (classification, string) result = failwith "todo"

(* Сложное *)
(** Упражнение: Allergies — аллергии по битовой маске.

    Аллергии кодируются битовой маской:
    - Eggs:         1   (2^0)
    - Peanuts:      2   (2^1)
    - Shellfish:    4   (2^2)
    - Strawberries: 8   (2^3)
    - Tomatoes:     16  (2^4)
    - Chocolate:    32  (2^5)
    - Pollen:       64  (2^6)
    - Cats:         128 (2^7)

    Примеры:
    {[
      allergies 0 = []
      allergies 1 = [Eggs]
      allergies 5 = [Eggs; Shellfish]    (* 1 + 4 = 0b101 *)
      allergies 255 = [все 8 аллергенов] (* все биты установлены *)
      allergies 256 = []                  (* overflow, игнорируем *)

      is_allergic_to Eggs 1 = true
      is_allergic_to Peanuts 1 = false
      is_allergic_to Eggs 5 = true
    ]}

    Подсказки:
    1. Используйте битовые операции: land (AND)
    2. Проверка бита: (score land bit_value) <> 0
    3. allergies: проверьте все 8 аллергенов, соберите в список
    4. is_allergic_to: проверьте конкретный бит

    Связанные концепции:
    - Битовые операции: land, lor, lsl, lsr
    - Enumeration через powers of 2
    - Flags и битовые маски

    Время: ~30 минут *)
type allergen =
  | Eggs | Peanuts | Shellfish | Strawberries
  | Tomatoes | Chocolate | Pollen | Cats

let allergies (_score : int) : allergen list = failwith "todo"
let is_allergic_to (_allergen : allergen) (_score : int) : bool = failwith "todo"
