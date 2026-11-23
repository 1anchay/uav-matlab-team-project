function plot_advanced_mission(r, scene, cfg)
%PLOT_ADVANCED_MISSION Seven-module operational engineering dashboard.
% All plots are derived from actual simulated telemetry and real geometry.
figure('Name',['UAV Advanced V2 - ' r.scenario], ...
    'NumberTitle','off','Position',[60 70 1320 840]);
tl = tiledlayout(3,2,'TileSpacing','compact','Padding','compact');
title(tl,sprintf('ADVANCED UAV V2 | %s | %s | %d replans', ...
    upper(r.scenario),r.status,r.replanCount), ...
    'FontWeight','bold','FontSize',14);

nexttile;
hold on; axis equal; grid on;
theta = linspace(0,2*pi,180);
for k=1:numel(scene.obstacles)
    obs = scene.obstacles(k);
    plot(obs.center(1)+obs.radius*cos(theta), ...
        obs.center(2)+obs.radius*sin(theta), ...
        'Color',[0.85 0.3 0.3],'LineWidth',1.7, ...
        'HandleVisibility','off');
    plot(obs.center(1)+(obs.radius+cfg.advanced.replanClearance)*cos(theta), ...
        obs.center(2)+(obs.radius+cfg.advanced.replanClearance)*sin(theta), ...
        ':','Color',[0.65 0.3 0.3],'HandleVisibility','off');
end
for k=1:numel(r.routeEvents)
    path = r.routeEvents(k).route;
    if k==1
        plot(path(:,1),path(:,2),'--','Color',[0.40 0.43 0.74], ...
            'DisplayName','Initial route');
    else
        plot(path(:,1),path(:,2),'-.','Color',[0.93 0.56 0.13], ...
            'HandleVisibility','off');
    end
end
plot(r.position(:,1),r.position(:,2),'Color',[0.08 0.62 0.43], ...
    'LineWidth',2.0,'DisplayName','Actual flight');
hit = find(r.replanEvents);
if ~isempty(hit)
    scatter(r.position(hit,1),r.position(hit,2),50,'o', ...
        'MarkerEdgeColor',[0.97 0.46 0.04], ...
        'DisplayName','Online replan');
end
plot(scene.goal(1),scene.goal(2),'p','MarkerSize',11, ...
    'MarkerFaceColor',[0.96 0.74 0.16], ...
    'MarkerEdgeColor','black','HandleVisibility','off');
xlabel('X (m)');ylabel('Y (m)');
title('03/04/06 — Online discovery, route and safety');
legend('Location','best');

nexttile;
plot(r.time,r.navError,'LineWidth',1.3,'Color',[0.26 0.43 0.82]);
hold on;
stairs(r.time,double(~r.gpsAvailable)*max(0.25,max(r.navError)), ...
    '--','Color',[0.83 0.35 0.31]);
grid on;xlabel('Time (s)');ylabel('Position error (m)');
title(sprintf('01 — GPS/estimate | RMSE %.3f m',r.navRMSE));
legend('Error','GPS unavailable (scaled)','Location','best');

nexttile;
speed = sqrt(sum(r.velocity.^2,2));
plot(r.time,speed,'LineWidth',1.5,'Color',[0.16 0.48 0.79]);
hold on;yline(cfg.advanced.cruiseSpeed,'--','Cruise limit');
grid on;xlabel('Time (s)');ylabel('Speed (m/s)');
title('02 — Control and speed envelope');

nexttile;
plot(r.time,r.battery,'LineWidth',1.6,'Color',[0.13 0.63 0.38]);
hold on;yline(cfg.battery.lowWarningPercent,'--','Low battery');
yline(cfg.safety.criticalBatteryPercent,':','Critical');
grid on;xlabel('Time (s)');ylabel('Charge (%)');
title(sprintf('07 — Energy | final %.1f %%',r.finalBattery));

nexttile;
plot(r.time,r.minObstacleDistance,'LineWidth',1.5, ...
    'Color',[0.91 0.46 0.17]);
hold on;yline(0,'--','Collision boundary');
grid on;xlabel('Time (s)');ylabel('Boundary clearance (m)');
title(sprintf('04/06 — Obstacle clearance | %d safety actions', ...
    r.totalSafetyActions));

nexttile;
stairs(r.time,double(r.linkDelivered),'LineWidth',1.1, ...
    'Color',[0.25 0.51 0.79]);
hold on;stairs(r.time,double(r.replanEvents),'LineWidth',1.5, ...
    'Color',[0.96 0.46 0.05]);
ylim([-0.1 1.2]);yticks([0 1]);grid on;
xlabel('Time (s)');ylabel('Event');
title(sprintf('05/03 — Link %.1f %% | %d discoveries', ...
    r.packetDeliveryRate,r.discoveredObstacles));
legend('Delivered packet','New route','Location','best');
end
