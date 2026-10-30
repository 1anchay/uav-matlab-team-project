# Подключение семи участников к GitHub

У проекта один общий репозиторий: `1anchay/uav-matlab-team-project`. Владелец может предоставить коллегам права записи.

## Два новых участника
- **Артём Пучков:** `team/artem-flight-safety` и `team/06_artem_puchkov_flight_safety/`.
- **Иван Касимов:** `team/ivan-kasimov-energy` и `team/07_ivan_kasimov_energy/`.

Чтобы пригласить их как collaborators, нужно узнать **их GitHub usernames**. Отображаемые имена из мессенджера не подходят для приглашения.

## Создать персональные ветки вручную
```powershell
git fetch origin
git switch main
git pull
git switch -c team/artem-flight-safety
git push -u origin team/artem-flight-safety
git switch main
git switch -c team/ivan-kasimov-energy
git push -u origin team/ivan-kasimov-energy
```

Дополнительно можно использовать `bootstrap_github.ps1` (уже существующий репозиторий скрипт не пересоздаёт). Работа ведётся через Pull Request.
