# RSS Reader — Интеграционный проект

Консольный RSS-агрегатор на OCaml.

## Описание

Этот проект объединяет знания из нескольких глав:
- **Chapter 8:** Валидация и обработка ошибок
- **Chapter 12:** Конкурентность с Eio
- **Chapter 14:** Парсинг XML
- **Chapter 15:** CLI приложения с Cmdliner

## Цели обучения

- Создание реального приложения с несколькими модулями
- Работа с внешними библиотеками (cohttp-eio, ezxmlm, cmdliner)
- Конкурентная загрузка данных
- Парсинг структурированных данных
- Проектирование CLI интерфейса

## Структура проекта

```
project_rss_reader/
├── lib/
│   ├── validator.ml      # Валидация URL
│   ├── feed_parser.ml    # Парсинг RSS XML
│   ├── storage.ml        # Хранение фидов
│   └── dune
├── bin/
│   ├── main.ml           # CLI интерфейс
│   └── dune
├── test/
│   ├── test_validator.ml
│   ├── fixtures/
│   └── dune
├── GUIDE.md              # Пошаговый гайд
└── README.md             # Этот файл
```

## Быстрый старт

1. Прочитайте [GUIDE.md](GUIDE.md) для пошаговых инструкций
2. Установите зависимости:
   ```bash
   opam install uri str cmdliner
   # Опционально для полной реализации:
   # opam install cohttp-eio ezxmlm
   ```
3. Запустите тесты:
   ```bash
   dune test
   ```
4. Соберите и запустите:
   ```bash
   dune build
   dune exec rss-reader -- add "https://example.com/rss"
   ```

## Функциональность

- [x] Базовая структура проекта
- [ ] Валидация URL (Шаг 1)
- [ ] Парсинг RSS (Шаг 2)
- [ ] HTTP загрузка (Шаг 3)
- [ ] Хранилище (Шаг 4)
- [ ] CLI команды (Шаг 5)

## Время выполнения

**Оценка:** 6-8 часов

## Дополнительные ресурсы

- [RSS 2.0 Specification](https://www.rssboard.org/rss-specification)
- [Eio documentation](https://github.com/ocaml-multicore/eio)
- [Cmdliner tutorial](https://erratique.ch/software/cmdliner/doc/Cmdliner)
