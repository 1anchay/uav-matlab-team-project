%% Optional: verifies standalone Model Reference files and overview layout.
% Requires MATLAB + Simulink; not run by tests/run_tests.m.
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
models = build_component_models();
assert(numel(models) == 8, 'Expected 7 modules and 1 shared Dynamics model');
for k = 1:numel(models)
    load_system(models{k});
    assert(bdIsLoaded(models{k}), 'Unable to load referenced model');
end
build_simulink_model();
load_system('UAV_Team_Model');
blocks = find_system('UAV_Team_Model','SearchDepth',1, ...
    'BlockType','ModelReference');
assert(numel(blocks) == 8, 'Expected 7 model references and shared Dynamics');
set_param('UAV_Team_Model','SimulationCommand','update');
fprintf('Model Reference smoke test passed (architecture ONLY).\n');
