# Команда и распределение задач — 7 участников

| № | Участник | Подсистема | Папка | Ветка |
|---|---|---|---|---|
| 1 | Ernesto Horserofl | Навигация и ориентирование | `team/01_ernesto_horserofl_navigation/` | `team/ernesto-navigation` |
| 2 | Иван Живоглядов | Управление полётом | `team/02_ivan_zhivoglyadov_flight_control/` | `team/ivan-flight-control` |
| 3 | Бодя Лемченко | Маршрут и планирование | `team/03_bodya_lemchenko_route_planning/` | `team/bodya-route-planning` |
| 4 | Александр Лзедзей | Обнаружение объектов | `team/04_aleksandr_lzedzei_object_detection/` | `team/aleksandr-object-detection` |
| 5 | Арсений Терехов | Связь и наземная станция | `team/05_arseniy_terekhov_ground_station/` | `team/arseniy-ground-station` |
| 6 | Артём Пучков | Контроль безопасности полёта | `team/06_artem_puchkov_flight_safety/` | `team/artem-flight-safety` |
| 7 | Иван Касимов | Энергосистема и батарея | `team/07_ivan_kasimov_energy/` | `team/ivan-kasimov-energy` |

## Общее правило
Каждый участник преимущественно меняет **свою папку и MATLAB-файл**. Общие файлы (`simulate_uav.m`, `config_uav.m`, `run_project.m`, `build_simulink_model.m`) редактируются согласованно через Pull Request.

## Интеграция
Общая ветка `main` содержит интегрированную версию. Перед слиянием запускаются `run_project` и `run('tests/run_tests.m')`; участники проверяют контракт сигналов в `docs/INTERFACES.md`.

**Схема для преподавателя:** [взаимодействие семи модулей](docs/TEAM_INTERACTION.md).

Для приглашения новых участников на GitHub нужны их **GitHub usernames**, а не отображаемые имена в мессенджере.
