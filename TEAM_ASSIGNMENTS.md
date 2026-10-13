# Команда и распределение задач

| № | Участник | Подсистема | Папка | Ветка |
|---|---|---|---|---|
| 1 | Ernesto Horserofl | Навигация и ориентирование | `team/01_ernesto_horserofl_navigation/` | `team/ernesto-navigation` |
| 2 | Иван Живоглядов | Управление полётом | `team/02_ivan_zhivoglyadov_flight_control/` | `team/ivan-flight-control` |
| 3 | Бодя Лемченко | Маршрут и планирование | `team/03_bodya_lemchenko_route_planning/` | `team/bodya-route-planning` |
| 4 | Александр Лзедзей | Обнаружение объектов | `team/04_aleksandr_lzedzei_object_detection/` | `team/aleksandr-object-detection` |
| 5 | Арсений Терехов | Связь и наземная станция | `team/05_arseniy_terekhov_ground_station/` | `team/arseniy-ground-station` |

## Общее правило
Каждый участник в первую очередь меняет **свою папку и свой MATLAB-файл**. Изменения общих файлов (`simulate_uav.m`, `config_uav.m`, `run_project.m`, `build_simulink_model.m`) делаются только если они необходимы для интеграции и должны быть описаны в Pull Request.

## Общий продукт
Ветка `main` — интеграционная версия. В неё попадают только изменения, которые:
1. запускаются в MATLAB;
2. не ломают другие подсистемы;
3. проходят `tests/run_tests.m`;
4. описаны в Pull Request.

## Если участников станет больше
Для нового участника создаётся папка `team/06_name_new_subsystem/`, отдельная ветка `team/...`, README с входами/выходами и минимальный тест. Номер следующих участников увеличивается последовательно.
