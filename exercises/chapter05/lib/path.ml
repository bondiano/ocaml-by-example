(** Виртуальная файловая система. *)

(** Элемент файловой системы: файл или директория. *)
type path =
  | File of string * int
  | Directory of string * path list

(** Имя элемента. *)
let filename = function
  | File (name, _) -> name
  | Directory (name, _) -> name

(** Является ли элемент директорией. *)
let is_directory = function
  | Directory _ -> true
  | File _ -> false

(** Размер файла (None для директорий). *)
let file_size = function
  | File (_, size) -> Some size
  | Directory _ -> None

(** Дочерние элементы (пустой список для файлов). *)
let children = function
  | Directory (_, cs) -> cs
  | File _ -> []

(** Обход в глубину: все элементы дерева. *)
let rec all_paths p =
  p :: List.concat_map all_paths (children p)

(** Тестовое дерево файловой системы. *)
let root =
  Directory ("root", [
    File ("readme.txt", 100);
    Directory ("src", [
      File ("main.ml", 500);
      File ("utils.ml", 300);
      Directory ("lib", [
        File ("parser.ml", 800);
        File ("lexer.ml", 600);
      ]);
    ]);
    Directory ("test", [
      File ("test_main.ml", 400);
    ]);
    File (".gitignore", 50);
  ])
