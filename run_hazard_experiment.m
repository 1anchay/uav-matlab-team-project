function experiment = run_hazard_experiment(makePlots)
%RUN_HAZARD_EXPERIMENT Test a new obstacle unknown to the route planner.
% Does not edit or overwrite the existing .slx files.
% Uses Simulink.SimulationInput to override Obstacle Map for one simulation.
% This is a STATIC unexpected obstacle, not a dynamically moving object.
if nargin < 1, makePlots = true; end
setup_paths();
baseline = run_functional_demo(false);
model = baseline.model;
cfg = config_uav();
scene = init_scenario(cfg);

map = zeros(3,numel(scene.obstacles));
for j = 1:numel(scene.obstacles)
    map(:,j) = [scene.obstacles(j).center(:);scene.obstacles(j).radius];
end

% Place an extra hazard on the validated nominal trajectory near t=7 s.
% Replace the first map entry (3xN dimensions remain unchanged).
idx = find(baseline.time >= 7,1,'first');
assert(~isempty(idx) && idx <= size(baseline.state,1), ...
    'UAV:MissingBaseline','No baseline state at 7 seconds.');
hazardCenter = baseline.state(idx,1:2)';
hazardRadius = 3;
map(:,1) = [hazardCenter;hazardRadius];

simulationInput = Simulink.SimulationInput(model);
simulationInput = setBlockParameter(simulationInput, ...
    [model '/Obstacle Map'],'Value',mat2str(map,12));
out = sim(simulationInput);

ts = get(out,'uavf_telemetry');
ss = get(out,'uavf_state');
tt = get(out,'uavf_target');
state = unpack_signal(ss,5);
telemetry = unpack_signal(ts,7);

experiment.baseline = baseline;
experiment.time = ss.Time(:);
experiment.state = state;
experiment.telemetry = telemetry;
experiment.target = unpack_signal(tt,2);
experiment.hazardCenter = hazardCenter';
experiment.hazardRadius = hazardRadius;
experiment.obstacleMap = map;
experiment.evasions = sum(telemetry(:,7)==1);
experiment.batteryWarnings = sum(telemetry(:,7)==2);
experiment.invalidNavigation = sum(telemetry(:,7)==3);
experiment.finalDistanceToGoal = norm(state(end,1:2)-[100 80]);
experiment.minClearance = inf;
for k = 1:size(map,2)
    dx = state(:,1)-map(1,k);
    dy = state(:,2)-map(2,k);
    d = sqrt(dx.^2+dy.^2)-map(3,k);
    experiment.minClearance = min(experiment.minClearance,min(d));
end
experiment.collisionDetected = experiment.minClearance <= 0;
experiment.interventionObserved = experiment.evasions > 0;

fprintf('Unexpected obstacle at [%.2f %.2f], radius %.1f m\n', ...
    hazardCenter(1),hazardCenter(2),hazardRadius);
fprintf('Safety interventions: %d samples\n',experiment.evasions);
fprintf('Minimum boundary clearance: %.2f m\n',experiment.minClearance);
fprintf('Final distance to original goal: %.2f m\n', ...
    experiment.finalDistanceToGoal);
if experiment.collisionDetected
    fprintf('WARNING: model trajectory intersects an obstacle.\n');
end
if ~experiment.interventionObserved
    fprintf('WARNING: no safety intervention recorded. Investigate.\n');
end

if makePlots
    figure('Name','Unexpected obstacle — safety stress test', ...
        'NumberTitle','off','Position',[80 80 1080 530]);
    tiledlayout(1,2,'TileSpacing','compact','Padding','compact');
    nexttile;
    hold on; axis equal; grid on;
    th = linspace(0,2*pi,160);
    for k = 1:size(map,2)
        plot(map(1,k)+map(3,k)*cos(th), ...
            map(2,k)+map(3,k)*sin(th),'--','Color',[0.79 0.31 0.29], ...
            'HandleVisibility','off');
    end
    plot(baseline.state(:,1),baseline.state(:,2), ...
        'LineWidth',1.6,'Color',[0.36 0.42 0.77], ...
        'DisplayName','Baseline');
    plot(state(:,1),state(:,2), ...
        'LineWidth',1.8,'Color',[0.13 0.57 0.39], ...
        'DisplayName','Unknown obstacle');
    plot(hazardCenter(1),hazardCenter(2),'rx','MarkerSize',12, ...
        'HandleVisibility','off');
    plot(100,80,'kp','MarkerSize',10,'HandleVisibility','off');
    xlabel('X (m)'); ylabel('Y (m)');
    title('Route planned BEFORE new obstacle was known');
    legend('Location','best');
    nexttile;
    stairs(ts.Time,telemetry(:,7),'LineWidth',1.4);
    grid on; ylim([-0.2 3.3]); yticks(0:3);
    xlabel('Time (s)'); ylabel('Safety code');
    title(sprintf('Interventions %d | closest distance %.2f m', ...
        experiment.evasions,experiment.minClearance));
end
end

function value = unpack_signal(ts,n)
value = squeeze(ts.Data);
if size(value,2)==n
    return;
elseif size(value,1)==n
    value = value';
else
    error('UAV:SignalFormat','Unexpected signal shape (expected %d columns).',n);
end
end
