%% BASIC TESTS FOR SEVEN UAV MODULES
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();

cfg = config_uav();
rng(cfg.seed);
scenario = init_scenario(cfg);
route = subsystem_route_planning(scenario.start, scenario.goal, scenario.obstacles, cfg);

% 1. Маршрут начинается и заканчивается в требуемых точках
assert(norm(route(1,:) - scenario.start) < 1e-9, 'Route start is wrong');
assert(norm(route(end,:) - scenario.goal) < 1e-9, 'Route goal is wrong');

% 2. Отрезки маршрута обходят препятствия
for i = 1:size(route,1)-1
    assert(segment_is_safe(route(i,:), route(i+1,:), scenario.obstacles, ...
        cfg.route.clearance - 0.05), 'Unsafe route segment detected');
end

% 3. Базовые ограничения управления
state = scenario.initialState;
nav = subsystem_navigation(state, cfg);
control = subsystem_flight_control(nav, scenario.goal, cfg);
assert(norm(control.acceleration) <= cfg.maxAccel + 1e-9, 'Acceleration limit violated');
assert(abs(control.yawRate) <= cfg.maxYawRate + 1e-9, 'Yaw-rate limit violated');

% 4. Новый модуль энергосистемы
energy = subsystem_energy(state, cfg);
assert(energy.nextBattery < state.battery, 'Battery should decrease');
assert(energy.nextBattery >= 0, 'Battery must not be negative');
assert(isfinite(energy.estimatedRemainingSeconds), 'Energy estimate must be finite');

% 5. Новый модуль безопасности: отсутствие вмешательства в пустой сцене
[safe, safety] = subsystem_flight_safety(nav, struct('relativeXY', {}, ...
    'distanceToBoundary', {}), control, energy, cfg);
assert(~safety.intervened, 'Unexpected safety intervention');
assert(norm(safe.acceleration) <= cfg.maxAccel + 1e-9, 'Safety acceleration limit');

% 6. Аварийное сближение: система задаёт увод от препятствия
closeObstacle = struct('relativeXY', [5 0], 'distanceToBoundary', 1.0);
[corrected, warning] = subsystem_flight_safety(nav, closeObstacle, control, energy, cfg);
assert(warning.intervened, 'Safety module did not react');
assert(corrected.acceleration(1) < 0, 'Safety must accelerate away from obstacle');

% 7. Телеметрия содержит данные новых модулей
packet = subsystem_ground_station(nav, state, corrected, 1, closeObstacle, cfg, warning, energy);
assert(isfield(packet, 'safetyStatus'), 'Missing safety status');
assert(isfield(packet, 'estimatedRemainingTime'), 'Missing energy forecast');

% 8. Интеграционная симуляция
results = simulate_uav(scenario, route, cfg);
assert(~isempty(results.position), 'Simulation returned no data');
assert(all(isfinite(results.position(:))), 'Simulation contains NaN/Inf');
assert(min(results.minObstacleDistance) > 0, 'UAV collided with obstacle');
assert(numel(results.batteryDrainRate) == numel(results.time), 'Energy log mismatch');
assert(numel(results.safetyStatus) == numel(results.time), 'Safety log mismatch');

fprintf('All seven-module tests passed. Mission status: %s\n', results.status);
