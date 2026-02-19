/* stubs.c --- Примеры C-стабов для OCaml FFI.
 *
 * Каждая функция демонстрирует конкретный аспект OCaml C API:
 *   caml_count_char   — работа со строками (String_val, caml_string_length)
 *   caml_str_repeat   — выделение памяти  (caml_alloc_string, CAMLlocal1)
 *   caml_sum_int_array — работа с массивами (Field, Wosize_val)
 *
 * Чтобы использовать OCaml C API, нужны три заголовочных файла:
 *
 *   caml/mlvalues.h  — тип value и макросы преобразования (Int_val, Val_int,
 *                       String_val, Field, Wosize_val …)
 *   caml/memory.h    — макросы безопасности GC (CAMLparam*, CAMLreturn,
 *                       CAMLlocal*)
 *   caml/alloc.h     — функции выделения памяти в куче OCaml
 *                       (caml_alloc_string, caml_alloc_tuple …)
 *
 * Все функции-стабы должны иметь сигнатуру:
 *   CAMLprim value имя_функции(value arg1, value arg2, …)
 */

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <string.h>

/* ==========================================================================
 * caml_count_char : string -> char -> int
 *
 * Подсчитывает, сколько раз символ [ch] встречается в строке [str].
 *
 * Ключевые элементы:
 *
 *   CAMLparam2(str, ch)
 *     Регистрирует аргументы [str] и [ch] как GC-корни.
 *     Правило: вызывайте CAMLparam* для КАЖДОГО аргумента типа value.
 *     Если не зарегистрировать аргументы и произойдёт аллокация (GC-цикл),
 *     GC может переместить объекты, а сохранённые указатели станут
 *     недействительными.
 *
 *   String_val(str)
 *     Возвращает const char* — указатель на байты OCaml-строки.
 *     ВАЖНО: не сохраняйте этот указатель через вызовы аллокации — GC
 *     может переместить строку. Всегда берите String_val заново после
 *     любой аллокации.
 *
 *   caml_string_length(str)
 *     Длина строки в байтах. OCaml-строки не нуль-терминированы,
 *     поэтому нельзя использовать strlen().
 *
 *   Int_val(ch)
 *     OCaml char хранится как тегированный int (так же как int).
 *     Int_val снимает тег и возвращает C intnat.
 *
 *   Val_int(n)
 *     Превращает C intnat в OCaml int (устанавливает тег).
 *
 *   CAMLreturn(expr)
 *     Аналог return, но предварительно снимает GC-корни, зарегистрированные
 *     CAMLparam*. Всегда используйте CAMLreturn вместо return.
 * ========================================================================== */
CAMLprim value caml_count_char(value str, value ch) {
  CAMLparam2(str, ch);
  const char *s    = String_val(str);
  mlsize_t    len  = caml_string_length(str);
  char        want = (char)Int_val(ch);   /* OCaml char == int под капотом */
  int         cnt  = 0;
  for (mlsize_t i = 0; i < len; i++)
    if (s[i] == want) cnt++;
  CAMLreturn(Val_int(cnt));
}

/* ==========================================================================
 * caml_str_repeat : string -> int -> string
 *
 * Возвращает новую строку: [str] повторённую [n] раз подряд.
 *
 * Новые концепции:
 *
 *   CAMLlocal1(result)
 *     Объявляет локальную переменную типа value, зарегистрированную как
 *     GC-корень. Используйте CAMLlocal* для любых локальных value-переменных,
 *     которые вы аллоцируете. Если не зарегистрировать — GC может
 *     собрать объект, пока вы ещё с ним работаете.
 *
 *   caml_alloc_string(len)
 *     Выделяет новую OCaml-строку (Bytes) длиной [len] байт.
 *     После вызова GC мог запуститься — все ранее сохранённые указатели
 *     на содержимое объектов кучи недействительны. Берите String_val
 *     и Bytes_val ПОСЛЕ аллокации.
 *
 *   Bytes_val(v)
 *     Как String_val, но возвращает char* (изменяемый). Используется
 *     для записи в свежевыделенный буфер.
 * ========================================================================== */
CAMLprim value caml_str_repeat(value str, value n) {
  CAMLparam2(str, n);
  CAMLlocal1(result);

  mlsize_t src_len = caml_string_length(str);
  intnat   times   = Int_val(n);

  if (times <= 0 || src_len == 0) {
    result = caml_alloc_string(0);
    CAMLreturn(result);
  }

  mlsize_t dst_len = src_len * (mlsize_t)times;
  result = caml_alloc_string(dst_len);

  /* Берём указатели ПОСЛЕ аллокации */
  const char *src = String_val(str);
  char       *dst = (char *)Bytes_val(result);
  for (intnat i = 0; i < times; i++)
    memcpy(dst + (size_t)i * src_len, src, src_len);

  CAMLreturn(result);
}

/* ==========================================================================
 * caml_sum_int_array : int array -> int
 *
 * Возвращает сумму элементов OCaml int array.
 *
 * Новые концепции:
 *
 *   Wosize_val(arr)
 *     Количество OCaml-слов в блоке. Для unboxed-массивов (float array)
 *     это число элементов. Для int array (boxed) — тоже число элементов,
 *     потому что каждый int занимает ровно один слот.
 *
 *   Field(arr, i)
 *     i-й слот блока [arr]. Для int array возвращает value, содержащий
 *     тегированный int — поэтому нужен Int_val(Field(arr, i)).
 * ========================================================================== */
CAMLprim value caml_sum_int_array(value arr) {
  CAMLparam1(arr);
  mlsize_t len = Wosize_val(arr);
  intnat   sum = 0;
  for (mlsize_t i = 0; i < len; i++)
    sum += Int_val(Field(arr, i));
  CAMLreturn(Val_int(sum));
}
