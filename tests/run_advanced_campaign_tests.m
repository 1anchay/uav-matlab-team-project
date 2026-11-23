%% Advanced V2 campaign: six scenario-specific acceptance contracts.
% The low-battery scenario must stop; its correct outcome is NOT GOAL_REACHED.
% Separate from the existing 13-group Advanced V2 unit+integration test.
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();

names = {'clear','unexpected','gps_outage','radio_blackout', ...
    'critical_battery','two_unknown'};
expected = {'GOAL_REACHED','GOAL_REACHED','GOAL_REACHED', ...
    'GOAL_REACHED','LOW_BATTERY','GOAL_REACHED'};
passed = false(1,numel(names));

for k = 1:numel(names)
    [scene,cfg] = advanced_scenario(names{k});
    r = simulate_advanced_uav(scene,cfg);
    assert(strcmp(r.status,expected{k}), ...
        'UAV:Advanced:WrongStatus', ...
        '%s: expected %s, observed %s',names{k},expected{k},r.status);

    switch names{k}
        case 'clear'
            assert(r.replanCount == 0 && isinf(r.minimumClearance), ...
                'Unobstructed case should have no replans or obstacle clearance.');
        case 'unexpected'
            assert(r.discoveredObstacles >= 1 && r.replanCount >= 1, ...
                'Unknown obstacle must lead to active online replanning.');
            assert(r.minimumClearance > 0, ...
                'Unexpected obstacle case must remain collision-free.');
        case 'gps_outage'
            assert(any(~r.gpsAvailable) && any(~r.navValid), ...
                'GPS outage must be exercised in the integrated model.');
        case 'radio_blackout'
            assert(r.packetsDelivered == 0 && r.packetDeliveryRate == 0, ...
                'No packets should arrive during 100%% radio blackout.');
        case 'critical_battery'
            assert(r.duration == 0 && ~r.success, ...
                'Critical battery must terminate immediately.');
        case 'two_unknown'
            assert(r.discoveredObstacles == 2 && r.replanCount >= 2, ...
                'Both hidden objects must be detected and cause replanning.');
            assert(r.minimumClearance > 0, ...
                'Two-hidden-obstacle mission must be collision-free.');
    end

    passed(k) = true;
    fprintf('%-18s expected=%-13s observed=%-13s PASS\n', ...
        names{k}, expected{k}, r.status);
end
fprintf('Advanced V2 campaign acceptance: %d/%d PASS\n', ...
    sum(passed),numel(passed));
