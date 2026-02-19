(** Референсные решения — не подсматривайте, пока не попробуете сами! *)

open Chapter04.Address_book

(** Найти запись по названию улицы. *)
let find_entry_by_street street_name book =
  book |> List.find_opt (fun entry ->
    entry.address.street = street_name
  )

(** Проверить, есть ли запись с данным именем и фамилией.
    Использует именованные аргументы. *)
let entry_exists ~first_name ~last_name book =
  book |> List.exists (fun entry ->
    entry.first_name = first_name && entry.last_name = last_name
  )

(** Удалить дубликаты по имени и фамилии (сохраняет первое вхождение). *)
let remove_duplicates book =
  let same_name e1 e2 =
    e1.first_name = e2.first_name && e1.last_name = e2.last_name
  in
  List.fold_left
    (fun acc entry ->
      if List.exists (same_name entry) acc then acc
      else acc @ [entry])
    [] book

(** Two-Fer. *)
let two_fer ?(name = "you") () =
  Printf.sprintf "One for %s, one for me." name

(** Grade School. *)
module GradeSchool = struct
  type t = (int * string list) list

  let empty = []

  let add student grade school =
    let students =
      match List.assoc_opt grade school with
      | Some ss -> ss @ [student]
      | None -> [student]
    in
    (grade, students) :: List.filter (fun (g, _) -> g <> grade) school

  let grade g school =
    match List.assoc_opt g school with
    | Some ss -> ss
    | None -> []

  let sorted school =
    school
    |> List.map (fun (g, ss) -> (g, List.sort String.compare ss))
    |> List.sort (fun (a, _) (b, _) -> Int.compare a b)
end
