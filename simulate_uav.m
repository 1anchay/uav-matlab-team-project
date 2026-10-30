function results = simulate_uav(scenario, route, cfg)
%SIMULATE_UAV Интеграция семи подсистем и упрощенной динамики БПЛА.

state = scenario.initialState;
N = floor(cfg.totalTime / cfg.dt) + 1;
time = (0:N-1)' * cfg.dt;

pos = nan(N,3);
vel = nan(N,3);
yaw = nan(N,1);
battery = nan(N,1);
navPos = nan(N,3);
navSpeed = nan(N,1);
linkOK = false(N,1);
detectionCount = zeros(N,1);
waypointIndexLog = nan(N,1);
minObstacleDistance = nan(N,1);
batteryDrainRate = nan(N,1);
estimatedRemainingTime = nan(N,1);
safetyIntervention = false(N,1);
safetyStatus = cell(N,1);

waypointIndex = min(2, size(route,1));
finishIndex = N;
status = 'TIME_LIMIT';

for i = 1:N
    % 1. Навигация
    nav = subsystem_navigation(state, cfg);

    % 4. Обнаружение препятствий
    detections = subsystem_object_detection(nav, scenario.obstacles, cfg);

    % 3. Маршрут заранее рассчитан; выбираем очередную точку
    target = route(waypointIndex,:);
    if norm(nav.position - target) <= cfg.waypointTolerance && waypointIndex < size(route,1)
        waypointIndex = waypointIndex + 1;
        target = route(waypointIndex,:);
    end

    % 2. Первичная команда управления
    control = subsystem_flight_control(nav, target, cfg);

    % 7. Энергосистема
    energy = subsystem_energy(state, cfg);

    % 6. Контроль безопасности и корректировка команд
    [safeControl, safety] = subsystem_flight_safety(nav, detections, control, energy, cfg);

    % 5. Телеметрия с дополнительными статусами безопасности/батареи
    packet = subsystem_ground_station(nav, state, safeControl, waypointIndex, ...
        detections, cfg, safety, energy);
    packet.timeStamp = time(i); %#ok<NASGU>

    % Логирование состояния до интеграционного шага
    pos(i,:) = state.position;
    vel(i,:) = state.velocity;
    yaw(i) = state.yaw;
    battery(i) = state.battery;
    navPos(i,:) = nav.position;
    navSpeed(i) = nav.speed;
    linkOK(i) = packet.linkOK;
    detectionCount(i) = numel(detections);
    waypointIndexLog(i) = waypointIndex;
    batteryDrainRate(i) = energy.drainRate;
    estimatedRemainingTime(i) = energy.estimatedRemainingSeconds;
    safetyIntervention(i) = safety.intervened;
    safetyStatus{i} = safety.status;

    distances = zeros(1,numel(scenario.obstacles));
    for k = 1:numel(scenario.obstacles)
        distances(k) = norm(state.position(1:2) - scenario.obstacles(k).center) - ...
            scenario.obstacles(k).radius;
    end
    if isempty(distances)
        minObstacleDistance(i) = inf;
    else
        minObstacleDistance(i) = min(distances);
    end

    if norm(state.position - scenario.goal) <= cfg.goalTolerance
        status = 'GOAL_REACHED';
        finishIndex = i;
        break;
    end
    if state.battery <= cfg.safety.criticalBatteryPercent
        status = 'LOW_BATTERY';
        finishIndex = i;
        break;
    end

    % Общая модель движения (не отдельный участник)
    state.velocity = state.velocity + safeControl.acceleration * cfg.dt;
    state.velocity = limit_norm(state.velocity, cfg.maxSpeed);
    state.position = state.position + state.velocity * cfg.dt;
    state.position(3) = max(cfg.minAltitude, min(cfg.maxAltitude, state.position(3)));
    state.yaw = wrap_angle(state.yaw + safeControl.yawRate * cfg.dt);
    state.battery = energy.nextBattery;
end

idx = 1:finishIndex;
results.time = time(idx);
results.position = pos(idx,:);
results.velocity = vel(idx,:);
results.yaw = yaw(idx);
results.battery = battery(idx);
results.navPosition = navPos(idx,:);
results.navSpeed = navSpeed(idx);
results.linkOK = linkOK(idx);
results.detectionCount = detectionCount(idx);
results.waypointIndex = waypointIndexLog(idx);
results.minObstacleDistance = minObstacleDistance(idx);
results.batteryDrainRate = batteryDrainRate(idx);
results.estimatedRemainingTime = estimatedRemainingTime(idx);
results.safetyIntervention = safetyIntervention(idx);
results.safetyStatus = safetyStatus(idx);
results.status = status;
results.route = route;
results.finalPosition = pos(finishIndex,:);
results.finalBattery = battery(finishIndex);
results.packetDeliveryRate = 100 * mean(linkOK(idx));
end
