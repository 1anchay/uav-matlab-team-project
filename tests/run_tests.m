%% UAV: проверка требований семи модулей и общей интеграции
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();

names = {'01_Карпухин_Эрнест', '02_Живоглядов_Иван', ...
    '03_Лемченко_Богдан', '04_Дзедзей_Александр', ...
    '05_Терехов_Арсений', '06_Пучков_Артём', '07_Касимов_Иван'};
functions = {'subsystem_navigation.m', 'subsystem_flight_control.m', ...
    'subsystem_route_planning.m', 'subsystem_object_detection.m', ...
    'subsystem_ground_station.m', 'subsystem_flight_safety.m', ...
    'subsystem_energy.m'};
assert(numel(names) == 7 && numel(functions) == 7, 'Expected seven modules');
for k = 1:7
    path = fullfile(root,'team',names{k},functions{k});
    assert(exist(path,'file') == 2, 'Missing module: %s', path);
end
fprintf('[01] Seven module folders OK\n');

cfg = config_uav();
rng(cfg.seed);
scenario = init_scenario(cfg);
route = subsystem_route_planning(scenario.start,scenario.goal,scenario.obstacles,cfg);
assert(isequal(route(1,:),scenario.start), 'Wrong route start');
assert(isequal(route(end,:),scenario.goal), 'Wrong route goal');
for k = 1:size(route,1)-1
    assert(segment_is_safe(route(k,:),route(k+1,:), ...
        scenario.obstacles,cfg.route.clearance), 'Route violates clearance');
end
fprintf('[02] Planner safety OK\n');

emptyObstacles = scenario.obstacles([]);
directRoute = subsystem_route_planning(scenario.start,scenario.goal,emptyObstacles,cfg);
assert(size(directRoute,1) == 2, 'No obstacles => direct path');
blocked = [scenario.obstacles(1).center scenario.start(3)];
caught = false;
try
    subsystem_route_planning(blocked, scenario.goal, scenario.obstacles, cfg);
catch ME
    caught = strcmp(ME.identifier,'UAV:RoutePlanning:InvalidEndpoint');
end
assert(caught,'Planner must reject start inside safety zone');
cfgNoPass = cfg;
cfgNoPass.route.maxPasses = 0;
caught = false;
try
    subsystem_route_planning(scenario.start,scenario.goal,scenario.obstacles,cfgNoPass);
catch ME
    caught = strcmp(ME.identifier,'UAV:RoutePlanning:UnsafeRoute');
end
assert(caught,'Planner must reject unsafe route');
fprintf('[03] Planner edge cases OK\n');

state = scenario.initialState;
nav = subsystem_navigation(state,cfg);
navFiltered = subsystem_navigation(state,cfg,nav);
assert(all(isfinite(navFiltered.position)), 'Navigation not finite');
assert(isfield(nav,'rawPosition') && isfield(nav,'quality'), ...
    'Missing navigation diagnostic data');
badState = state;
badState.position(1) = NaN;
badNav = subsystem_navigation(badState,cfg,nav);
assert(~badNav.positionValid && all(isfinite(badNav.position)), ...
    'Invalid GPS data must be flagged and handled');
fprintf('[04] Navigation and bad GPS OK\n');

control = subsystem_flight_control(nav,scenario.goal,cfg);
assert(norm(control.acceleration) <= cfg.maxAccel+1e-9, ...
    'Acceleration exceeds max');
assert(abs(control.yawRate) <= cfg.maxYawRate+1e-9, ...
    'Yaw rate exceeds max');
farCmd = subsystem_flight_control(nav,nav.position+[30 0 0],cfg);
nearCmd = subsystem_flight_control(nav,nav.position+[0.2 0 0],cfg);
assert(norm(nearCmd.desiredVelocity) < norm(farCmd.desiredVelocity), ...
    'Desired speed should decrease near target');
fprintf('[05] Flight control limits and braking OK\n');

navSensor = nav;
navSensor.position = [0 0 20];
navSensor.velocity = [5 0 0];
navSensor.course = 0;
navSensor.positionValid = true;
navSensor.headingValid = true;
testObstacle = struct('center',[8 0],'radius',2,'name','Test obstacle');
detections = subsystem_object_detection(navSensor,testObstacle,cfg);
assert(numel(detections)==1,'Obstacle should be detected');
assert(detections(1).timeToCollision > 0 && ...
    isfinite(detections(1).timeToCollision), 'TTC must be finite');
assert(detections(1).closingSpeed > 0, 'Closing speed must be positive');
assert(detections(1).confidence >= 0 && ...
    detections(1).confidence <= 1, 'Confidence out of range');
assert(isempty(subsystem_object_detection(badNav,testObstacle,cfg)), ...
    'Invalid navigation should suppress detections');
fprintf('[06] Object detection and TTC OK\n');

energy = subsystem_energy(state,cfg);
energyMoving = subsystem_energy(state,cfg,control);
assert(energy.nextBattery < state.battery && energy.nextBattery>=0, ...
    'Battery integration failed');
assert(energyMoving.drainRate >= energy.drainRate, ...
    'Acceleration must not reduce estimated energy drain');
lowState = state;
lowState.battery = 4;
lowEnergy = subsystem_energy(lowState,cfg);
assert(lowEnergy.lowBattery && lowEnergy.criticalBattery, ...
    'Critical battery threshold failed');
zeroState = state;
zeroState.battery = 0;
zeroEnergy = subsystem_energy(zeroState,cfg);
assert(zeroEnergy.nextBattery == 0, 'Battery cannot become negative');
fprintf('[07] Energy and thresholds OK\n');

% Прогнозируемое сближение при известной относительной скорости.
nominalControl = subsystem_flight_control(navSensor,[30 0 20],cfg);
[corrected,safety] = subsystem_flight_safety(navSensor,detections, ...
    nominalControl,energy,cfg);
assert(safety.predictedConflict && safety.intervened, ...
    'Predictive safety should react to obstacle');
assert(norm(corrected.acceleration)<=cfg.maxAccel+1e-9, ...
    'Safety acceleration limit');
closeDetection = struct('relativeXY',[2 0],'distanceToBoundary',1);
[emergency,emergencyStatus] = subsystem_flight_safety(navSensor, ...
    closeDetection,nominalControl,energy,cfg);
assert(emergencyStatus.intervened && emergency.acceleration(1)<0, ...
    'Close obstacle should cause evasive command');
[~,invalidStatus] = subsystem_flight_safety(badNav, ...
    struct('relativeXY',{},'distanceToBoundary',{}), ...
    control,energy,cfg);
assert(strcmp(invalidStatus.status,'NAV_INVALID'), ...
    'Invalid navigation needs a dedicated safety status');
fprintf('[08] Flight safety and degraded navigation OK\n');

packet = subsystem_ground_station(navSensor,state,corrected,1, ...
    detections,cfg,safety,energy);
assert(isfield(packet,'safetyStatus') && ...
    isfield(packet,'estimatedRemainingTime') && ...
    isfield(packet,'navValid'), 'Missing ground-station signals');
cfgDrop = cfg;
cfgDrop.comms.packetLossProbability = 1;
lost = subsystem_ground_station(navSensor,state,corrected,1, ...
    detections,cfgDrop,safety,energy);
assert(~lost.linkOK,'100 percent packet loss must be simulated');
fprintf('[09] Telemetry and packet loss OK\n');

% Полная симуляция: воспроизводимость, отсутствие NaN и столкновений.
rng(cfg.seed);
results = simulate_uav(scenario,route,cfg);
assert(~isempty(results.position) && all(isfinite(results.position(:))), ...
    'Integration contains invalid coordinates');
assert(~strcmp(results.status,'COLLISION') && ...
    min(results.minObstacleDistance)>0, 'UAV collided with obstacle');
assert(numel(results.batteryDrainRate)==numel(results.time), ...
    'Energy log length mismatch');
assert(numel(results.safetyStatus)==numel(results.time), ...
    'Safety log length mismatch');
assert(numel(results.navValid)==numel(results.time), ...
    'Navigation validity log length mismatch');
assert(numel(results.telemetryPackets)==numel(results.time), ...
    'Telemetry log length mismatch');
assert(sum(~cellfun(@isempty,results.telemetryPackets))==sum(results.linkOK), ...
    'Delivered packet count mismatch');
rng(cfg.seed);
resultsAgain = simulate_uav(scenario,route,cfg);
assert(isequaln(results.position,resultsAgain.position) && ...
    strcmp(results.status,resultsAgain.status), ...
    'Fixed random seed should reproduce the mission');
fprintf('[10] Integration and reproducibility OK\n');

% Отдельный интеграционный сценарий без препятствий должен достигать цели.
scenarioEmpty = scenario;
scenarioEmpty.obstacles = emptyObstacles;
rng(cfg.seed);
simpleResults = simulate_uav(scenarioEmpty,directRoute,cfg);
assert(strcmp(simpleResults.status,'GOAL_REACHED'), ...
    'Simple unobstructed mission should reach goal');
fprintf('[11] Unobstructed mission success OK\n');

fprintf('\nAll seven-module MATLAB tests passed. Default mission: %s\n',results.status);
