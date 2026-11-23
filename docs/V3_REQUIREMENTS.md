# Требования, трассируемость и приёмка V3

Статусы разделены: **verified** = имеется вывод MATLAB Online или завершённого CI;
**implemented, pending** = исходники созданы, но не выполнялись в MATLAB Online;
**future** = пока не реализовано. Наличие кода не означает прохождение теста.

| ID | Требование | Реализация | Проверка | Статус |
|---|---|---|---|---|
| R-01 | 7 независимых владельцев исходников | `team/01...07/v3_*.m` | Структура Git + `run_v3_algorithm_tests` | verified — unit + default Simulink scenario |
| R-02 | 7 независимых исполняемых Model Reference | `build_v3_simulink_model.m` | `run_v3_simulink_tests` [V3-A] | verified — unit + default Simulink scenario |
| R-03 | Отдельные Dynamics и Mission Supervisor | Общие `UAV3_Dynamics`, `UAV3_MissionLifecycle` | [V3-A/B] | verified — unit + default Simulink scenario |
| R-04 | Явные размеры входов | `build_v3_simulink_model.m` | compile [V3-B] | verified — unit + default Simulink scenario |
| R-05 | Нет алгебраического цикла | Верхнеуровневый Feedback Delay | [V3-B] | verified — unit + default Simulink scenario |
| R-06 | Препятствие не известно планировщику вначале | `v3_detection.m`, `v3_replanner.m` | unit [V3-01/02] | verified — unit + default Simulink scenario |
| R-07 | Replan происходит В Simulink | `UAV3_Replanner_03` | [V3-D] + журнал `uav3_plan` | verified — unit + default Simulink scenario |
| R-08 | Виртуальная GPS-потеря упражняется | `v3_gps_schedule.m`, `v3_navigation.m` | [V3-D] | verified — unit + default Simulink scenario |
| R-09 | Ограничения скорости/ускорения и батареи | `v3_control.m`, `v3_energy.m`, Dynamics | [V3-C] | verified — unit + default Simulink scenario |
| R-10 | Пересечение препятствия не допускается в базовом тесте | `v3_safety.m`, Dynamics | [V3-C] | verified — unit + default Simulink scenario |
| R-11 | Статус GOAL_REACHED и ранняя остановка | `UAV3_MissionLifecycle` | [V3-D] | verified — unit + default Simulink scenario |
| R-12 | Телеметрия содержит 9 числовых каналов | `v3_ground.m`, To Workspace | [V3-C] | verified — unit + default Simulink scenario |
| R-13 | Вся V2 MATLAB-регрессия сохраняется | Без изменений старых `subsystem_*.m` | существующие suites в CI | verified in GitHub CI |
| R-14 | Независимое исследование misses сенсора **V2** | `run_robustness_study.m` | smoke 4/4 (CI) + full 60-run (MATLAB Online) | **verified V2: 60/60 goal, 0 observed collisions** |
| R-15 | Экспорт данных и отчётов | `run_defense_showcase.m` | проверить результаты `results/defense` | implemented, pending |
| R-16 | Физическая 3D-динамика и sensor fusion | Отдельный будущий этап | будущие испытания | future |

**Состояние CI MATLAB:** подтверждены `V3 algorithm unit tests: 6/6 PASS`
и `V2 robustness smoke tests: 4/4 measured runs PASS` в GitHub
Actions, 23.11.2026 (run ID 45167864440). **Позднее получены V3-A–D 4/4 PASS в MATLAB Online.**
Это подтверждает базовый сценарий интегрированной модели. Полный **V2** robustness sweep пройден (60/60 GOAL_REACHED) в MATLAB Online;
расширенные карты и устойчивость интегрированной **V3** ещё не проверены.

**Условия приёмки V3:** unit 6/6, Simulink stages [A]–[D] PASS,
минимальная физическая дистанция до круга положительна, одна новая цель
маршрута действительно появляется при обнаружении и супервизор завершает
миссию. Эти условия подтверждены для базового мира V3:
GOAL_REACHED, 1 replan, 11.75 м до круга и завершение за 22.60 с.
Другие карты и аварийные состояния требуют отдельных испытаний.

Отдельно испытать сценарий с двумя объектами, чтобы не экстраполировать
успешный one-circle сценарий на любые карты.

## Дополнительные критерии перед защитой — pending

| ID | Новая проверка | Файл | Статус |
|---|---|---|---|
| R-17 | Два физических скрытых круга в Simulink | `run_v3_scenario('two_unknown')` | implemented, pending |
| R-18 | Коллизия при старте → код 2 | `run_v3_scenario('collision_at_start')` | implemented, pending |
| R-19 | Критический заряд → код 3 | `run_v3_scenario('critical_battery')` | implemented, pending |
| R-20 | Невалидное состояние → код 4 | `run_v3_scenario('invalid_state')` | implemented, pending |
| R-21 | Начало на цели → код 1 | `run_v3_scenario('goal_at_start')` | implemented, pending |
| R-22 | Сегментная проверка зазора | `v3_swept_clearance.m` | unit test pending |

Тест `run('tests/run_v3_extended_integration_tests.m')` проверяет
новые требования; его результат не предсказан заранее. Запуск
`run_v3_acceptance_campaign` сообщает о FAIL и ERROR, а не маскирует их.
