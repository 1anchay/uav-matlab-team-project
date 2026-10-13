function scenario = init_scenario(cfg)
%INIT_SCENARIO Исходная обстановка для демонстрации проекта.

scenario.start = cfg.scenario.start;
scenario.goal = cfg.scenario.goal;
scenario.bounds = cfg.scenario.bounds;

% Круговые препятствия на плоскости XY.
% center = [x y], radius = радиус объекта/запретной зоны.
scenario.obstacles(1).center = [35 25];
scenario.obstacles(1).radius = 8;
scenario.obstacles(1).name = 'Obstacle A';

scenario.obstacles(2).center = [60 52];
scenario.obstacles(2).radius = 10;
scenario.obstacles(2).name = 'Obstacle B';

scenario.obstacles(3).center = [78 32];
scenario.obstacles(3).radius = 7;
scenario.obstacles(3).name = 'Obstacle C';

scenario.initialState.position = scenario.start;
scenario.initialState.velocity = [0 0 0];
scenario.initialState.yaw = 0;
scenario.initialState.battery = cfg.battery.initialPercent;
end
