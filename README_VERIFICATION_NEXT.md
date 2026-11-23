# Следующий проверочный этап

Эта ветка улучшает учебный проект **без изменения подтверждённой базовой модели**.

## Что добавлено

- `run_verification_campaign` — 4 детерминированных сценария + 10 Монте-Карло запусков.
- `plot_verification_dashboard` — наглядный мониторинг семи модулей и статистика.
- `run_hazard_experiment` — испытание Simulink модели на препятствии, не включённом в предварительный маршрут.
- `polish_functional_model` — аккуратная цветовая архитектура с сохранением предыдущего .slx.
- `tests/run_verification_campaign_tests.m` и `tests/run_hazard_experiment_tests.m` — проверки.
- `docs/TEAM_DELIVERY_PLAN.md` — отдельные критерии готовности семи участников.

## Проверка в MATLAB Online

```matlab
run_verification_campaign
run('tests/run_verification_campaign_tests.m')

% Для исполняемой Simulink-модели
polish_functional_model
run_hazard_experiment
run('tests/run_hazard_experiment_tests.m')
```

**Новые тесты ещё не выполнялись в MATLAB Online.** Это отдельный экспериментальный слой. Результат столкновения или отсутствие safety intervention — не повод скрывать ошибку: это конкретная задача для дальнейшей доработки планирования и контроля.

См. [матрицу сценариев](docs/SCENARIO_TEST_MATRIX.md), [план инженерных работ](docs/TEAM_DELIVERY_PLAN.md) и [проверенную базу](docs/VERIFICATION_STATUS.md).
