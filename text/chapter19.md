# ppx и метапрограммирование

## Цели главы

В этой главе мы изучим **метапрограммирование** в OCaml --- написание программ, которые генерируют другие программы на этапе компиляции:

- **Метапрограммирование** --- что это, зачем, три подхода (Lisp, Rust, OCaml).
- **Конвейер компиляции** --- где работает ppx, extension points и derivers.
- **ppx_deriving** --- автоматическая генерация `show`, `eq`, `ord`.
- **Написание своего ppx** --- знакомство с ppxlib.
- **Сравнение с Haskell** --- Template Haskell, GHC Generics.

## Подготовка проекта

Код этой главы находится в `exercises/chapter19`. Для этой главы потребуются библиотеки ppxlib и ppx_deriving:

```text
$ opam install ppxlib ppx_deriving
$ cd exercises/chapter19
$ dune build
```

Убедитесь, что в файле `dune` вашей библиотеки указан препроцессор:

```text
(library
 (name chapter18)
 (preprocess (pps ppx_deriving.show ppx_deriving.eq ppx_deriving.ord)))
```

## Что такое метапрограммирование?

**Метапрограммирование** --- написание кода, который генерирует другой код. Вместо того чтобы вручную писать повторяющиеся функции для каждого типа, мы просим компилятор сгенерировать их автоматически. Это сокращает шаблонный код, гарантирует согласованность и безопасность --- при изменении типа сгенерированные функции обновляются автоматически.

Рассмотрим типичную ситуацию. У нас есть тип:

```ocaml
type color = Red | Green | Blue
```

Нам нужна функция `show_color : color -> string`. Можно написать её вручную:

```ocaml
let show_color = function
  | Red -> "Red"
  | Green -> "Green"
  | Blue -> "Blue"
```

Но если типов много, или они часто меняются, ручное поддержание таких функций становится утомительным и подверженным ошибкам. Метапрограммирование решает эту проблему --- компилятор генерирует `show_color` автоматически из определения типа.

## Три подхода к метапрограммированию

Разные языки предлагают разные подходы к метапрограммированию. Рассмотрим три наиболее характерных: Lisp, Rust и OCaml.

### Lisp: код как данные

Lisp занимает уникальное место в истории метапрограммирования. Благодаря свойству **гомоиконичности** (homoiconicity) --- код и данные имеют одинаковое представление (S-выражения) --- макросы в Lisp работают с кодом как с обычными списками.

```lisp
;; Определяем макрос when --- условие без else
(defmacro when (condition &body body)
  `(if ,condition (progn ,@body)))

;; Использование:
(when (> x 0)
  (print "positive")
  (inc counter))

;; Раскрывается в:
(if (> x 0) (progn (print "positive") (inc counter)))
```

Здесь обратная кавычка `` ` `` создаёт шаблон, запятая `,` подставляет значение, а `,@` --- сплайсит список. Макросы Lisp --- это обычные функции, которые получают код в виде списков и возвращают новый код.

Преимущества Lisp-макросов --- максимальная гибкость: любая трансформация кода возможна. Недостаток --- отсутствие типизации: макрос может сгенерировать синтаксически некорректный код, и ошибка обнаружится только при раскрытии.

### Rust: макросы на токенах

Rust предлагает два вида макросов: **декларативные** (`macro_rules!`) и **процедурные** (proc macros).

Декларативные макросы работают через сопоставление с образцом на токенах:

```rust
macro_rules! vec_of {
    ($($x:expr),*) => { vec![$($x),*] };
}
// vec_of![1, 2, 3] раскрывается в vec![1, 2, 3]
```

Процедурные макросы --- полноценные Rust-программы, которые трансформируют поток токенов. Самый распространённый вид --- `#[derive(...)]`:

```rust
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
struct Point {
    x: f64,
    y: f64,
}
```

Под капотом `#[derive(Debug)]` вызывает процедурный макрос, который получает `TokenStream` и возвращает новый `TokenStream`. Крейты `syn` и `quote` предоставляют инструменты для парсинга и генерации. Модель Rust: **токены -> токены** --- менее гибко, чем Lisp, но безопаснее.

### OCaml ppx: трансформация AST

OCaml использует подход **AST -> AST**. Вместо работы с текстом или токенами ppx-расширения оперируют **абстрактным синтаксическим деревом** --- типизированным представлением программы после парсинга.

```ocaml
type point = { x : float; y : float }
[@@deriving show, eq]

(* Генерирует:
   val pp_point : Format.formatter -> point -> unit
   val show_point : point -> string
   val equal_point : point -> point -> bool
*)
```

Ключевое отличие от Rust: ppx работает с **типизированным AST**, а не с потоком токенов. Каждый узел дерева имеет определённый тип (`expression`, `pattern`, `structure_item`), что гарантирует синтаксическую корректность сгенерированного кода.

```admonish tip title="Для Python/TS-разработчиков"
В Python метапрограммирование реализовано через декораторы, метаклассы и `ast`-модуль. В TypeScript --- через декораторы (experimental) и трансформеры компилятора. Подход OCaml (ppx) ближе всего к TypeScript-трансформерам: это плагин, который модифицирует AST на этапе компиляции. Но в отличие от TypeScript, ppx в OCaml --- стабильная и широко используемая технология: `[@@deriving yojson]` автоматически генерирует функции сериализации, как `@dataclass` + `dataclasses_json` в Python, но на этапе компиляции и с полной типобезопасностью.
```

### Сравнительная таблица

| Аспект | Lisp | Rust | OCaml ppx |
|--------|------|------|-----------|
| Модель | Код = данные (S-expr) | Токены -> Токены | AST -> AST |
| Типизация входа | Нет | Частичная (TokenStream) | Полная (Parsetree) |
| Типизация выхода | Нет | Частичная | Полная |
| Гигиена | Нет (ручная) | Частичная | Полная (через ppxlib) |
| Гибкость | Максимальная | Высокая | Средняя |
| Безопасность | Минимальная | Средняя | Максимальная |
| Отладка | `macroexpand` | `cargo expand` | `dune describe pp` |
| Экосистема | defmacro | syn/quote | ppxlib |

Каждый подход --- компромисс между гибкостью и безопасностью. Lisp даёт максимальную свободу, Rust балансирует удобство и типобезопасность, OCaml выбирает максимальную структурированность.

## Конвейер компиляции OCaml

Чтобы понять, где работает ppx, рассмотрим конвейер компиляции OCaml:

```text
исходный код (.ml)
      |
      v
  [Парсинг] ---> нетипизированный AST (Parsetree)
      |
      v
  [ppx rewrite] ---> трансформированный AST     <-- ppx работает здесь
      |
      v
  [Типизация] ---> типизированный AST (Typedtree)
      |
      v
  [Lambda] ---> промежуточное представление
      |
      v
  [Кодогенерация] ---> байткод (.cmo) или нативный код (.cmx)
```

Важный момент: ppx работает **после** парсинга, но **до** типизации. ppx видит структуру кода (выражения, типы, модули), но **не видит** информацию о типах. Сгенерированные определения проверяются типизатором как обычный код.

## Два вида ppx

В OCaml существуют два основных вида ppx-трансформаций: **extension points** и **derivers**.

### Extension points (точки расширения)

Extension points --- это места в коде, помеченные специальным синтаксисом `[%name ...]` или `let%name`, куда ppx вставляет сгенерированный код:

```ocaml
(* Выражение: [%name payload] *)
let greeting = [%string "Hello, %{name}!"]

(* let-привязка: let%name *)
let%lwt data = Lwt_io.read_line stdin in
Lwt_io.printl data

(* Атрибут модульного уровня: [%%name] *)
[%%import "config.h"]
```

Extension points --- это «дырки» в коде, которые ppx заполняет сгенерированным выражением. Популярные примеры: `ppx_expect` (`let%expect_test`), `ppx_lwt` (`let%lwt`), `ppx_string` (`[%string ...]`).

### Derivers (деривации)

Derivers генерируют **новые функции** на основе определения типа. Они активируются аннотацией `[@@deriving name]`:

```ocaml
type color = Red | Green | Blue
[@@deriving show, eq, ord]

(* Генерирует:
   val pp_color : Format.formatter -> color -> unit
   val show_color : color -> string
   val equal_color : color -> color -> bool
   val compare_color : color -> color -> int
*)
```

Derivers --- самый распространённый вид ppx. Аннотация `[@@deriving ...]` применяется к **определению типа**. PPX-расширение получает AST типа, анализирует его структуру (variant, record, alias) и генерирует соответствующие функции.

```admonish tip title="Для Python/TS-разработчиков"
`[@@deriving show, eq]` похож на `@dataclass` в Python, который автоматически генерирует `__repr__`, `__eq__`, `__hash__`. В TypeScript ближайший аналог --- библиотеки вроде `class-transformer` / `class-validator`, которые генерируют код через декораторы. Разница: в Python/TypeScript генерация происходит в рантайме (через метаклассы или рефлексию), а в OCaml --- на этапе компиляции. Это означает нулевой runtime overhead и гарантированную корректность сгенерированного кода.
```

## Использование ppx_deriving

Библиотека **ppx_deriving** предоставляет набор стандартных дериваций. Рассмотрим каждую подробно.

### [@@deriving show]

Генерирует функции для преобразования значений в строку:

```ocaml
type direction = North | South | East | West
[@@deriving show]

(* Генерирует:
   val pp_direction : Format.formatter -> direction -> unit
   val show_direction : direction -> string
*)
```

Использование:

```text
# show_direction North;;
- : string = "Direction.North"

# show_direction South;;
- : string = "Direction.South"
```

Для записей:

```ocaml
type person = {
  name : string;
  age : int;
  active : bool;
} [@@deriving show]

(* val show_person : person -> string *)
```

```text
# show_person { name = "Alice"; age = 30; active = true };;
- : string = "{ name = \"Alice\"; age = 30; active = true }"
```

Для параметризованных типов `show_tree` принимает дополнительный аргумент --- функцию для отображения элемента типа `'a`.

### [@@deriving eq]

Генерирует структурное равенство:

```ocaml
type color = Red | Green | Blue
[@@deriving eq]

(* val equal_color : color -> color -> bool *)
```

```text
# equal_color Red Red;;
- : bool = true

# equal_color Red Blue;;
- : bool = false
```

Для записей сравниваются все поля. Важно: `equal` использует **структурное** равенство, а не физическое (`==`). Для `float` используется `Float.equal`, что корректно обрабатывает `nan` (в отличие от `=`).

### [@@deriving ord]

Генерирует функцию сравнения, совместимую с `compare`:

```ocaml
type priority = Low | Medium | High | Critical
[@@deriving ord]

(* val compare_priority : priority -> priority -> int *)
```

```text
# compare_priority Low High;;
- : int = -1

# compare_priority High Low;;
- : int = 1

# compare_priority Medium Medium;;
- : int = 0
```

Для вариантных типов порядок определяется **порядком объявления** конструкторов. `Low` < `Medium` < `High` < `Critical`, потому что именно в таком порядке они объявлены.

Для записей поля сравниваются **лексикографически** --- сначала первое поле, при равенстве --- второе и т.д.

### Комбинирование дериваций

Деривации можно комбинировать в одной аннотации:

```ocaml
type suit = Spades | Hearts | Diamonds | Clubs
[@@deriving show, eq, ord]

(* Генерирует все три набора функций:
   val show_suit : suit -> string
   val equal_suit : suit -> suit -> bool
   val compare_suit : suit -> suit -> int
*)
```

### Припоминание: [@@deriving yojson]

В главе 14 мы уже использовали ppx для автоматической JSON-сериализации --- `[@@deriving yojson]` генерирует `t_to_yojson` и `t_of_yojson`. Это тот же механизм, только вместо `show` или `eq` генерируются функции сериализации.

### Настройка dune

Для каждого ppx-плагина нужно указать его в секции `preprocess` файла `dune`:

```text
(library
 (name mylib)
 (libraries yojson)
 (preprocess (pps ppx_deriving.show ppx_deriving.eq ppx_deriving.ord
                  ppx_deriving_yojson)))
```

Каждый плагин указывается отдельно. `ppx_deriving.show`, `ppx_deriving.eq`, `ppx_deriving.ord` --- модули библиотеки ppx_deriving. `ppx_deriving_yojson` --- отдельный пакет.

## Исследование AST

Иногда полезно увидеть, что именно ppx сгенерировал. Команда `dune describe pp lib/mymodule.ml` выводит файл **после** всех ppx-трансформаций. Например, для кода:

```ocaml
type color = Red | Green | Blue
[@@deriving show, eq]
```

Команда `dune describe pp` покажет примерно следующее:

```ocaml
type color = Red | Green | Blue

let pp_color fmt = function
  | Red -> Format.fprintf fmt "Red"
  | Green -> Format.fprintf fmt "Green"
  | Blue -> Format.fprintf fmt "Blue"

let show_color x = Format.asprintf "%a" pp_color x

let equal_color a b =
  match a, b with
  | Red, Red -> true
  | Green, Green -> true
  | Blue, Blue -> true
  | _ -> false
```

Это помогает понять, какой код генерируется, и отладить проблемы с ppx.

## Пишем свой ppx с ppxlib

Рассмотрим, как создать свой ppx-деривер. Мы напишем `[@@deriving describe]`, который для вариантного типа генерирует функцию `describe : t -> string`, возвращающую имя конструктора в нижнем регистре.

### Цель

```ocaml
type http_method = Get | Post | Put | Delete
[@@deriving describe]

(* Должно сгенерировать:
   val describe_http_method : http_method -> string
   describe_http_method Get = "get"
   describe_http_method Post = "post"
   describe_http_method Put = "put"
   describe_http_method Delete = "delete"
*)
```

### Структура ppx-плагина

PPX-плагин --- это отдельная библиотека, которая регистрируется через `ppxlib`:

```ocaml
open Ppxlib

let generate_case ~loc constructor_name =
  let pattern = Ast_builder.Default.ppat_construct ~loc
    (Located.mk ~loc (Lident constructor_name)) None in
  let description = String.lowercase_ascii constructor_name in
  let expression = Ast_builder.Default.estring ~loc description in
  Ast_builder.Default.case ~lhs:pattern ~guard:None ~rhs:expression

let impl_generator ~ctxt:_ ((_rec_flag, type_decls) : rec_flag * type_declaration list)
  : structure =
  List.concat_map (fun (td : type_declaration) ->
    match td.ptype_kind with
    | Ptype_variant constructors ->
      let loc = td.ptype_loc in
      let func_name = "describe_" ^ td.ptype_name.txt in
      let cases = List.map (fun (c : constructor_declaration) ->
        generate_case ~loc c.pcd_name.txt) constructors in
      let body = Ast_builder.Default.pexp_function ~loc cases in
      let binding = Ast_builder.Default.value_binding ~loc
        ~pat:(Ast_builder.Default.ppat_var ~loc (Located.mk ~loc func_name))
        ~expr:body in
      [Ast_builder.Default.pstr_value ~loc Nonrecursive [binding]]
    | _ ->
      Location.raise_errorf ~loc:td.ptype_loc
        "deriving describe: only variant types are supported"
  ) type_decls

let () =
  ignore (Deriving.add "describe"
    ~str_type_decl:(Deriving.Generator.V2.make_noarg impl_generator))
```

Ключевые элементы: `Ast_builder.Default` строит AST-узлы безопасно (каждый требует `~loc`), `ppat_construct` создаёт паттерн конструктора, `estring` --- строковый литерал, `pexp_function` --- match-выражение. `Deriving.add` регистрирует имя деривера, генератор анализирует `Ptype_variant` и возвращает новые определения.

### Настройка dune для ppx

PPX-библиотека требует особой настройки:

```text
(library
 (name ppx_describe)
 (kind ppx_rewriter)
 (libraries ppxlib))
```

Ключевой момент --- `(kind ppx_rewriter)`, который говорит dune, что это не обычная библиотека, а ppx-расширение.

Написание своего ppx --- продвинутая тема. На практике большинство задач решается стандартными деривациями из ppx_deriving. Но понимание механизма помогает разобраться, что происходит «под капотом».

## Сравнение с Haskell

В Haskell метапрограммирование реализовано через несколько механизмов.

### Template Haskell

**Template Haskell (TH)** --- макросистема Haskell, аналогичная ppx. TH работает с типизированным AST Haskell и может генерировать произвольный код:

```haskell
-- Haskell: Template Haskell
{-# LANGUAGE TemplateHaskell #-}

-- Генерация экземпляра Show вручную через TH
$(deriveShow ''MyType)

-- Квазицитирование
myExpr = [| 1 + 2 |]   -- -> Exp
myType = [t| Int -> Bool |]  -- -> Type
```

### GHC Generics и deriving via

**GHC Generics** --- другой подход: вместо генерации кода создаётся обобщённое представление типа. Библиотеки (aeson, binary) работают с этим представлением через `deriving Generic`. **DerivingVia** позволяет заимствовать реализации через newtype-обёртки: `deriving (Show, Eq) via String`.

### Сравнительная таблица

| Аспект | OCaml ppx | Haskell TH | GHC Generics | Haskell deriving |
|--------|-----------|------------|--------------|------------------|
| Когда работает | Компиляция (после парсинга) | Компиляция (splice) | Рантайм (обобщение) | Компиляция |
| Модель | AST -> AST | AST -> AST | Тип -> Generic Rep | Встроен в GHC |
| Видит типы | Нет | Да | Да | Да |
| Произвольный код | Да | Да | Нет (ограничен Generic) | Нет |
| Простота использования | `[@@deriving ...]` | `$(...)` или `deriving` | `deriving Generic` | `deriving (Show)` |
| Отладка | `dune describe pp` | `-ddump-splices` | Нет (обычный код) | `-ddump-deriv` |
| Расширяемость | Любой может написать ppx | Любой может написать TH | Любой (класс Default) | Только встроенные + TH |

Главное отличие: ppx OCaml работает **до** типизации, а Template Haskell --- **после**. Это делает TH более мощным, но и более сложным. На практике оба подхода решают одни и те же задачи --- большинство разработчиков используют `deriving` для стандартных функций.

```admonish info title="Real World OCaml"
Подробнее о ppx и метапрограммировании --- в главе [Data Serialization with S-Expressions](https://dev.realworldocaml.org/data-serialization.html) книги Real World OCaml, где подробно рассматривается `ppx_sexp_conv` от Jane Street и принципы работы ppx-расширений.
```

## Популярные ppx-расширения

Помимо ppx_deriving, экосистема предоставляет множество полезных ppx: `ppx_sexp_conv` (S-expression от Jane Street), `ppx_compare` и `ppx_hash` (сравнение и хеширование), `ppx_expect` и `ppx_inline_test` (тестирование), `ppx_let` (монадический синтаксис `let%bind`, `let%map`), `ppx_string` (интерполяция строк). Jane Street активно использует ppx в своей кодовой базе и является одним из крупнейших контрибьюторов в экосистему ppxlib.

## Ограничения ppx

PPX --- мощный инструмент, но у него есть ограничения:

- **Нет доступа к типам** --- ppx работает до типизации и не знает, какой тип имеет выражение.
- **Усложнение отладки** --- ошибки указывают на сгенерированный код, а не на аннотацию. Используйте `dune describe pp`.
- **Время компиляции** --- каждое ppx-расширение добавляет проход по AST.
- **Непрозрачность** --- без `dune describe pp` непонятно, какой код генерируется.
- **Привязка к версии AST** --- при обновлении компилятора может измениться AST (ppxlib абстрагирует эту проблему).

Рекомендация: используйте стандартные деривации (`show`, `eq`, `ord`, `yojson`), пишите собственные ppx только при реальной необходимости.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Лёгкое)** Определите тип `color` с конструкторами `Red`, `Green`, `Blue`, `Yellow` и аннотацией `[@@deriving show, eq, ord]`. Реализуйте функцию `all_colors`, которая возвращает список всех цветов, и функцию `color_to_hex`, которая возвращает hex-код цвета:

    ```ocaml
    type color = Red | Green | Blue | Yellow
    [@@deriving show, eq, ord]

    val all_colors : color list
    (* [Red; Green; Blue; Yellow] *)

    val color_to_hex : color -> string
    (* Red -> "#FF0000", Green -> "#00FF00", Blue -> "#0000FF", Yellow -> "#FFFF00" *)
    ```

    Используйте `show_color` (сгенерированную ppx) для проверки: `show_color Red` должна вернуть строку с именем конструктора.

2. **(Среднее)** Определите тип записи `student` с полями `name : string`, `grade : int`, `active : bool` и аннотацией `[@@deriving eq]`. Реализуйте функцию `dedup_students`, которая удаляет дубликаты из списка студентов, используя сгенерированную `equal_student`:

    ```ocaml
    type student = { name : string; grade : int; active : bool }
    [@@deriving eq]

    val dedup_students : student list -> student list
    ```

    *Подсказка:* используйте `List.fold_left` и `List.exists` с `equal_student`.

3. **(Среднее)** Определите типы `suit` (Spades, Hearts, Diamonds, Clubs) и `rank` (Two ... Ace) с `[@@deriving show]`. Реализуйте функцию `make_card_name`, которая принимает `suit` и `rank` и возвращает строку вида `"Ace of Spades"`, используя сгенерированные `show_suit` и `show_rank`:

    ```ocaml
    type suit = Spades | Hearts | Diamonds | Clubs
    [@@deriving show]

    type rank = Two | Three | Four | Five | Six | Seven
              | Eight | Nine | Ten | Jack | Queen | King | Ace
    [@@deriving show]

    val make_card_name : suit -> rank -> string
    (* make_card_name Spades Ace = "Ace of Spades" *)
    ```

    *Подсказка:* `show_suit` и `show_rank` могут содержать префикс модуля. Используйте функции для извлечения нужной части строки, или определите свои вспомогательные функции.

4. **(Сложное)** Определите тип `suit` (Spades, Hearts, Diamonds, Clubs) с `[@@deriving eq, ord]`. Вручную (без ppx) реализуйте функции `all_suits` и `next_suit`, имитируя то, что мог бы сгенерировать ppx-деривер:

    ```ocaml
    val all_suits : suit list
    (* [Spades; Hearts; Diamonds; Clubs] *)

    val next_suit : suit -> suit option
    (* next_suit Spades = Some Hearts,
       next_suit Hearts = Some Diamonds,
       next_suit Diamonds = Some Clubs,
       next_suit Clubs = None *)
    ```

    Реализуйте также `suit_to_symbol`:

    ```ocaml
    val suit_to_symbol : suit -> string
    (* Spades -> "\xe2\x99\xa0", Hearts -> "\xe2\x99\xa5",
       Diamonds -> "\xe2\x99\xa6", Clubs -> "\xe2\x99\xa3" *)
    ```

    Используйте `equal_suit` (сгенерированную ppx) для проверки: убедитесь, что `next_suit` корректно «оборачивается» --- `next_suit Clubs = None`.

## Заключение

В этой главе мы:

- Разобрали три подхода к метапрограммированию: макросы Lisp (код = данные), макросы Rust (токены -> токены), ppx OCaml (AST -> AST).
- Изучили конвейер компиляции OCaml и место ppx в нём --- после парсинга, но до типизации.
- Познакомились с двумя видами ppx: extension points (`[%name ...]`) и derivers (`[@@deriving ...]`).
- Освоили ppx_deriving: `show` для строкового представления, `eq` для равенства, `ord` для сравнения.
- Научились исследовать сгенерированный код через `dune describe pp`.
- Рассмотрели архитектуру собственного ppx-деривера на основе ppxlib.
- Сравнили ppx с Template Haskell и GHC Generics.

Метапрограммирование --- мощный инструмент для борьбы с шаблонным кодом. PPX-система OCaml предлагает безопасный подход: трансформации работают с типизированным AST, что исключает генерацию синтаксически некорректного кода. На практике `[@@deriving ...]` покрывает подавляющее большинство потребностей --- от отладочного вывода до JSON-сериализации.

В следующей главе мы изучим оптимизации --- как сделать OCaml-код максимально быстрым.
