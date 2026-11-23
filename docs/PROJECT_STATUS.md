# Текущий статус UAV Team Project — 23 ноября 2026

## Что мы покажем преподавателю

Рабочая учебная система с 7 независимыми разработчиками, несколькими
уровнями модели и репродуцируемыми испытаниями. **Проект — не реальный
автопилот и не средство управления физическим БПЛА.**

| Ветка / версия | Главное отличие | Подтверждение |
|---|---|---|
| Базовый MATLAB | 7 подсистем, маршрут и миссия | 11/11 MATLAB PASS |
| Функциональный Simulink (`UAVF`) | 7 Model Reference + общая Dynamics; ранняя остановка | Integration [A]–[D] PASS, GOAL_REACHED, hazard challenge PASS |
| Advanced MATLAB V2 | **Реальный online replan** неизвестных кругов, GPS outage, comms, energy reserve | 13/13 PASS, кампания 6/6 PASS |
| **Новая V3 Simulink** | 7 персональных исполняемых Model Reference, runtime detection и отдельный replan внутри Simulink | MATLAB unit **6/6 PASS**; Simulink **V3-A–D 4/4 PASS** в MATLAB Online |

## Контрольные цифры последней проверенной Advanced V2

- Неожиданное препятствие: **1** новый объект, **1** online replan.
- Время до цели **23,10 с**, ошибка **0,13 м**.
- Запас до физической границы круга **9,39 м**.
- Навигационная RMSE **0,171 м**.
- Доставлено **96,1 %** телеметрии, батарея после миссии **96,46 %**.
- С двумя неизвестными объектами: **2** replans, GOAL_REACHED,
  зазор **9,11 м**.
- Шесть испытаний Advanced V2: **6/6 ожидаемых исходов**,
  включая корректную остановку из-за low battery.

## Последние подтверждённые CI результаты

GitHub Actions run **45167864440**, завершён успешно:

```text
Mission Lifecycle Supervisor unit tests: 6/6 PASS
Advanced V2 acceptance suite: 13/13 PASS
Advanced V2 campaign acceptance: 6/6 PASS
V3 algorithm unit tests: 6/6 PASS
V2 robustness smoke tests: 4/4 measured runs PASS
```

Это результат CI для MATLAB-кода. **После него** новая V3 Simulink
была отдельно успешно запущена в MATLAB Online (V3-A–D 4/4).

## Новая экспериментальная версия V3

- Генератор: `build_v3_simulink_model.m`.
- Результат при успешном выполнении: 9 отдельных моделей-компонентов
  (семь участников + общая Dynamics и Supervisor) и 1 верхнеуровневая
  `UAV3_Team_Model.slx`.
- Новый планировщик получает обнаружения с датчика и изменяет target
  **во время работы Simulink**; не является точной копией V2 planner.
- Архитектура: фиксированные порты, Goto/From для читаемой схемы,
  явная дискретная задержка обратной связи.
- Проверка: `run('tests/run_v3_simulink_tests.m')`.
- Статус модели: **скомпилирована и запущена в MATLAB Online; 4/4 PASS**
  для стандартного мира. Время 22.60 с; GOAL_REACHED; 1 replan; GPS outage
  20 шагов; минимум зазора 11.75 м; подробности в
  [журнале V3](evidence/V3_SIMULINK_VALIDATION_20261123.md).

## Документы для защиты

1. [Полный технический отчёт](ACADEMIC_TECHNICAL_REPORT.md)
2. [Матрица требований и тестов](V3_REQUIREMENTS.md)
3. [Метрики для каждого из семи участников](SEVEN_MEMBER_SCORECARD.md)
4. [Сценарий выступления семи участников](DEFENSE_PRESENTATION_7_SPEAKERS.md)
5. [Инструкция живой демонстрации](TEACHER_DEMO_RUNBOOK.md)
6. [Журнал верификации](VERIFICATION_STATUS.md)
7. [Информация о Simulink V3](../models/v3/README.md)

## Дальнейшая проверка

```matlab
% Сначала убедиться, что открыта feature/v3-model-based-defense-package-20261123
run('tests/run_v3_algorithm_tests.m')
build_v3_simulink_model
r = run_v3_simulink_demo(true);
run('tests/run_v3_simulink_tests.m')

% Отдельная исследовательская часть
study = run_robustness_study(10,true, ...
    {'unexpected','two_unknown'},[0 0.15 0.35]);
export_robustness_report(study)
run_defense_showcase(false)
```

Новая версия хранится отдельно и не перезаписывает ранее проверенную
`UAVF_Team_Model.slx`. Зависимые PR нужно объединять в порядке
с согласованием интерфейсов командой.
