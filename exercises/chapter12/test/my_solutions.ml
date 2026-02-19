(** Здесь вы можете писать свои решения упражнений. *)

(** Упражнение 1: Параллельное вычисление двух чисел Фибоначчи. *)
let parallel_fib (_n : int) (_m : int) : int =
  failwith "todo"

(** Упражнение 2: Конкурентный map. *)
let concurrent_map : ('a -> 'b) -> 'a list -> 'b list =
  fun _f _lst -> failwith "todo"

(** Упражнение 3: Producer-consumer с суммированием. *)
let produce_consume (_n : int) : int =
  failwith "todo"

(** Упражнение 4: Гонка --- результат первой завершившейся функции. *)
let race (_tasks : (unit -> 'a) list) : 'a =
  failwith "todo"
