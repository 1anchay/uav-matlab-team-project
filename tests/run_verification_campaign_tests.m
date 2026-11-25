%% Deterministic mission campaign and 7-module behavioral contracts.
% Run from repository root. Does not require Simulink.
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
report = run_verification_campaign(false);
assert(report.passedCases==report.totalCases, ...
    'UAV:CampaignFailed','At least one deterministic mission failed.');
assert(numel(report.monteCarlo)==10, ...
    'UAV:CampaignCount','Unexpected Monte Carlo trial count.');
assert(all(arrayfun(@(x) isfinite(x.finalDistance),report.monteCarlo)), ...
    'UAV:CampaignNonFinite','Non-finite Monte Carlo distance.');
assert(all([report.monteCarlo.minClearance]>0), ...
    'UAV:CampaignCollision','A randomized run collided with an obstacle.');

% 2D module 06: force a head-on obstacle response without needing Simulink.
navigation = [0;0;5;0];
detection = [3;5;0;2];
energy = [0.1;90;0];
[safe,flag] = simulink_safety([2;0],detection,navigation,energy);
assert(flag==1 && safe(1)<0 && norm(safe)<=3+1e-9, ...
    'UAV:SafetyFailure','Safety must decelerate before a head-on obstacle.');

% 2D module 06: critically low battery causes a distinct protective status.
[brake,flag] = simulink_safety([2;0],[1000;0;0;0],navigation,[0.1;4;1]);
assert(flag==2 && brake(1)<0 && norm(brake)<=3+1e-9, ...
    'UAV:CriticalBattery','Critical battery mode did not activate.');

% Invalid navigation: do not issue an unbounded command.
[neutral,flag] = simulink_safety([2;0],[1000;0;0;0], ...
    [NaN;0;0;0],energy);
assert(flag==3 && all(neutral==0), ...
    'UAV:NavFailure','Invalid navigation should suppress unsafe commands.');

% No threat: standard command is unchanged.
[control,flag] = simulink_safety([1;0],[1000;0;0;0],navigation,energy);
assert(flag==0 && norm(control-[1;0])<1e-10, ...
    'UAV:FalseAlarm','Nominal safety response changed a valid command.');
fprintf('Behavioral safety scenarios: 4/4 PASS\n');
fprintf('Mission campaign: %d/%d PASS; randomized trials collision-free.\n', ...
    report.passedCases,report.totalCases);
