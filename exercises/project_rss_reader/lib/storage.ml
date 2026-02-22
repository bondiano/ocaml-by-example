(** In-memory хранилище фидов и постов. *)

type t = {
  mutable feeds : (string * Feed_parser.feed) list;  (* url, feed *)
  mutable all_posts : Feed_parser.post list;
}

let create () : t = { feeds = []; all_posts = [] }

let add_feed (storage : t) ~(url : string) (feed : Feed_parser.feed)
    : (unit, string) result =
  (* TODO: добавить фид
     1. Проверить что URL не существует
     2. Добавить в feeds
     3. Добавить посты в all_posts (с дедупликацией) *)
  if List.mem_assoc url storage.feeds then
    Error "URL already exists"
  else begin
    storage.feeds <- (url, feed) :: storage.feeds;
    storage.all_posts <- feed.posts @ storage.all_posts;
    Ok ()
  end

let get_feeds (storage : t) : (string * Feed_parser.feed) list =
  storage.feeds

let get_recent_posts (storage : t) ~(limit : int) : Feed_parser.post list =
  (* TODO: вернуть последние N постов, отсортированных по дате *)
  List.filteri (fun i _ -> i < limit) storage.all_posts
