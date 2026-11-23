# Требования, трассируемость и приёмка V3

Статусы разделены: **verified** = есть лог MATLAB Online;
**implemented, pending** = исходники созданы, но не выполнялись в MATLAB Online;
**future** = пока не реализовано. Наличие кода не означает прохождение теста.

| ID | Требование | Реализация | Проверка | Статус |
|---|---|---|---|---|
| R-01 | 7 независимых владельцев исходников | `team/01...07/v3_*.m` | Структура Git + `run_v3_algorithm_tests` | verified source structure / unit CI |
| R-02 | 7 независимых исполняемых Model Reference | `build_v3_simulink_model.m` | `run_v3_simulink_tests` [V3-A] | implemented, pending |
| R-03 | Отдельные Dynamics и Mission Supervisor | Общие `UAV3_Dynamics`, `UAV3_MissionLifecycle` | [V3-A/B] | implemented, pending |
| R-04 | Явные размеры входов | `build_v3_simulink_model.m` | compile [V3-B] | implemented, pending |
| R-05 | Нет алгебраического цикла | Верхнеуровневый Feedback Delay | [V3-B] | implemented, pending |
| R-06 | Препятствие не известно планировщику вначале | `v3_detection.m`, `v3_replanner.m` | unit [V3-01/02] | implemented, pending |
| R-07 | Replan происходит В Simulink | `UAV3_Replanner_03` | [V3-D] + журнал `uav3_plan` | implemented, pending |
| R-08 | Виртуальная GPS-потеря упражняется | `v3_gps_schedule.m`, `v3_navigation.m` | [V3-D] | implemented, pending |
| R-09 | Ограничения скорости/ускорения и батареи | `v3_control.m`, `v3_energy.m`, Dynamics | [V3-C] | implemented, pending |
| R-10 | Пересечение препятствия не допускается в базовом тесте | `v3_safety.m`, Dynamics | [V3-C] | implemented, pending |
| R-11 | Статус GOAL_REACHED и ранняя остановка | `UAV3_MissionLifecycle` | [V3-D] | implemented, pending |
| R-12 | Телеметрия содержит 9 числовых каналов | `v3_ground.m`, To Workspace | [V3-C] | implemented, pending |
| R-13 | Вся V2 MATLAB-регрессия сохраняется | Без изменений старых `subsystem_*.m` | существующие suites в CI | verified for earlier V2 |
| R-14 | Независимое исследование misses сенсора | `run_robustness_study.m` | `run_robustness_smoke_tests.m` | implemented, pending |
| R-15 | Экспорт данных и отчётов | `run_defense_showcase.m` | проверить результаты `results/defense` | implemented, pending |
| R-16 | Физическая 3D-динамика и sensor fusion | Отдельный будущий этап | будущие испытания | future |

**Состояние CI MATLAB:** подтверждены `V3 algorithm unit tests: 6/6 PASS`
и `V2 robustness smoke tests: 4/4 measured runs PASS` в GitHub
Actions, 23.11.2026 (run ID 45167864440). **Модельные V3-A–D ещё не
запускались** в MATLAB Online. В строках ниже сохранён статус
`implemented, pending` для требований, требующих интеграции.

**Условия приёмки V3:** unit 6/6, Simulink stages [A]–[D] PASS,
минимальная физическая дистанция до круга положительна, одна новая цель
маршрута действительно появляется при обнаружении и супервизор завершает
миссию. До выполнения в MATLAB Online отмечать эти требования выполненными
**нельзя**.

Отдельно испытать сценарий с двумя объектами, чтобы не экстраполировать
успешный one-circle сценарий на любые карты.
