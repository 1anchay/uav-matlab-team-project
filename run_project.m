%% UAV TEAM PROJECT — 7 участников / 7 подсистем
clear; clc; close all;
setup_paths();

cfg = config_uav();
rng(cfg.seed);
scenario = init_scenario(cfg);

fprintf('=== UAV TEAM PROJECT: SEVEN MODULES ===\n');
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
fprintf('Safety interventions: %d\n', sum(results.safetyIntervention));
fprintf('Average battery drain rate: %.3f percentage points/s\n', mean(results.batteryDrainRate));
fprintf('\nRun build_simulink_model for the architectural overview in Simulink.\n');
