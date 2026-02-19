(** Адресная книга

    Типы и функции для работы с адресной книгой. *)

(** Адрес: улица, город, регион. *)
type address = {
  street : string;
  city   : string;
  state  : string;
}

(** Запись адресной книги: имя, фамилия и адрес. *)
type entry = {
  first_name : string;
  last_name  : string;
  address    : address;
}

(** Адресная книга — список записей. *)
type address_book = entry list

(** Отформатировать адрес в строку. *)
let show_address addr =
  addr.street ^ ", " ^ addr.city ^ ", " ^ addr.state

(** Отформатировать запись адресной книги в строку. *)
let show_entry entry =
  entry.last_name ^ ", " ^ entry.first_name ^ ": "
  ^ show_address entry.address

(** Пустая адресная книга. *)
let empty_book : address_book = []

(** Добавить запись в адресную книгу. *)
let insert_entry entry book = entry :: book

(** Найти запись по имени и фамилии. *)
let find_entry first last book =
  book |> List.find_opt (fun entry ->
    entry.first_name = first && entry.last_name = last
  )
