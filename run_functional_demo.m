function result = run_functional_demo(makePlots)
%RUN_FUNCTIONAL_DEMO Build and simulate the independent 2D Simulink model.
% Requires Simulink. This does NOT replace run_project (the 3D MATLAB demo).
% Returns data for automated testing; plots when called without arguments.
if nargin < 1, makePlots = true; end
root = fileparts(mfilename('fullpath'));
addpath(root);
setup_paths();
modelFile = build_functional_simulink_model();
[~,modelName] = fileparts(modelFile);

% Separate Model References execute actual MATLAB Function code.
if getSimulinkBlockHandle([modelName '/Mission Supervisor']) == -1
    error('UAVF:MissionUpgradeNeeded', ...
        'Run repair_functional_mission on existing generated models first.');
end
out = sim(modelName);
telemetry = get(out,'uavf_telemetry');
state = get(out,'uavf_state');
target = get(out,'uavf_target');
mission = get(out,'uavf_mission_status');

result.time = telemetry.Time(:);
result.missionCodes = double(mission.Data(:));
result.duration = result.time(end);
result.terminalCode = result.missionCodes(end);
result.missionFinished = any(result.missionCodes ~= 0);
result.telemetry = signal_rows(telemetry,7);
result.state = signal_rows(state,5);
result.target = signal_rows(target,2);
result.goal = [100 80];
result.finalPosition = result.state(end,1:2);
result.distanceToGoal = norm(result.finalPosition - result.goal);
result.goalReached = result.distanceToGoal < 5;
result.minBattery = min(result.state(:,5));
result.maxSpeed = max(sqrt(sum(result.state(:,3:4).^2,2)));
result.safetyInterventions = sum(result.telemetry(:,7) == 1);
result.safetyErrors = sum(result.telemetry(:,7) == 3);
result.model = modelName;

fprintf('Functional Simulink model: %s\n',modelName);
fprintf('Final position: [%.2f %.2f] m\n',result.finalPosition(1),result.finalPosition(2));
fprintf('Distance to goal: %.2f m\n',result.distanceToGoal);
fprintf('Maximum speed: %.2f m/s\n',result.maxSpeed);
fprintf('Minimum battery: %.2f %%\n',result.minBattery);
fprintf('Mission end time: %.2f s of %.2f s configured\n', ...
    result.duration,config_uav_total_time());
fprintf('Mission status code: %d (0=flying, 1=goal, 2=collision, 3=low battery, 4=invalid)\n', ...
    result.terminalCode);
fprintf('Evasive actions (samples): %d\n',result.safetyInterventions);
if result.goalReached
    fprintf('2D Model Reference mission: GOAL_REACHED\n');
else
    fprintf('2D Model Reference mission: NOT_REACHED (review trajectory)\n');
end

if makePlots
    cfg = config_uav();
    scenario = init_scenario(cfg);
    route = subsystem_route_planning(scenario.start,scenario.goal, ...
        scenario.obstacles,cfg);

    figure('Name','Functional Simulink UAV — trajectory');
    hold on; grid on; axis equal;
    th = linspace(0,2*pi,180);
    for k = 1:numel(scenario.obstacles)
        obs = scenario.obstacles(k);
        r = obs.radius + cfg.route.clearance;
        plot(obs.center(1)+r*cos(th),obs.center(2)+r*sin(th),'--');
    end
    plot(route(:,1),route(:,2),'o--','LineWidth',1.2, ...
        'DisplayName','MATLAB planned waypoints');
    plot(result.state(:,1),result.state(:,2),'-','LineWidth',2, ...
        'DisplayName','Simulink trajectory');
    plot(result.goal(1),result.goal(2),'p','MarkerSize',11, ...
        'DisplayName','Goal');
    xlabel('X, m'); ylabel('Y, m');
    title('Independent executable Simulink Model References (2D)');
    legend('Location','bestoutside');

    figure('Name','Functional Simulink UAV — telemetry');
    tiledlayout(3,1);
    nexttile;
    plot(result.time,result.state(:,5),'LineWidth',1.4);
    grid on; ylabel('Battery, %'); title('Energy model');
    nexttile;
    plot(result.time,sqrt(sum(result.state(:,3:4).^2,2)),'LineWidth',1.4);
    grid on; ylabel('Speed, m/s'); title('Flight dynamics');
    nexttile;
    stairs(result.time,result.telemetry(:,7),'LineWidth',1.1);
    grid on; ylabel('Safety code'); xlabel('Time, s');
end
end

function totalTime = config_uav_total_time()
cfg = config_uav();
totalTime = cfg.totalTime;
end

function x = signal_rows(ts,n)
% Output time series may store vector samples as N-by-n or n-by-1-by-N.
x = squeeze(ts.Data);
if size(x,2) == n
    return;
elseif size(x,1) == n
    x = x.';
else
    error('UAVF:BadLogShape','Unexpected logged signal size; expected %d fields.',n);
end
end
