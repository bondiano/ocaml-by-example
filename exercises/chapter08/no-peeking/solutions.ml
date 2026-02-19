(** Референсные решения --- не подсматривайте, пока не попробуете сами! *)

open Chapter08.Validation

(** Валидация телефонного номера с накоплением ошибок. *)
let validate_phone phone =
  validate_all [
    non_empty "Телефон";
    digits_only "Телефон";
    min_length "Телефон" 7;
  ] phone

(** Валидация персоны с накоплением ошибок по всем полям. *)
let validate_person first last street city state =
  let errors =
    (match validate_all [non_empty "Имя"] first with
     | Ok _ -> [] | Error es -> es)
    @ (match validate_all [non_empty "Фамилия"] last with
       | Ok _ -> [] | Error es -> es)
    @ (match validate_address street city state with
       | Ok _ -> [] | Error es -> es)
  in
  match errors with
  | [] -> Ok { first_name = first; last_name = last;
               address = { street; city; state } }
  | es -> Error es

(** Применить функцию к каждому элементу, собрав все ошибки. *)
let traverse_result f lst =
  let oks, errs =
    List.fold_left (fun (oks, errs) x ->
      match f x with
      | Ok v -> (v :: oks, errs)
      | Error e -> (oks, e :: errs)
    ) ([], []) lst
  in
  match errs with
  | [] -> Ok (List.rev oks)
  | es -> Error (List.rev es)

(** Конвертация option -> result. *)
let option_to_result ~error = function
  | Some x -> Ok x
  | None -> Error error

(** Конвертация result -> option. *)
let result_to_option = function
  | Ok x -> Some x
  | Error _ -> None

(** ISBN-10 Verifier. *)
let isbn_verifier isbn =
  let digits =
    isbn
    |> String.to_seq
    |> Seq.filter (fun c -> c <> '-')
    |> List.of_seq
  in
  if List.length digits <> 10 then false
  else
    let values =
      List.mapi (fun i c ->
        if i = 9 && c = 'X' then Some 10
        else if c >= '0' && c <= '9' then Some (Char.code c - Char.code '0')
        else None
      ) digits
    in
    if List.exists (fun v -> v = None) values then false
    else
      let sum =
        List.mapi (fun i v -> Option.get v * (10 - i)) values
        |> List.fold_left ( + ) 0
      in
      sum mod 11 = 0

(** Luhn algorithm. *)
let luhn number =
  let digits =
    number
    |> String.to_seq
    |> Seq.filter (fun c -> c <> ' ')
    |> List.of_seq
  in
  if List.length digits <= 1 then false
  else if List.exists (fun c -> c < '0' || c > '9') digits then false
  else
    let nums = List.rev_map (fun c -> Char.code c - Char.code '0') digits in
    let sum =
      List.mapi (fun i d ->
        if i mod 2 = 1 then
          let doubled = d * 2 in
          if doubled > 9 then doubled - 9 else doubled
        else d
      ) nums
      |> List.fold_left ( + ) 0
    in
    sum mod 10 = 0

(** Валидация email с полиморфными вариантами. *)
let validate_email email =
  if String.length email = 0 then Error (`EmptyEmail)
  else if not (String.contains email '@') then Error (`NoAtSign)
  else
    let parts = String.split_on_char '@' email in
    match parts with
    | [_; domain] when String.length domain > 0 && String.contains domain '.' ->
      Ok email
    | [_; domain] -> Error (`InvalidDomain domain)
    | _ -> Error (`NoAtSign)
