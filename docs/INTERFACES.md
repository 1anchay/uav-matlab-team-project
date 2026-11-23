# Контракты сигналов 7 модулей UAV

Все длины — метры, скорость — м/с, ускорение — м/с², углы — радианы, батарея — %. Функции выполняются в MATLAB; схемы Simulink пока не содержат этих алгоритмов.

## 01 Навигация — Эрнест Карпухин

`nav = subsystem_navigation(trueState, cfg, previousNav)`; последний аргумент необязателен.

Выход: `nav.position [1x3]`, `nav.velocity [1x3]`, `nav.speed`, `nav.altitude`, `nav.course`, `nav.yaw`, `nav.positionValid`, `nav.headingValid`, `nav.quality`, `nav.rawPosition`, `nav.rawVelocity`. `course` — курс скорости при движении; `yaw` — курс корпуса. `previousNav` используется как вход дискретного фильтра.

## 03 Маршрут — Богдан Лемченко

`route = subsystem_route_planning(startPos, goalPos, obstacles, cfg)` до начала симуляции. Возвращает `route [N x 3]`, каждый сегмент проходит вне запретных кругов с дополнительным зазором `cfg.route.clearance`. Недопустимые точки и неудачное планирование приводят к исключению `UAV:RoutePlanning:InvalidEndpoint` и `UAV:RoutePlanning:UnsafeRoute`.

## 04 Обнаружение — Александр Дзедзей

`detections = subsystem_object_detection(nav,obstacles,cfg)`. Массив структур с полями `name`, `distanceToBoundary`, `bearing`, `relativeXY [1x2]`, `isWarning`, `confidence`, `closingSpeed`, `timeToCollision`, `penetrationDepth`. При недостоверной навигации — пустые обнаружения.

## 02 Управление — Иван Живоглядов

`control = subsystem_flight_control(nav,targetWaypoint,cfg)`. Поля: `target`, `desiredVelocity [1x3]`, `acceleration [1x3]`, `yawRate`, `positionError [1x3]`, `distanceToTarget`.

## 07 Энергия — Иван Касимов

`energy = subsystem_energy(state,cfg,control)`; `control` необязателен. Поля `currentBattery`, `nextBattery`, `drainRate`, `lowBattery`, `criticalBattery`, `estimatedRemainingSeconds`, `predictedSpeed`. Время оценивается **до критического порога**, а не до полного разряда.

## 06 Безопасность — Артём Пучков

`[safeControl,safety] = subsystem_flight_safety(nav,detections,control,energy,cfg)`. `safeControl` сохраняет структуру команды; `acceleration` и `yawRate` могут измениться. Поля `safety`: `status`, `intervened`, `obstacleWarning`, `nearestObstacleDistance`, `predictedNearestDistance`, `predictedConflict`, `lowBattery`, `criticalBattery`, `navValid`. `status`: `OK`, `OBSTACLE_WARNING`, `OBSTACLE_AVOIDANCE`, `LOW_BATTERY`, `CRITICAL_BATTERY`, `NAV_INVALID`.

## 05 Наземная станция — Арсений Терехов

`packet = subsystem_ground_station(nav,state,safeControl,waypointIndex,detections,cfg,safety,energy)`. Последние два аргумента необязательны. Поля включают `linkOK`, `timeStamp`, `position`, `altitude`, `speed`, `course`, `battery`, `waypointIndex`, `detectedObjects`, `commandedAcceleration`, `safetyStatus`, `safetyIntervention`, `navValid`, `batteryWarning`, `criticalBattery`, `estimatedRemainingTime`.

## Общая динамика — интегратор

`simulate_uav(scenario,route,cfg)` обновляет истинное состояние по `safeControl`, заряд по `energy.nextBattery`, логирует результаты. Не является восьмым модулем. Статусы `GOAL_REACHED`, `TIME_LIMIT`, `LOW_BATTERY`, `COLLISION`. Сценарий использует неподвижные круговые препятствия в XY. Динамическое перепланирование **не реализовано**: в архитектурной схеме поток обнаружений используется для контроля безопасности и телеметрии, а маршрут строится заранее.

## Управление изменениями

При изменении поля обязательно обнови вызывающие функции, этот документ, тест и README соответствующего участника. Совместные изменения оформляй отдельным Pull Request.
