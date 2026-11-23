# Как работать в команде из 7 человек

## 1. Получить доступ

Публичный репозиторий можно клонировать без приглашения, но для `git push` нужен доступ **Write**. Владелец приглашает GitHub-аккаунты участников; имена из Discord или мессенджера не заменяют GitHub username. См. [GITHUB_SETUP.md](GITHUB_SETUP.md).

```powershell
git clone https://github.com/1anchay/uav-matlab-team-project.git
cd uav-matlab-team-project
git fetch origin
```

## 2. Работать в своей ветке

Найди свою ветку и именную папку в [TEAM_ASSIGNMENTS.md](TEAM_ASSIGNMENTS.md). Пример для Артёма:

```powershell
git switch team/artem-flight-safety
git merge origin/main
```

Если персональной ветки нет, её создают от актуальной `main` после согласования с владельцем. Старые ветки сохраняют исторические названия, чтобы не терять существующие ссылки и коммиты.

## 3. Менять свой модуль

Изменяй прежде всего `team/NN_Фамилия_Имя/`, читай README внутри и соблюдай [контракт сигналов](docs/INTERFACES.md). Для изменений `simulate_uav.m`, `config_uav.m`, `setup_paths.m`, тестов и общих интерфейсов предупреди команду и открой PR.

## 4. Проверить локально

```matlab
run_project
run('tests/run_tests.m')
```

## 5. Отправить изменения

```powershell
git add .
git commit -m "[SAFETY] improve avoidance logic"
git push -u origin HEAD
```

Используй префиксы: `[NAV]`, `[FLIGHT]`, `[ROUTE]`, `[DETECT]`, `[GROUND]`, `[SAFETY]`, `[ENERGY]` или `[INTEGRATION]`.

## 6. Pull Request → review → merge

В PR перечисли изменённые файлы, цель, тесты и затронутые интерфейсы. Другой участник проверяет изменения; только затем они попадают в `main`. **Не делай прямой push в main.**

> При переезде с прежних имён папок обнови свою локальную ветку от `origin/main` после объединения миграции. Старые пути не должны оставаться в MATLAB path одновременно с новыми.
