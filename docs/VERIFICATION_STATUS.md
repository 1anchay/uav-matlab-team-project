# Журнал верификации UAV

Дата подготовки: 23 ноября 2026 г.

## Подтверждено пользователем в MATLAB Online

**Ветка:** `improve/seven-modules-mbd-verification-20261123` (исходники сохранены также в `checkpoint/matlab-simulink-smoke-passed-20261123`).

- `run('tests/run_tests.m')` — все **11/11** сценариев успешно выполнены, `Default mission: GOAL_REACHED`.
- `build_component_models` — созданы 7 обзорных моделей участников и общая Dynamics.
- `build_simulink_model` — обзорная схема из Model Reference создана.
- `run('tests/run_simulink_smoke_tests.m')` — **Model Reference smoke test passed (architecture ONLY)**.
- Скриншот общей схемы `UAV_Team_Model` получен в чате.

## Подготовлено, но НЕ проверено в MATLAB Online

**Ветка:** `feature/executable-simulink-architecture-20261123`.

- `build_functional_simulink_model` — код генератора восьми исполняемых отдельных моделей и верхнего уровня.
- `run_functional_demo` — численная симуляция и графики.
- `run('tests/run_functional_simulink_tests.m')` — статическая структура, компиляция, размеры, конечность, ограничения, отсутствие столкновений, достижение цели.

**Нельзя ставить PASS для этой второй группы без фактического вывода MATLAB Online.**

Независимая приближённая проверка 2D-уравнений на исходных круговых препятствиях дала ожидаемое приближение к точке [100,80] при ограничении скорости и положительном расстоянии до препятствий. Это сверка формул, не проверка кода Simulink или условий времени исполнения.

## Последовательность проверки перед PR merge

```matlab
run('tests/run_tests.m')
run('tests/run_simulink_smoke_tests.m')
build_functional_simulink_model
run_functional_demo
run('tests/run_functional_simulink_tests.m')
```

Выполнить из корня репозитория на ветке с новой функциональной архитектурой. Сохранить лог Command Window и скриншоты `UAVF_Team_Model` + двух графиков. Если одна из команд выдаст ошибку, исправить в отдельном коммите и повторить все проверки.

## GitHub

- `main` не меняется напрямую.
- PR #3 вводит семичленную структуру; PR #4 — улучшения MATLAB-кода; новая ветка зависит от PR #4.
- Создана независимая контрольная ветка с уже проверенным кодом.
- GitHub не имеет доступа к локальным файлам `.slx` пользователя в MATLAB Drive, поэтому их нужно отдельно зафиксировать в Git, когда будет подтверждена работоспособность новой модели.
