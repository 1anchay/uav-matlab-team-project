function results = simulate_uav(scenario, route, cfg)
%SIMULATE_UAV Интеграция пяти подсистем вокруг упрощенной модели БПЛА.

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

waypointIndex = min(2, size(route,1));
finishIndex = N;
status = 'TIME_LIMIT';

for i = 1:N
    % 1) Навигация
    nav = subsystem_navigation(state, cfg);

    % 4) Обнаружение объектов
    detections = subsystem_object_detection(nav, scenario.obstacles, cfg);

    % 3) Планировщик уже создал безопасный набор контрольных точек.
    % На каждом шаге выбирается текущая цель маршрута.
    target = route(waypointIndex,:);
    if norm(nav.position - target) <= cfg.waypointTolerance && waypointIndex < size(route,1)
        waypointIndex = waypointIndex + 1;
        target = route(waypointIndex,:);
    end

    % 2) Управление полетом
    control = subsystem_flight_control(nav, target, cfg);

    % 5) Наземная станция/канал связи
    packet = subsystem_ground_station(nav, state, control, waypointIndex, detections, cfg);
    packet.timeStamp = time(i); %#ok<NASGU>

    % Логирование до изменения состояния
    pos(i,:) = state.position;
    vel(i,:) = state.velocity;
    yaw(i) = state.yaw;
    battery(i) = state.battery;
    navPos(i,:) = nav.position;
    navSpeed(i) = nav.speed;
    linkOK(i) = packet.linkOK;
    detectionCount(i) = numel(detections);
    waypointIndexLog(i) = waypointIndex;

    distances = zeros(1,numel(scenario.obstacles));
    for k = 1:numel(scenario.obstacles)
        distances(k) = norm(state.position(1:2) - scenario.obstacles(k).center) - scenario.obstacles(k).radius;
    end
    minObstacleDistance(i) = min(distances);

    % Критерий выполнения миссии
    if norm(state.position - scenario.goal) <= cfg.goalTolerance
        status = 'GOAL_REACHED';
        finishIndex = i;
        break;
    end
    if state.battery <= 5
        status = 'LOW_BATTERY';
        finishIndex = i;
        break;
    end

    % Упрощенная динамика аппарата: интегрирование ускорения и скорости.
    state.velocity = state.velocity + control.acceleration * cfg.dt;
    state.velocity = limit_norm(state.velocity, cfg.maxSpeed);
    state.position = state.position + state.velocity * cfg.dt;
    state.position(3) = max(cfg.minAltitude, min(cfg.maxAltitude, state.position(3)));
    state.yaw = wrap_angle(state.yaw + control.yawRate * cfg.dt);

    % Расход батареи зависит от времени и интенсивности движения.
    drain = cfg.battery.baseDrainPerSecond + cfg.battery.motionDrainFactor * norm(state.velocity);
    state.battery = max(0, state.battery - drain * cfg.dt);
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
results.status = status;
results.route = route;
results.finalPosition = pos(finishIndex,:);
results.finalBattery = battery(finishIndex);
results.packetDeliveryRate = 100 * mean(linkOK(idx));
end
