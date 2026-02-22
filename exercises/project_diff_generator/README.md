# Проект 3: Генератор дифференциалов (Diff)

Инструмент для сравнения файлов и генерации unified diff.

## Обзор

Этот проект объединяет концепции из:
- **Глава 08**: Алгоритмы и структуры данных (LCS)
- **Глава 15**: Парсинг
- **Глава 18**: CLI приложения

**Цель**: Создать CLI-инструмент для сравнения файлов, аналогичный `diff -u`.

## Структура проекта

```
lib/
├── diff_types.ml    -- Типы для представления различий
├── lcs.ml           -- Longest Common Subsequence алгоритм
├── diff.ml          -- Генерация diff из LCS
└── formatter.ml     -- Форматирование в unified diff

bin/
└── main.ml          -- CLI интерфейс

test/
└── test_diff.ml     -- Unit-тесты + Property-Based тесты
```

## Сборка и запуск

```bash
# Сборка
dune build

# Тесты
dune runtest

# Запуск CLI
dune exec diff-gen -- file1.txt file2.txt

# С кастомным контекстом (default: 3)
dune exec diff-gen -- file1.txt file2.txt -u 5
```

## Что такое diff?

Diff показывает различия между двумя текстовыми файлами в формате unified diff:

```diff
--- old.txt
+++ new.txt
@@ -1,3 +1,3 @@
 This line is the same
-This line is removed
+This line is added
 This line is also the same
```

## Алгоритм

Diff использует алгоритм **Longest Common Subsequence (LCS)**:

1. **LCS** находит самую длинную подпоследовательность строк, общую для обоих файлов
2. **Backtracking** восстанавливает последовательность операций (Keep/Insert/Delete)
3. **Grouping** объединяет операции в hunks с контекстом
4. **Formatting** выводит в unified diff формате

### Пример LCS

```
Old: [A, B, C, D]
New: [A, X, C, D]

LCS: [A, C, D]

Operations:
- Keep A
- Delete B
- Insert X
- Keep C
- Keep D
```

## Примеры использования

### Пример 1: Простое сравнение

**old.txt:**
```
apple
banana
cherry
```

**new.txt:**
```
apple
blueberry
cherry
```

**Команда:**
```bash
dune exec diff-gen -- old.txt new.txt
```

**Вывод:**
```diff
--- old.txt
+++ new.txt
@@ -1,3 +1,3 @@
 apple
-banana
+blueberry
 cherry
```

### Пример 2: Множественные изменения

**old.txt:**
```
line1
line2
line3
line4
line5
```

**new.txt:**
```
line1
modified2
line3
line4
modified5
```

**Вывод:**
```diff
--- old.txt
+++ new.txt
@@ -1,5 +1,5 @@
 line1
-line2
+modified2
 line3
 line4
-line5
+modified5
```

## Unified Diff формат

Unified diff состоит из:

1. **Заголовок файлов:**
   ```diff
   --- old.txt
   +++ new.txt
   ```

2. **Hunk заголовок:**
   ```diff
   @@ -1,3 +1,3 @@
   ```
   - `-1,3`: старый файл, начиная со строки 1, 3 строки
   - `+1,3`: новый файл, начиная со строки 1, 3 строки

3. **Операции:**
   - ` ` (пробел): строка без изменений (Keep)
   - `-`: удалённая строка (Delete)
   - `+`: добавленная строка (Insert)

## Этапы разработки

См. [GUIDE.md](./GUIDE.md) для пошаговых инструкций.

1. **Типы** (30 мин) — определение структур данных
2. **LCS Алгоритм** (90 мин) — динамическое программирование
3. **Генерация Diff** (60 мин) — группировка в hunks
4. **Форматирование** (45 мин) — unified diff формат
5. **CLI** (30 мин) — интерфейс командной строки
6. **Тестирование** (60 мин) — unit и property-based тесты
7. **Расширения** (опционально) — цветной вывод, статистика

## Зависимости

- `cmdliner` — CLI парсинг
- `alcotest` — unit-тесты
- `qcheck` — property-based тесты

## Критерии успеха

- [ ] LCS алгоритм реализован корректно
- [ ] Diff показывает добавления/удаления/сохранения
- [ ] Hunks правильно группируются с контекстом
- [ ] Unified diff формат корректен
- [ ] CLI работает с файлами
- [ ] Unit-тесты проходят
- [ ] Property-based тесты проходят

## Расширения (опционально)

1. **Цветной вывод** — используйте ANSI escape codes для подсветки
2. **Patience Diff** — более продвинутый алгоритм (используется в Git)
3. **Статистика** — флаг `--stat` для краткой сводки изменений
4. **Side-by-side** — флаг `-y` для параллельного отображения

## Ресурсы

- [Myers Diff Algorithm](https://blog.jcoglan.com/2017/02/12/the-myers-diff-algorithm-part-1/)
- [Unified Diff Format](https://en.wikipedia.org/wiki/Diff#Unified_format)
- [LCS Algorithm](https://en.wikipedia.org/wiki/Longest_common_subsequence_problem)
