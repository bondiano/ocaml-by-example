(** Простое хранилище записей. *)

(** Запись. *)
type record = {
  id : int;
  name : string;
  value : string;
}

(** Хранилище записей. *)
type store = {
  mutable entries : record list;
  mutable next_id : int;
}

(** Создать пустое хранилище. *)
let create_store () =
  { entries = []; next_id = 1 }

(** Добавить запись. Возвращает созданную запись. *)
let add_record store ~name ~value =
  let record = { id = store.next_id; name; value } in
  store.entries <- record :: store.entries;
  store.next_id <- store.next_id + 1;
  record

(** Найти запись по id. *)
let find_record store id =
  List.find_opt (fun r -> r.id = id) store.entries

(** Удалить запись по id. *)
let remove_record store id =
  store.entries <- List.filter (fun r -> r.id <> id) store.entries

(** Все записи в порядке добавления. *)
let all_records store =
  List.rev store.entries

(** Количество записей. *)
let count store =
  List.length store.entries

(** Отформатировать запись в строку. *)
let show_record r =
  Printf.sprintf "[%d] %s = %s" r.id r.name r.value

(** === Сборщик мусора === *)

(** Получить статистику GC. *)
let gc_stats () =
  let open Gc in
  let s = stat () in
  Printf.sprintf
    "Minor collections: %d, Major collections: %d, Compactions: %d"
    s.minor_collections s.major_collections s.compactions

(** Простой кеш на weak references. *)
module WeakCache = struct
  type 'a t = {
    table : 'a Weak.t;
    size : int;
  }

  let create size = { table = Weak.create size; size }

  let get cache i =
    if i >= 0 && i < cache.size then Weak.get cache.table i
    else None

  let set cache i value =
    if i >= 0 && i < cache.size then
      Weak.set cache.table i (Some value)

  let clear cache =
    for i = 0 to cache.size - 1 do
      Weak.set cache.table i None
    done
end
