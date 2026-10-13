%% UAV TEAM PROJECT
% Небольшой учебный проект по модельно-ориентированному проектированию.
% Пять программных подсистем соответствуют пяти участникам команды.

clear; clc; close all;

setup_paths();

cfg = config_uav();
rng(cfg.seed);
scenario = init_scenario(cfg);

fprintf('=== UAV MODEL-ORIENTED TEAM PROJECT ===\n');
fprintf('Planning route...\n');
route = subsystem_route_planning(scenario.start, scenario.goal, scenario.obstacles, cfg);
fprintf('Waypoints: %d\n', size(route,1));

results = simulate_uav(scenario, route, cfg);
plot_results(results, scenario, cfg);

fprintf('\nMission status: %s\n', results.status);
fprintf('Simulation time: %.1f s\n', results.time(end));
fprintf('Final position: [%.1f %.1f %.1f] m\n', results.finalPosition);
fprintf('Final battery: %.1f %%\n', results.finalBattery);
fprintf('Telemetry delivery: %.1f %%\n', results.packetDeliveryRate);
fprintf('Minimum obstacle-boundary distance: %.2f m\n', min(results.minObstacleDistance));
fprintf('\nRun build_simulink_model to generate the block architecture in Simulink.\n');
