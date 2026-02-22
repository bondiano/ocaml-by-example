(** Здесь вы можете писать свои решения упражнений. *)

open Chapter07.Hashable

(* ===== Базовые модули ===== *)

(* Среднее *)
(** Упражнение 1: IntSet — множество целых чисел.

    Реализуйте простое множество на основе отсортированного списка.
    Сигнатура Set_intf определена в lib/hashable.ml.

    Требуется реализовать:
    - add: добавить элемент (если его нет)
    - mem: проверить наличие элемента

    Подсказки:
    1. Список всегда отсортирован по возрастанию
    2. add: вставляйте элемент в правильную позицию
    3. mem: используйте бинарный поиск или линейный scan
    4. Избегайте дубликатов: если элемент уже есть — не добавляйте

    Время: ~15 минут *)
module IntSet : Set_intf with type elt = int = struct
  type elt = int
  type t = int list

  let empty = []

  let add _x _s = failwith "todo"

  let mem _x _s = failwith "todo"

  let elements s = s

  let size s = List.length s
end

(* Среднее *)
(** Упражнение 2: MakeSet — функтор для параметризованного множества.

    Создайте функтор который принимает модуль Comparable
    и создаёт множество для этого типа.

    Это обобщённая версия IntSet — работает для любых типов с compare.

    Подсказки:
    1. Аналогично IntSet, но используйте Elt.compare вместо Int.compare
    2. add: вставляйте в правильную позицию по Elt.compare
    3. mem: ищите с помощью Elt.compare

    Связанные темы: Functors, parametric modules, polymorphism
    Время: ~20 минут *)
module MakeSet (Elt : Comparable) : Set_intf with type elt = Elt.t = struct
  type elt = Elt.t
  type t = Elt.t list

  let empty = []

  let add _x _s = failwith "todo"

  let mem _x _s = failwith "todo"

  let elements s = s

  let size s = List.length s
end

(* ===== First-class modules ===== *)

(* Среднее *)
(** Упражнение 3: max_element — максимум через first-class module.

    Найти максимальный элемент в списке используя модуль Comparable
    как first-class value.

    Примеры:
    {[
      max_element (module Int) [1; 5; 3] = Some 5
      max_element (module Int) [] = None
    ]}

    Подсказки:
    1. Pattern match на [] -> None | x :: xs -> ...
    2. List.fold_left для поиска максимума
    3. Используйте C.compare для сравнения: C.compare a b > 0 означает a > b

    Связанные темы: First-class modules, GADT syntax
    Время: ~12 минут *)
let max_element (type a) (module C : Comparable with type t = a) (_lst : a list)
    : a option =
  ignore (module C : Comparable with type t = a);
  failwith "todo"

(* ===== Расширение модулей ===== *)

(* Среднее *)
(** Упражнение 4: ExtendedIntSet — множество с дополнительными операциями.

    Расширьте IntSet новыми операциями:
    - union: объединение множеств
    - inter: пересечение множеств

    Используйте include для переиспользования IntSet.

    Подсказки:
    1. union: объедините два отсортированных списка (merge)
    2. inter: найдите общие элементы
    3. Используйте рекурсию с двумя указателями

    Пример union:
    {[
      merge [1; 3; 5] [2; 3; 4] = [1; 2; 3; 4; 5]
    ]}

    Пример inter:
    {[
      inter [1; 3; 5] [2; 3; 4] = [3]
    ]}

    Время: ~18 минут *)
module ExtendedIntSet : sig
  include Set_intf with type elt = int
  val union : t -> t -> t
  val inter : t -> t -> t
end = struct
  include IntSet

  let union _s1 _s2 = failwith "todo"

  let inter _s1 _s2 = failwith "todo"
end

(* ===== Алгебраические структуры ===== *)

(* Лёгкое *)
(** Упражнение 5: First Semigroup — "первый элемент побеждает".

    Реализуйте полугруппу где combine всегда возвращает первый аргумент.

    Примеры:
    {[
      First.combine "hello" "world" = "hello"
      First.combine "a" "b" = "a"
    ]}

    Semigroup — структура с ассоциативной операцией combine.

    Подсказка: просто верните первый аргумент!
    Время: ~8 минут *)
module First : Chapter07.Monoid.Semigroup with type t = string = struct
  type t = string
  let combine _a _b = failwith "todo"
end

(* Среднее *)
(** Упражнение 6: concat_all — свёртка через моноид.

    Объедините все элементы списка используя моноид.

    Моноид = Semigroup + identity element (empty).

    Примеры:
    {[
      module StringMonoid = struct
        type t = string
        let empty = ""
        let combine = (^)
      end

      concat_all (module StringMonoid) ["hello"; " "; "world"]
        = "hello world"
    ]}

    Подсказки:
    1. List.fold_left M.combine M.empty lst
    2. M.empty — начальное значение
    3. M.combine — операция объединения

    Связанные темы: Monoids, fold, first-class modules
    Время: ~15 минут *)
let concat_all (type a) (module M : Chapter07.Monoid.Monoid with type t = a)
    (_lst : a list) : a =
  ignore (module M : Chapter07.Monoid.Monoid with type t = a);
  failwith "todo"

(* ===== Продвинутые функторы ===== *)

(* Сложное *)
(** Упражнение 7: MakeCustomSet — полнофункциональное множество.

    Реализуйте полный набор операций над множеством через функтор.

    Требуется реализовать 9 функций:
    1. add — добавить элемент
    2. mem — проверить наличие
    3. remove — удалить элемент
    4. elements — получить список элементов
    5. size — размер множества
    6. union — объединение
    7. inter — пересечение
    8. diff — разность (элементы из s1, но не из s2)
    9. is_empty — проверка пустоты

    Подсказки:
    1. Используйте отсортированный список как представление
    2. add: вставка с сохранением порядка
    3. remove: фильтрация или рекурсия
    4. union/inter/diff: слияние двух отсортированных списков
    5. Используйте Elt.compare для сравнения элементов

    Пример union (merge двух отсортированных списков):
    {[
      let rec union s1 s2 = match s1, s2 with
        | [], s | s, [] -> s
        | x::xs, y::ys ->
            match Elt.compare x y with
            | 0 -> x :: union xs ys        (* равны — берём один *)
            | n when n < 0 -> x :: union xs s2  (* x < y *)
            | _ -> y :: union s1 ys        (* x > y *)
    ]}

    Связанные темы: Functors, abstract types, set operations
    Время: ~50 минут (все 9 функций) *)
module MakeCustomSet (Elt : ORDERED) : sig
  type t
  type elt = Elt.t
  val empty : t
  val add : elt -> t -> t
  val mem : elt -> t -> bool
  val remove : elt -> t -> t
  val elements : t -> elt list
  val size : t -> int
  val union : t -> t -> t
  val inter : t -> t -> t
  val diff : t -> t -> t
  val is_empty : t -> bool
end = struct
  type elt = Elt.t
  type t = elt list

  let empty = []
  let add _x _s = failwith "todo"
  let mem _x _s = failwith "todo"
  let remove _x _s = failwith "todo"
  let elements s = s
  let size s = List.length s
  let union _s1 _s2 = failwith "todo"
  let inter _s1 _s2 = failwith "todo"
  let diff _s1 _s2 = failwith "todo"
  let is_empty s = s = []
end

(** Примечание: ORDERED определяется выше *)
module type ORDERED = sig
  type t
  val compare : t -> t -> int
end
