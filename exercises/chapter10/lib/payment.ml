(** Типобезопасная платёжная система.
    Демонстрация паттернов: smart constructors, phantom types, FSM. *)

(** Money --- положительная денежная сумма (smart constructor). *)
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

(** CardNumber --- номер банковской карты (smart constructor, 16 цифр). *)
module CardNumber : sig
  type t

  val make : string -> (t, string) result
  val to_masked : t -> string
  val to_string : t -> string
end = struct
  type t = string

  let make s =
    let digits =
      String.to_seq s
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

(** PaymentState --- конечный автомат платежа с phantom types.

    Порядок переходов:
    Draft -> Submitted -> Paid -> Shipped

    Каждый переход принимает платёж в определённом состоянии
    и возвращает платёж в следующем. Нарушение порядка ---
    ошибка компиляции. *)
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
  val state_name : 'state payment -> string
end = struct
  type draft
  type submitted
  type paid
  type shipped

  type 'state payment = {
    amount : Money.t;
    description : string;
    state_name : string;
    data : string;
  }

  let create ~amount description =
    { amount; description; state_name = "draft"; data = "" }

  let submit p ~card =
    { amount = p.amount;
      description = p.description;
      state_name = "submitted";
      data = CardNumber.to_masked card }

  let pay p ~transaction_id =
    { amount = p.amount;
      description = p.description;
      state_name = "paid";
      data = transaction_id }

  let ship p ~tracking =
    { amount = p.amount;
      description = p.description;
      state_name = "shipped";
      data = tracking }

  let amount p = p.amount
  let description p = p.description
  let state_name p = p.state_name
end
