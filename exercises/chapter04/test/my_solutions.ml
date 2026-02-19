(** Здесь вы можете писать свои решения упражнений. *)

open Chapter04.Shapes

let area (_shape : shape) : float =
  failwith "todo"

let scale (_factor : float) (_shape : shape) : shape =
  failwith "todo"

let shape_text (_shape : shape) : string option =
  failwith "todo"

let safe_head (_lst : 'a list) : 'a option =
  failwith "todo"

(** Упражнение: Bob — определить ответ Боба на высказывание. *)
let bob (_input : string) : string = failwith "todo"

(** Упражнение: Triangle — классификация треугольника. *)
type triangle = Equilateral | Isosceles | Scalene

let classify_triangle (_a : float) (_b : float) (_c : float)
    : (triangle, string) result = failwith "todo"

(** Упражнение: Raindrops — преобразование числа по делимости. *)
let raindrops (_n : int) : string = failwith "todo"

(** Упражнение: Perfect Numbers — классификация числа. *)
type classification = Perfect | Abundant | Deficient

let classify (_n : int) : (classification, string) result = failwith "todo"

(** Упражнение: Allergies — определение аллергий по баллу. *)
type allergen =
  | Eggs | Peanuts | Shellfish | Strawberries
  | Tomatoes | Chocolate | Pollen | Cats

let allergies (_score : int) : allergen list = failwith "todo"
let is_allergic_to (_allergen : allergen) (_score : int) : bool = failwith "todo"
