%% Acceptance tests for executable 2D Model Reference architecture.
% Run AFTER run('tests/run_tests.m') and old Simulink smoke test.
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
assert(license('test','Simulink')==1,'Simulink is required.');

modelFile = build_functional_simulink_model();
[~,main] = fileparts(modelFile);
load_system(main);

refs = find_system(main,'SearchDepth',1,'BlockType','ModelReference');
assert(numel(refs)==8, ...
    'Expected 7 executable member Model References + Dynamics.');
for k = 1:numel(refs)
    referencedName = get_param(refs{k},'ModelName');
    load_system(referencedName);
    charts = find(sfroot,'-isa','Stateflow.EMChart');
    inReferenced = false;
    for j = 1:numel(charts)
        if strncmp(char(charts(j).Path),[referencedName '/'], ...
                numel(referencedName)+1)
            inReferenced = true;
            assert(~contains(char(charts(j).Script),'InterfacePlaceholder'), ...
                'Placeholder found in executable model');
        end
    end
    assert(inReferenced,'No executable MATLAB Function in %s',referencedName);
end
% Матрица Obstacles должна быть именно 3 x N, а не наследуемым scalar.
cfg = config_uav();
scene = init_scenario(cfg);
route = subsystem_route_planning(scene.start,scene.goal,scene.obstacles,cfg);
expectedDims = functional_port_dimensions(size(route,1),numel(scene.obstacles));
modelNames = {'UAVF_Navigation_01','UAVF_FlightControl_02', ...
    'UAVF_Waypoint_03','UAVF_Detection_04', ...
    'UAVF_GroundStation_05','UAVF_Safety_06', ...
    'UAVF_Energy_07','UAVF_Dynamics_Overview'};
inports = {{'State'},{'Navigation','Target'}, ...
    {'Navigation','Waypoints'},{'Navigation','Obstacles'}, ...
    {'Navigation','Detection','Energy','SafetyStatus','State'}, ...
    {'Control','Detection','Navigation','Energy'}, ...
    {'State','Control'},{'SafeControl','Energy'}};
for k = 1:numel(modelNames)
    for j = 1:numel(inports{k})
        actual = strrep(get_param([modelNames{k} '/' inports{k}{j}], ...
            'PortDimensions'),' ','');
        wanted = strrep(expectedDims{k}{j},' ','');
        assert(strcmp(actual,wanted), ...
            'Wrong dimensions in %s/%s: %s instead of %s', ...
            modelNames{k},inports{k}{j},actual,wanted);
    end
end
% Требуется явная задержка на верхнем уровне в контуре Model Reference:
% без неё persistent waypoint может попасть в алгебраическую петлю.
feedbackDelay = [main '/State Feedback Delay'];
assert(getSimulinkBlockHandle(feedbackDelay) ~= -1, ...
    'Missing top-level Unit Delay in the flight feedback loop.');
assert(strcmp(get_param(feedbackDelay,'BlockType'),'UnitDelay'), ...
    'State feedback must pass through Unit Delay.');
navPort = get_param([main '/01 Navigation'],'PortHandles');
energyPort = get_param([main '/07 Energy'],'PortHandles');
feedbackPort = get_param(feedbackDelay,'PortHandles');
assert(get_param(get_param(navPort.Inport(1),'Line'),'SrcPortHandle') == ...
    feedbackPort.Outport(1), 'Navigation bypasses feedback delay');
assert(get_param(get_param(energyPort.Inport(1),'Line'),'SrcPortHandle') == ...
    feedbackPort.Outport(1), 'Energy bypasses feedback delay');
fprintf('[A] 8 Model References, port dimensions and feedback delay verified.\n');

assert(getSimulinkBlockHandle([main '/Mission Supervisor']) ~= -1, ...
    'Missing mission terminal supervisor. Run repair_functional_mission.');
assert(getSimulinkBlockHandle([main '/Stop On Terminal State']) ~= -1, ...
    'Missing Stop Simulation block.');
set_param(main,'SimulationCommand','update');
fprintf('[B] Simulink diagram compiled.\n');

r = run_functional_demo(false);
assert(size(r.state,2)==5 && size(r.telemetry,2)==7, ...
    'Wrong dimensions in simulation log');
assert(~isempty(r.time) && all(isfinite(r.state(:))) && ...
    all(isfinite(r.telemetry(:))), 'Simulation contains NaN or Inf');
assert(r.minBattery >= 0 && r.minBattery <= 100, ...
    'Battery outside physical percentage range');
assert(all(diff(r.state(:,5)) <= 1e-7), ...
    'Battery should never increase in this scenario');
assert(r.maxSpeed <= 10 + 1e-6,'Velocity limit violated');

% Проверяем фактическую траекторию относительно физических кругов препятствий.
cfg = config_uav();
scenario = init_scenario(cfg);
for k = 1:numel(scenario.obstacles)
    obs = scenario.obstacles(k);
    dx = r.state(:,1)-obs.center(1);
    dy = r.state(:,2)-obs.center(2);
    clearance = sqrt(dx.^2+dy.^2)-obs.radius;
    assert(all(clearance > 0), ...
        'Simulink trajectory intersects obstacle %d',k);
end
fprintf('[C] Simulation data, limits and collision checks passed.\n');

% Fail explicitly if the reference mission is incomplete.
assert(r.goalReached, ...
    '2D Model Reference drone did not reach the goal (distance %.2f m)', ...
    r.distanceToGoal);
assert(r.missionFinished && any(r.missionCodes==1), ...
    'Mission supervisor did not report GOAL_REACHED.');
assert(r.duration < cfg.totalTime - cfg.dt, ...
    'Mission should terminate before the 120-second StopTime.');
fprintf('[D] Functional 2D mission reached goal.\n');
fprintf('All executable Simulink tests passed.\n');
