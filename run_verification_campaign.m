function report = run_verification_campaign(makePlots)
%RUN_VERIFICATION_CAMPAIGN Reproducible regression scenarios for 7 modules.
% 4 deterministic cases and 10 Monte Carlo seeds; never modifies cfg files.
% MATLAB-only: no Simulink or extra toolboxes needed.
if nargin < 1, makePlots = true; end
setup_paths();
cfg = config_uav();
ids = {'baseline','clear_map','radio_blackout','critical_battery'};
names = {'Nominal mission','No obstacles','100% telemetry loss','Critical battery'};
expected = {'GOAL_REACHED','GOAL_REACHED','GOAL_REACHED','LOW_BATTERY'};
blank = struct('id','','name','','expected','','status','','passed',false, ...
    'result',[],'scenario',[],'error','');
entries = repmat(blank,1,numel(ids));

for i = 1:numel(ids)
    localCfg = cfg;
    scene = init_scenario(localCfg);
    switch ids{i}
        case 'clear_map'
            scene.obstacles = scene.obstacles([]);
        case 'radio_blackout'
            localCfg.comms.packetLossProbability = 1;
        case 'critical_battery'
            scene.initialState.battery = localCfg.safety.criticalBatteryPercent-1;
    end
    entries(i).id = ids{i};
    entries(i).name = names{i};
    entries(i).expected = expected{i};
    entries(i).scenario = scene;
    rng(localCfg.seed);
    try
        route = subsystem_route_planning(scene.start,scene.goal, ...
            scene.obstacles,localCfg);
        result = simulate_uav(scene,route,localCfg);
        entries(i).result = result;
        entries(i).status = result.status;
        entries(i).passed = strcmp(result.status,expected{i});
        if strcmp(ids{i},'radio_blackout')
            entries(i).passed = entries(i).passed && ...
                all(~result.linkOK) && result.packetDeliveryRate == 0;
        elseif strcmp(ids{i},'critical_battery')
            entries(i).passed = entries(i).passed && numel(result.time)==1;
        end
    catch ME
        entries(i).status = 'ERROR';
        entries(i).passed = false;
        entries(i).error = [ME.identifier ': ' ME.message];
    end
    fprintf('%-18s expected=%-13s observed=%-13s %s\n', ...
        ids{i},expected{i},entries(i).status,pass_label(entries(i).passed));
end

% Monte Carlo changes only the seed. Success fraction is measured, not assumed.
trials = 10;
mc = repmat(struct('seed',0,'status','','success',false, ...
    'minClearance',NaN,'finalDistance',NaN,'duration',NaN,'error',''),1,trials);
for k = 1:trials
    localCfg = cfg;
    localCfg.seed = cfg.seed + 100 + k;
    scene = init_scenario(localCfg);
    mc(k).seed = localCfg.seed;
    rng(localCfg.seed);
    try
        route = subsystem_route_planning(scene.start,scene.goal, ...
            scene.obstacles,localCfg);
        simData = simulate_uav(scene,route,localCfg);
        mc(k).status = simData.status;
        mc(k).success = simData.missionSuccess;
        mc(k).minClearance = min(simData.minObstacleDistance);
        mc(k).finalDistance = norm(simData.finalPosition-scene.goal);
        mc(k).duration = simData.time(end);
    catch ME
        mc(k).status = 'ERROR';
        mc(k).error = [ME.identifier ': ' ME.message];
    end
end

report.cases = entries;
report.monteCarlo = mc;
report.passedCases = sum([entries.passed]);
report.totalCases = numel(entries);
report.monteCarloSuccessRate = 100*mean([mc.success]);
report.seed = cfg.seed;
fprintf('\nDeterministic scenarios: %d/%d PASS\n', ...
    report.passedCases,report.totalCases);
fprintf('Monte Carlo: %.1f %% GOAL_REACHED (%d seeds)\n', ...
    report.monteCarloSuccessRate,trials);
fprintf('Monte Carlo results are measured indicators, not a safety proof.\n');
if makePlots
    plot_verification_dashboard(report);
end
end

function label = pass_label(isPass)
if isPass, label = 'PASS'; else, label = 'FAIL'; end
end
