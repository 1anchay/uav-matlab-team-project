# Как работать командой

## 1. Клонирование
```powershell
git clone https://github.com/1anchay/uav-matlab-team-project.git
cd uav-matlab-team-project
```

## 2. Каждый работает в своей ветке
Пример:
```powershell
git switch team/ivan-flight-control
```

Перед началом новой работы:
```powershell
git fetch origin
git merge origin/main
```

## 3. Меняем только свою подсистему
Основные рабочие файлы лежат в `team/<ваша_папка>/`.

## 4. Проверка в MATLAB
```matlab
run_project
run('tests/run_tests.m')
```

## 5. Сохраняем изменения
```powershell
git add .
git commit -m "[FLIGHT] smooth yaw control"
git push
```

Префиксы коммитов:
- `[NAV]` — навигация;
- `[FLIGHT]` — управление;
- `[ROUTE]` — маршрут;
- `[DETECT]` — обнаружение;
- `[GROUND]` — связь/станция;
- `[INTEGRATION]` — общие изменения.

## 6. Pull Request
После push участник создаёт Pull Request из своей ветки в `main` и пишет:
- что изменено;
- какие входы/выходы затронуты;
- как проверено;
- есть ли изменения в общих файлах.

Другой участник просматривает PR. После проверки изменения объединяются с `main`.

## Главное правило
Никто не переписывает чужую подсистему «молча». Если нужен новый сигнал между двумя блоками — сначала согласуйте название и формат в `docs/INTERFACES.md`.
