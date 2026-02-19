# Expression Problem

## Цели главы

В этой главе мы изучим **Expression Problem** --- классическую задачу проектирования расширяемых программ. Вы узнаете, как различные механизмы OCaml решают эту задачу, и научитесь выбирать подходящий инструмент:

- Формулировка Expression Problem (Wadler, 1998).
- Два измерения расширяемости: новые случаи и новые операции.
- Решение через алгебраические типы (варианты).
- Решение через объекты.
- Решение через модули и Tagless Final.
- Решение через полиморфные варианты и открытую рекурсию.
- Сравнение подходов.
- Проект: расширяемый калькулятор тремя способами.

## Подготовка проекта

Код этой главы находится в `exercises/chapter10`. Соберите проект:

```text
$ cd exercises/chapter10
$ dune build
```

## Что такое Expression Problem

Expression Problem --- термин, введённый Филиппом Вадлером (Philip Wadler) в 1998 году. Задача звучит так:

> Определить тип данных, к которому можно добавлять **новые случаи** (cases) и **новые операции** (operations) **без перекомпиляции существующего кода** и **с сохранением статической типобезопасности**.

Рассмотрим конкретный пример. Допустим, у нас есть язык арифметических выражений:

- Выражения: `Int` (целое число) и `Add` (сложение).
- Операции: `eval` (вычисление) и `show` (отображение).

```
            | eval      | show      |
  ----------+-----------+-----------+
  Int       | eval_int  | show_int  |
  Add       | eval_add  | show_add  |
```

Таблица имеет два измерения. **Расширение** означает добавление:

- Нового столбца --- новой операции (например, `pretty_print`).
- Новой строки --- нового случая (например, `Mul`).

### Два измерения расширения

В большинстве языков одно измерение расширяется легко, а другое --- трудно.

**Функциональные языки** (Haskell, OCaml с вариантами): легко добавить новую операцию (новая функция по существующему типу), но добавление нового случая требует изменения **всех** существующих функций.

**Объектно-ориентированные языки** (Java, C#): легко добавить новый случай (новый класс, реализующий интерфейс), но добавление новой операции требует изменения **всех** существующих классов.

Expression Problem --- это вызов: можно ли добиться расширяемости в обоих измерениях одновременно?

## Решение 1: Варианты (алгебраические типы)

Начнём с привычного подхода --- определим выражения как вариантный тип:

```ocaml
type expr =
  | Int of int
  | Add of expr * expr
```

### Операции

Каждая операция --- отдельная функция с сопоставлением по образцу:

```ocaml
let rec eval = function
  | Int n -> n
  | Add (a, b) -> eval a + eval b

let rec show = function
  | Int n -> string_of_int n
  | Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"
```

```text
# eval (Add (Int 1, Add (Int 2, Int 3)));;
- : int = 6

# show (Add (Int 1, Add (Int 2, Int 3)));;
- : string = "(1 + (2 + 3))"
```

### Добавить операцию --- легко

Хотим добавить `double` --- удвоение всех чисел в выражении:

```ocaml
let rec double = function
  | Int n -> Int (n * 2)
  | Add (a, b) -> Add (double a, double b)
```

Мы написали **новую функцию**, не трогая существующий код. Все старые функции (`eval`, `show`) продолжают работать.

### Добавить вариант --- трудно

Хотим добавить `Mul` (умножение). Нужно изменить определение типа:

```ocaml
type expr =
  | Int of int
  | Add of expr * expr
  | Mul of expr * expr   (* новый случай *)
```

Теперь компилятор выдаст предупреждения во **всех** функциях (`eval`, `show`, `double`) --- каждую нужно дополнить веткой для `Mul`. Это безопасно (компилятор подскажет), но требует изменения существующего кода.

```ocaml
let rec eval = function
  | Int n -> n
  | Add (a, b) -> eval a + eval b
  | Mul (a, b) -> eval a * eval b  (* новая ветка *)

let rec show = function
  | Int n -> string_of_int n
  | Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"
  | Mul (a, b) -> "(" ^ show a ^ " * " ^ show b ^ ")"  (* новая ветка *)
```

### Резюме

| Направление расширения | Сложность |
|------------------------|-----------|
| Новая операция         | Легко --- пишем новую функцию |
| Новый случай           | Трудно --- изменяем тип и все функции |

В Haskell ситуация аналогичная. `data Expr = Int Int | Add Expr Expr` расширяется так же --- легко добавить новую функцию, трудно добавить конструктор.

## Решение 2: Объекты

OCaml поддерживает объектно-ориентированное программирование. Попробуем решить Expression Problem через объекты:

```ocaml
class virtual expr = object
  method virtual eval : int
  method virtual show : string
end
```

Каждый случай --- отдельный класс:

```ocaml
class int_expr (n : int) = object
  inherit expr
  method eval = n
  method show = string_of_int n
end

class add_expr (a : expr) (b : expr) = object
  inherit expr
  method eval = a#eval + b#eval
  method show = "(" ^ a#show ^ " + " ^ b#show ^ ")"
end
```

```text
# let e = new add_expr (new int_expr 1) (new add_expr (new int_expr 2) (new int_expr 3));;
# e#eval;;
- : int = 6
# e#show;;
- : string = "(1 + (2 + 3))"
```

### Добавить вариант --- легко

Хотим добавить `Mul`. Пишем **новый класс**, не трогая существующие:

```ocaml
class mul_expr (a : expr) (b : expr) = object
  inherit expr
  method eval = a#eval * b#eval
  method show = "(" ^ a#show ^ " * " ^ b#show ^ ")"
end
```

Все старые классы (`int_expr`, `add_expr`) не изменились.

### Добавить операцию --- трудно

Хотим добавить метод `double`. Нужно изменить базовый класс `expr`:

```ocaml
class virtual expr = object
  method virtual eval : int
  method virtual show : string
  method virtual double : expr   (* новый метод *)
end
```

Теперь **все** существующие классы (`int_expr`, `add_expr`, `mul_expr`) должны реализовать `double`. Это зеркальная проблема по сравнению с вариантами.

### Резюме

| Направление расширения | Сложность |
|------------------------|-----------|
| Новая операция         | Трудно --- изменяем базовый класс и все подклассы |
| Новый случай           | Легко --- пишем новый класс |

В Java/C# ситуация аналогичная. Интерфейс `Expr` с методами `eval()` и `show()` легко расширяется новыми классами, но добавление нового метода в интерфейс ломает все реализации.

## Решение 3: Модули и Tagless Final

**Tagless Final** --- подход, в котором выражения описываются не как тип данных, а как **набор операций** (smart-конструкторов) в сигнатуре модуля. Каждая **интерпретация** --- отдельный модуль, реализующий сигнатуру.

### Сигнатура

```ocaml
module type Expr = sig
  type t
  val int_ : int -> t
  val add : t -> t -> t
end
```

Тип `t` абстрактный --- он может быть `int` (для вычисления), `string` (для отображения) или чем-то ещё. Функции `int_` и `add` --- «конструкторы» выражений.

### Интерпретация: вычисление

```ocaml
module Eval : Expr with type t = int = struct
  type t = int
  let int_ n = n
  let add a b = a + b
end
```

### Интерпретация: отображение

```ocaml
module Show : Expr with type t = string = struct
  type t = string
  let int_ n = string_of_int n
  let add a b = "(" ^ a ^ " + " ^ b ^ ")"
end
```

### Использование

Выражение записывается **один раз** как функция, параметризованная модулем:

```ocaml
let example (module E : Expr) =
  E.add (E.int_ 1) (E.add (E.int_ 2) (E.int_ 3))
```

```text
# example (module Eval);;
- : int = 6

# example (module Show);;
- : string = "(1 + (2 + 3))"
```

Или через функтор:

```ocaml
module Example (E : Expr) = struct
  let result = E.add (E.int_ 1) (E.add (E.int_ 2) (E.int_ 3))
end

module R1 = Example(Eval)
module R2 = Example(Show)
```

```text
# R1.result;;
- : int = 6

# R2.result;;
- : string = "(1 + (2 + 3))"
```

### Добавить операцию --- новый модуль

Хотим добавить операцию `pretty_print` с красивыми отступами? Пишем **новый модуль**:

```ocaml
module PrettyPrint : Expr with type t = int -> string = struct
  type t = int -> string
  let int_ n _indent = string_of_int n
  let add a b indent =
    let pad = String.make indent ' ' in
    pad ^ "Add\n"
    ^ pad ^ "  " ^ a (indent + 2) ^ "\n"
    ^ pad ^ "  " ^ b (indent + 2)
end
```

Существующие модули не изменились.

### Добавить вариант --- расширить сигнатуру

Хотим добавить `Mul`? Расширяем сигнатуру:

```ocaml
module type ExprMul = sig
  include Expr
  val mul : t -> t -> t
end
```

И реализуем расширенные модули:

```ocaml
module EvalMul : ExprMul with type t = int = struct
  include Eval
  let mul a b = a * b
end

module ShowMul : ExprMul with type t = string = struct
  include Show
  let mul a b = "(" ^ a ^ " * " ^ b ^ ")"
end
```

Обратите внимание: мы использовали `include Eval` и `include Show` --- **повторного кода нет**. Старые модули `Eval` и `Show` не изменились.

```text
# let example2 (module E : ExprMul) =
    E.mul (E.int_ 2) (E.add (E.int_ 3) (E.int_ 4));;

# example2 (module EvalMul);;
- : int = 14

# example2 (module ShowMul);;
- : string = "(2 * (3 + 4))"
```

### Почему это работает

Tagless Final решает Expression Problem благодаря двум механизмам:

1. **Абстрактный тип `t`** --- позволяет каждому модулю выбирать своё представление.
2. **`include`** --- позволяет расширять модули без копирования кода.

В Haskell аналогичный подход --- классы типов (type classes). Сигнатура `module type Expr` --- это аналог класса типов:

```haskell
-- Haskell: класс типов
class Expr repr where
  int_ :: Int -> repr
  add  :: repr -> repr -> repr

-- OCaml: сигнатура модуля
module type Expr = sig
  type t
  val int_ : int -> t
  val add : t -> t -> t
end
```

Добавление новой операции --- новый экземпляр (instance) в Haskell, новый модуль в OCaml. Добавление нового конструктора --- расширение класса в Haskell, `include` в OCaml.

### Резюме

| Направление расширения | Сложность |
|------------------------|-----------|
| Новая операция         | Легко --- новый модуль, реализующий `Expr` |
| Новый случай           | Легко --- расширяем сигнатуру через `include` |

## Решение 4: Полиморфные варианты (открытая рекурсия)

Полиморфные варианты (polymorphic variants) --- ещё один способ решения Expression Problem в OCaml. В отличие от обычных вариантов, полиморфные варианты **не привязаны** к конкретному определению типа.

### Базовые выражения

```ocaml
type 'a expr_base = [> `Int of int | `Add of 'a * 'a ] as 'a
```

Здесь `[> ...]` означает «открытый тип» --- он может содержать **как минимум** указанные конструкторы, но допускает и другие.

Операции определяются для конкретных конструкторов:

```ocaml
let rec eval : 'a expr_base -> int = function
  | `Int n -> n
  | `Add (a, b) -> eval a + eval b
  | _ -> failwith "unknown expression"

let rec show : 'a expr_base -> string = function
  | `Int n -> string_of_int n
  | `Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"
  | _ -> failwith "unknown expression"
```

```text
# eval (`Add (`Int 1, `Add (`Int 2, `Int 3)));;
- : int = 6

# show (`Add (`Int 1, `Add (`Int 2, `Int 3)));;
- : string = "(1 + (2 + 3))"
```

### Добавить вариант --- расширить тип

Хотим добавить `Mul`? Определяем расширенный тип и функции:

```ocaml
type 'a expr_mul = [> `Int of int | `Add of 'a * 'a | `Mul of 'a * 'a ] as 'a

let rec eval_mul : 'a expr_mul -> int = function
  | `Int n -> n
  | `Add (a, b) -> eval_mul a + eval_mul b
  | `Mul (a, b) -> eval_mul a * eval_mul b
  | _ -> failwith "unknown expression"

let rec show_mul : 'a expr_mul -> string = function
  | `Int n -> string_of_int n
  | `Add (a, b) -> "(" ^ show_mul a ^ " + " ^ show_mul b ^ ")"
  | `Mul (a, b) -> "(" ^ show_mul a ^ " * " ^ show_mul b ^ ")"
  | _ -> failwith "unknown expression"
```

```text
# eval_mul (`Mul (`Int 2, `Add (`Int 3, `Int 4)));;
- : int = 14

# show_mul (`Mul (`Int 2, `Add (`Int 3, `Int 4)));;
- : string = "(2 * (3 + 4))"
```

### Избавление от дублирования через открытую рекурсию

В примере выше мы продублировали ветки `Int` и `Add` в `eval_mul`. Можно этого избежать с помощью **открытой рекурсии** --- рекурсивный вызов передаётся как параметр:

```ocaml
let eval_base self = function
  | `Int n -> n
  | `Add (a, b) -> self a + self b

let eval_mul_ext self = function
  | `Mul (a, b) -> self a * self b
  | other -> eval_base self other

let rec eval_mul_v2 x = eval_mul_ext eval_mul_v2 x
```

```text
# eval_mul_v2 (`Mul (`Int 2, `Add (`Int 3, `Int 4)));;
- : int = 14
```

Здесь `eval_base` и `eval_mul_ext` не рекурсивны сами по себе --- рекурсия замыкается через параметр `self`. Это позволяет **комбинировать** обработчики разных расширений.

### Достоинства и ограничения

Полиморфные варианты --- мощный инструмент, но у него есть ограничения:

- **Сообщения об ошибках** --- типы полиморфных вариантов бывают длинными и трудночитаемыми.
- **Производительность** --- полиморфные варианты немного медленнее обычных.
- **Вайлдкард `_`** --- необходимость catch-all ветки ослабляет проверку полноты.

### Резюме

| Направление расширения | Сложность |
|------------------------|-----------|
| Новая операция         | Средне --- новая функция, но без полноты проверки |
| Новый случай           | Средне --- расширяем тип, комбинируем через открытую рекурсию |

## Сравнение подходов

| Подход | Новая операция | Новый случай | Типобезопасность | Сложность |
|--------|---------------|-------------|-----------------|-----------|
| Варианты (ADT) | Легко | Трудно (изменить тип + все функции) | Полная (exhaustiveness) | Низкая |
| Объекты | Трудно (изменить базовый класс) | Легко | Полная (виртуальные методы) | Средняя |
| Tagless Final | Легко (новый модуль) | Легко (`include` + новая функция) | Полная | Средняя |
| Полиморфные варианты | Средне | Средне (открытая рекурсия) | Частичная (нужен `_`) | Высокая |

**Рекомендации:**

- **Варианты** --- лучший выбор по умолчанию. Если набор случаев фиксирован и стабилен (например, AST конкретного языка), а операции добавляются часто --- используйте обычные варианты.
- **Tagless Final** --- когда нужна расширяемость в обоих измерениях. Особенно хорош для DSL (domain-specific languages), где и операции, и типы выражений могут расти.
- **Объекты** --- редко используются в идиоматическом OCaml. Полезны при взаимодействии с ОО-библиотеками или когда подтипирование действительно нужно.
- **Полиморфные варианты** --- для случаев, когда нужна гибкость без тяжёлой модульной системы. Хороши для протоколов и расширяемых обработчиков.

## Проект: расширяемый калькулятор

Модуль `lib/expr.ml` реализует расширяемый калькулятор тремя способами: через варианты, Tagless Final и полиморфные варианты.

### Способ 1: Варианты

```ocaml
module Variant = struct
  type expr =
    | Int of int
    | Add of expr * expr

  let rec eval = function
    | Int n -> n
    | Add (a, b) -> eval a + eval b

  let rec show = function
    | Int n -> string_of_int n
    | Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"
end
```

### Способ 2: Tagless Final

```ocaml
module type EXPR = sig
  type t
  val int_ : int -> t
  val add : t -> t -> t
end

module TF_Eval : EXPR with type t = int = struct
  type t = int
  let int_ n = n
  let add a b = a + b
end

module TF_Show : EXPR with type t = string = struct
  type t = string
  let int_ n = string_of_int n
  let add a b = "(" ^ a ^ " + " ^ b ^ ")"
end
```

### Способ 3: Полиморфные варианты

```ocaml
module PolyVar = struct
  type 'a t = [> `Int of int | `Add of 'a * 'a ] as 'a

  let rec eval : 'a t -> int = function
    | `Int n -> n
    | `Add (a, b) -> eval a + eval b
    | _ -> failwith "unknown"

  let rec show : 'a t -> string = function
    | `Int n -> string_of_int n
    | `Add (a, b) -> "(" ^ show a ^ " + " ^ show b ^ ")"
    | _ -> failwith "unknown"
end
```

### Пример использования всех трёх подходов

```text
# (* Вариантный подход *)
  Variant.(eval (Add (Int 1, Add (Int 2, Int 3))));;
- : int = 6

# (* Tagless Final *)
  let module E = TF_Eval in E.add (E.int_ 1) (E.add (E.int_ 2) (E.int_ 3));;
- : int = 6

# (* Полиморфные варианты *)
  PolyVar.eval (`Add (`Int 1, `Add (`Int 2, `Int 3)));;
- : int = 6
```

Все три подхода дают одинаковый результат, но отличаются возможностями расширения.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Среднее)** Добавьте конструктор `Mul of expr * expr` к вариантному типу `expr` и расширьте функции `eval` и `show`.

    ```ocaml
    module VariantMul : sig
      type expr =
        | Int of int
        | Add of expr * expr
        | Mul of expr * expr

      val eval : expr -> int
      val show : expr -> string
    end
    ```

    Например:
    - `eval (Mul (Int 2, Add (Int 3, Int 4)))` = `14`
    - `show (Mul (Int 2, Add (Int 3, Int 4)))` = `"(2 * (3 + 4))"`

2. **(Среднее)** Добавьте интерпретацию `pretty_print` для Tagless Final --- модуль, генерирующий строку с правильной расстановкой скобок и инфиксной записью, но **без лишних скобок** у литералов.

    ```ocaml
    module TF_Pretty : EXPR with type t = string
    ```

    Например:
    - `TF_Pretty.int_ 42` = `"42"`
    - `TF_Pretty.add (TF_Pretty.int_ 1) (TF_Pretty.int_ 2)` = `"(1 + 2)"`
    - Вложенные: `TF_Pretty.add (TF_Pretty.int_ 1) (TF_Pretty.add (TF_Pretty.int_ 2) (TF_Pretty.int_ 3))` = `"(1 + (2 + 3))"`

3. **(Среднее)** Добавьте `` `Neg `` (унарное отрицание) к полиморфным вариантам. Реализуйте `eval_neg` и `show_neg`.

    ```ocaml
    type 'a expr_neg = [> `Int of int | `Add of 'a * 'a | `Neg of 'a ] as 'a

    val eval_neg : 'a expr_neg -> int
    val show_neg : 'a expr_neg -> string
    ```

    Например:
    - `` eval_neg (`Neg (`Int 5)) `` = `-5`
    - `` show_neg (`Neg (`Add (`Int 1, `Int 2))) `` = `"(-(1 + 2))"`

4. **(Сложное)** Реализуйте Tagless Final DSL для **булевых** выражений. Определите сигнатуру `BOOL_EXPR` и два модуля-интерпретатора.

    ```ocaml
    module type BOOL_EXPR = sig
      type t
      val bool_ : bool -> t
      val and_ : t -> t -> t
      val or_ : t -> t -> t
      val not_ : t -> t
    end

    module Bool_Eval : BOOL_EXPR with type t = bool
    module Bool_Show : BOOL_EXPR with type t = string
    ```

    Например:
    - `Bool_Eval.(and_ (bool_ true) (or_ (bool_ false) (bool_ true)))` = `true`
    - `Bool_Show.(and_ (bool_ true) (or_ (bool_ false) (bool_ true)))` = `"(true && (false || true))"`

5. **(Сложное)** Объедините арифметический и булев DSL. Создайте сигнатуру `COMBINED_EXPR`, включающую операции из обоих DSL, а также операцию сравнения `eq : t -> t -> t`. Реализуйте `Combined_Show`.

    ```ocaml
    module type COMBINED_EXPR = sig
      type t
      val int_ : int -> t
      val add : t -> t -> t
      val bool_ : bool -> t
      val and_ : t -> t -> t
      val or_ : t -> t -> t
      val not_ : t -> t
      val eq : t -> t -> t
    end

    module Combined_Show : COMBINED_EXPR with type t = string
    ```

    Например:
    - `Combined_Show.(eq (add (int_ 1) (int_ 2)) (int_ 3))` = `"((1 + 2) == 3)"`
    - `Combined_Show.(and_ (bool_ true) (eq (int_ 1) (int_ 1)))` = `"(true && (1 == 1))"`

## Заключение

В этой главе мы:

- Познакомились с Expression Problem --- классической задачей расширяемости программ.
- Изучили четыре подхода к её решению в OCaml.
- Увидели, что **варианты** оптимальны, когда набор случаев фиксирован.
- Изучили **Tagless Final** --- элегантное решение, расширяемое в обоих измерениях через модульную систему OCaml.
- Познакомились с **полиморфными вариантами** и открытой рекурсией.
- Сравнили Tagless Final с классами типов Haskell.
- Реализовали расширяемый калькулятор тремя способами.

В следующей главе мы изучим обработчики эффектов --- мощный механизм OCaml 5 для управления вычислительными эффектами.
