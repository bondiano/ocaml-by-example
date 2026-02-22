# OBE - OCaml by Example CLI

Единая утилита командной строки для работы с упражнениями OCaml by Example.

## Описание

`obe` объединяет функциональность:
- **Проверки упражнений** (из `obe-check`)
- **Отслеживания прогресса** (из `progress-tracker`)
- **Управления решениями** (из bash-скриптов)

Читатели собирают эту утилиту в Главе 2 как первое практическое упражнение,
а затем используют её на протяжении всей книги для проверки решений и отслеживания прогресса.

## Установка

```bash
# Из корня проекта ocaml-by-example:
cd obe
dune build
dune install  # опционально, для глобальной установки
```

## Использование

### `obe check`

Проверить текущее упражнение (запустить из директории упражнения):

```bash
cd exercises/chapter04
obe check
```

Вывод:
```
🧪 Проверка упражнения...

Testing `Chapter04'.
[OK] test1
[OK] test2
[OK] test3

✅ Все тесты прошли!
✓ Отмечено в календаре (2026-02-21)
🔥 Streak: 3 дня подряд! Так держать!
```

### `obe progress`

Показать прогресс по всем главам:

```bash
obe progress           # таблица (по умолчанию)
obe progress -f json   # JSON формат
```

Вывод:
```
📊 OCaml by Example — Прогресс упражнений
═══════════════════════════════════════════

┌──────────────┬────────┬────────┬─────────┬──────────┐
│ Глава        │ Всего  │ Сделано│ Осталось│ Прогресс │
├──────────────┼────────┼────────┼─────────┼──────────┤
│ chapter02    │      9 │      9 │       0 │ ████████ │
│ chapter04    │      8 │      3 │       5 │ ███░░░░░ │
│ chapter05    │     12 │      0 │      12 │ ░░░░░░░░ │
└──────────────┴────────┴────────┴─────────┴──────────┘

ИТОГО: 12/29 упражнений (41%)
```

### `obe show`

Показать календарь и статистику streak'ов:

```bash
obe show
```

Вывод:
```
📅 OCaml by Example — Calendar

    February 2026
Mo  ░██░░░█
Tu  █████░░
We  ░█████░
Th  ██░░███
Fr  ░░█████

🔥 Current streak: 5 days
🏆 Longest streak: 12 days
📊 Total: 23/120 exercises (19%)
```

### `obe skip`

Пропустить текущее упражнение:

```bash
cd exercises/chapter04
obe skip
```

Вывод:
```
⏭️  Текущее упражнение пропущено
Следующее: chapter05 (0/12)
```

### `obe stats`

Статистика по уровням сложности:

```bash
obe stats           # краткая
obe stats -d        # детальная разбивка по главам
```

Вывод:
```
📈 Статистика по уровням сложности
═══════════════════════════════════

Лёгкое:  45 упражнений
Среднее: 62 упражнения
Сложное: 13 упражнений

Всего: 120 упражнений
```

### `obe reset`

Сбросить решения к заглушкам (создаёт backup):

```bash
obe reset chapter04 --confirm      # одна глава
obe reset --confirm                # все главы
```

**⚠️ Внимание**: Требует флаг `--confirm` для защиты от случайного запуска.

Вывод:
```
🧹 Сброс решений для chapter04...
✅ Backup сохранён: chapter04/test/my_solutions.ml.backup
✅ Решения сброшены
```

### `obe test`

Запустить тесты:

```bash
obe test chapter04   # для одной главы
obe test             # для всех глав
```

## Конфигурация

Утилита читает конфигурацию из `.ocaml-by-example.toml` в корне проекта.

Пример конфигурации:

```toml
[exercises]
order = ["chapter02", "chapter04", "chapter05", ...]

[exercises.chapter02]
name = "Окружение и инструменты"
difficulty = "easy"
total_exercises = 9

[exercises.chapter04]
name = "Основные типы данных"
difficulty = "easy"
total_exercises = 8

[progress]
file = ".obe-progress.json"

[goals]
daily_streak_target = 7
total_target = 120
```

## Прогресс

Прогресс сохраняется в `.obe-progress.json` в корне проекта:

```json
{
  "marks": [
    {
      "date": "2026-02-21",
      "chapter": "chapter02",
      "exercise_num": 1,
      "status": "Pass"
    }
  ],
  "current_streak": 3,
  "longest_streak": 5,
  "total_exercises_done": 12
}
```

## Архитектура

```
obe/
├── bin/
│   ├── dune
│   └── main.ml           # CLI (Cmdliner)
├── lib/
│   ├── dune
│   ├── config.ml         # Чтение .ocaml-by-example.toml
│   ├── progress.ml       # Сохранение/загрузка прогресса (JSON)
│   ├── next_exercise.ml  # Определение следующего упражнения
│   ├── checker.ml        # Запуск тестов через dune
│   ├── calendar.ml       # Визуализация календаря
│   ├── scanner.ml        # Сканирование my_solutions.ml
│   ├── parser.ml         # Анализ кода (поиск todo)
│   ├── formatter.ml      # Форматирование таблиц
│   └── stats.ml          # Статистика по сложности
├── dune-project
├── obe.opam
└── README.md
```

## Зависимости

- `cmdliner` — парсинг аргументов CLI
- `yojson` — работа с JSON (прогресс)
- `str` — регулярные выражения (парсинг кода)

## Для разработчиков

Собрать и запустить из исходников:

```bash
dune build
dune exec obe -- check
```

Запустить тесты:

```bash
dune runtest
```

## Лицензия

MIT
