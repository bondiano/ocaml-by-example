# Парсер-комбинаторы и GADT

## Цели главы

Два инструмента.

**Парсер-комбинаторы** — построение парсеров из маленьких композируемых частей. Библиотека **Angstrom**: базовые парсеры, комбинаторы (`*>`, `<*`, `>>=`, `<|>`, `fix`), JSON-подобный парсер.

**GADT (Generalized Algebraic Data Types)** — конструкторы уточняют возвращаемый тип. Типобезопасный вычислитель выражений: `Add (Bool true, Int 3)` не компилируется.

## Подготовка проекта

Код этой главы находится в `exercises/chapter17`. Для этой главы потребуется библиотека Angstrom:

```text
$ opam install angstrom
$ cd exercises/chapter17
$ dune build
```

## Что такое парсер-комбинаторы?

**Парсер** — функция, которая принимает входную строку и возвращает структурированный результат (или ошибку). **Комбинатор** — функция, которая объединяет парсеры в более сложные парсеры.

Вместо того чтобы писать парсер целиком (как в yacc/bison), мы **собираем** его из маленьких кирпичиков:

```
парсер_числа + парсер_оператора + парсер_числа = парсер_выражения
```

Преимущества:

- **Композируемость** — маленькие парсеры легко объединять.
- **Типобезопасность** — каждый парсер возвращает конкретный тип.
- **Тестируемость** — каждый парсер можно тестировать отдельно.
- **Читаемость** — код парсера похож на грамматику.

```admonish tip title="Для Python/TS-разработчиков"
В Python для парсинга обычно используют регулярные выражения или библиотеки вроде `pyparsing` и `lark`. В TypeScript — `parsimmon` или `chevrotain`. Парсер-комбинаторы в OCaml (Angstrom) — это другой подход: вы описываете грамматику как композицию маленьких функций, каждая из которых парсит одну часть. Это похоже на то, как если бы в Python вы писали `parse_number | parse_string | parse_array` — но с полной типобезопасностью и без регулярных выражений.
```

## Библиотека Angstrom

[Angstrom](https://github.com/inhabitedtype/angstrom) — быстрая библиотека парсер-комбинаторов для OCaml, оптимизированная для работы с потоками данных. Она аналогична `attoparsec` в Haskell.

Основной тип: `'a Angstrom.t` — парсер, возвращающий значение типа `'a`.

### Базовые парсеры

```ocaml
open Angstrom

(* Парсер одного символа *)
let _ = char 'a'         (* char Angstrom.t — ожидает ровно 'a' *)

(* Парсер строки *)
let _ = string "hello"   (* string Angstrom.t — ожидает "hello" *)

(* Парсер символов по предикату *)
let _ = take_while (fun c -> c >= '0' && c <= '9')   (* string t — 0+ символов *)
let _ = take_while1 (fun c -> c >= '0' && c <= '9')  (* string t — 1+ символов *)

(* Пропустить символы по предикату *)
let _ = skip_while (fun c -> c = ' ')  (* unit t — пропускает пробелы *)
```

### Запуск парсера

```ocaml
let result = Angstrom.parse_string ~consume:All (string "hello") "hello"
(* result : (string, string) result = Ok "hello" *)

let error = Angstrom.parse_string ~consume:All (string "hello") "world"
(* error : (string, string) result = Error ": string" *)
```

Параметр `~consume:All` требует, чтобы парсер прочитал всю строку. Если останутся непрочитанные символы — это ошибка.

## Комбинаторы

### Последовательность: `*>` и `<*`

```ocaml
(* *> — выполнить оба парсера, вернуть результат правого *)
let p1 = string "hello" *> string " world"
(* parse_string ~consume:All p1 "hello world" = Ok " world" *)

(* <* — выполнить оба парсера, вернуть результат левого *)
let p2 = string "hello" <* string " world"
(* parse_string ~consume:All p2 "hello world" = Ok "hello" *)
```

Это позволяет удобно пропускать незначимые части (пробелы, скобки, разделители).

### Привязка: `>>=` (bind)

```ocaml
(* >>= — передать результат первого парсера во второй *)
let digit_then_letter =
  take_while1 (fun c -> c >= '0' && c <= '9') >>= fun digits ->
  take_while1 (fun c -> c >= 'a' && c <= 'z') >>= fun letters ->
  return (digits, letters)
(* parse_string ~consume:All digit_then_letter "123abc" = Ok ("123", "abc") *)
```

`return v` — парсер, который ничего не потребляет и возвращает `v`.

### Отображение: `>>|` (map)

```ocaml
(* >>| — преобразовать результат парсера *)
let integer =
  take_while1 (fun c -> c >= '0' && c <= '9') >>| int_of_string
(* int Angstrom.t *)
```

### Альтернатива: `<|>`

```ocaml
(* <|> — попробовать первый парсер, при неудаче — второй *)
let bool_parser =
  string "true" *> return true
  <|> string "false" *> return false
```

**Важно:** `<|>` откатывается (backtrack) только если первый парсер не потребил ни одного символа. Для полного отката используйте `Angstrom.option` или планируйте грамматику без неоднозначностей.

### Повторение: `many`, `many1`, `sep_by`

```ocaml
(* many — 0 или более повторений *)
let digits = many (satisfy (fun c -> c >= '0' && c <= '9'))
(* char list Angstrom.t *)

(* many1 — 1 или более повторений *)
let digits1 = many1 (satisfy (fun c -> c >= '0' && c <= '9'))

(* sep_by — элементы, разделённые разделителем *)
let csv_ints = sep_by (char ',') integer
(* int list Angstrom.t *)

(* sep_by1 — как sep_by, но минимум 1 элемент *)
let csv_ints1 = sep_by1 (char ',') integer
```

### Комбинирование: `lift2`

```ocaml
(* lift2 — применить функцию к результатам двух парсеров *)
let pair = lift2 (fun a b -> (a, b)) integer (char ',' *> integer)
(* (int * int) Angstrom.t *)
(* parse_string ~consume:All pair "42,17" = Ok (42, 17) *)
```

### Рекурсивные парсеры: `fix`

Для рекурсивных грамматик (вложенные скобки, деревья) нужен `fix`:

```ocaml
(* fix — создать рекурсивный парсер *)
let nested_parens =
  fix (fun self ->
    char '(' *> self <* char ')'   (* вложенные скобки *)
    <|> string ""                   (* или пустая строка *)
  )
```

`fix` передаёт парсеру ссылку на самого себя, позволяя определять рекурсивные грамматики без `let rec` (который не работает с типом `'a t`).

## Пример: JSON-подобный парсер

Соберём всё вместе и построим парсер для подмножества JSON:

```ocaml
type json_value =
  | JNull
  | JBool of bool
  | JInt of int
  | JString of string
  | JArray of json_value list
  | JObject of (string * json_value) list
```

### Вспомогательные парсеры

```ocaml
let ws = skip_while (fun c -> c = ' ' || c = '\t' || c = '\n' || c = '\r')

let integer =
  ws *> take_while1 (fun c -> c >= '0' && c <= '9') >>| int_of_string

let quoted_string =
  ws *> char '"' *> take_while (fun c -> c <> '"') <* char '"'

let boolean =
  ws *> (string "true" *> return true <|> string "false" *> return false)
```

### Рекурсивный парсер

```ocaml
let json_value =
  fix (fun json_value ->
    let jnull = ws *> string "null" *> return JNull in
    let jbool = boolean >>| fun b -> JBool b in
    let jint = integer >>| fun n -> JInt n in
    let jstring = quoted_string >>| fun s -> JString s in
    let jarray =
      ws *> char '[' *>
      sep_by (ws *> char ',') json_value
      <* ws <* char ']' >>| fun items -> JArray items
    in
    let key_value =
      lift2 (fun k v -> (k, v))
        (quoted_string <* ws <* char ':')
        json_value
    in
    let jobject =
      ws *> char '{' *>
      sep_by (ws *> char ',') key_value
      <* ws <* char '}' >>| fun pairs -> JObject pairs
    in
    jnull <|> jbool <|> jint <|> jstring <|> jarray <|> jobject
  )

let parse_json str =
  parse_string ~consume:All (ws *> json_value <* ws) str
```

Обратите внимание на использование `fix`: `json_value` ссылается на самого себя внутри `jarray` и `jobject`, что позволяет парсить вложенные структуры.

```text
# parse_json "{\"name\": \"OCaml\", \"version\": 5}";;
- : ... = Ok (JObject [("name", JString "OCaml"); ("version", JInt 5)])

# parse_json "[1, 2, [3, 4]]";;
- : ... = Ok (JArray [JInt 1; JInt 2; JArray [JInt 3; JInt 4]])
```

## GADT: обобщённые алгебраические типы данных

### Обычные ADT: проблема

Представим, что мы хотим описать арифметические и логические выражения одним типом:

```ocaml
(* Обычный variant — НЕ типобезопасный *)
type expr =
  | Int of int
  | Bool of bool
  | Add of expr * expr
  | Eq of expr * expr
  | If of expr * expr * expr
```

Проблема: ничего не мешает написать `Add (Bool true, Int 3)` — это скомпилируется, но не имеет смысла. Функция `eval` вынуждена обрабатывать ошибки в рантайме:

```ocaml
let rec eval = function
  | Int n -> `Int n
  | Bool b -> `Bool b
  | Add (a, b) ->
    (match eval a, eval b with
     | `Int x, `Int y -> `Int (x + y)
     | _ -> failwith "type error")  (* ошибка в рантайме! *)
  | ...
```

### GADT: решение

GADT позволяют конструкторам **уточнять** тип возвращаемого значения:

```ocaml
type _ expr =
  | Int : int -> int expr
  | Bool : bool -> bool expr
  | Add : int expr * int expr -> int expr
  | Mul : int expr * int expr -> int expr
  | Eq : int expr * int expr -> bool expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr
```

Обратите внимание на синтаксис:

- `type _ expr` — параметр типа не именован, он определяется конструкторами.
- `Int : int -> int expr` — конструктор `Int` принимает `int` и возвращает `int expr`.
- `Bool : bool -> bool expr` — конструктор `Bool` возвращает `bool expr`.
- `Add : int expr * int expr -> int expr` — складывать можно **только** `int expr`.
- `Eq : int expr * int expr -> bool expr` — сравнение возвращает `bool expr`.
- `If : bool expr * 'a expr * 'a expr -> 'a expr` — условие должно быть `bool`, ветки — одного типа.

Теперь `Add (Bool true, Int 3)` — **ошибка компиляции**, а не рантайма!

```admonish tip title="Для Python/TS-разработчиков"
GADT не имеют прямого аналога в Python или TypeScript. Ближайшее приближение в TypeScript — conditional types и discriminated unions, но они не дают такого уровня гарантий. В Python `@overload` из `typing` позволяет различать возвращаемые типы по аргументам, но проверка остаётся на уровне статического анализатора (mypy), а не компилятора. В OCaml GADT гарантируют на этапе компиляции, что `Add` может принимать только `int expr`, а не `bool expr` — такой вид ошибок физически невозможен.
```

```text
# Add (Bool true, Int 3);;
Error: This expression has type bool expr but an expression of type int expr was expected
```

### Типобезопасное вычисление

```ocaml
let rec eval : type a. a expr -> a = function
  | Int n -> n
  | Bool b -> b
  | Add (a, b) -> eval a + eval b
  | Mul (a, b) -> eval a * eval b
  | Eq (a, b) -> eval a = eval b
  | If (cond, then_, else_) ->
    if eval cond then eval then_ else eval else_
```

Аннотация `type a. a expr -> a` — это **локально абстрактный тип**. Она говорит компилятору, что `a` — параметр типа, который определяется при сопоставлении:

- Если `expr` — это `Int n`, то `a = int`, и мы возвращаем `int`.
- Если `expr` — это `Bool b`, то `a = bool`, и мы возвращаем `bool`.

Без `type a.` компилятор не сможет вывести тип: ведь `eval` возвращает разные типы в разных ветках!

### Показать выражение

```ocaml
let rec show_expr : type a. a expr -> string = function
  | Int n -> string_of_int n
  | Bool b -> string_of_bool b
  | Add (a, b) -> Printf.sprintf "(%s + %s)" (show_expr a) (show_expr b)
  | Mul (a, b) -> Printf.sprintf "(%s * %s)" (show_expr a) (show_expr b)
  | Eq (a, b) -> Printf.sprintf "(%s = %s)" (show_expr a) (show_expr b)
  | If (c, t, e) ->
    Printf.sprintf "(if %s then %s else %s)" (show_expr c) (show_expr t) (show_expr e)
```

Аннотация `type a. a expr -> string` здесь обязательна по той же причине, что и в `eval`: функция работает с выражениями разных типов (и `int expr`, и `bool expr`), поэтому компилятор должен знать, что `a` — локальный параметр, а не фиксированный тип. Результат всегда `string`, независимо от `a`.

### Пример использования

```text
# eval (Add (Int 3, Mul (Int 4, Int 5)));;
- : int = 23

# eval (If (Eq (Int 1, Int 1), Int 42, Int 0));;
- : int = 42

# eval (If (Bool true, Add (Int 1, Int 2), Int 0));;
- : int = 3

# show_expr (Add (Int 3, Int 4));;
- : string = "(3 + 4)"
```

Обратите внимание на типы в выводе utop: `eval (Add ...)` возвращает `int`, `eval (If ...)` тоже возвращает `int` (тип ветвей), а `show_expr` всегда возвращает `string`. Компилятор знает конкретный возвращаемый тип каждого вызова — это и есть ключевое преимущество GADT перед обычными ADT.

### Сложный пример: типобезопасная формула

```ocaml
(* если (2 + 3) = 5 то 6 * 7 иначе 0 *)
let formula = If (Eq (Add (Int 2, Int 3), Int 5), Mul (Int 6, Int 7), Int 0)
(* formula : int expr *)

let _ = eval formula
(* - : int = 42 *)
```

Этот GADT гарантирует на этапе компиляции:

- Нельзя сложить `Bool` и `Int`.
- Условие в `If` всегда `bool expr`.
- Обе ветки `If` имеют одинаковый тип.
- `eval` не может упасть с ошибкой типа.

## Комбинирование: парсер + GADT

Можно распарсить строку в `json_value`, а затем преобразовать в GADT-выражение:

```ocaml
(* Простой пример: парсим арифметическое выражение *)
(* "2 + 3 * 4" -> Add (Int 2, Mul (Int 3, Int 4)) *)
(* Результат вычисления: 14 *)
```

Для полноценного парсера арифметики нужно учитывать приоритет операторов. Angstrom позволяет это сделать через рекурсивные парсеры с `fix`:

```ocaml
let arith_parser =
  let integer = ws *> take_while1 (fun c -> c >= '0' && c <= '9') >>| int_of_string in
  let parens p = ws *> char '(' *> p <* ws <* char ')' in
  fix (fun expr ->
    let atom = integer <|> parens expr in
    let rec chain_mul acc =
      (ws *> char '*' *> atom >>= fun r -> chain_mul (acc * r))
      <|> return acc
    in
    let mul_expr = atom >>= chain_mul in
    let rec chain_add acc =
      (ws *> char '+' *> mul_expr >>= fun r -> chain_add (acc + r))
      <|> return acc
    in
    mul_expr >>= chain_add
  )
```

Этот парсер правильно обрабатывает приоритет: `2 + 3 * 4` вычисляется как `2 + (3 * 4) = 14`. Ключевой приём — двухуровневая рекурсия: `mul_expr` обрабатывает умножение (высший приоритет), а `chain_add` собирает слагаемые из результатов умножений.

## Сравнение с Haskell

| Аспект | OCaml | Haskell |
|--------|-------|---------|
| Парсер-комбинаторы | Angstrom | Parsec, Megaparsec, Attoparsec |
| GADT синтаксис | `type _ t = C : int -> int t` | `data T a where C :: Int -> T Int` |
| Локальные типы | `type a. a t -> a` | Неявно через `GADTs` расширение |
| Free-монады | Не идиоматичны | Популярны для DSL |
| Effect handlers | Встроены в OCaml 5 | Через библиотеки (polysemy, fused-effects) |

В Haskell для типобезопасных DSL часто используют **Free-монады** — обобщённый способ построить интерпретируемое AST. В OCaml GADT + обработчики эффектов (effect handlers) решают аналогичные задачи более прямолинейно.

Angstrom по API очень похож на `attoparsec` из Haskell — те же комбинаторы (`*>`, `<*`, `<|>`, `>>=`, `>>|`), тот же подход. Если вы знакомы с Haskell-парсерами, Angstrom покажется знакомым.

```admonish info title="Real World OCaml"
Подробнее о парсинге и работе с данными — в главе [Parsing with OCamllex and Menhir](https://dev.realworldocaml.org/parsing-with-ocamllex-and-menhir.html) книги Real World OCaml. Там рассматривается другой подход — генераторы парсеров (Menhir), который лучше подходит для сложных грамматик с полноценной обработкой ошибок.
```

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Лёгкое)** Напишите парсер списка целых чисел в формате `[1, 2, 3]`.

    ```ocaml
    val int_list_parser : int list Angstrom.t
    ```

    Парсер должен обрабатывать пробелы между элементами и пустой список `[]`.

    *Подсказка:* используйте `sep_by`, `char`, `take_while1` и `>>|`.

2. **(Лёгкое)** Напишите парсер пар ключ-значение в формате `key=value`.

    ```ocaml
    val key_value_parser : (string * string) Angstrom.t
    ```

    Ключ — последовательность символов до `=`, значение — до конца строки (или пробела).

    *Подсказка:* используйте `take_while1` и `lift2`.

3. **(Среднее)** Расширьте GADT выражений операторами `Not` (логическое отрицание) и `Gt` (больше).

    ```ocaml
    type _ extended_expr =
      | Int : int -> int extended_expr
      | Bool : bool -> bool extended_expr
      | Add : int extended_expr * int extended_expr -> int extended_expr
      | Not : bool extended_expr -> bool extended_expr
      | Gt : int extended_expr * int extended_expr -> bool extended_expr

    val eval_extended : 'a extended_expr -> 'a
    ```

    *Подсказка:* используйте `type a.` аннотацию для полиморфной рекурсии.

4. **(Сложное)** Напишите парсер арифметических выражений с операторами `+` и `*` и скобками, учитывающий приоритет операторов (`*` связывает сильнее `+`).

    ```ocaml
    val arith_parser : int Angstrom.t
    ```

    Примеры:
    - `"42"` -> `42`
    - `"1 + 2"` -> `3`
    - `"3 * 4"` -> `12`
    - `"2 + 3 * 4"` -> `14` (не `20`)
    - `"(2 + 3) * 4"` -> `20`

    *Подсказка:* используйте `fix` для рекурсии, разделите на уровни: `atom` (число или скобки), `mul_expr` (умножения), `add_expr` (сложения).

## Заключение

Angstrom: `char`, `string`, `take_while`, `take_while1`, `*>`, `<*`, `>>=`, `>>|`, `<|>`, `many`, `sep_by`, `fix`, `lift2`. JSON-подобный парсер строится из этих кирпичиков.

GADT: аннотация `type a. a expr -> a` для полиморфной рекурсии. Ошибки типов в выражениях становятся ошибками компиляции.

В следующей главе — веб-приложение с Dream.
