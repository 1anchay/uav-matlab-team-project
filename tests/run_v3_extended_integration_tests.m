%% NEW six-scenario V3 acceptance test (requires MATLAB Online + Simulink).
% Keep this separate from verified baseline V3-A--D suite.
% A failing two-circle case is a useful uncovered engineering defect.
clear;clc;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
assert(license('test','Simulink')==1, ...
    'UAV3:SimulinkRequired','Simulink is required for extended V3 testing.');
campaign=run_v3_acceptance_campaign(false);
for k=1:campaign.total
    row=campaign.rows(k);
    assert(row.accepted,'UAV3:ExtendedAcceptance', ...
        '%s failed: expected=%g observed=%g, replans=%g, clearance=%g. %s', ...
        row.name,row.expected,row.observed,row.replans, ...
        row.clearance,row.error);
end
fprintf('Six V3 fault-injection and obstacle scenarios: 6/6 PASS\n');
