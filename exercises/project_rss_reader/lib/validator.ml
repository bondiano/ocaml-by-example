(** URL валидатор для RSS фидов. *)

type url = string

type validation_error =
  | Empty_url
  | Invalid_scheme  (* только http/https *)
  | Invalid_format
  | Already_exists

(** Валидировать URL.
    Ok url если валиден, Error причина если нет. *)
let validate_url (url : url) ~(existing : url list) : (url, validation_error) result =
  (* TODO: реализуйте валидацию
     Подсказки:
     1. Проверьте что URL не пустой
     2. Используйте Uri.of_string для парсинга
     3. Проверьте схему через Uri.scheme
     4. Проверьте наличие в existing через List.mem *)
  ignore existing;
  if url = "" then Error Empty_url
  else Ok url  (* TODO: добавьте остальные проверки *)

(** Показать ошибку в читаемом виде *)
let show_error : validation_error -> string = function
  | Empty_url -> "URL не может быть пустым"
  | Invalid_scheme -> "URL должен начинаться с http:// или https://"
  | Invalid_format -> "Некорректный формат URL"
  | Already_exists -> "Этот URL уже добавлен"
