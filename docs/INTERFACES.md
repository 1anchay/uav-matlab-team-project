# Интерфейсы взаимодействия семи модулей

## №1 Navigation
`subsystem_navigation(state,cfg) -> nav`

- `nav.position [1x3]` — м;
- `nav.velocity [1x3]` — м/с;
- `nav.speed` — м/с;
- `nav.course` — курс, рад;
- `nav.altitude`, `nav.positionValid`, `nav.headingValid`.

## №3 Route Planning (до цикла)
`subsystem_route_planning(startPos,goalPos,obstacles,cfg) -> route`

- `route [Nx3]` — набор waypoint;
- `target [1x3]` — текущая цель для Flight Control, выбирается интегратором.

## №4 Object Detection
`subsystem_object_detection(nav,obstacles,cfg) -> detections`

Элемент массива: `name`, `distanceToBoundary`, `bearing`, `relativeXY [1x2]`, `isWarning`.

## №2 Flight Control
`subsystem_flight_control(nav,target,cfg) -> control`

- `control.acceleration [1x3]` — м/с²;
- `control.yawRate` — рад/с;
- дополнительные поля: `target`, `desiredVelocity`, `positionError`.

## №7 Energy
`subsystem_energy(state,cfg) -> energy`

- `energy.currentBattery`, `energy.nextBattery` — %;
- `energy.drainRate` — процентных пунктов в секунду;
- `energy.estimatedRemainingSeconds` — с;
- `energy.lowBattery`, `energy.criticalBattery` — логические флаги.

## №6 Flight Safety
`[safeControl,safety] = subsystem_flight_safety(nav,detections,control,energy,cfg)`

- `safeControl` — структура `control` с проверенными/скорректированными `acceleration` и `yawRate`;
- `safety.status` — `OK`, `OBSTACLE_WARNING`, `OBSTACLE_AVOIDANCE`, `LOW_BATTERY`, `CRITICAL_BATTERY`;
- `safety.intervened`, `safety.obstacleWarning`, `safety.nearestObstacleDistance`, `safety.lowBattery`, `safety.criticalBattery`.

## №5 Ground Station
`subsystem_ground_station(nav,state,safeControl,waypointIndex,detections,cfg,safety,energy) -> packet`

Основные поля: `linkOK`, `position`, `altitude`, `speed`, `course`, `battery`, `waypointIndex`, `detectedObjects`, `commandedAcceleration`, `safetyStatus`, `batteryWarning`, `estimatedRemainingTime`.

Последние два аргумента (`safety`, `energy`) — **необязательные** для совместимости с прежним кодом.

## Общая Dynamics
На шаге интеграции обновляет `state.position`, `state.velocity`, `state.yaw` из `safeControl` и `state.battery` из `energy.nextBattery`. Это общая модель, не участник №8.

## Правило изменения интерфейса
Любая замена названия или типа поля требует синхронного обновления интегратора, этого документа и тестов; изменения обсуждаются в Pull Request.

## Расположение исходников

- **Эрнест Карпухин:** `team/01_Карпухин_Эрнест/subsystem_navigation.m`
- **Иван Живоглядов:** `team/02_Живоглядов_Иван/subsystem_flight_control.m`
- **Богдан Лемченко:** `team/03_Лемченко_Богдан/subsystem_route_planning.m`
- **Александр Дзедзей:** `team/04_Дзедзей_Александр/subsystem_object_detection.m`
- **Арсений Терехов:** `team/05_Терехов_Арсений/subsystem_ground_station.m`
- **Артём Пучков:** `team/06_Пучков_Артём/subsystem_flight_safety.m`
- **Иван Касимов:** `team/07_Касимов_Иван/subsystem_energy.m`
