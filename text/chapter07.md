# Модули и функторы

## Цели главы

В этой главе мы изучим **модульную систему** OCaml --- одну из самых мощных среди всех языков программирования. Вместо классов типов (type classes) Haskell, OCaml использует модули для абстракции, инкапсуляции и параметрического полиморфизма:

- Модули --- именованные коллекции типов и значений.
- Сигнатуры (module types) --- интерфейсы модулей.
- Абстрактные типы --- сокрытие реализации.
- Функторы --- параметризованные модули.
- Модули первого класса --- передача модулей как значений.
- `include` и `open` --- композиция модулей.
- Сравнение с классами типов Haskell.

## Подготовка проекта

Код этой главы находится в `exercises/chapter07`. Соберите проект:

```text
$ cd exercises/chapter07
$ dune build
```

## Модули

В OCaml каждый `.ml`-файл автоматически является модулем. Но модули можно также определять **внутри** файла:

```ocaml
module Counter = struct
  type t = int
  let zero = 0
  let increment c = c + 1
  let to_string c = string_of_int c
end
```

Использование:

```text
# Counter.zero;;
- : int = 0

# Counter.increment Counter.zero;;
- : int = 1

# Counter.to_string 42;;
- : string = "42"
```

Модуль --- это именованная коллекция **типов**, **значений** и **вложенных модулей**.

### Вложенные модули

Модули могут быть вложенными:

```ocaml
module Geometry = struct
  module Point = struct
    type t = { x : float; y : float }
    let origin = { x = 0.0; y = 0.0 }
    let distance p1 p2 =
      Float.sqrt ((p1.x -. p2.x) ** 2.0 +. (p1.y -. p2.y) ** 2.0)
  end

  module Circle = struct
    type t = { center : Point.t; radius : float }
    let area c = Float.pi *. c.radius *. c.radius
  end
end
```

Обращение: `Geometry.Point.origin`, `Geometry.Circle.area`.

## Сигнатуры

Сигнатура (module type) --- это **интерфейс** модуля. Она описывает, какие типы и значения модуль предоставляет:

```ocaml
module type Printable = sig
  type t
  val to_string : t -> string
end
```

Сигнатура `Printable` говорит: «модуль должен иметь тип `t` и функцию `to_string : t -> string`». Тип `t` --- **абстрактный** --- сигнатура не раскрывает его реализацию.

### Ограничение модуля сигнатурой

Сигнатуру можно применить к модулю:

```ocaml
module IntPrintable : Printable with type t = int = struct
  type t = int
  let to_string = string_of_int
end
```

Конструкция `with type t = int` раскрывает абстрактный тип --- пользователи модуля видят, что `t = int`. Без неё тип `t` был бы непрозрачным.

```admonish tip title="Для Python/TS-разработчиков"
Сигнатуры модулей в OCaml --- аналог интерфейсов (`interface`) в TypeScript и абстрактных базовых классов (`ABC`) или протоколов (`Protocol`) в Python. Например, `module type Printable = sig type t val to_string : t -> string end` --- это как `interface Printable<T> { toString(value: T): string }` в TS. Ключевое отличие: в OCaml сигнатура может скрывать реализацию типа (`type t` без определения), чего в TypeScript и Python добиться сложнее.
```

```admonish info title="Подробнее"
Детальное описание модульной системы: [Real World OCaml, глава «Files, Modules, and Programs»](https://dev.realworldocaml.org/files-modules-and-programs.html)
```

### Абстрактные типы

Абстрактные типы --- мощный механизм инкапсуляции. Они скрывают реализацию, позволяя менять её без нарушения внешнего кода:

```ocaml
module type Stack = sig
  type 'a t
  val empty : 'a t
  val push : 'a -> 'a t -> 'a t
  val pop : 'a t -> ('a * 'a t) option
  val is_empty : 'a t -> bool
end

module ListStack : Stack = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> None
    | x :: rest -> Some (x, rest)
  let is_empty = function
    | [] -> true
    | _ :: _ -> false
end
```

Пользователи `ListStack` работают с типом `'a ListStack.t`, не зная, что внутри это список. Мы можем заменить реализацию на массив --- внешний код не изменится.

```text
# let s = ListStack.push 1 (ListStack.push 2 ListStack.empty);;
val s : int ListStack.t = <abstr>

# ListStack.pop s;;
- : (int * int ListStack.t) option = Some (1, <abstr>)
```

Обратите внимание: utop показывает `<abstr>` вместо конкретного значения --- тип абстрагирован.

## Сравнение с классами типов Haskell

В Haskell абстракция и полиморфизм достигаются через классы типов:

```haskell
-- Haskell
class Hashable a where
  hash :: a -> Int

instance Hashable Int where
  hash = id
```

В OCaml ту же задачу решают **сигнатуры и модули**:

```ocaml
(* OCaml *)
module type Hashable = sig
  type t
  val hash : t -> int
end

module IntHashable : Hashable with type t = int = struct
  type t = int
  let hash x = x
end
```

### Основные различия

| Аспект | Haskell (классы типов) | OCaml (модули) |
|--------|----------------------|----------------|
| Диспетчеризация | Автоматическая (компилятор выбирает инстанс) | Явная (модуль передаётся как аргумент) |
| Уникальность | Один инстанс на тип | Несколько модулей для одного типа |
| Расширяемость | Инстансы добавляются где угодно | Модули создаются в одном месте |
| Абстракция | Ограничения в типах (`Eq a =>`) | Параметры функторов |

У каждого подхода свои плюсы. Автоматическая диспетчеризация Haskell удобнее для простых случаев. Явные модули OCaml дают больше контроля и позволяют иметь несколько реализаций для одного типа (например, разные порядки сортировки).

## Функторы

Функтор (functor) --- это **модуль, параметризованный другим модулем**. Функтор принимает модуль как аргумент и возвращает новый модуль. Это аналог параметрического полиморфизма на уровне модулей.

### Пример: множество

Стандартная библиотека OCaml предоставляет функтор `Set.Make`:

```ocaml
module IntSet = Set.Make(Int)
```

`Int` --- модуль с типом `t = int` и функцией `compare`. `Set.Make` --- функтор, принимающий модуль с `compare` и создающий модуль множества:

```text
# let s = IntSet.of_list [3; 1; 4; 1; 5; 9; 2; 6];;
val s : IntSet.t = <abstr>

# IntSet.elements s;;
- : int list = [1; 2; 3; 4; 5; 6; 9]

# IntSet.mem 3 s;;
- : bool = true
```

### Создание функтора

Определим собственный функтор. Начнём с сигнатуры для сравнимых типов:

```ocaml
module type Comparable = sig
  type t
  val compare : t -> t -> int
end
```

Теперь функтор, создающий модуль множества на основе сортированного списка:

```ocaml
module MakeSet (Elt : Comparable) : sig
  type t
  val empty : t
  val add : Elt.t -> t -> t
  val mem : Elt.t -> t -> bool
  val elements : t -> Elt.t list
  val of_list : Elt.t list -> t
end = struct
  type t = Elt.t list

  let empty = []

  let rec add x = function
    | [] -> [x]
    | (y :: _) as lst when Elt.compare x y < 0 -> x :: lst
    | y :: rest when Elt.compare x y = 0 -> y :: rest
    | y :: rest -> y :: add x rest

  let rec mem x = function
    | [] -> false
    | y :: _ when Elt.compare x y = 0 -> true
    | y :: rest when Elt.compare x y > 0 -> mem x rest
    | _ -> false

  let elements s = s

  let of_list lst = List.fold_left (fun acc x -> add x acc) empty lst
end
```

Использование:

```ocaml
module StringSet = MakeSet(String)

let s = StringSet.of_list ["banana"; "apple"; "cherry"]
let _ = StringSet.mem "apple" s   (* true *)
let _ = StringSet.elements s      (* ["apple"; "banana"; "cherry"] *)
```

Функтор `MakeSet` принимает модуль с `Comparable` сигнатурой и создаёт специализированное множество.

```admonish tip title="Для TypeScript-разработчиков"
Функторы в OCaml --- это как generic-фабрики модулей. Если в TypeScript вы бы написали `function createSet<T extends Comparable<T>>(): SetModule<T>`, то в OCaml это `module MakeSet (Elt : Comparable) = struct ... end`. Функтор принимает не тип, а целый **модуль** с типами и функциями, и возвращает новый модуль. Это мощнее generics: параметром может быть не только тип, но и набор операций над ним.
```

### Функторы стандартной библиотеки

OCaml stdlib использует функторы повсеместно:

```ocaml
(* Множество *)
module IntSet = Set.Make(Int)
module StringSet = Set.Make(String)

(* Словарь (Map) *)
module IntMap = Map.Make(Int)
module StringMap = Map.Make(String)

(* Хэш-таблица *)
module IntTable = Hashtbl.Make(struct
  type t = int
  let equal = Int.equal
  let hash = Hashtbl.hash
end)
```

## Полугруппы и моноиды

Модульная система OCaml позволяет естественно выразить алгебраические абстракции. Две из самых полезных --- **полугруппа** (semigroup) и **моноид** (monoid).

### Полугруппа: тип с ассоциативной операцией

```ocaml
module type Semigroup = sig
  type t
  val combine : t -> t -> t
end
```

Полугруппа --- это тип `t` с операцией `combine`, которая ассоциативна: `combine (combine a b) c = combine a (combine b c)`. Примеры:

```ocaml
module IntSum : Semigroup with type t = int = struct
  type t = int
  let combine = ( + )
end

module IntProduct : Semigroup with type t = int = struct
  type t = int
  let combine = ( * )
end

module StringConcat : Semigroup with type t = string = struct
  type t = string
  let combine = ( ^ )
end
```

Обратите внимание: для `int` мы определили **два** модуля-полугруппы --- суммирование и умножение. В Haskell для этого потребовались бы newtype-обёртки (`Sum`, `Product`). В OCaml модули позволяют иметь несколько реализаций для одного типа без каких-либо обёрток.

### Моноид: полугруппа с нейтральным элементом

```ocaml
module type Monoid = sig
  include Semigroup
  val empty : t
end
```

Моноид расширяет полугруппу нейтральным элементом `empty`: `combine empty x = x` и `combine x empty = x`.

```ocaml
module IntSumMonoid : Monoid with type t = int = struct
  type t = int
  let combine = ( + )
  let empty = 0
end

module IntProductMonoid : Monoid with type t = int = struct
  type t = int
  let combine = ( * )
  let empty = 1
end

module StringMonoid : Monoid with type t = string = struct
  type t = string
  let combine = ( ^ )
  let empty = ""
end

module ListMonoid (A : sig type t end) : Monoid with type t = A.t list = struct
  type t = A.t list
  let combine = ( @ )
  let empty = []
end
```

### `concat_all` через first-class module

Моноид позволяет свернуть **любой** список значений в одно:

```ocaml
let concat_all (type a) (module M : Monoid with type t = a) (lst : a list) : a =
  List.fold_left M.combine M.empty lst
```

```text
# concat_all (module IntSumMonoid) [1; 2; 3; 4];;
- : int = 10

# concat_all (module IntProductMonoid) [1; 2; 3; 4];;
- : int = 24

# concat_all (module StringMonoid) ["hello"; " "; "world"];;
- : string = "hello world"
```

Одна функция `concat_all` работает с любым моноидом. Модуль передаётся как значение первого класса.

### `OptionMonoid` --- функтор: из Semigroup делаем Monoid

Из любой полугруппы можно построить моноид, обернув тип в `option`: нейтральный элемент --- `None`, а `combine` объединяет значения внутри `Some`:

```ocaml
module OptionMonoid (S : Semigroup) : Monoid with type t = S.t option = struct
  type t = S.t option
  let empty = None
  let combine a b =
    match a, b with
    | None, x | x, None -> x
    | Some x, Some y -> Some (S.combine x y)
end
```

```text
# module OptIntMax = OptionMonoid(struct
    type t = int
    let combine = max
  end);;

# OptIntMax.combine (Some 3) (Some 5);;
- : int option = Some 5

# OptIntMax.combine None (Some 5);;
- : int option = Some 5

# OptIntMax.empty;;
- : int option = None
```

Даже если `max` не имеет нейтрального элемента (наименьшего `int` не существует), `OptionMonoid` добавляет его через `None`.

### Сравнение с Haskell

В Haskell моноид --- это класс типов:

```haskell
-- Haskell
class Monoid a where
  mempty  :: a
  mappend :: a -> a -> a

-- Проблема: для int нужны newtype
newtype Sum = Sum Int
instance Monoid Sum where ...

newtype Product = Product Int
instance Monoid Product where ...
```

В OCaml модульный подход устраняет необходимость в newtype-обёртках. `IntSumMonoid` и `IntProductMonoid` --- это просто разные модули, оба с `type t = int`. Нет ограничения «один инстанс на тип».

## `open` и `include`

### `open`

`open` делает содержимое модуля доступным без квалификации:

```ocaml
let f () =
  let open List in
  [1; 2; 3] |> filter (fun x -> x > 1) |> map (fun x -> x * 2)
```

Локальный `let open M in ...` ограничивает область видимости. Глобальный `open M` в начале файла открывает модуль для всего файла. Используйте глобальный `open` осторожно --- он может вызвать конфликты имён.

### `include`

`include` копирует содержимое одного модуля в другой:

```ocaml
module ExtendedList = struct
  include List

  let sum lst = fold_left ( + ) 0 lst

  let mean lst =
    let n = length lst in
    if n = 0 then 0.0
    else float_of_int (sum lst) /. float_of_int n
end
```

`ExtendedList` содержит все функции `List` плюс `sum` и `mean`. Это удобно для расширения существующих модулей.

`include` работает и с сигнатурами:

```ocaml
module type Extended_comparable = sig
  include Comparable
  val equal : t -> t -> bool
  val min : t -> t -> t
end
```

## Модули первого класса

В OCaml модули можно использовать как **обычные значения** --- передавать в функции, возвращать из функций, хранить в структурах данных. Такие модули называются модулями первого класса (first-class modules).

### Упаковка и распаковка

```ocaml
(* Упаковка модуля в значение *)
let int_printable = (module IntPrintable : Printable with type t = int)

(* Распаковка значения обратно в модуль *)
let print_value (type a) (module P : Printable with type t = a) (x : a) =
  P.to_string x
```

```text
# print_value (module IntPrintable) 42;;
- : string = "42"
```

### Пример: полиморфная функция с модулем

```ocaml
module type Comparable = sig
  type t
  val compare : t -> t -> int
end

let max_element (type a) (module C : Comparable with type t = a) (lst : a list) =
  match lst with
  | [] -> None
  | x :: rest ->
    Some (List.fold_left (fun acc y ->
      if C.compare y acc > 0 then y else acc
    ) x rest)
```

```text
# max_element (module Int) [3; 1; 4; 1; 5];;
- : int option = Some 5

# max_element (module String) ["banana"; "apple"; "cherry"];;
- : string option = Some "cherry"
```

Функция `max_element` принимает модуль `Comparable` как значение и использует его для сравнения. Это аналог передачи словаря type class в Haskell, но явный.

```admonish tip title="Для Python-разработчиков"
Модули первого класса --- это как передача «стратегии» в функцию. В Python вы бы передали класс или объект с нужными методами: `def max_element(comparator, lst)`. В OCaml передаётся целый модуль: `max_element (module Int) [3; 1; 4]`. Преимущество --- типовая система OCaml гарантирует, что переданный модуль содержит все нужные операции. В Python ошибка «нет такого метода» обнаружится только в рантайме.
```

### Когда использовать модули первого класса

- Когда нужно выбрать реализацию **в рантайме**.
- Для хранения разных модулей в коллекции.
- Для конфигурируемых алгоритмов (выбор стратегии сортировки, хэширования и т.д.).

## Проект: библиотека хэширования

Модуль `lib/hashable.ml` демонстрирует функторный подход к хэшированию.

### Сигнатура

```ocaml
module type Hashable = sig
  type t
  val hash : t -> int
end
```

### Реализации

```ocaml
let combine h1 h2 = h1 * 31 + h2

module IntHash : Hashable with type t = int = struct
  type t = int
  let hash x = x
end

module StringHash : Hashable with type t = string = struct
  type t = string
  let hash s =
    String.fold_left (fun acc c -> combine acc (Char.code c)) 0 s
end

module PairHash (H1 : Hashable) (H2 : Hashable)
  : Hashable with type t = H1.t * H2.t = struct
  type t = H1.t * H2.t
  let hash (a, b) = combine (H1.hash a) (H2.hash b)
end
```

`PairHash` --- функтор с **двумя** параметрами. Он принимает два модуля `Hashable` и создаёт хэшируемый тип-пару.

### Функтор для HashSet

```ocaml
module MakeHashSet (H : Hashable) : sig
  type t
  val empty : t
  val add : H.t -> t -> t
  val mem : H.t -> t -> bool
  val to_list : t -> H.t list
end = struct
  let num_buckets = 16
  type t = H.t list array

  let empty = Array.make num_buckets []

  let bucket_index x = abs (H.hash x) mod num_buckets

  let add x s =
    let s' = Array.copy s in
    let i = bucket_index x in
    if not (List.mem x s'.(i)) then
      s'.(i) <- x :: s'.(i);
    s'

  let mem x s =
    List.mem x s.(bucket_index x)

  let to_list s =
    Array.to_list s |> List.concat
end
```

## Паттерн modules-as-types

В OCaml-сообществе существует устоявшаяся конвенция: основной тип модуля называется `t`. Это позволяет обращаться к типу как `Module.t`, что читается естественно и единообразно.

### Конвенция `type t`

```ocaml
(* Было *)
type entry = { name: string; address: string }
let make_entry ~name ~address = { name; address }

(* Стало *)
type t = { name: string; address: string }
let make ~name ~address = { name; address }
```

Функции тоже именуются без суффикса типа: `make` вместо `make_entry`, `pp` вместо `pp_entry`, `to_string` вместо `entry_to_string`. Поскольку функции находятся внутри модуля, квалификация `Entry.make`, `Entry.to_string` делает суффикс избыточным.

### `.mli` файлы и `private`

Для контроля конструирования значений используют `.mli`-файлы (интерфейсы модулей) с ключевым словом `private`:

```ocaml
(* user.ml *)
type t = { name: string; age: int }
let make ~name ~age =
  assert (age > 0);
  { name; age }

(* user.mli *)
type t = private { name: string; age: int }
val make : name:string -> age:int -> t
```

`private` позволяет читать поля (`user.name`), но запрещает конструирование напрямую --- только через `make`. Это обеспечивает инварианты (в данном случае `age > 0`) без потери удобства чтения полей.

## IO-агностичные библиотеки через функторы

### Проблема

Библиотека может зависеть от конкретной реализации IO: Lwt (асинхронный), Eio (эффект-ориентированный), синхронный stdlib. Привязка к одной реализации ограничивает переиспользование.

### Решение: абстрагировать IO через сигнатуру

```ocaml
module type IO = sig
  type +'a t
  val return : 'a -> 'a t
  val bind : 'a t -> ('a -> 'b t) -> 'b t
end
```

### Функтор, параметризованный IO

```ocaml
module Make_service (IO : IO) = struct
  open IO
  let process data =
    bind (return (String.uppercase_ascii data)) (fun upper ->
    return ("processed: " ^ upper))
end
```

Модуль `Make_service` не знает, какой IO используется --- синхронный, Lwt или Eio. Он работает с любой реализацией, удовлетворяющей сигнатуре `IO`.

### Инстанцирование для синхронного IO

```ocaml
module Sync_IO : IO with type 'a t = 'a = struct
  type 'a t = 'a
  let return x = x
  let bind x f = f x
end

module Sync_service = Make_service(Sync_IO)
let result = Sync_service.process "hello"
(* result = "processed: HELLO" *)
```

Синхронная реализация `Sync_IO` --- это тождественная монада: `type 'a t = 'a`, `return` --- это `id`, `bind` --- это применение функции. При подстановке `Sync_IO` весь монадический код сводится к обычным синхронным вызовам.

Этот паттерн широко используется в экосистеме OCaml для создания библиотек, совместимых с разными рантаймами.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Среднее)** Создайте модуль `IntSet` с сигнатурой `Set_intf`, реализующий множество целых чисел на основе сортированного списка.

    ```ocaml
    val int_set_empty : My_solutions.IntSet.t
    val int_set_add : int -> My_solutions.IntSet.t -> My_solutions.IntSet.t
    val int_set_mem : int -> My_solutions.IntSet.t -> bool
    val int_set_elements : My_solutions.IntSet.t -> int list
    ```

    *Подсказка:* добавление в сортированный список --- вставка на правильную позицию с помощью рекурсии.

2. **(Сложное)** Реализуйте функтор `MakeSet`, параметризованный модулем с сигнатурой `Comparable`, который создаёт множество.

    ```ocaml
    module MakeSet (Elt : Comparable) : sig
      type t
      val empty : t
      val add : Elt.t -> t -> t
      val mem : Elt.t -> t -> bool
      val elements : t -> Elt.t list
    end
    ```

    *Подсказка:* аналогично `IntSet`, но используйте `Elt.compare` вместо операторов `<` и `=`.

3. **(Среднее)** Реализуйте функцию `max_element`, которая принимает модуль `Comparable` как значение первого класса и находит максимальный элемент в списке.

    ```ocaml
    val max_element :
      (module Comparable with type t = 'a) -> 'a list -> 'a option
    ```

    *Подсказка:* используйте `(type a)` для введения локального абстрактного типа.

4. **(Среднее)** Реализуйте модуль `ExtendedIntSet`, который расширяет `IntSet` дополнительными операциями `size`, `union` и `inter`.

    ```ocaml
    val extended_int_set_size : My_solutions.ExtendedIntSet.t -> int
    val extended_int_set_union :
      My_solutions.ExtendedIntSet.t -> My_solutions.ExtendedIntSet.t -> My_solutions.ExtendedIntSet.t
    ```

    *Подсказка:* используйте `include` для включения `IntSet`.

5. **(Среднее)** Реализуйте полугруппу `First` --- `combine` всегда возвращает первый аргумент. Затем создайте `OptionMonoid(First)` и проверьте, что `concat_all` на списке `option` возвращает первый `Some`.

    ```ocaml
    module First : Semigroup with type t = string
    ```

    *Подсказка:* `let combine a _b = a`.

6. **(Среднее)** Реализуйте `concat_all` --- функцию, которая принимает модуль `Monoid` как значение первого класса и сворачивает список.

    ```ocaml
    val concat_all : (module Monoid with type t = 'a) -> 'a list -> 'a
    ```

    *Подсказка:* используйте `(type a)` и `List.fold_left`.

7. **(Сложное)** Custom Set --- реализуйте параметрический модуль множества `MakeCustomSet(Elt : ORDERED)` с операциями `empty`, `add`, `mem`, `remove`, `elements`, `size`, `union`, `inter`, `diff`, `is_empty`. Внутреннее представление --- отсортированный список.

    ```ocaml
    module type ORDERED = sig
      type t
      val compare : t -> t -> int
    end

    module MakeCustomSet (Elt : ORDERED) : sig
      type t
      type elt = Elt.t
      val empty : t
      val add : elt -> t -> t
      val mem : elt -> t -> bool
      val remove : elt -> t -> t
      val elements : t -> elt list
      val size : t -> int
      val union : t -> t -> t
      val inter : t -> t -> t
      val diff : t -> t -> t
      val is_empty : t -> bool
    end
    ```

    *Подсказка:* используйте отсортированный список как внутреннее представление. Операции `add`, `mem`, `remove` работают за O(n), `union`, `inter`, `diff` --- через свёртку.

## Заключение

В этой главе мы:

- Изучили модули --- основу организации кода в OCaml.
- Познакомились с сигнатурами и абстрактными типами для инкапсуляции.
- Разобрали функторы --- параметризованные модули, аналог generics на уровне модулей.
- Узнали о модулях первого класса --- передаче модулей как значений.
- Изучили полугруппы и моноиды --- алгебраические абстракции через модули.
- Научились использовать `open` и `include` для композиции модулей.
- Сравнили модульный подход OCaml с классами типов Haskell.

В следующей главе мы изучим обработку ошибок: типы `option` и `result`, let-операторы и паттерн накопления ошибок.
