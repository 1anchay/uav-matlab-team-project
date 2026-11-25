function plot_verification_dashboard(report)
%PLOT_VERIFICATION_DASHBOARD Seven-module mission monitoring dashboard.
% First case is always the nominal mission.
item = report.cases(1);
assert(~isempty(item.result),'UAV:NoBaseline','No baseline results available.');
r = item.result;
scene = item.scenario;
cfg = config_uav();
t = r.time;
th = linspace(0,2*pi,200);

figure('Name','UAV Verification Dashboard - 7 Modules', ...
    'NumberTitle','off','Position',[80 80 1250 770]);
tiles = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
title(tiles,sprintf('UAV | 7 modules | %s | %.1f%% packets delivered', ...
    r.status,r.packetDeliveryRate),'FontSize',14,'FontWeight','bold');

nexttile;
hold on; grid on; axis equal;
for k = 1:numel(scene.obstacles)
    obs = scene.obstacles(k);
    plot(obs.center(1)+obs.radius*cos(th), ...
        obs.center(2)+obs.radius*sin(th),'Color',[0.77 0.31 0.3], ...
        'HandleVisibility','off');
    plot(obs.center(1)+(obs.radius+cfg.route.clearance)*cos(th), ...
        obs.center(2)+(obs.radius+cfg.route.clearance)*sin(th), ...
        ':','Color',[0.77 0.31 0.3],'HandleVisibility','off');
end
plot(r.route(:,1),r.route(:,2),'--o','Color',[0.22 0.37 0.78], ...
    'DisplayName','Planned route');
plot(r.position(:,1),r.position(:,2),'LineWidth',1.9, ...
    'Color',[0.13 0.55 0.40],'DisplayName','Actual flight');
plot(scene.start(1),scene.start(2),'ks','MarkerFaceColor','k', ...
    'HandleVisibility','off');
plot(scene.goal(1),scene.goal(2),'kp','MarkerSize',11, ...
    'MarkerFaceColor',[0.97 0.74 0.2], ...
    'HandleVisibility','off');
xlabel('X (m)'); ylabel('Y (m)'); title('01/03/04 — Route and obstacles');
legend('Location','best');

nexttile;
navError = sqrt(sum((r.navPosition-r.position).^2,2));
plot(t,navError,'LineWidth',1.4,'Color',[0.34 0.38 0.82]);
grid on; xlabel('Time (s)'); ylabel('Error (m)');
title(sprintf('01 — Navigation | RMSE %.3f m',sqrt(mean(navError.^2))));

nexttile;
plot(t,r.navSpeed,'LineWidth',1.4,'Color',[0.13 0.47 0.8]);
hold on; yline(cfg.maxSpeed,'--','Speed limit');
grid on; xlabel('Time (s)'); ylabel('Speed (m/s)');
title('02 — Flight control and speed');

nexttile;
plot(t,r.battery,'LineWidth',1.7,'Color',[0.20 0.62 0.35]);
hold on; yline(cfg.battery.lowWarningPercent,'--','Low');
yline(cfg.safety.criticalBatteryPercent,':','Critical');
grid on; xlabel('Time (s)'); ylabel('Battery (%)');
title(sprintf('07 — Energy | final %.1f %%',r.finalBattery));

nexttile;
plot(t,r.minObstacleDistance,'LineWidth',1.4,'Color',[0.82 0.42 0.23]);
hold on; yline(cfg.route.clearance,'--','Plan clearance');
grid on; xlabel('Time (s)'); ylabel('Boundary clearance (m)');
title(sprintf('04/06 — Safety | %d interventions',sum(r.safetyIntervention)));

nexttile;
stairs(t,double(r.linkOK),'Color',[0.23 0.46 0.70], ...
    'LineWidth',1.1);
hold on; stairs(t,double(r.safetyIntervention),'Color',[0.82 0.31 0.3]);
grid on; ylim([-0.1 1.2]); yticks([0 1]);
xlabel('Time (s)'); ylabel('Boolean');
title('05/06 — Delivered telemetry and safety');
legend('Packet delivered','Safety action','Location','best');

figure('Name','UAV Reliability Sweep - 10 randomized missions', ...
    'NumberTitle','off','Position',[120 100 1000 480]);
mc = report.monteCarlo;
t2 = tiledlayout(1,2,'TileSpacing','compact');
title(t2,sprintf('Reproducibility check | %.0f %% successful seeds', ...
    report.monteCarloSuccessRate));
nexttile;
bar([mc.seed],[mc.finalDistance]); grid on;
xlabel('Random seed'); ylabel('Final distance to goal (m)');
title('Navigation variability');
nexttile;
bar([mc.seed],[mc.minClearance]); grid on;
yline(0,'--','Collision boundary');
xlabel('Random seed'); ylabel('Closest obstacle clearance (m)');
title('Safety margins across seeds');
end
