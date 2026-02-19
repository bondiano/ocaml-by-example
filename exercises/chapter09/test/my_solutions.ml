(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1 (Лёгкое): PositiveInt --- smart constructor
    для строго положительных целых чисел.

    make n -> Ok, если n > 0, иначе Error "число должно быть положительным".
    add складывает два значения.
    to_string --- строковое представление. *)
module PositiveInt : sig
  type t
  val make : int -> (t, string) result
  val value : t -> int
  val add : t -> t -> t
  val to_string : t -> string
end = struct
  type t = int
  let make _n = failwith "todo"
  let value _t = failwith "todo"
  let add _a _b = failwith "todo"
  let to_string _t = failwith "todo"
end

(** Упражнение 2 (Среднее): Email --- smart constructor для email-адресов.

    Правила валидации:
    - строка не пуста -> Error "email не может быть пустым"
    - содержит '@' -> Error "email должен содержать @"
    - домен содержит '.' -> Error "некорректный домен"
    - иначе Ok *)
module Email : sig
  type t
  val make : string -> (t, string) result
  val to_string : t -> string
end = struct
  type t = string
  let make _s = failwith "todo"
  let to_string _t = failwith "todo"
end

(** Упражнение 3 (Среднее): NonEmptyList --- список,
    гарантированно содержащий хотя бы один элемент.

    head и tail не могут завершиться ошибкой.
    Внутреннее представление: 'a * 'a list. *)
module NonEmptyList : sig
  type 'a t
  val make : 'a list -> ('a t, string) result
  val singleton : 'a -> 'a t
  val head : 'a t -> 'a
  val tail : 'a t -> 'a list
  val to_list : 'a t -> 'a list
  val length : 'a t -> int
  val map : ('a -> 'b) -> 'a t -> 'b t
end = struct
  type 'a t = 'a * 'a list
  let make _lst = failwith "todo"
  let singleton _x = failwith "todo"
  let head (_x, _xs) = failwith "todo"
  let tail (_x, _xs) = failwith "todo"
  let to_list (_x, _xs) = failwith "todo"
  let length (_x, _xs) = failwith "todo"
  let map _f (_x, _xs) = failwith "todo"
end

(** Упражнение 4 (Среднее): TrafficLight --- светофор
    как конечный автомат с phantom types.

    Порядок: Red -> Green -> Yellow -> Red -> ...
    Нарушение порядка --- ошибка компиляции. *)
module TrafficLight : sig
  type red
  type yellow
  type green

  type 'state light

  val start : red light
  val red_to_green : red light -> green light
  val green_to_yellow : green light -> yellow light
  val yellow_to_red : yellow light -> red light
  val show : 'state light -> string
end = struct
  type red
  type yellow
  type green

  type 'state light = { color : string }

  let start = failwith "todo"
  let red_to_green _l = failwith "todo"
  let green_to_yellow _l = failwith "todo"
  let yellow_to_red _l = failwith "todo"
  let show _l = failwith "todo"
end

(** Упражнение 5 (Сложное): Form --- строитель формы
    с накоплением ошибок.

    field name raw_value parser --- валидирует одно поле.
    map2 f a b --- комбинирует два поля, накапливая ошибки.
    map3 f a b c --- комбинирует три поля.
    run --- возвращает Ok результат или Error список пар (имя_поля, ошибка). *)
module Form : sig
  type 'a validated
  val field : string -> string -> (string -> ('a, string) result) -> 'a validated
  val map2 : ('a -> 'b -> 'c) -> 'a validated -> 'b validated -> 'c validated
  val map3 : ('a -> 'b -> 'c -> 'd) ->
    'a validated -> 'b validated -> 'c validated -> 'd validated
  val run : 'a validated -> ('a, (string * string) list) result
end = struct
  type 'a validated = ('a, (string * string) list) result
  let field _name _raw _parser = failwith "todo"
  let map2 _f _a _b = failwith "todo"
  let map3 _f _a _b _c = failwith "todo"
  let run v = v
end

(** Упражнение 6 (Сложное): FileHandle --- API для работы с «файлами»,
    где чтение и запись возможны только для открытых дескрипторов.

    Использует phantom types: opened / closed.
    read и write принимают только opened handle.
    close возвращает closed handle. *)
module FileHandle : sig
  type opened
  type closed

  type 'state handle

  val open_file : string -> opened handle
  val read : opened handle -> string
  val write : opened handle -> string -> opened handle
  val close : opened handle -> closed handle
  val name : 'state handle -> string
end = struct
  type opened
  type closed

  type 'state handle = { name : string; content : string }

  let open_file _path = failwith "todo"
  let read _h = failwith "todo"
  let write _h _data = failwith "todo"
  let close _h = failwith "todo"
  let name _h = failwith "todo"
end
