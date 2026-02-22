(** RSS feed parser. *)

type post = {
  title : string;
  link : string;
  description : string option;
  pub_date : string option;
  guid : string option;
}

type feed = {
  title : string;
  link : string;
  description : string;
  posts : post list;
}

(** Парсить RSS XML строку.
    Возвращает Ok feed или Error с описанием ошибки парсинга. *)
let parse (xml_string : string) : (feed, string) result =
  (* TODO: реализуйте парсер используя ezxmlm
     Пример структуры RSS 2.0:
     <rss version="2.0">
       <channel>
         <title>Feed Title</title>
         <link>http://example.com</link>
         <description>Feed description</description>
         <item>
           <title>Post title</title>
           <link>http://example.com/post</link>
           <description>Post description</description>
           <guid>unique-id</guid>
         </item>
       </channel>
     </rss>
  *)
  ignore xml_string;
  Error "TODO: Implement RSS parser"
