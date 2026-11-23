%% Integration acceptance for independent V3 live-replanning Simulink model.
% Run from the repository root in MATLAB Online after unit tests.
clear;clc;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
assert(license('test','Simulink')==1,'UAV3:SimulinkRequired', ...
    'This test requires a Simulink installation.');
filename=build_v3_simulink_model();
[~,main]=fileparts(filename);
load_system(main);

refs=find_system(main,'SearchDepth',1,'BlockType','ModelReference');
assert(numel(refs)==9, ...
    'Expected 7 independently owned Model References plus 2 shared.');
names=cellfun(@(path)get_param(path,'ModelName'),refs, ...
    'UniformOutput',false);
assert(numel(unique(names))==9, ...
    'Each V3 component must be its own Model Reference.');
for k=1:numel(names)
    load_system(names{k});
    charts=find(sfroot,'-isa','Stateflow.EMChart');
    hasAlgorithm=false;
    for j=1:numel(charts)
        if strcmp(char(charts(j).Path),[names{k} '/Algorithm'])
            hasAlgorithm=true;
            break;
        end
    end
    assert(hasAlgorithm,'Missing executable algorithm in %s',names{k});
end
fprintf('[V3-A] 7 owner references + 2 shared references PASS\n');

assert(getSimulinkBlockHandle([main '/Feedback Delay'])~=-1, ...
    'Missing top-level state-feedback delay.');
assert(getSimulinkBlockHandle([main '/Stop on Mission End'])~=-1, ...
    'Missing terminal Stop Simulation block.');
set_param(main,'SimulationCommand','update');
fprintf('[V3-B] Compile and feedback architecture PASS\n');

r=run_v3_simulink_demo(false);
assert(size(r.state,2)==5 && size(r.telemetry,2)==9 && ...
    size(r.plan,2)==3, 'Incorrect logged signal shape.');
assert(all(isfinite(r.state(:))) && all(isfinite(r.telemetry(:))), ...
    'Non-finite simulation data.');
assert(r.maximumSpeed<=10+1e-7 && r.minimumBattery>=0, ...
    'Speed or battery constraint violated.');
assert(r.minimumClearance>0,'Simulated drone collided with a circle.');
fprintf('[V3-C] Dynamics and collision constraints PASS\n');

assert(r.replans>=1 && r.knownObstacleCount>=1, ...
    'V3 online planner did not discover/replan around the hidden obstacle.');
assert(r.gpsOutageSamples>=1, ...
    'GPS-loss simulation was not exercised.');
assert(r.goalReached && r.duration<90, ...
    'V3 mission did not complete successfully before StopTime.');
fprintf('[V3-D] Online replan, GPS dropout, goal and early stop PASS\n');
fprintf('V3 live Simulink acceptance: 4/4 PASS\n');
