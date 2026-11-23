%% Fast MATLAB-only tests for the new V3 scenario and swept path checks.
clear;clc;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
names={'baseline','two_unknown','collision_at_start', ...
    'critical_battery','invalid_state','goal_at_start'};
for k=1:numel(names)
    s=v3_scenario_settings(names{k});
    assert(isequal(size(s.world),[3 2]) && ...
        isequal(size(s.initialState),[5 1]) && ...
        isequal(size(s.goal),[2 1]), ...
        'Scenario interface was not fixed-size.');
end
fprintf('[SC-01] Six independent fixed-size scenarios PASS\n');
assert(v3_scenario_settings('two_unknown').world(3,2)>0, ...
    'Second circle must be a real physical obstacle.');
fprintf('[SC-02] Real two-obstacle map PASS\n');
world=[0 1000;0 1000;2 0];
clearance=v3_swept_clearance([-5 0;5 0],world);
assert(clearance < 0,'Swept collision must detect missed samples.');
fprintf('[SC-03] Swept collision detection PASS\n');
assert(isnan(v3_swept_clearance([NaN 0],world)), ...
    'Nonfinite geometry must never appear safe.');
fprintf('[SC-04] Invalid samples are not collision-free PASS\n');
fprintf('V3 scenario contract tests: 4/4 PASS\n');
