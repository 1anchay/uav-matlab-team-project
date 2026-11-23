%% Advanced V2: seven modular units + integrated scenarios.
% IMPORTANT: these are NEW tests, distinct from the already validated suite.
clear;clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
cfg = advanced_config();
rng(cfg.advanced.seed);

% 01: GPS outage and recovery; explicit measurement validity.
state = struct('position',[0 0 20],'velocity',[1 0 0], ...
    'yaw',0,'battery',100);
n1 = advanced_navigation(state,[],true,cfg);
n2 = advanced_navigation(state,n1,false,cfg);
assert(n1.gpsAvailable && ~n2.gpsAvailable && ...
    n2.outageSteps==1 && all(isfinite(n2.position)), ...
    'Advanced navigation GPS dropout handling failed.');
for k=1:cfg.advanced.maxDeadReckonSteps
    n2 = advanced_navigation(state,n2,false,cfg);
end
assert(~n2.positionValid,'Prolonged GPS outage must degrade navigation.');
n3 = advanced_navigation(state,n2,true,cfg);
assert(n3.positionValid && n3.outageSteps==0,'GPS recovery failed.');
fprintf('[01] GPS dropout and recovery PASS\n');

% 02: control outputs remain physically limited and degrade conservatively.
cmd = advanced_tracking_control(n1,[50 50 20],cfg);
assert(norm(cmd.acceleration)<=cfg.maxAccel+1e-9 && ...
    abs(cmd.yawRate)<=cfg.maxYawRate+1e-9, ...
    'Controller violates acceleration or yaw limits.');
degraded = advanced_tracking_control(n2,[50 50 20],cfg);
assert(strcmp(degraded.mode,'DEGRADED') && ...
    norm(degraded.acceleration)<=cfg.maxAccel+1e-9, ...
    'Controller must brake on invalid navigation.');
fprintf('[02] Controller limits and degraded mode PASS\n');

% 03: strict route replan around an unknown obstacle; all segments checked.
[scene,local] = advanced_scenario('unexpected',cfg);
obs = scene.obstacles;
p = advanced_replan_route([20 16 20],scene.goal,obs,local);
assert(p.ok && p.waypoints>2,'Planner did not produce an obstacle detour.');
for k=1:size(p.route,1)-1
    assert(segment_is_safe(p.route(k,:),p.route(k+1,:), ...
        obs,local.advanced.replanClearance), ...
        'Route replan violates required clearance.');
end
fprintf('[03] Real geometric replanning PASS\n');

% 04: reveal unknown obstacle only within sensor range.
obsNav = n1;obsNav.position = [35 30 20];
scan = advanced_sensor_scan(obsNav,obs,false(1,numel(obs)),local);
assert(any(scan.newlyDetected) && all(scan.known), ...
    'Visible unknown obstacle must become known.');
fprintf('[04] Dynamic obstacle discovery PASS\n');

% 05: delayed downlink and 100% loss are separately measurable.
radio = [];cfgRadio=cfg;
cfgRadio.advanced.packetLossProbability=0;
cfgRadio.advanced.packetLatencySteps=3;
[radio,msg] = advanced_comms_step(radio,struct('value',17),1,cfgRadio);
assert(isempty(msg)&&radio.deliveredCount==0,'No packet should arrive early.');
[radio,msg] = advanced_comms_step(radio,[],4,cfgRadio);
assert(~isempty(msg) && msg.value==17 && ...
    radio.deliveredCount==1 && radio.delaySamples(1)==3, ...
    'Queue did not deliver packet after configured delay.');
cfgRadio.advanced.packetLossProbability=1;
[radio,msg] = advanced_comms_step(radio,struct('value',18),5,cfgRadio);
assert(isempty(msg) && radio.lost==1,'Radio blackout not modeled.');
fprintf('[05] Delayed/lost telemetry PASS\n');

% 06: geofence and absent navigation trigger braking.
edgeNav=n1;edgeNav.position=[cfg.advanced.geofence(2)+1 0 20];
energy=advanced_energy_monitor(state,cmd,100,cfg);
[~,safeStatus]=advanced_safety_supervisor(edgeNav,obs([]),cmd,energy,cfg);
assert(safeStatus.geofence && safeStatus.intervened, ...
    'Geofence was not enforced.');
fprintf('[06] Geofence safety PASS\n');

% 07: reserve prediction uses distance to destination.
e1=advanced_energy_monitor(state,cmd,10,cfg);
e2=advanced_energy_monitor(state,cmd,1000,cfg);
assert(e2.reserveAtGoalPercent<e1.reserveAtGoalPercent && ...
    e1.nextBattery<=state.battery, ...
    'Energy reserve is not distance-sensitive.');
fprintf('[07] Energy reserve estimate PASS\n');

% Integration: strictly verify new online-replanning behavior.
[clearScene,clearCfg] = advanced_scenario('clear',cfg);
clearRun = simulate_advanced_uav(clearScene,clearCfg);
assert(clearRun.success && clearRun.replanCount==0, ...
    'Unobstructed V2 mission did not reach destination.');
fprintf('[08] Clear-map integration PASS\n');

[hiddenScene,hiddenCfg] = advanced_scenario('unexpected',cfg);
hiddenRun = simulate_advanced_uav(hiddenScene,hiddenCfg);
assert(hiddenRun.discoveredObstacles>=1 && hiddenRun.replanCount>=1, ...
    'Hidden obstacle did not trigger true route replanning.');
assert(hiddenRun.minimumClearance>0 && ...
    ~strcmp(hiddenRun.status,'COLLISION'), ...
    'Hidden obstacle experiment caused collision.');
assert(hiddenRun.success, ...
    'Hidden obstacle mission did not reach goal: %s',hiddenRun.status);
fprintf('[09] Online-replanning integration PASS\n');

[blackScene,blackCfg] = advanced_scenario('radio_blackout',cfg);
blackRun = simulate_advanced_uav(blackScene,blackCfg);
assert(blackRun.packetsDelivered==0 && blackRun.success, ...
    'Loss of telemetry must not stop the autonomous training mission.');
fprintf('[10] Telemetry blackout integration PASS\n');

[lowScene,lowCfg] = advanced_scenario('critical_battery',cfg);
lowRun=simulate_advanced_uav(lowScene,lowCfg);
assert(strcmp(lowRun.status,'LOW_BATTERY') && lowRun.duration==0, ...
    'Critical battery must stop immediately.');
fprintf('[11] Critical battery integration PASS\n');

[gpsScene,gpsCfg] = advanced_scenario('gps_outage',cfg);
gpsRun=simulate_advanced_uav(gpsScene,gpsCfg);
assert(any(~gpsRun.gpsAvailable) && ...
    any(~gpsRun.navValid), ...
    'GPS outage case did not exercise loss of navigation validity.');
assert(all(isfinite(gpsRun.position(:))) && ...
    ~strcmp(gpsRun.status,'COLLISION'), ...
    'GPS outage produced invalid or colliding state.');
fprintf('[12] GPS outage/failsafe integration PASS\n');

% Fixed-seed determinism is a testable requirement.
hiddenAgain=simulate_advanced_uav(hiddenScene,hiddenCfg);
assert(isequaln(hiddenRun.position,hiddenAgain.position) && ...
    hiddenRun.replanCount==hiddenAgain.replanCount && ...
    strcmp(hiddenRun.status,hiddenAgain.status), ...
    'V2 experiment should be reproducible with a fixed seed.');
fprintf('[13] Repeatability PASS\n');
fprintf('\nAdvanced V2 acceptance suite: 13/13 PASS\n');
