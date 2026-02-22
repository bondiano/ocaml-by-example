# Проектирование через типы (Часть 2)

## Введение

Это вторая часть главы о проектировании через типы. В [первой части](chapter10a.md) мы изучили Smart Constructors, Make Illegal States Unrepresentable и Phantom Types — паттерны, которые используют систему типов для предотвращения ошибок на этапе компиляции.

В этой части мы рассмотрим:

- **Parse, Don't Validate** — паттерн, при котором парсинг данных сразу возвращает типизированную информацию, а не просто булев флаг валидности.
- **Практический проект** — типобезопасную платёжную систему, объединяющую все изученные техники.

Код проекта находится в той же директории `exercises/chapter10`.

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

Упражнения для всей главы (обе части) находятся в [части 1](chapter10a.md#упражнения). Код в `exercises/chapter10`.

## Заключение

В этой части главы мы рассмотрели:

- **Parse, Don't Validate** — данные преобразуются в типизированные значения на границе системы, избавляя внутренний код от повторных проверок.
- **Практический проект** — типобезопасная платёжная система, объединяющая все паттерны из обеих частей главы.

Вместе с [первой частью](chapter10a.md), где мы изучили Smart Constructors, Make Illegal States Unrepresentable и Phantom Types, мы получили полный набор техник проектирования через типы:

- **Smart constructors** — абстрактный тип + функция-валидатор. Единственный способ получить значение — пройти валидацию.
- **Make Illegal States Unrepresentable** — каждое состояние кодируется отдельным типом. Невалидные комбинации невозможны структурно.
- **Parse, Don't Validate** — парсинг данных возвращает типизированную информацию, а не булев флаг.
- **Phantom types** — пустые типы как метки для статической проверки протоколов использования.

Главный принцип: **переложить проверку инвариантов с программиста на компилятор**. Чем больше ошибок ловится на этапе компиляции, тем меньше тестов нужно для проверки «невозможных» состояний.

```admonish info title="Подробнее"
Подробное описание модульной системы OCaml и использования абстрактных типов для ограничения конструирования: [Real World OCaml, глава «Files, Modules, and Programs»](https://dev.realworldocaml.org/files-modules-and-programs.html).
```

В следующей главе — Expression Problem: классическая задача расширяемости типов и функций.
