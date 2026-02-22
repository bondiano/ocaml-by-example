(** Здесь вы можете писать свои решения упражнений. *)

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

(* ===== Advanced Phantom Types ===== *)

(* Сложное *)
(** Упражнение 6: FileHandle — типобезопасная работа с «файлами».

    Создать API для работы с файлами, где read и write доступны
    только для открытых файлов (проверка на уровне типов).

    Phantom types:
    - type opened / type closed
    - type 'state handle — параметр указывает открыт ли файл

    Гарантии типов:
    - read и write принимают только opened handle
    - close принимает opened handle, возвращает closed handle
    - name работает с любым handle

    Попытка read/write на closed handle — ошибка компиляции.

    Операции:
    - open_file: создать opened handle
    - read: прочитать содержимое (только opened)
    - write: записать данные (только opened, возвращает opened)
    - close: закрыть файл (opened → closed)
    - name: получить имя файла (любой state)

    Примеры:
    {[
      let h = FileHandle.open_file "test.txt"
      FileHandle.name h = "test.txt"

      let h = FileHandle.write h "hello"
      FileHandle.read h = "hello"

      let h_closed = FileHandle.close h
      (* Ошибка компиляции: *)
      (* FileHandle.read h_closed *)
      (* FileHandle.write h_closed "data" *)

      (* Но name работает: *)
      FileHandle.name h_closed = "test.txt"
    ]}

    Подсказки:
    1. type opened, closed — phantom types
    2. type 'state handle = { name : string; content : string }
    3. open_file path = { name = path; content = "" } : opened handle
    4. read h = h.content (только opened)
    5. write h data = { h with content = h.content ^ data } : opened handle
    6. close (_ : opened handle) = ... : closed handle
       (просто меняем тип, содержимое то же)
    7. name h = h.name (полиморфная функция для любого 'state)

    Связанные темы: Phantom types, resource safety, session types, type-safe APIs
    Время: ~30 минут *)
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
