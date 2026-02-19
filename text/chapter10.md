# Проектирование через типы

## Цели главы

Эта глава о **проектировании через типы** (type-driven design) — подходе, при котором система типов не только проверяет корректность, но и **предотвращает** некорректные состояния на уровне компиляции.

Темы главы:

- **Smart Constructors** (умные конструкторы) — ограничение конструирования значений через валидацию.
- **Make Illegal States Unrepresentable** — кодирование допустимых состояний в типах.
- **Parse, Don't Validate** — парсинг как способ получить типизированную информацию.
- **Phantom types** — типы-метки для статической проверки протоколов.
- Проект: типобезопасная платёжная система.

Если вы знакомы с Haskell, эти идеи покажутся знакомыми — `newtype` + smart constructors, Data.Refined, phantom types. В OCaml инструментарий другой (модули, `.mli`, `private`), но принципы те же.

## Подготовка проекта

Код этой главы находится в `exercises/chapter10`. Соберите проект:

```text
$ cd exercises/chapter10
$ dune build
```

## Smart Constructors (Умные конструкторы)

### Проблема: неограниченное конструирование

Предположим, мы моделируем денежную сумму:

```ocaml
type money = float
```

Ничто не мешает создать отрицательную сумму:

```ocaml
let price : money = -42.0   (* компилируется без ошибок! *)
```

Или email:

```ocaml
type email = string

let bad_email : email = "не-email"   (* тоже компилируется *)
```

Тип `string` не несёт информации о том, что значение прошло валидацию. Вызывающий код не знает, можно ли доверять этому значению.

В Haskell аналогичная проблема решается через `newtype` + модуль с ограниченным экспортом:

```haskell
-- Haskell
module Email (Email, mkEmail, unEmail) where

newtype Email = Email String

mkEmail :: String -> Maybe Email
mkEmail s
  | '@' `elem` s = Just (Email s)
  | otherwise     = Nothing

unEmail :: Email -> String
unEmail (Email s) = s
```

В OCaml мы используем **модули** и **абстрактные типы**.

### Решение: абстрактный тип + конструктор-валидатор

Идея: спрятать внутреннее представление типа и предоставить единственный способ создания значения — через функцию-валидатор.

```ocaml
module Email : sig
  type t
  val make : string -> (t, string) result
  val to_string : t -> string
end = struct
  type t = string

  let make s =
    if String.contains s '@' then Ok s
    else Error "email должен содержать @"

  let to_string t = t
end
```

Теперь единственный способ получить значение типа `Email.t` — вызвать `Email.make`, который проверяет формат:

```text
# Email.make "user@example.com";;
- : (Email.t, string) result = Ok <abstr>

# Email.make "invalid";;
- : (Email.t, string) result = Error "email должен содержать @"

# Email.to_string (Result.get_ok (Email.make "user@example.com"));;
- : string = "user@example.com"
```

Ключевой момент: тип `Email.t` **абстрактный** — снаружи модуля невозможно создать его напрямую, обойдя валидацию. Компилятор гарантирует, что если у вас есть значение типа `Email.t`, оно прошло проверку.

````admonish tip title="Для Python/TypeScript-разработчиков"
В Python и TypeScript для валидации часто используют библиотеки вроде **Pydantic** или **Zod**:

```python
# Python (Pydantic)
class Email(BaseModel):
    value: str

    @validator('value')
    def must_contain_at(cls, v):
        if '@' not in v:
            raise ValueError('email должен содержать @')
        return v
```

```typescript
// TypeScript (Zod)
const Email = z.string().email();
type Email = z.infer<typeof Email>;
```

Разница в том, что Pydantic и Zod проверяют данные **в рантайме** — ничто не мешает обойти валидацию, создав объект напрямую. В OCaml абстрактный тип `Email.t` делает обход **невозможным** на уровне компиляции: единственный путь получить `Email.t` — вызвать `Email.make`, который всегда проверяет формат.
````

### Примеры: Email, Money, NonEmptyList, PositiveInt

**Money — положительная денежная сумма:**

```ocaml
module Money : sig
  type t
  val make : float -> (t, string) result
  val amount : t -> float
  val add : t -> t -> t
  val to_string : t -> string
end = struct
  type t = float

  let make f =
    if f > 0.0 then Ok f
    else Error "сумма должна быть положительной"

  let amount t = t
  let add a b = a +. b

  let to_string t =
    Printf.sprintf "%.2f" t
end
```

```text
# Money.make 100.0;;
- : (Money.t, string) result = Ok <abstr>

# Money.make (-5.0);;
- : (Money.t, string) result = Error "сумма должна быть положительной"

# let m1 = Result.get_ok (Money.make 100.0);;
# let m2 = Result.get_ok (Money.make 50.0);;
# Money.to_string (Money.add m1 m2);;
- : string = "150.00"
```

**NonEmptyList — список, который гарантированно не пуст:**

```ocaml
module NonEmptyList : sig
  type 'a t
  val make : 'a list -> ('a t, string) result
  val of_pair : 'a -> 'a list -> 'a t
  val head : 'a t -> 'a          (* никогда не падает *)
  val tail : 'a t -> 'a list
  val to_list : 'a t -> 'a list
end = struct
  type 'a t = 'a * 'a list

  let make = function
    | [] -> Error "список не может быть пустым"
    | x :: xs -> Ok (x, xs)

  let of_pair x xs = (x, xs)
  let head (x, _) = x
  let tail (_, xs) = xs
  let to_list (x, xs) = x :: xs
end
```

Внутреннее представление `'a * 'a list` — пара из первого элемента и оставшихся. Это гарантирует непустоту: чтобы создать значение типа `'a t`, нужно иметь хотя бы один элемент. Обратите внимание: `head` и `tail` **не могут** завершиться ошибкой. Тип `'a t` гарантирует, что в списке есть хотя бы один элемент. Это пример того, как тип кодирует инварианты данных.

**PositiveInt — строго положительное целое число:**

```ocaml
module PositiveInt : sig
  type t
  val make : int -> (t, string) result
  val value : t -> int
  val add : t -> t -> t
end = struct
  type t = int

  let make n =
    if n > 0 then Ok n
    else Error "число должно быть положительным"

  let value t = t
  let add a b = a + b
end
```

### `.mli` и `private` — альтернативный подход

В OCaml есть ещё один способ ограничить конструирование — ключевое слово `private` в `.mli`-файлах.

`money.mli`:

```ocaml
type t = private float

val make : float -> (t, string) result
val add : t -> t -> t
val to_string : t -> string
```

`money.ml`:

```ocaml
type t = float

let make f =
  if f > 0.0 then Ok f
  else Error "сумма должна быть положительной"

let add a b = a +. b
let to_string t = Printf.sprintf "%.2f" t
```

Ключевое слово `private` означает: тип виден снаружи (его можно использовать в pattern matching), но конструировать напрямую нельзя:

```text
# let m = Result.get_ok (Money.make 100.0);;

(* Pattern matching работает: *)
# let (f : float) = (m :> float);;
val f : float = 100.

(* Но прямое создание запрещено: *)
# let bad : Money.t = 42.0;;
Error: This expression has type float but an expression of type
       Money.t was expected
```

Синтаксис `(m :> float)` — это явное приведение типа (coercion): извлечь внутренний `float` из `private`-типа. С полностью абстрактным типом такое приведение было бы ошибкой компиляции. Прямое же присвоение `42.0 : Money.t` запрещено — нельзя обойти `make`.

Сравнение подходов:

| Аспект | Абстрактный тип (`type t`) | `private` |
|--------|---------------------------|-----------|
| Видимость представления | Полностью скрыто | Видно, но read-only |
| Pattern matching | Невозможен | Возможен |
| Coercion (`t :> base`) | Невозможен | Возможен |
| Подходит для | Полная инкапсуляция | Типы, где matching полезен |

Для большинства smart constructors лучше использовать полностью абстрактный тип — он даёт максимальную защиту. `private` удобен, когда нужно деструктурировать значение без вызова функции-аксессора.

## Make Illegal States Unrepresentable

### Проблема: булевы флаги и невозможные состояния

Рассмотрим модель заказа в интернет-магазине:

```ocaml
type order = {
  id : int;
  items : string list;
  is_submitted : bool;
  is_paid : bool;
  is_shipped : bool;
  payment_id : string option;
  tracking_number : string option;
}
```

Эта модель допускает **невозможные состояния**:

```ocaml
(* Отправлен, но не оплачен? *)
let bad1 = {
  id = 1; items = ["книга"];
  is_submitted = true; is_paid = false; is_shipped = true;
  payment_id = None; tracking_number = Some "TRACK123";
}

(* Не отправлен, но есть tracking number? *)
let bad2 = {
  id = 2; items = ["ручка"];
  is_submitted = true; is_paid = true; is_shipped = false;
  payment_id = Some "PAY456"; tracking_number = Some "TRACK789";
}
```

Булевы флаги создают 2^3 = 8 комбинаций, из которых допустимы только 4. Программист должен **помнить** инварианты, и компилятор ему не поможет.

В Haskell эту проблему решают через алгебраические типы данных (ADT). В OCaml — точно так же.

### Решение: кодирование состояний в типах

Вместо булевых флагов зададим каждое состояние как отдельный вариант:

```ocaml
type draft = {
  id : int;
  items : string list;
}

type submitted = {
  id : int;
  items : string list;
  submitted_at : float;
}

type paid = {
  id : int;
  items : string list;
  submitted_at : float;
  payment_id : string;
}

type shipped = {
  id : int;
  items : string list;
  submitted_at : float;
  payment_id : string;
  tracking_number : string;
}

type order =
  | Draft of draft
  | Submitted of submitted
  | Paid of paid
  | Shipped of shipped
```

Теперь невозможно создать заказ с `tracking_number`, но без `payment_id` — тип `shipped` требует оба поля. Каждый переход между состояниями — отдельная функция:

```ocaml
let submit (d : draft) ~submitted_at : submitted =
  { id = d.id; items = d.items; submitted_at }

let pay (s : submitted) ~payment_id : paid =
  { id = s.id; items = s.items;
    submitted_at = s.submitted_at; payment_id }

let ship (p : paid) ~tracking_number : shipped =
  { id = p.id; items = p.items;
    submitted_at = p.submitted_at;
    payment_id = p.payment_id; tracking_number }
```

Попытка нарушить порядок — ошибка компиляции:

```text
# let d = { id = 1; items = ["книга"] };;
# ship d ~tracking_number:"T123";;
Error: This expression has type draft
       but an expression of type paid was expected
```

````admonish tip title="Для Python/TypeScript-разработчиков"
В Python конечные автоматы обычно реализуют через строковые статусы и проверки в рантайме:

```python
class Order:
    def ship(self):
        if self.status != "paid":
            raise ValueError("Cannot ship unpaid order")
        self.status = "shipped"
```

В TypeScript можно использовать дискриминированные объединения (discriminated unions) для аналогичного подхода:

```typescript
type Order =
  | { status: "draft"; items: string[] }
  | { status: "paid"; items: string[]; paymentId: string }
  | { status: "shipped"; items: string[]; trackingNumber: string }
```

TypeScript-вариант ближе к OCaml, но не запрещает создание некорректных значений напрямую. В OCaml каждое состояние — отдельный тип, и функция `ship` физически не может принять неоплаченный заказ — это ошибка **компиляции**, а не рантайма.
````

### Пример: конечный автомат для заказа (Draft -> Submitted -> Paid -> Shipped)

Объединим всё в модуль:

```ocaml
module Order : sig
  type draft
  type submitted
  type paid
  type shipped
  type t = Draft of draft | Submitted of submitted
         | Paid of paid | Shipped of shipped

  val create : items:string list -> draft
  val submit : draft -> submitted
  val pay : submitted -> payment_id:string -> paid
  val ship : paid -> tracking_number:string -> shipped

  val to_order : draft -> t
  val items : t -> string list
end = struct
  type draft = { id : int; items : string list }
  type submitted = { id : int; items : string list; submitted_at : float }
  type paid = { id : int; items : string list; submitted_at : float;
                payment_id : string }
  type shipped = { id : int; items : string list; submitted_at : float;
                   payment_id : string; tracking_number : string }
  type t = Draft of draft | Submitted of submitted
         | Paid of paid | Shipped of shipped

  let next_id = ref 0
  let fresh_id () = incr next_id; !next_id

  let create ~items = { id = fresh_id (); items }

  let submit d =
    { id = d.id; items = d.items;
      submitted_at = Unix.gettimeofday () }

  let pay s ~payment_id =
    { id = s.id; items = s.items;
      submitted_at = s.submitted_at; payment_id }

  let ship p ~tracking_number =
    { id = p.id; items = p.items;
      submitted_at = p.submitted_at;
      payment_id = p.payment_id; tracking_number }

  let to_order d = Draft d

  let items = function
    | Draft d -> d.items
    | Submitted s -> s.items
    | Paid p -> p.items
    | Shipped s -> s.items
end
```

Такая модель — конечный автомат (finite state machine, FSM), где переходы между состояниями проверяются компилятором. Невозможно:

- Оплатить неотправленный заказ (`pay` принимает только `submitted`).
- Отправить неоплаченный заказ (`ship` принимает только `paid`).
- Вернуться в предыдущее состояние (нет функции `unpay` или `unship`).

### Phantom types для маркировки

**Phantom types** (типы-фантомы) — типовые параметры, которые не используются в представлении данных, но участвуют в проверке типов. Они позволяют «помечать» значения на уровне типов.

В Haskell phantom types — известный паттерн:

```haskell
-- Haskell
newtype Tagged tag a = Tagged a

data Open
data Closed

type Handle tag = Tagged tag FileHandle

open :: FilePath -> IO (Handle Open)
close :: Handle Open -> IO (Handle Closed)
read :: Handle Open -> IO String   — нельзя читать закрытый!
```

В OCaml phantom types работают аналогично:

```ocaml
type draft_state
type submitted_state
type paid_state
type shipped_state

type 'state order = {
  id : int;
  items : string list;
  data : string;   (* различные данные в зависимости от состояния *)
}
```

Типы `draft_state`, `submitted_state` и т.д. — **пустые** (у них нет конструкторов). Их единственная роль — быть метками в параметре `'state`.

```ocaml
let create ~items : draft_state order =
  { id = 0; items; data = "" }

let submit (o : draft_state order) : submitted_state order =
  { id = o.id; items = o.items; data = "submitted" }

let pay (o : submitted_state order) ~payment_id : paid_state order =
  { id = o.id; items = o.items; data = payment_id }

let ship (o : paid_state order) ~tracking : shipped_state order =
  { id = o.id; items = o.items; data = tracking }
```

Обратите внимание: все четыре функции возвращают значения одного и того же типа `'state order` (одна запись с одинаковыми полями), но с **разным** параметром `'state`. Сам параметр нигде не используется в данных — он существует только для проверки типов. Компилятор проверяет порядок переходов:

```text
# let o = create ~items:["книга"];;
val o : draft_state order = ...

# let o = submit o;;
val o : submitted_state order = ...

# ship o ~tracking:"T123";;
Error: This expression has type submitted_state order
       but an expression of type paid_state order was expected
```

Phantom types особенно полезны, когда:

- Все состояния имеют **одинаковое** представление (один тип записи).
- Нужно «пометить» значение, не меняя его структуру.
- Нужно обеспечить протокол использования (open/close, lock/unlock, connect/disconnect).

Для заказа с **разными** данными в каждом состоянии (как `payment_id`, `tracking_number`) лучше подходят отдельные типы или GADT.

````admonish tip title="Для TypeScript-разработчиков"
TypeScript поддерживает «брендированные типы» (branded types) — аналог phantom types:

```typescript
type Brand<T, B> = T & { __brand: B };
type USD = Brand<number, "USD">;
type EUR = Brand<number, "EUR">;

function addUSD(a: USD, b: USD): USD {
  return (a + b) as USD;
}

// addUSD(usd, eur) — ошибка TypeScript!
```

Идея та же: параметр-метка (`__brand`) не существует в рантайме, но TypeScript проверяет его на этапе компиляции. В OCaml phantom types реализуются через пустые типы (`type usd` без конструкторов) в параметрах типа.
````

## Parse, Don't Validate

### Проблема: валидация возвращает `bool`, теряет информацию

Рассмотрим типичную валидацию:

```ocaml
let is_valid_email (s : string) : bool =
  String.contains s '@'

let is_non_empty (s : string) : bool =
  String.length s > 0

let is_positive (n : int) : bool =
  n > 0
```

Эти функции проверяют данные, но **не сохраняют результат проверки** в типе. После вызова `is_valid_email` у нас по-прежнему `string` — и ничто не мешает передать невалидный `string` в код, ожидающий валидный email:

```ocaml
let send_email (email : string) =
  (* Надеемся, что email валидный... *)
  Printf.printf "Отправляем на %s\n" email

let process input =
  if is_valid_email input then
    send_email input   (* Ok, но... *)
  else
    print_endline "Невалидный email"

(* Ничто не мешает вызвать напрямую: *)
let () = send_email "это-не-email"   (* Компилируется! *)
```

Валидация через `bool` создаёт **зазор** между проверкой и использованием. Проверка выполняется в одном месте, а использование — в другом, и между ними нет связи на уровне типов.

### Решение: парсинг возвращает типизированное значение

Вместо валидации (возвращает `bool`) используйте **парсинг** (возвращает типизированное значение):

```ocaml
(* Валидация — теряет информацию *)
val is_valid_email : string -> bool

(* Парсинг — сохраняет информацию в типе *)
val parse_email : string -> (Email.t, string) result
```

Парсинг преобразует «сырые» данные (`string`, `int`, `Yojson.Safe.t`) в **типизированные** значения (`Email.t`, `Money.t`, `Config.t`). Если преобразование невозможно — возвращает ошибку.

```ocaml
module Email : sig
  type t
  val parse : string -> (t, string) result
  val to_string : t -> string
end = struct
  type t = string

  let parse s =
    if String.length s = 0 then Error "email не может быть пустым"
    else if not (String.contains s '@') then Error "email должен содержать @"
    else
      let parts = String.split_on_char '@' s in
      match parts with
      | [_local; domain] when String.contains domain '.' -> Ok s
      | _ -> Error "некорректный формат email"

  let to_string t = t
end
```

Функция `parse` проверяет три условия последовательно: непустота, наличие `@`, наличие `.` в домене. Паттерн `[_local; domain]` совпадает только если `@` ровно одна — при двух `@` список имел бы три элемента и попал в ветку `_`.

Теперь `send_email` принимает `Email.t`, а не `string`:

```ocaml
let send_email (email : Email.t) =
  Printf.printf "Отправляем на %s\n" (Email.to_string email)

let process input =
  match Email.parse input with
  | Ok email -> send_email email   (* Гарантированно валидный *)
  | Error msg -> Printf.printf "Ошибка: %s\n" msg

(* Невозможно вызвать с невалидным значением: *)
(* send_email "это-не-email"  — ошибка компиляции! *)
```

### Связь с предыдущими паттернами

«Parse, Don't Validate» — это **обобщение** smart constructors и «Make Illegal States Unrepresentable»:

1. **Smart constructors** — парсинг примитивного значения в доменный тип: `string -> Email.t`, `float -> Money.t`.
2. **Make Illegal States Unrepresentable** — парсинг набора данных в допустимое состояние: вместо `{is_paid: bool; payment_id: string option}` создаём тип `Paid of {payment_id: string}`.
3. **Parse, Don't Validate** — философия: каждая граница системы (ввод пользователя, API, конфиг) — это точка парсинга. Внутри системы работаем только с типизированными значениями.

Вот ключевая идея: **парсинг выполняется один раз** на границе системы. После этого все функции работают с типизированными данными и не нуждаются в повторной валидации. Тип сам по себе является доказательством валидности.

### Границы программы и границы системы

Принцип «Parse, Don't Validate» — мощный инструмент для отдельной программы. Но в реальном продакшене программа — лишь один артефакт из многих. Статья Иана Данкана [*«What Functional Programmers Get Wrong About Systems»*](https://www.iankduncan.com/engineering/2026-02-09-what-functional-programmers-get-wrong-about-systems) (2026) формулирует проблему резко:

> *«Единица корректности в продакшене — не программа, а набор деплоев.»*

Система типов проверяет свойства **одного артефакта**. Но в продакшене одновременно работают **несколько версий** вашего кода. Разрыв между этими двумя мирами — источник реальных ошибок.

**Проблема 1: несколько версий сосуществуют.** Деплой никогда не заменяет код атомарно. Во время rolling deploy старые и новые воркеры обрабатывают запросы одновременно. Представьте, что вы добавляете новый вариант в тип:

```ocaml
(* v1 *)
type payment_status = Pending | Completed | Failed

(* v2 — добавили Refunded *)
type payment_status = Pending | Completed | Failed | Refunded
```

На несколько минут старые воркеры будут получать сообщения с `Refunded` — и не будут знать, что с ними делать. Типы гарантируют корректность **внутри** каждой версии, но **между версиями** нет проверки.

**Проблема 2: сериализованные данные переживают код.** Очередь сообщений (Kafka, RabbitMQ) — это «капсула времени для версий». Если Kafka хранит сообщения 30 дней, вы должны уметь десериализовать **30 разных форматов** одновременно. `parse` в «Parse, Don't Validate» работает на входе в программу, но что именно он парсит — может оказаться артефактом давно откачанной версии.

**Проблема 3: семантический дрейф обходит систему типов.** Самый коварный случай — когда тип не меняется, но **смысл** значения меняется:

```ocaml
(* v1: amount — центы *)
type payment = { amount : int; currency : string }

(* v2: amount — доллары *)
type payment = { amount : int; currency : string }
```

Тип идентичен. Парсер пропустит оба формата. Но значение отличается в 100 раз. Никакой type checker этого не поймает.

#### Как расширить «Parse, Don't Validate» на уровень системы

Данкан не отвергает принцип — он показывает, что его нужно **расширить** за пределы одного артефакта:

1. **Версионируйте сериализованные данные.** Каждое сообщение, API-ответ и миграция базы несёт неявный версионный контракт. Делайте его **явным** — используйте schema ID, теги версий, маркеры формата. Реестры схем (Confluent Schema Registry, Buf для Protobuf) реализуют «parse, don't validate» **на границе между версиями**, а не только на границе одной программы.

2. **Используйте паттерн expand-and-contract для миграций.** Код можно откатить, но схему базы данных — нет. «Однонаправленная трещотка миграции» означает, что откат на старый код с новой схемой создаёт непротестированное состояние. Четырёхшаговый процесс:
   - Добавить nullable колонку (expand).
   - Записывать в оба формата.
   - Бэкфиллить старые данные.
   - Удалить старую колонку (contract).

3. **Проверяйте совместимость на этапе деплоя, а не в рантайме.** GraphQL operations checks сравнивают предложенные изменения схемы с реальными клиентскими запросами **до** деплоя. Это переносит проверку совместимости из рантайма на этап сборки — тот же принцип, что «Parse, Don't Validate», но на уровне всей системы.

#### Практическое правило

Разделяйте мир на три зоны:

| Зона | Стратегия | Инструмент |
|------|-----------|------------|
| **Внутри программы** | Parse, Don't Validate | Система типов OCaml, smart constructors |
| **Между версиями одного сервиса** | Версионированные схемы, совместимость | Protobuf/schema registry, expand-and-contract |
| **Между разными сервисами** | Контрактное тестирование, API-версионирование | GraphQL operations checks, Pact, API gateways |

Внутри программы тип — это доказательство. На границе между версиями тип — это **контракт**, который нуждается в явной проверке совместимости. «Parse, Don't Validate» остаётся верным принципом — но его юрисдикция заканчивается на границе одного артефакта, а продакшен — это ансамбль артефактов разных поколений.

## Проект: типобезопасная платёжная система

Модуль `lib/payment.ml` объединяет все паттерны главы в одном проекте — типобезопасной платёжной системе.

### Money — smart constructor

```ocaml
module Money : sig
  type t
  val make : float -> (t, string) result
  val amount : t -> float
  val add : t -> t -> t
  val to_string : t -> string
end = struct
  type t = float

  let make f =
    if f > 0.0 then Ok f
    else Error "сумма должна быть положительной"

  let amount t = t
  let add a b = a +. b
  let to_string t = Printf.sprintf "%.2f" t
end
```

### CardNumber — smart constructor

```ocaml
module CardNumber : sig
  type t
  val make : string -> (t, string) result
  val to_masked : t -> string
  val to_string : t -> string
end = struct
  type t = string

  let make s =
    let digits = String.to_seq s
      |> Seq.filter (fun c -> c <> ' ' && c <> '-')
      |> String.of_seq
    in
    if String.length digits <> 16 then
      Error "номер карты должен содержать 16 цифр"
    else if not (String.for_all (fun c -> c >= '0' && c <= '9') digits) then
      Error "номер карты должен содержать только цифры"
    else
      Ok digits

  let to_masked t =
    let len = String.length t in
    String.init len (fun i ->
      if i < len - 4 then '*' else t.[i])

  let to_string t = t
end
```

```text
# CardNumber.make "4111 1111 1111 1111";;
- : (CardNumber.t, string) result = Ok <abstr>

# CardNumber.make "123";;
- : (CardNumber.t, string) result = Error "номер карты должен содержать 16 цифр"

# let card = Result.get_ok (CardNumber.make "4111111111111111");;
# CardNumber.to_masked card;;
- : string = "************1111"
```

### PaymentState — конечный автомат

```ocaml
module PaymentState : sig
  type draft
  type submitted
  type paid
  type shipped

  type 'state payment

  val create : amount:Money.t -> string -> draft payment
  val submit : draft payment -> card:CardNumber.t -> submitted payment
  val pay : submitted payment -> transaction_id:string -> paid payment
  val ship : paid payment -> tracking:string -> shipped payment

  val amount : 'state payment -> Money.t
  val description : 'state payment -> string
end = struct
  type draft
  type submitted
  type paid
  type shipped

  type 'state payment = {
    amount : Money.t;
    description : string;
    data : string;
  }

  let create ~amount description =
    { amount; description; data = "" }

  let submit p ~card =
    { amount = p.amount;
      description = p.description;
      data = CardNumber.to_masked card }

  let pay p ~transaction_id =
    { amount = p.amount;
      description = p.description;
      data = transaction_id }

  let ship p ~tracking =
    { amount = p.amount;
      description = p.description;
      data = tracking }

  let amount p = p.amount
  let description p = p.description
end
```

Используем всю систему вместе:

```ocaml
let process_payment () =
  let ( let* ) = Result.bind in
  let* amount = Money.make 99.99 in
  let* card = CardNumber.make "4111 1111 1111 1111" in

  let payment = PaymentState.create ~amount "Книга по OCaml" in
  let payment = PaymentState.submit payment ~card in
  let payment = PaymentState.pay payment ~transaction_id:"TXN-001" in
  let payment = PaymentState.ship payment ~tracking:"TRACK-42" in

  Ok (Printf.sprintf "Оплата %s за '%s' отправлена"
    (Money.to_string (PaymentState.amount payment))
    (PaymentState.description payment))
```

Здесь `let ( let* ) = Result.bind` вводит оператор монадического связывания. Строки `let* amount = Money.make 99.99 in` означают: если `Money.make` вернул `Ok v`, присвоить `v` переменной `amount` и продолжить; если `Error e` — немедленно вернуть `Error e` из всей функции. Это позволяет писать цепочки операций, возвращающих `result`, без вложенных `match`.

```text
# process_payment ();;
- : (string, string) result =
Ok "Оплата 99.99 за 'Книга по OCaml' отправлена"
```

Попытка нарушить порядок — ошибка компиляции:

```text
# let p = PaymentState.create ~amount "test" in
  PaymentState.ship p ~tracking:"T";;
Error: This expression has type draft payment
       but an expression of type paid payment was expected
```

Вся система типобезопасна:

- `Money.t` гарантирует положительную сумму.
- `CardNumber.t` гарантирует 16 цифр.
- Phantom types в `PaymentState` гарантируют порядок переходов.

## Упражнения

Решения пишите в `test/my_solutions.ml`. Проверяйте: `dune runtest`.

1. **(Лёгкое)** Реализуйте модуль `PositiveInt` — smart constructor для строго положительных целых чисел.

    ```ocaml
    module PositiveInt : sig
      type t
      val make : int -> (t, string) result
      val value : t -> int
      val add : t -> t -> t
      val to_string : t -> string
    end
    ```

    `make n` возвращает `Ok`, если `n > 0`, иначе `Error "число должно быть положительным"`. `add` складывает два значения.

2. **(Среднее)** Реализуйте модуль `Email` — smart constructor для email-адресов.

    ```ocaml
    module Email : sig
      type t
      val make : string -> (t, string) result
      val to_string : t -> string
    end
    ```

    Валидация: строка не пуста, содержит `@`, домен (часть после `@`) содержит `.`. `make "" -> Error "email не может быть пустым"`. `make "user" -> Error "email должен содержать @"`. `make "user@host" -> Error "некорректный домен"`. `make "user@host.com" -> Ok <email>`.

3. **(Среднее)** Реализуйте модуль `NonEmptyList` — список, гарантированно содержащий хотя бы один элемент.

    ```ocaml
    module NonEmptyList : sig
      type 'a t
      val make : 'a list -> ('a t, string) result
      val singleton : 'a -> 'a t
      val head : 'a t -> 'a
      val tail : 'a t -> 'a list
      val to_list : 'a t -> 'a list
      val length : 'a t -> int
      val map : ('a -> 'b) -> 'a t -> 'b t
    end
    ```

    Ключевое свойство: `head` и `tail` **не могут** завершиться ошибкой. `make [] -> Error`, `make [1;2;3] -> Ok`, `head -> 'a` (не `'a option`!).

    *Подсказка:* внутреннее представление — пара `'a * 'a list`.

4. **(Среднее)** Смоделируйте светофор как конечный автомат с phantom types.

    ```ocaml
    module TrafficLight : sig
      type red
      type yellow
      type green

      type 'state light

      val start : red light
      val red_to_green : red light -> green light
      val green_to_yellow : green light -> yellow light
      val yellow_to_red : yellow light -> red light
      val show : 'state light -> string
    end
    ```

    Порядок переходов: Red -> Green -> Yellow -> Red -> ... Попытка вызвать `green_to_yellow` на `red light` должна быть ошибкой компиляции.

5. **(Сложное)** Реализуйте модуль `Form` — строитель формы с накоплением ошибок.

    ```ocaml
    module Form : sig
      type 'a validated
      val field : string -> string -> (string -> ('a, string) result) -> 'a validated
      val map2 : ('a -> 'b -> 'c) -> 'a validated -> 'b validated -> 'c validated
      val map3 : ('a -> 'b -> 'c -> 'd) ->
        'a validated -> 'b validated -> 'c validated -> 'd validated
      val run : 'a validated -> ('a, (string * string) list) result
    end
    ```

    `field name raw_value parser` — создаёт валидированное поле. `map2 f a b` — комбинирует два поля, накапливая ошибки. `run` — возвращает результат или список пар `(имя_поля, ошибка)`.

    Пример:

    ```ocaml
    type user = { name : string; age : int }

    let parse_name s =
      if String.length s > 0 then Ok s
      else Error "не может быть пустым"

    let parse_age s =
      match int_of_string_opt s with
      | Some n when n > 0 -> Ok n
      | _ -> Error "должен быть положительным числом"

    let validate name_str age_str =
      let open Form in
      run (map2
        (fun name age -> { name; age })
        (field "имя" name_str parse_name)
        (field "возраст" age_str parse_age))
    ```

    *Подсказка:* внутреннее представление `'a validated = ('a, (string * string) list) result`.

6. **(Сложное)** Реализуйте модуль `FileHandle` — API для работы с «файлами», где чтение и запись возможны только для открытых дескрипторов. Используйте phantom types.

    ```ocaml
    module FileHandle : sig
      type opened
      type closed

      type 'state handle

      val open_file : string -> opened handle
      val read : opened handle -> string
      val write : opened handle -> string -> opened handle
      val close : opened handle -> closed handle
      val name : 'state handle -> string
    end
    ```

    Ключевое свойство: `read` и `write` принимают **только** `opened handle`. Попытка прочитать из закрытого дескриптора — ошибка компиляции. `close` возвращает `closed handle`, по которому уже нельзя вызвать `read`/`write`.

    *Подсказка:* внутреннее представление — запись `{ name: string; content: string }`. Реальный файловый ввод-вывод не нужен — эмулируйте работу со строками в памяти.

## Заключение

В этой главе:

- **Smart constructors** — абстрактный тип + функция-валидатор. Единственный способ получить значение — пройти валидацию.
- **Make Illegal States Unrepresentable** — каждое состояние кодируется отдельным типом. Невалидные комбинации невозможны структурно.
- **Parse, Don't Validate** — данные преобразуются в типизированные значения на границе системы. Внутри системы повторная проверка не нужна.
- **Phantom types** — пустые типы как метки для статической проверки протоколов использования.
- Все паттерны объединены в типобезопасной платёжной системе.

Главный принцип: **переложить проверку инвариантов с программиста на компилятор**. Чем больше ошибок ловится на этапе компиляции, тем меньше тестов нужно для проверки «невозможных» состояний.

```admonish info title="Подробнее"
Подробное описание модульной системы OCaml и использования абстрактных типов для ограничения конструирования: [Real World OCaml, глава «Files, Modules, and Programs»](https://dev.realworldocaml.org/files-modules-and-programs.html).
```

В следующей главе — Expression Problem: классическая задача расширяемости типов и функций.
