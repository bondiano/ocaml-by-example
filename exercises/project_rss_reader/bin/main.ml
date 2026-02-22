open Cmdliner
open Rss_reader

let storage = Storage.create ()

(* Команда: add <url> *)
let add_cmd =
  let add url =
    (* TODO: реализуйте добавление фида
       См. GUIDE.md шаг 5 для деталей *)
    Printf.printf "TODO: Добавить фид %s\n" url;
    let existing = Storage.get_feeds storage |> List.map fst in
    match Validator.validate_url url ~existing with
    | Error e ->
        Printf.eprintf "Ошибка: %s\n" (Validator.show_error e);
        exit 1
    | Ok _url ->
        Printf.printf "URL валиден. TODO: загрузить и распарсить\n"
  in
  let url_arg = Arg.(required & pos 0 (some string) None & info []) in
  let doc = "Добавить RSS фид" in
  Cmd.v (Cmd.info "add" ~doc) Term.(const add $ url_arg)

(* Команда: list *)
let list_cmd =
  let list_feeds () =
    let feeds = Storage.get_feeds storage in
    if feeds = [] then
      Printf.printf "Нет добавленных фидов\n"
    else begin
      Printf.printf "Добавленные фиды:\n";
      List.iter (fun (url, (feed : Feed_parser.feed)) ->
        Printf.printf "  - %s (%s)\n" feed.title url
      ) feeds
    end
  in
  let doc = "Показать все фиды" in
  Cmd.v (Cmd.info "list" ~doc) Term.(const list_feeds $ const ())

(* Команда: posts *)
let posts_cmd =
  let show_posts () =
    let posts = Storage.get_recent_posts storage ~limit:10 in
    if posts = [] then
      Printf.printf "Нет постов\n"
    else begin
      Printf.printf "Последние посты:\n";
      List.iter (fun (post : Feed_parser.post) ->
        Printf.printf "  - %s (%s)\n" post.title post.link
      ) posts
    end
  in
  let doc = "Показать последние посты" in
  Cmd.v (Cmd.info "posts" ~doc) Term.(const show_posts $ const ())

let () =
  let doc = "RSS Reader — консольный RSS агрегатор" in
  let default_cmd = Cmd.group (Cmd.info "rss-reader" ~doc)
    [add_cmd; list_cmd; posts_cmd]
  in
  exit (Cmd.eval default_cmd)
