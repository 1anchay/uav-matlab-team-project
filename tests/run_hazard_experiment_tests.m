%% Challenge test: stationary obstacle missing from the precomputed route.
% Run separately AFTER the nominal functional Simulink test.
% May fail: failure is an engineering finding, not a reason to bypass test.
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
r = run_hazard_experiment(false);
assert(all(isfinite(r.state(:))) && all(isfinite(r.telemetry(:))), ...
    'UAV:HazardNumeric','Invalid numeric output under obstacle challenge.');
assert(r.interventionObserved, ...
    'UAV:SafetyNotTriggered','Reactive safety did not intervene.');
assert(~r.collisionDetected, ...
    'UAV:HazardCollision','Drone collided with an unexpected obstacle.');
fprintf('Hazard challenge PASSED: %d evasive samples; min clearance %.2f m\n', ...
    r.evasions,r.minClearance);
