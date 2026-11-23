function results = simulate_uav(scenario, route, cfg)
%SIMULATE_UAV Интеграция семи MATLAB-модулей и общей модели движения.
% Плоские препятствия: цилиндры по всей высоте в этой упрощённой модели.

assert(size(route,2) == 3 && size(route,1) >= 2, 'Route must be Nx3');
state = scenario.initialState;
previousNav = [];
N = floor(cfg.totalTime / cfg.dt) + 1;
time = (0:N-1)' * cfg.dt;

pos = nan(N,3);
vel = nan(N,3);
yaw = nan(N,1);
battery = nan(N,1);
navPos = nan(N,3);
navSpeed = nan(N,1);
navValid = false(N,1);
linkOK = false(N,1);
telemetryPackets = cell(N,1);
detectionCount = zeros(N,1);
waypointIndexLog = nan(N,1);
minObstacleDistance = nan(N,1);
batteryDrainRate = nan(N,1);
estimatedRemainingTime = nan(N,1);
safetyIntervention = false(N,1);
predictedConflict = false(N,1);
safetyStatus = cell(N,1);

waypointIndex = 2;
finishIndex = N;
status = 'TIME_LIMIT';

for i = 1:N
    % 01: фильтрованная навигационная оценка
    nav = subsystem_navigation(state, cfg, previousNav);
    previousNav = nav;

    % 04: обнаружение круговых препятствий
    detections = subsystem_object_detection(nav, scenario.obstacles, cfg);

    % 03: выбираем цель из рассчитанного до симуляции маршрута
    target = route(waypointIndex,:);
    if norm(nav.position - target) <= cfg.waypointTolerance && ...
            waypointIndex < size(route,1)
        waypointIndex = waypointIndex + 1;
        target = route(waypointIndex,:);
    end

    % 02: первичная команда; 07: ожидаемый расход
    control = subsystem_flight_control(nav, target, cfg);
    energy = subsystem_energy(state, cfg, control);

    % 06: безопасная команда и предупреждения; 05: телеметрия
    [safeControl, safety] = subsystem_flight_safety(nav, detections, control, energy, cfg);
    % Расход пересчитываем после коррекции команды модулем безопасности.
    energy = subsystem_energy(state, cfg, safeControl);
    packet = subsystem_ground_station(nav, state, safeControl, waypointIndex, ...
        detections, cfg, safety, energy);
    packet.timeStamp = time(i); %#ok<NASGU>

    pos(i,:) = state.position;
    vel(i,:) = state.velocity;
    yaw(i) = state.yaw;
    battery(i) = state.battery;
    navPos(i,:) = nav.position;
    navSpeed(i) = nav.speed;
    navValid(i) = safety.navValid;
    linkOK(i) = packet.linkOK;
    if packet.linkOK
        telemetryPackets{i} = packet;
    end
    detectionCount(i) = numel(detections);
    waypointIndexLog(i) = waypointIndex;
    batteryDrainRate(i) = energy.drainRate;
    estimatedRemainingTime(i) = energy.estimatedRemainingSeconds;
    safetyIntervention(i) = safety.intervened;
    predictedConflict(i) = safety.predictedConflict;
    safetyStatus{i} = safety.status;

    distances = zeros(1,numel(scenario.obstacles));
    for k = 1:numel(scenario.obstacles)
        distances(k) = norm(state.position(1:2) - ...
            scenario.obstacles(k).center) - scenario.obstacles(k).radius;
    end
    if isempty(distances)
        minObstacleDistance(i) = inf;
    else
        minObstacleDistance(i) = min(distances);
    end

    if minObstacleDistance(i) <= 0
        status = 'COLLISION';
        finishIndex = i;
        break;
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

    % Общая учебная динамика (отдельного участника у блока нет).
    state.velocity = limit_norm(state.velocity + ...
        safeControl.acceleration * cfg.dt, cfg.maxSpeed);
    nextPosition = state.position + state.velocity * cfg.dt;
    nextPosition(3) = max(cfg.minAltitude, min(cfg.maxAltitude, nextPosition(3)));
    state.position = nextPosition;
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
results.navValid = navValid(idx);
results.linkOK = linkOK(idx);
results.telemetryPackets = telemetryPackets(idx);
results.detectionCount = detectionCount(idx);
results.waypointIndex = waypointIndexLog(idx);
results.minObstacleDistance = minObstacleDistance(idx);
results.batteryDrainRate = batteryDrainRate(idx);
results.estimatedRemainingTime = estimatedRemainingTime(idx);
results.safetyIntervention = safetyIntervention(idx);
results.predictedConflict = predictedConflict(idx);
results.safetyStatus = safetyStatus(idx);
results.status = status;
results.route = route;
results.finalPosition = pos(finishIndex,:);
results.finalBattery = battery(finishIndex);
results.packetDeliveryRate = 100 * mean(linkOK(idx));
results.missionSuccess = strcmp(status, 'GOAL_REACHED');
if finishIndex > 1
    results.travelDistance = sum(sqrt(sum(diff(pos(idx,:),1,1).^2,2)));
else
    results.travelDistance = 0;
end
end
