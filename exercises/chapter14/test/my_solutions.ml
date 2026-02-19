(** Здесь вы можете писать свои решения упражнений. *)

(* ====================================================================== *)
(*  JSON-упражнения (1–4)                                                  *)
(* ====================================================================== *)

(** Упражнение 1: Ручная конвертация product -> JSON. *)
type product = {
  title    : string;
  price    : float;
  in_stock : bool;
}

let product_to_json (_p : product) : Yojson.Safe.t =
  failwith "todo"

(** Упражнение 2: Ручная конвертация JSON -> product. *)
let product_of_json (_json : Yojson.Safe.t) : (product, string) result =
  failwith "todo"

(** Упражнение 3: Преобразование списка JSON-объектов — извлечь имена. *)
let extract_names (_json : Yojson.Safe.t) : string list =
  failwith "todo"

(** Упражнение 4: ppx — тип с автоматической сериализацией. *)
type config = {
  host  : string;
  port  : int;
  debug : bool;
} [@@deriving yojson]

(* ====================================================================== *)
(*  FFI-упражнения (5–7)                                                   *)
(*                                                                         *)
(*  Откройте lib/stubs.c и прочитайте реализации C-функций перед           *)
(*  тем, как писать привязки. Каждый комментарий в stubs.c объясняет,      *)
(*  какие макросы и функции OCaml C API использованы.                      *)
(* ====================================================================== *)

(** Упражнение 5. Напишите [external]-привязку к [caml_count_char].

    Прочитайте сигнатуру в lib/stubs.c:
      CAMLprim value caml_count_char(value str, value ch)

    Аргументы и возвращаемое значение:
      str  — OCaml string  → C: String_val(str) : const char*
      ch   — OCaml char    → C: (char)Int_val(ch)  (char хранится как int)
      возвращает int        ← C: Val_int(count)

    Задача: замените определение ниже на [external]-объявление с правильным
    именем C-функции и типом OCaml.

    Подсказка: external count_char : ??? -> ??? -> ??? = "???" *)
let count_char (_s : string) (_c : char) : int =
  failwith "todo"

(** Упражнение 6. Привязка к [caml_str_repeat] и безопасная обёртка.

    Прочитайте сигнатуру в lib/stubs.c:
      CAMLprim value caml_str_repeat(value str, value n)

    В C-реализации:
      n <= 0  → возвращает пустую строку (уже обрабатывается в C)
      n > 0   → выделяет строку через caml_alloc_string

    Шаг A: замените [raw_str_repeat] ниже на [external]-объявление.
    Шаг Б: реализуйте [str_repeat] как безопасную обёртку: если [n < 0],
           возвращайте [""], иначе вызывайте [raw_str_repeat]. *)

let raw_str_repeat (_s : string) (_n : int) : string =
  failwith "todo"
(* Шаг A: замените строку выше на:
   external raw_str_repeat : string -> int -> string = "caml_str_repeat" *)

let str_repeat (_s : string) (_n : int) : string =
  failwith "todo"

(** Упражнение 7. Привязка к [caml_sum_int_array] и функция [mean].

    Прочитайте сигнатуру в lib/stubs.c:
      CAMLprim value caml_sum_int_array(value arr)

    В C-реализации:
      Wosize_val(arr) — длина массива
      Field(arr, i)   — i-й элемент (тегированный int)

    Шаг A: замените [raw_sum_int_array] на [external]-объявление.
    Шаг Б: реализуйте [mean : int array -> float option].
           Для пустого массива верните [None], иначе [Some (сумма / длина)].

    Подсказка: [Array.length arr] даёт длину на стороне OCaml. *)

let raw_sum_int_array (_arr : int array) : int =
  failwith "todo"
(* Шаг A: замените строку выше на:
   external raw_sum_int_array : int array -> int = "caml_sum_int_array" *)

let mean (_arr : int array) : float option =
  failwith "todo"
