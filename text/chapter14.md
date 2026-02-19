# FFI и JSON

## Цели главы

Две темы: FFI и JSON.

**FFI (Foreign Function Interface)** — как вызывать C-функции из OCaml через ключевое слово `external`. Зачем это нужно, какие типы соответствуют каким, и где можно получить segfault.

**JSON** — библиотека Yojson и тип `Yojson.Safe.t`. Ручной парсинг через pattern matching и автоматическая сериализация через `ppx_deriving_yojson`.

## Подготовка проекта

Код этой главы находится в `exercises/chapter14`. Соберите проект:

```text
$ cd exercises/chapter14
$ dune build
```

Для этой главы требуются библиотеки `yojson` и `ppx_deriving_yojson`. Убедитесь, что они установлены:

```text
$ opam install yojson ppx_deriving_yojson
```

## Часть 1: FFI — вызов C-функций из OCaml

### Зачем нужен FFI?

OCaml — компилируемый язык с эффективной средой выполнения, но иногда нужно:

- Использовать существующие C-библиотеки (OpenSSL, SQLite, zlib).
- Вызывать системные функции ОС.
- Оптимизировать критичные участки кода на C.
- Интегрироваться с экосистемой других языков через C ABI.

В Haskell для FFI используется ключевое слово `foreign import`:

```haskell
-- Haskell FFI
foreign import ccall "sin" c_sin :: CDouble -> CDouble
```

В OCaml аналогичную роль играет ключевое слово `external`.

```admonish tip title="Для Python/TS-разработчиков"
В Python для вызова C-функций используется `ctypes` или расширения на C через Python C API. В TypeScript/Node.js есть `ffi-napi` или N-API (node-addon-api). В OCaml FFI встроен в язык через ключевое слово `external` — никаких дополнительных обёрток и библиотек не нужно. Однако, как и `ctypes` в Python, FFI в OCaml требует аккуратности с типами — компилятор не проверяет соответствие типов OCaml и C.
```

### Ключевое слово `external`

`external` объявляет функцию, реализованную на C:

```ocaml
external c_sin : float -> float = "caml_sin_float" "sin"
  [@@unboxed] [@@noalloc]
external c_cos : float -> float = "caml_cos_float" "cos"
  [@@unboxed] [@@noalloc]
```

Разберём синтаксис:

- `external c_sin` — имя функции в OCaml.
- `: float -> float` — тип функции в OCaml.
- `= "caml_sin_float" "sin"` — два имени C-функций: первое для байткод-компилятора, второе для нативного.
- `[@@unboxed]` — аргументы и результат передаются без упаковки (boxing). Требует указания двух C-имён.
- `[@@noalloc]` — функция не выделяет память в куче OCaml.

### Соответствие типов OCaml и C

| Тип OCaml | Тип C | Примечание |
|-----------|-------|------------|
| `int` | `intnat` | Машинное целое минус 1 бит (тег) |
| `float` | `double` | 64-битное число с плавающей точкой |
| `bool` | `intnat` | 0 = false, 1 = true |
| `string` | `char *` | Строки OCaml — не нуль-терминированные! |
| `unit` | `value` | Представлен как `Val_unit` |
| `'a array` | `value` | Массив боксированных значений |

### Пример: математические функции из libm

Стандартная библиотека C `libm` содержит математические функции, которые можно вызывать напрямую:

```ocaml
external c_sin : float -> float = "caml_sin_float" "sin"
  [@@unboxed] [@@noalloc]
external c_cos : float -> float = "caml_cos_float" "cos"
  [@@unboxed] [@@noalloc]
external c_sqrt : float -> float = "caml_sqrt_float" "sqrt"
  [@@unboxed] [@@noalloc]
external c_exp : float -> float = "caml_exp_float" "exp"
  [@@unboxed] [@@noalloc]
external c_log : float -> float = "caml_log_float" "log"
  [@@unboxed] [@@noalloc]
```

Использование:

```text
# c_sin 0.0;;
- : float = 0.

# c_sin (Float.pi /. 2.0);;
- : float = 1.

# c_cos 0.0;;
- : float = 1.

# c_sqrt 2.0;;
- : float = 1.41421356237309515
```

Функции ведут себя как обычные OCaml-функции — компилятор не знает, что за ними стоит вызов в C. `sin(π/2) = 1` и `sqrt(2) ≈ 1.414` — результаты соответствуют стандартным математическим значениям.

Атрибуты `[@@unboxed]` и `[@@noalloc]` — оптимизации для простых числовых функций. `[@@unboxed]` избегает упаковки `float` в блок кучи, а `[@@noalloc]` сообщает сборщику мусора, что вызов безопасен. При использовании `[@@unboxed]` обязательно указывать два имени C-функций — для байткод-компилятора и для нативного.

### Простые external без атрибутов

Если не нужны оптимизации `[@@unboxed]` и `[@@noalloc]`, можно указать одно имя C-функции:

```ocaml
external c_abs : int -> int = "abs"
```

Это проще, но медленнее для числовых типов из-за боксинга.

### Функции с несколькими аргументами

Для C-функций с несколькими аргументами тоже нужно указать **два** имени — для байткод-компилятора и нативного:

```ocaml
external c_pow : float -> float -> float
  = "caml_pow_bytecode" "pow" [@@unboxed] [@@noalloc]
```

Первое имя — обёртка для байткода (все аргументы передаются как `value`), второе — нативная C-функция.

### Безопасность FFI

FFI — **небезопасная** операция. Компилятор OCaml **не проверяет** соответствие типов с C-функцией. Если вы объявите неправильный тип, программа может упасть с segfault:

```ocaml
(* ОПАСНО: неправильный тип! sin принимает double, а не int *)
external bad_sin : int -> int = "sin"
(* Это скомпилируется, но вызовет undefined behavior *)
```

Правила безопасности:

1. Убедитесь, что типы OCaml соответствуют типам C.
2. Не используйте `[@@noalloc]` если C-функция может вызвать callback в OCaml.
3. Будьте осторожны со строками — строки OCaml не нуль-терминированы.
4. Не передавайте OCaml-значения в C без правильного маршаллинга.

### Библиотека ctypes

Для более сложного FFI (структуры, указатели, callbacks) существует библиотека **ctypes**, которая позволяет описывать C-привязки целиком на OCaml:

```ocaml
(* С ctypes (концептуально): *)
open Ctypes
open Foreign

let c_strlen = foreign "strlen" (string @-> returning int)
let c_puts = foreign "puts" (string @-> returning int)
```

`ctypes` безопаснее ручных `external`-объявлений, потому что генерирует правильный маршаллинг автоматически. Но `external` быстрее для простых случаев, так как не имеет накладных расходов.

Подробное изучение ctypes выходит за рамки этой главы, но знать о его существовании полезно.

```admonish tip title="Экосистема: ctypes — высокоуровневая альтернатива raw FFI"
Библиотека [ctypes](https://github.com/yallop/ocaml-ctypes) позволяет описывать C-привязки целиком на OCaml, без написания C-стабов вручную. Она похожа на `ctypes` в Python: описываете типы C-функций декларативно, а маршаллинг генерируется автоматически. Для простых числовых функций `external` быстрее, но для сложных C API (структуры, указатели, callbacks) `ctypes` значительно безопаснее и удобнее. Подробнее о `ctypes` — далее в этой главе.
```

## Часть 1.5: Написание собственных C-стабов

До сих пор мы вызывали готовые C-функции из libc (`sin`, `cos`, `abs`). Но FFI по-настоящему нужен, когда нужно написать **собственный C-код** и вызывать его из OCaml. Это стандартная практика для обёртки C-библиотек.

В проекте `exercises/chapter14` есть файл `lib/stubs.c` — три реальных C-функции с подробными комментариями. Откройте его сейчас и читайте параллельно с этим разделом.

### Заголовочные файлы OCaml C API

Каждый C-стаб подключает три заголовка:

```c
#include <caml/mlvalues.h>  /* value, Int_val, Val_int, String_val, Field … */
#include <caml/memory.h>    /* CAMLparam*, CAMLreturn, CAMLlocal* */
#include <caml/alloc.h>     /* caml_alloc_string, caml_alloc_tuple … */
```

### Тип `value` и представление данных

В C все OCaml-значения имеют тип `value` — машинное слово. Разные OCaml-типы представлены по-разному:

| Тип OCaml | Хранится как | Макрос для доступа |
|-----------|-------------|-------------------|
| `int` | тегированный int | `Int_val(v)` / `Val_int(n)` |
| `char` | тегированный int (как `int`) | `Int_val(v)` / `Val_int(c)` |
| `bool` | `Val_int(0)` или `Val_int(1)` | `Bool_val(v)` / `Val_bool(b)` |
| `string` | блок с тегом `String_tag` | `String_val(v)` / `caml_string_length(v)` |
| `'a array` | блок с тегом `0` | `Field(v, i)` / `Wosize_val(v)` |
| `unit` | `Val_unit` (= `Val_int(0)`) | — |

Обратите внимание: **`char` в OCaml — это `int`**. Когда вы передаёте `char` в `external`-функцию, в C получаете тегированный int, доступный через `Int_val`.

### Макросы безопасности GC: `CAMLparam` и `CAMLreturn`

Сборщик мусора OCaml может **переместить объекты в куче** во время аллокации. Если C-функция сохранила адрес объекта в обычной переменной, этот адрес станет недействительным. Макросы `CAMLparam*` и `CAMLlocal*` регистрируют переменные как **GC-корни** — сборщик будет обновлять их при перемещении объектов.

**Правило:** вызывайте `CAMLparam*` для каждого аргумента `value` в начале функции, `CAMLlocal*` для локальных `value`-переменных, и всегда `CAMLreturn` вместо `return`.

```c
CAMLprim value caml_count_char(value str, value ch) {
  CAMLparam2(str, ch);           /* регистрируем 2 аргумента */
  const char *s   = String_val(str);
  mlsize_t   len  = caml_string_length(str);
  char       want = (char)Int_val(ch);   /* char == int в OCaml */
  int        cnt  = 0;
  for (mlsize_t i = 0; i < len; i++)
    if (s[i] == want) cnt++;
  CAMLreturn(Val_int(cnt));      /* снимаем GC-корни и возвращаем */
}
```

Функция подсчитывает количество вхождений байта `ch` в строку `str`. `CAMLprim` — макрос для экспорта функции как OCaml-примитива. Возвращаемое значение `Val_int(cnt)` упаковывает C-целое обратно в OCaml-представление.

Нюанс со строками: функция `String_val(str)` возвращает указатель на байты строки в куче OCaml. Этот указатель **инвалидируется** при любой аллокации. Поэтому строковые операции без аллокаций (как `caml_count_char`) безопасны, а вот если нужно аллоцировать — берите указатель только после аллокации.

### Выделение памяти: `caml_alloc_string` и `CAMLlocal`

Когда C-функция возвращает новый OCaml-объект (строку, кортеж, список), нужно выделить его через функции OCaml-рантайма. Для строки — `caml_alloc_string(len)`. Поскольку аллокация может запустить GC, результат нужно защитить через `CAMLlocal1`:

```c
CAMLprim value caml_str_repeat(value str, value n) {
  CAMLparam2(str, n);
  CAMLlocal1(result);          /* локальный GC-корень для нового объекта */

  mlsize_t src_len = caml_string_length(str);
  intnat   times   = Int_val(n);

  result = caml_alloc_string(src_len * (mlsize_t)times);

  /* Берём указатели ПОСЛЕ аллокации — до этого они могли быть инвалидированы */
  const char *src = String_val(str);
  char       *dst = (char *)Bytes_val(result);
  for (intnat i = 0; i < times; i++)
    memcpy(dst + (size_t)i * src_len, src, src_len);

  CAMLreturn(result);
}
```

Функция повторяет строку `n` раз: сначала выделяет результирующую строку нужного размера, затем берёт указатели на байты (уже после аллокации — это критически важно), и копирует содержимое `times` раз через `memcpy`. `Bytes_val` аналогичен `String_val`, но возвращает указатель на изменяемые байты.

### Работа с массивами: `Field` и `Wosize_val`

OCaml `int array` — это блок значений в куче. Доступ к элементам через `Field(arr, i)`:

```c
CAMLprim value caml_sum_int_array(value arr) {
  CAMLparam1(arr);
  mlsize_t len = Wosize_val(arr);  /* количество элементов */
  intnat   sum = 0;
  for (mlsize_t i = 0; i < len; i++)
    sum += Int_val(Field(arr, i)); /* каждый элемент — тегированный int */
  CAMLreturn(Val_int(sum));
}
```

`Wosize_val(arr)` возвращает количество слов (элементов) в блоке кучи OCaml. Для `int array` каждый элемент — тегированное целое, доступное через `Field(arr, i)`. После `Int_val` тег снимается и получается обычное C-целое. Результат упаковывается обратно через `Val_int`.

### Подключение C-файла через dune

Чтобы dune скомпилировал `lib/stubs.c` как часть OCaml-библиотеки:

```text
(library
 (name mylib)
 (foreign_stubs (language c) (names stubs))  ; компилирует lib/stubs.c
 (libraries yojson))
```

После этого функции из `stubs.c` становятся символами библиотеки `mylib` и доступны из OCaml через `external`.

### Привязка функций из stubs.c

После компиляции C-файла пишем `external`-объявления в OCaml:

```ocaml
(* OCaml char передаётся как int → Int_val(ch) в C *)
external count_char : string -> char -> int = "caml_count_char"

(* Функция аллоцирует строку → не нужны [@@noalloc] *)
external raw_str_repeat : string -> int -> string = "caml_str_repeat"

external sum_int_array : int array -> int = "caml_sum_int_array"
```

Для простых функций без аллокации можно добавить `[@@noalloc]` — это хинт компилятору, что GC-барьер не нужен:

```ocaml
external count_char : string -> char -> int = "caml_count_char" [@@noalloc]
```

```admonish warning title="Когда нельзя использовать [@@noalloc]"
Если C-функция аллоцирует OCaml-память, вызывает callback в OCaml, или бросает OCaml-исключение — атрибут `[@@noalloc]` использовать нельзя. В `caml_count_char` нет аллокации, поэтому `[@@noalloc]` безопасен. В `caml_str_repeat` — нельзя.
```

## Часть 2: JSON с Yojson

### Зачем JSON?

JSON — самый популярный формат обмена данными в веб-разработке и API. В OCaml основная библиотека для работы с JSON — **Yojson**.

В Haskell для JSON используется `aeson`:

```haskell
-- Haskell: aeson
import Data.Aeson
data Person = Person { name :: Text, age :: Int }
  deriving (Generic, FromJSON, ToJSON)
```

В OCaml аналогичную роль играет связка `yojson` + `ppx_deriving_yojson`.

```admonish tip title="Для Python/TS-разработчиков"
В Python вы привыкли к `json.loads()` / `json.dumps()`, где JSON превращается в `dict`, `list`, `str`, `int`, `float`, `bool`, `None`. В TypeScript — `JSON.parse()` / `JSON.stringify()`. В OCaml подход аналогичен: `Yojson.Safe.from_string` парсит строку в алгебраический тип `Yojson.Safe.t`, а `Yojson.Safe.to_string` делает обратное. Главное отличие — тип `Yojson.Safe.t` явно описывает структуру JSON через варианты, и компилятор заставляет вас обработать все случаи при разборе.
```

### Тип `Yojson.Safe.t`

`Yojson.Safe.t` — алгебраический тип, представляющий любое JSON-значение:

```ocaml
type t =
  | `Null
  | `Bool of bool
  | `Int of int
  | `Float of float
  | `String of string
  | `List of t list
  | `Assoc of (string * t) list
```

Это **полиморфные варианты** (polymorphic variants). Обратите внимание на обратный апостроф перед именем конструктора.

Примеры:

```text
# `Null;;
- : [> `Null ] = `Null

# `Bool true;;
- : [> `Bool of bool ] = `Bool true

# `Int 42;;
- : [> `Int of int ] = `Int 42

# `String "hello";;
- : [> `String of string ] = `String "hello"

# `List [`Int 1; `Int 2; `Int 3];;
- : [> `List of [> `Int of int ] list ] = `List [`Int 1; `Int 2; `Int 3]

# `Assoc [("name", `String "Alice"); ("age", `Int 30)];;
- : ... = `Assoc [("name", `String "Alice"); ("age", `Int 30)]
```

Тип `[> `Null ]` в utop-выводе означает "открытый тип полиморфных вариантов, содержащий как минимум `Null`". Символ `>` — маркер открытого типа: к нему можно добавлять новые варианты. При использовании в `Yojson.Safe.t` все варианты фиксированы, и тип закрыт.

### Парсинг JSON из строки

`Yojson.Safe.from_string` преобразует строку в `Yojson.Safe.t`:

```text
# Yojson.Safe.from_string {|{"name": "Alice", "age": 30}|};;
- : Yojson.Safe.t = `Assoc [("name", `String "Alice"); ("age", `Int 30)]

# Yojson.Safe.from_string {|[1, 2, 3]|};;
- : Yojson.Safe.t = `List [`Int 1; `Int 2; `Int 3]

# Yojson.Safe.from_string "null";;
- : Yojson.Safe.t = `Null
```

Обратите внимание на синтаксис **quoted strings** `{| ... |}` — строки OCaml, в которых не нужно экранировать кавычки. Очень удобно для JSON.

### Генерация JSON в строку

`Yojson.Safe.to_string` преобразует `Yojson.Safe.t` обратно в строку:

```text
# let json = `Assoc [("name", `String "Bob"); ("age", `Int 25)] in
  Yojson.Safe.to_string json;;
- : string = "{\"name\":\"Bob\",\"age\":25}"

# Yojson.Safe.pretty_to_string json;;
- : string = "{\n  \"name\": \"Bob\",\n  \"age\": 25\n}"
```

`pretty_to_string` выводит JSON с отступами — удобно для отладки.

### Ручной парсинг: сопоставление с образцом

Главная сила OCaml при работе с JSON — **pattern matching**. Можно безопасно разобрать JSON-структуру:

```ocaml
let parse_name json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt "name" fields with
     | Some (`String name) -> Ok name
     | Some _ -> Error "name is not a string"
     | None -> Error "name field missing")
  | _ -> Error "expected JSON object"
```

`List.assoc_opt "name" fields` ищет ключ `"name"` в ассоциативном списке и возвращает `option`. Вложенный `match` проверяет не только наличие поля, но и его тип: `Some (`String name)` успешно сопоставляется только если значение — строка. `Some _` ловит случай, когда поле есть, но содержит другой тип (например, `Int` или `Bool`).

Для вложенных структур парсинг выглядит так:

```ocaml
type address = {
  street : string;
  city : string;
  zip : string;
}

type contact = {
  name : string;
  age : int;
  email : string option;
  address : address;
}

let contact_of_json (json : Yojson.Safe.t) : (contact, string) result =
  match json with
  | `Assoc fields ->
    (match
       List.assoc_opt "name" fields,
       List.assoc_opt "age" fields,
       List.assoc_opt "email" fields,
       List.assoc_opt "address" fields
     with
     | Some (`String name), Some (`Int age), email_json, Some (`Assoc addr) ->
       let email = match email_json with
         | Some (`String e) -> Some e
         | _ -> None
       in
       (match
          List.assoc_opt "street" addr,
          List.assoc_opt "city" addr,
          List.assoc_opt "zip" addr
        with
        | Some (`String street), Some (`String city), Some (`String zip) ->
          Ok { name; age; email; address = { street; city; zip } }
        | _ -> Error "invalid address fields")
     | _ -> Error "missing or invalid fields")
  | _ -> Error "expected JSON object"
```

Ключевая техника — одновременное сопоставление нескольких полей через кортеж: `match f1, f2, f3 with | Some v1, Some v2, Some v3 -> ...`. Это позволяет избежать вложенных `match` для каждого поля и обработать все ошибки одной веткой `| _ -> Error ...`. Ручной парсинг надёжен и явен, но **многословен** — для каждого типа нужно писать конвертер вручную.

### Ручная генерация JSON

Построить JSON-значение из OCaml-типа тоже просто:

```ocaml
let contact_to_json (c : contact) : Yojson.Safe.t =
  `Assoc [
    ("name", `String c.name);
    ("age", `Int c.age);
    ("email", match c.email with Some e -> `String e | None -> `Null);
    ("address", `Assoc [
      ("street", `String c.address.street);
      ("city", `String c.address.city);
      ("zip", `String c.address.zip);
    ]);
  ]
```

Поле `email` типа `option` вручную преобразуется в `null` при `None` — это типичный JSON-паттерн. Вложенная запись `address` становится вложенным `Assoc`. Функция строит JSON-дерево структурно, повторяя форму OCaml-типа.

### Вспомогательные функции

Полезно вынести повторяющиеся паттерны в утилиты:

```ocaml
let json_string_field key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`String s) -> Some s
     | _ -> None)
  | _ -> None

let json_int_field key json =
  match json with
  | `Assoc fields ->
    (match List.assoc_opt key fields with
     | Some (`Int n) -> Some n
     | _ -> None)
  | _ -> None
```

Обе функции возвращают `None` в двух случаях: если поле отсутствует, или если оно есть, но имеет другой тип. Это безопасный подход — вместо исключения вы получаете `option` и обрабатываете отсутствие явно.

Использование:

```text
# let json = Yojson.Safe.from_string {|{"name": "Alice", "age": 30}|} in
  json_string_field "name" json;;
- : string option = Some "Alice"

# json_int_field "age" json;;
- : int option = Some 30

# json_string_field "missing" json;;
- : string option = None
```

Первые два вызова извлекают поля по имени и возвращают значения в `Some`. Третий вызов возвращает `None` — поля `"missing"` в JSON нет, и функция сигнализирует об этом через `option`, а не исключением.

## Часть 3: ppx_deriving_yojson

### Проблема ручных кодеков

Ручные конвертеры JSON имеют недостатки:

- Много шаблонного кода.
- Легко допустить ошибку в имени поля.
- При изменении типа нужно обновлять конвертеры вручную.

### Автоматическая генерация с `[@@deriving yojson]`

`ppx_deriving_yojson` — PPX-расширение, которое автоматически генерирует функции сериализации и десериализации:

```ocaml
type address = {
  street : string;
  city : string;
  zip : string;
} [@@deriving yojson]

type contact = {
  name : string;
  age : int;
  email : string option;
  address : address;
} [@@deriving yojson]
```

Аннотация `[@@deriving yojson]` генерирует две функции:

- `address_to_yojson : address -> Yojson.Safe.t`
- `address_of_yojson : Yojson.Safe.t -> (address, string) result`

И аналогично для `contact`:

- `contact_to_yojson : contact -> Yojson.Safe.t`
- `contact_of_yojson : Yojson.Safe.t -> (contact, string) result`

### Использование

```text
# let alice = {
    name = "Alice"; age = 30; email = Some "alice@example.com";
    address = { street = "Main St"; city = "Moscow"; zip = "101000" }
  };;

# let json = contact_to_yojson alice;;
# Yojson.Safe.pretty_to_string json;;
- : string = {
  "name": "Alice",
  "age": 30,
  "email": ["Some", "alice@example.com"],
  "address": {
    "street": "Main St",
    "city": "Moscow",
    "zip": "101000"
  }
}
```

`ppx_deriving_yojson` генерирует функцию `contact_to_yojson` автоматически, обходя все поля записи. Обратите внимание: `option` сериализуется как `["Some", value]` или `"None"` по умолчанию. Это отличается от ручной сериализации, где мы использовали `null`.

### Десериализация

```text
# let json_str = {|{"name":"Bob","age":25,"email":"None",
    "address":{"street":"Elm St","city":"SPb","zip":"190000"}}|} in
  let json = Yojson.Safe.from_string json_str in
  contact_of_yojson json;;
- : (contact, string) result = Ok {name = "Bob"; age = 25; email = None; ...}
```

Строка `"None"` в JSON десериализуется в `None : string option` — именно в том формате, который `ppx_deriving_yojson` использует для кодирования `option`. Функция `contact_of_yojson` возвращает `result` — `Ok` при успехе или `Error` с описанием ошибки.

### Настройка dune

Для использования `ppx_deriving_yojson` нужно настроить `dune`:

```lisp
(library
 (name mylib)
 (libraries yojson)
 (preprocess (pps ppx_deriving_yojson)))
```

Ключевая строка — `(preprocess (pps ppx_deriving_yojson))`, которая включает PPX-препроцессор.

### Только сериализация или десериализация

Можно сгенерировать только одну из двух функций:

```ocaml
type log_entry = {
  timestamp : float;
  message : string;
} [@@deriving to_yojson]
(* Генерирует только log_entry_to_yojson *)

type config = {
  host : string;
  port : int;
} [@@deriving of_yojson]
(* Генерирует только config_of_yojson *)
```

## Часть 4: Проект — парсер конфигурации

Соберём всё вместе — напишем парсер конфигурационного файла в формате JSON.

### Тип конфигурации

```ocaml
type database_config = {
  host : string;
  port : int;
  name : string;
} [@@deriving yojson]

type app_config = {
  debug : bool;
  log_level : string;
  database : database_config;
} [@@deriving yojson]
```

### Чтение конфигурации

```ocaml
let load_config path =
  let content = In_channel.with_open_text path In_channel.input_all in
  let json = Yojson.Safe.from_string content in
  app_config_of_yojson json

let save_config path config =
  let json = app_config_to_yojson config in
  let content = Yojson.Safe.pretty_to_string json in
  Out_channel.with_open_text path (fun oc ->
    Out_channel.output_string oc content)
```

### Пример конфигурации

```json
{
  "debug": true,
  "log_level": "info",
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "mydb"
  }
}
```

Этот паттерн — типичный для OCaml-приложений: определить тип с `[@@deriving yojson]`, затем использовать `from_string` / `to_string` для ввода-вывода.

## Сравнение с Haskell

| Аспект | OCaml (yojson + ppx) | Haskell (aeson) |
|--------|---------------------|-----------------|
| Тип JSON | `Yojson.Safe.t` (полиморфные варианты) | `Value` (ADT) |
| Автодеривация | `[@@deriving yojson]` | `deriving (FromJSON, ToJSON)` |
| Генерируемые функции | `t_to_yojson`, `t_of_yojson` | `toJSON`, `parseJSON` |
| Возврат десериализации | `(t, string) result` | `Parser t` (монада) |
| Ручной парсинг | Pattern matching | `.:`, `.:?`, `withObject` |
| FFI | `external` + C stubs | `foreign import ccall` |
| Типобезопасность FFI | Нет (доверие программисту) | Нет (доверие программисту) |
| Высокоуровневый FFI | ctypes | inline-c, c2hs |

Общая идея одинакова: определить тип данных, автоматически получить сериализаторы, использовать их для ввода-вывода JSON.

```admonish info title="Real World OCaml"
Подробнее о FFI, JSON и взаимодействии с C — в главах [Foreign Function Interface](https://dev.realworldocaml.org/foreign-function-interface.html) и [Handling JSON Data](https://dev.realworldocaml.org/json.html) книги Real World OCaml.
```

## Ctypes — высокоуровневый FFI

В разделе про FFI мы кратко упомянули библиотеку **ctypes**. Рассмотрим её подробнее — ctypes позволяет описывать C-типы и вызывать C-функции **целиком на OCaml**, без написания C-кода и стабов вручную.

### Установка

```text
$ opam install ctypes ctypes-foreign
```

### Основы: вызов C-функций

Модуль `Foreign` предоставляет функцию `foreign`, которая связывает имя C-функции с описанием её типа:

```ocaml
open Ctypes
open Foreign

let c_sqrt = foreign "sqrt" (double @-> returning double)
let c_pow = foreign "pow" (double @-> double @-> returning double)
```

Оператор `@->` описывает аргументы, а `returning t` — тип возвращаемого значения. Типы (`double`, `int`, `string` и т.д.) — это значения модуля `Ctypes`, а не типы OCaml.

После объявления `c_sqrt` и `c_pow` — обычные OCaml-функции:

```text
# c_sqrt 2.0;;
- : float = 1.41421356237309515

# c_pow 2.0 10.0;;
- : float = 1024.
```

Ctypes автоматически выполняет маршаллинг аргументов: OCaml-значение `float` преобразуется в C-тип `double` и обратно. Выражение `c_pow 2.0 10.0` вычисляет 2^10 = 1024.

### Определение C-структур

Ctypes позволяет описывать C-структуры:

```ocaml
type point
let point : point structure typ = structure "point"
let x = field point "x" double
let y = field point "y" double
let () = seal point

(* Создание и использование *)
let p = make point in
setf p x 3.0;
setf p y 4.0;
let dist = sqrt (getf p x ** 2.0 +. getf p y ** 2.0)
```

Здесь `getf p x` читает поле `x` из структуры `p`, а `**` — оператор возведения в степень для `float`. Для точки (3.0, 4.0) расстояние до начала координат равно 5.0 (египетский треугольник 3-4-5).

Порядок действий:

1. `structure "point"` — объявить структуру с именем `point`.
2. `field point "x" double` — добавить поле `x` типа `double`.
3. `seal point` — завершить определение (вычислить размер и выравнивание).
4. `make point` — создать экземпляр структуры.
5. `setf` / `getf` — записать / прочитать поле.

**Частая ошибка:** если забыть вызвать `seal t`, при попытке использовать структуру вы получите исключение `Ctypes_static.IncompleteType`.

### Два подхода к связыванию

Ctypes поддерживает два режима работы:

1. **Dynamic linking** (через `libffi`) — быстрый старт, не требует компиляции C-кода. Библиотека загружается в рантайме (`.so` на Linux, `.dylib` на macOS). Удобно для прототипирования.

2. **Stub generation** — production-подход. Ctypes генерирует C-стабы на этапе сборки. Результат эффективнее (нет overhead от libffi), но сборка сложнее.

Для большинства задач dynamic linking достаточно. Stub generation имеет смысл, когда FFI-вызовы находятся на горячем пути.

### Ограничения

- Generated stubs не поддерживают атрибуты `[@noalloc]` и `[@unboxed]`, которые доступны при ручном `external`.
- Dynamic linking требует наличия `.so`/`.dylib` в системе в рантайме.
- Ctypes медленнее ручных `external` для простых числовых функций из-за дополнительного уровня абстракции.

Для простых числовых функций `external` с `[@@unboxed] [@@noalloc]` остаётся лучшим выбором. Ctypes раскрывает свою мощь при работе со структурами, указателями, массивами и сложными C API.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

**Перед FFI-упражнениями:** откройте `lib/stubs.c` и прочитайте все три реализации с комментариями — они подробно объясняют каждый макрос и функцию OCaml C API.

### JSON (1–4)

1. **(Среднее)** Реализуйте ручную конвертацию `product_to_json` для типа:

    ```ocaml
    type product = {
      title    : string;
      price    : float;
      in_stock : bool;
    }
    ```

    Функция должна возвращать `Yojson.Safe.t` — JSON-объект с полями `"title"`, `"price"`, `"in_stock"`.

2. **(Среднее)** Реализуйте обратную конвертацию `product_of_json`:

    ```ocaml
    val product_of_json : Yojson.Safe.t -> (product, string) result
    ```

    При невалидном JSON верните `Error` с описанием ошибки.

3. **(Среднее)** Реализуйте функцию `extract_names`, которая из JSON-массива объектов извлекает значения поля `"name"`:

    ```ocaml
    val extract_names : Yojson.Safe.t -> string list
    ```

    Например, для `[{"name": "Alice"}, {"name": "Bob"}, {"age": 25}]` результат: `["Alice"; "Bob"]`. Объекты без поля `"name"` пропускаются.

4. **(Лёгкое)** Определите тип `config` с полями `host : string`, `port : int`, `debug : bool` и аннотацией `[@@deriving yojson]`. Убедитесь, что автоматическая сериализация и десериализация работают (тесты проверят roundtrip).

### FFI — реальные привязки к C (5–7)

Функции `caml_count_char`, `caml_str_repeat`, `caml_sum_int_array` уже реализованы в `lib/stubs.c` и скомпилированы как часть библиотеки `chapter14`. Ваша задача — написать OCaml-привязки для них.

5. **(Среднее)** Напишите `external`-объявление для `caml_count_char`.

    Прочитайте сигнатуру C-функции в `lib/stubs.c`:
    ```c
    CAMLprim value caml_count_char(value str, value ch)
    ```

    Замените заглушку в `my_solutions.ml` на `external`-объявление с правильным именем символа и типом OCaml. Учтите: в C `ch` получается как `Int_val(ch)` — потому что OCaml `char` хранится как `int`.

    ```text
    # count_char "hello" 'l';;
    - : int = 2

    # count_char "mississippi" 's';;
    - : int = 4
    ```

6. **(Среднее)** Напишите `external`-объявление для `caml_str_repeat` (уже дано в заглушке как `let`) и реализуйте безопасную обёртку `str_repeat`, которая возвращает `""` при `n < 0`.

    ```text
    # str_repeat "ab" 3;;
    - : string = "ababab"

    # str_repeat "x" (-1);;
    - : string = ""
    ```

7. **(Среднее)** Напишите `external`-объявление для `caml_sum_int_array` (тип `int array -> int`) и реализуйте `mean : int array -> float option` поверх него. Верните `None` для пустого массива.

    ```text
    # mean [| 1; 2; 3; 4; 5 |];;
    - : float option = Some 3.

    # mean [||];;
    - : float option = None
    ```

    *Подсказка:* `Array.length arr` даёт длину массива на стороне OCaml. Делите `float_of_int (raw_sum arr)` на `float_of_int len`.

**Для любопытных:** попробуйте добавить в `lib/stubs.c` свою функцию `caml_string_is_palindrome : string -> bool` и написать для неё `external`-привязку. `Bool_val(v)` и `Val_bool(b)` — макросы для `bool`.

## Заключение

В этой главе: `external` для FFI, таблица соответствия типов OCaml и C, Yojson для ручного парсинга JSON, `ppx_deriving_yojson` для автоматической сериализации.

В следующей главе — полноценное CLI-приложение с Cmdliner.
