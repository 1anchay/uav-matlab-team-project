function plot_results(results, scenario, cfg)
%PLOT_RESULTS Графики для демонстрации преподавателю.

figure('Name','UAV mission: top view');
hold on; grid on; axis equal;

% Препятствия и безопасные зоны
th = linspace(0, 2*pi, 150);
for i = 1:numel(scenario.obstacles)
    c = scenario.obstacles(i).center;
    r = scenario.obstacles(i).radius;
    rs = r + cfg.route.clearance;
    plot(c(1) + r*cos(th),  c(2) + r*sin(th),  'LineWidth', 1.5);
    plot(c(1) + rs*cos(th), c(2) + rs*sin(th), '--', 'LineWidth', 1.0);
    text(c(1), c(2), scenario.obstacles(i).name, 'HorizontalAlignment','center');
end

plot(results.route(:,1), results.route(:,2), 'o--', 'LineWidth', 1.4, 'DisplayName','Planned route');
plot(results.position(:,1), results.position(:,2), '-', 'LineWidth', 2.0, 'DisplayName','UAV trajectory');
plot(scenario.start(1), scenario.start(2), 's', 'MarkerSize', 9, 'LineWidth', 2, 'DisplayName','Start');
plot(scenario.goal(1), scenario.goal(2), 'p', 'MarkerSize', 11, 'LineWidth', 2, 'DisplayName','Goal');
xlim(cfg.scenario.bounds(1:2)); ylim(cfg.scenario.bounds(3:4));
xlabel('X, m'); ylabel('Y, m');
title('Route planning and flight trajectory');
legend('Location','bestoutside');

figure('Name','UAV telemetry');
tiledlayout(3,1);
nexttile;
plot(results.time, results.position(:,3), 'LineWidth', 1.5); grid on;
ylabel('Altitude, m'); title('Navigation / telemetry');
nexttile;
plot(results.time, results.navSpeed, 'LineWidth', 1.5); grid on;
ylabel('Speed, m/s');
nexttile;
plot(results.time, results.battery, 'LineWidth', 1.5); grid on;
ylabel('Battery, %'); xlabel('Time, s');

figure('Name','Safety and communication');
tiledlayout(2,1);
nexttile;
plot(results.time, results.minObstacleDistance, 'LineWidth', 1.5); grid on; hold on;
yline(cfg.route.clearance, '--');
ylabel('Distance, m'); title('Minimum distance to obstacle boundary');
nexttile;
stairs(results.time, double(results.linkOK), 'LineWidth', 1.0); grid on;
ylim([-0.1 1.1]); yticks([0 1]); yticklabels({'lost','received'});
xlabel('Time, s'); ylabel('Telemetry packet');
end
