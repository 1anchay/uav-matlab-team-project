# UAV MATLAB / Simulink — командный проект БПЛА

**7 участников · 7 модулей · 1 общая симуляция**

Учебный проект по модельно-ориентированному проектированию автономного БПЛА. Утверждённое распределение ролей зафиксировано в [TEAM_ASSIGNMENTS.md](TEAM_ASSIGNMENTS.md), а связи между модулями — в [схеме архитектуры](docs/TEAM_INTERACTION.md).

## Участники и модули

| № | Разработчик | Функция | Исходный код |
|---|---|---|---|
| 01 | Эрнест Карпухин | Навигация и ориентирование | [`subsystem_navigation.m`](team/01_Карпухин_Эрнест/subsystem_navigation.m) |
| 02 | Иван Живоглядов | Управление полётом | [`subsystem_flight_control.m`](team/02_Живоглядов_Иван/subsystem_flight_control.m) |
| 03 | Богдан Лемченко | Планирование маршрута | [`subsystem_route_planning.m`](team/03_Лемченко_Богдан/subsystem_route_planning.m) |
| 04 | Александр Дзедзей | Обнаружение объектов | [`subsystem_object_detection.m`](team/04_Дзедзей_Александр/subsystem_object_detection.m) |
| 05 | Арсений Терехов | Связь и наземная станция | [`subsystem_ground_station.m`](team/05_Терехов_Арсений/subsystem_ground_station.m) |
| 06 | Артём Пучков | Контроль безопасности | [`subsystem_flight_safety.m`](team/06_Пучков_Артём/subsystem_flight_safety.m) |
| 07 | Иван Касимов | Энергосистема и батарея | [`subsystem_energy.m`](team/07_Касимов_Иван/subsystem_energy.m) |

Общая модель динамики БПЛА — **не восьмой модуль**. Она объединяет работу команды в `simulate_uav.m`.

## Быстрый запуск

Требуется MATLAB. Открой корень репозитория как *Current Folder* и выполни:

```matlab
run_project
run('tests/run_tests.m')
```

Для создания **обзорной архитектурной** схемы в Simulink:

```matlab
build_simulink_model
```

> Simulink-модель демонстрирует интерфейсы и расположение модулей. Расчёты полёта выполняются в MATLAB, не внутри диаграммы Simulink.

## Структура репозитория

```text
uav-matlab-team-project/
├── team/
│   ├── 01_Карпухин_Эрнест/
│   │   ├── README.md
│   │   └── subsystem_navigation.m
│   ├── 02_Живоглядов_Иван/
│   │   ├── README.md
│   │   └── subsystem_flight_control.m
│   ├── 03_Лемченко_Богдан/
│   │   ├── README.md
│   │   └── subsystem_route_planning.m
│   ├── 04_Дзедзей_Александр/
│   │   ├── README.md
│   │   └── subsystem_object_detection.m
│   ├── 05_Терехов_Арсений/
│   │   ├── README.md
│   │   └── subsystem_ground_station.m
│   ├── 06_Пучков_Артём/
│   │   ├── README.md
│   │   └── subsystem_flight_safety.m
│   ├── 07_Касимов_Иван/
│   │   ├── README.md
│   │   └── subsystem_energy.m
├── simulate_uav.m             # Общая динамика и интеграция
├── config_uav.m               # Конфигурация
├── setup_paths.m              # Подключение семи личных папок
├── run_project.m              # Точка запуска
├── build_simulink_model.m     # Обзорная модель Simulink
├── tests/run_tests.m          # MATLAB-тесты
├── docs/                      # Архитектура и интерфейсы
└── TEAM_ASSIGNMENTS.md        # Ответственные и ветки
```

## Как работать в команде

Каждый пишет код в **своей именной папке** и персональной ветке. В `main` изменения попадают только через Pull Request и проверку другими участниками. Инструкции: [CONTRIBUTING.md](CONTRIBUTING.md) · [GITHUB_SETUP.md](GITHUB_SETUP.md).

**Публичный репозиторий ≠ доступ на запись.** Для прямого `push` владелец должен пригласить каждый GitHub-аккаунт как collaborator с разрешением `Write`; без него можно предложить изменения через Fork → Pull Request.

## Документы

[Архитектура и потоки данных](docs/TEAM_INTERACTION.md) · [Интерфейсы модулей](docs/INTERFACES.md) · [Задачи команды](TEAM_ASSIGNMENTS.md) · [Промпт для дальнейшей работы с ИИ](docs/AI_WORK_PROMPT.md)

## Модельно-ориентированное проектирование: отдельные компоненты

Преподаватель предоставил сравнение Virtual/Atomic Subsystem, Subsystem Reference и Model Reference. Для независимой разработки у каждого из 7 участников будут **отдельные Simulink-модели**. Скрипты генерируют их только в установленном MATLAB/Simulink:

```matlab
build_component_models
build_simulink_model
run('tests/run_simulink_smoke_tests.m')
```

**Важно:** эти `.slx` — пока архитектурные заглушки портов. Их генерируют для демонстрации структуры Model Reference, а не для расчёта полёта. Настоящие алгоритмы остаются в MATLAB-модулях. См. [models/README.md](models/README.md).

## Верификация и учебные требования

- Основные модульные и интеграционные проверки: `run('tests/run_tests.m')`.
- Опциональная проверка структуры Model Reference: `run('tests/run_simulink_smoke_tests.m')`.
- Прослеживаемость требований: [docs/REQUIREMENTS_AND_TESTS.md](docs/REQUIREMENTS_AND_TESTS.md).
- Ограничение: безопасность и физическая достоверность реального БПЛА не подтверждены.

## Исполняемая Simulink-модель (отдельный вариант)

Помимо обзорной архитектуры `UAV_Team_Model`, теперь есть **функциональный 2D-прототип** с семью настоящими MATLAB Function-модулями в независимых Model Reference:

```matlab
build_functional_simulink_model
run_functional_demo
run('tests/run_functional_simulink_tests.m')
```

Это **не та же модель**, что MATLAB-симуляция `run_project`: она упрощена до 2D, использует маршрут, заранее построенный MATLAB-планировщиком, и имитирует круговые препятствия. Подробнее: [модель и ограничения](models/functional/README.md), [этапы разработки](docs/IMPLEMENTATION_ROADMAP.md), [план защиты](docs/DEFENSE_GUIDE.md).

**Проверка новой модели в MATLAB Online ещё не выполнена**; до успешного выполнения тестов не объединяйте соответствующий PR с интеграционной веткой.
