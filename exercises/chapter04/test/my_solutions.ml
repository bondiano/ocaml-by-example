(** Здесь вы можете писать свои решения упражнений. *)

open Chapter04.Address_book

(* Среднее *)
(** Упражнение: Find Entry by Street — найти запись по улице.

    Дано: название улицы и адресная книга.
    Найти: первую запись (entry) где entry.address.street совпадает.

    Тип entry определён в lib/address_book.ml:
    {[
      type entry = {
        first_name : string;
        last_name : string;
        address : address;
      }

      type address = {
        street : string;
        city : string;
        zip : string;
      }
    ]}

    Подсказки:
    1. Используйте List.find_opt для поиска
    2. Анонимная функция: fun entry -> entry.address.street = street_name
    3. Pipe operator |> упрощает код

    Время: ~10 минут *)
let find_entry_by_street (_street_name : string) (_book : entry list) : entry option =
  failwith "todo"

(* Лёгкое *)
(** Упражнение: Entry Exists — проверить существование записи.

    Дано: имя, фамилия (именованные аргументы) и адресная книга.
    Проверить: есть ли запись с такими именем и фамилией.

    Примеры:
    {[
      entry_exists ~first_name:"John" ~last_name:"Doe" book
    ]}

    Подсказки:
    1. Используйте List.exists
    2. Проверяйте оба поля: first_name И last_name

    Время: ~8 минут *)
let entry_exists ~first_name:(_first_name : string) ~last_name:(_last_name : string)
    (_book : entry list) : bool =
  failwith "todo"

(* Среднее *)
(** Упражнение: Remove Duplicates — удалить дубликаты по имени.

    Дано: адресная книга с возможными дубликатами.
    Удалить: записи с одинаковыми first_name И last_name (сохранить первое вхождение).

    Примеры:
    Если есть две записи John Doe — сохранить первую, удалить вторую.

    Подсказки:
    1. Используйте List.fold_left с accumulator
    2. Для каждой записи проверяйте: уже есть в accumulator?
    3. Напишите helper функцию same_name для сравнения
    4. Если нет в acc — добавьте: acc @ [entry]

    Время: ~20 минут *)
let remove_duplicates (_book : entry list) : entry list =
  failwith "todo"

(* Лёгкое *)
(** Упражнение: Two-Fer — опциональный аргумент.

    "Two-fer" (two for one) — фраза "One for X, one for me."

    Дано: опциональное имя (по умолчанию "you").
    Вернуть: строку "One for {name}, one for me."

    Примеры:
    {[
      two_fer () = "One for you, one for me."
      two_fer ~name:"Alice" () = "One for Alice, one for me."
    ]}

    Подсказка: используйте Printf.sprintf для форматирования
    Время: ~5 минут *)
let two_fer ?(name = "you") () : string = ignore name; failwith "todo"

(** Упражнение: Grade School — управление списком учеников.

    Реализуйте систему учёта учеников по классам (grades).
    Тип: список пар (номер_класса, список_учеников).

    Требования:
    1. empty — пустая школа
    2. add student grade school — добавить ученика в класс
    3. grade n school — получить всех учеников класса n
    4. sorted school — отсортировать (классы по возрастанию, ученики по алфавиту) *)
module GradeSchool = struct
  type t = (int * string list) list

  (* Лёгкое *)
  (** Пустая школа — просто пустой список.
      Время: ~1 минута *)
  let empty : t = []

  (* Среднее *)
  (** Добавить ученика в класс.

      Если класс уже существует — добавить к списку учеников.
      Если класса нет — создать новый класс с одним учеником.

      Подсказки:
      1. List.assoc_opt grade school — найти учеников класса grade
      2. Если Some students — добавить: students @ [student]
      3. Если None — создать: [student]
      4. Обновить школу: удалить старый класс, добавить новый
         (grade, new_students) :: List.filter (g <> grade) school

      Время: ~15 минут *)
  let add (_student : string) (_grade : int) (_school : t) : t = failwith "todo"

  (* Лёгкое *)
  (** Получить всех учеников класса.

      Подсказка: используйте List.assoc_opt, вернуть [] если класса нет
      Время: ~5 минут *)
  let grade (_grade : int) (_school : t) : string list = failwith "todo"

  (* Среднее *)
  (** Отсортировать школу.

      Требования:
      1. Классы в порядке возрастания номеров (1, 2, 3...)
      2. Ученики в каждом классе по алфавиту

      Подсказки:
      1. List.map для сортировки учеников: (g, List.sort String.compare ss)
      2. List.sort для сортировки классов: fun (a,_) (b,_) -> Int.compare a b

      Время: ~15 минут *)
  let sorted (_school : t) : (int * string list) list = failwith "todo"
end
