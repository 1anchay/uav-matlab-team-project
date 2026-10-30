# Работа команды из 7 участников

## Клонирование
```powershell
git clone https://github.com/1anchay/uav-matlab-team-project.git
cd uav-matlab-team-project
```

## Ветки
Каждый работает только в своей ветке, указанной в [TEAM_ASSIGNMENTS.md](TEAM_ASSIGNMENTS.md). Например:

```powershell
git fetch origin
git switch team/artem-flight-safety
git merge origin/main
```

Ключевые новые ветки:
- `team/artem-flight-safety` — Артём Пучков, безопасность;
- `team/ivan-kasimov-energy` — Иван Касимов, энергосистема.

## MATLAB-проверки
```matlab
run_project
run('tests/run_tests.m')
```

## Сохранение работы
```powershell
git add .
git commit -m "[SAFETY] add obstacle guard tests"
git push
```

Префиксы: `[NAV]`, `[FLIGHT]`, `[ROUTE]`, `[DETECT]`, `[GROUND]`, `[SAFETY]`, `[ENERGY]`, `[INTEGRATION]`.

## Pull Request
Укажите, что изменено, какие входы/выходы затронуты, пройдены ли тесты. При изменении интерфейса одновременно обновите `docs/INTERFACES.md` и связанные вызовы.

Другой участник проверяет PR. Только после этого изменения объединяются с `main`.
