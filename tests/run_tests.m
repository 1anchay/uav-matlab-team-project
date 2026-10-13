%% BASIC TESTS FOR UAV TEAM PROJECT
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();

cfg = config_uav();
rng(cfg.seed);
scenario = init_scenario(cfg);
route = subsystem_route_planning(scenario.start, scenario.goal, scenario.obstacles, cfg);

% Тест 1: маршрут начинается и заканчивается в требуемых точках
assert(norm(route(1,:) - scenario.start) < 1e-9, 'Route start is wrong');
assert(norm(route(end,:) - scenario.goal) < 1e-9, 'Route goal is wrong');

% Тест 2: все участки маршрута должны обходить безопасные зоны
for i = 1:size(route,1)-1
    assert(segment_is_safe(route(i,:), route(i+1,:), scenario.obstacles, cfg.route.clearance - 0.05), ...
        'Unsafe route segment detected');
end

% Тест 3: команды управления не превышают ограничения
state = scenario.initialState;
nav = subsystem_navigation(state, cfg);
control = subsystem_flight_control(nav, scenario.goal, cfg);
assert(norm(control.acceleration) <= cfg.maxAccel + 1e-9, 'Acceleration limit violated');
assert(abs(control.yawRate) <= cfg.maxYawRate + 1e-9, 'Yaw-rate limit violated');

% Тест 4: интеграционная симуляция запускается и выдает результат
results = simulate_uav(scenario, route, cfg);
assert(~isempty(results.position), 'Simulation returned no data');
assert(all(isfinite(results.position(:))), 'Simulation contains NaN/Inf');
assert(min(results.minObstacleDistance) > 0, 'UAV collided with obstacle');

fprintf('All basic tests passed. Mission status: %s\n', results.status);
