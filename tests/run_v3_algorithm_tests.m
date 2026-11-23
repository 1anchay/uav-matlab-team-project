%% V3 fixed-size codegen algorithm contracts. No Simulink required.
clear;clc;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();

% Sensor: circle hidden at launch; in range at observation point.
world=[50 1000;40 1000;7 0];
nav=[0;0;0;0];
[observed,nearest]=v3_detection(nav,world);
assert(all(observed(4,:)==0) && nearest(1)==1000, ...
    'Sensor should not observe distant objects.');
nav=[21;17;5;3];
[observed,nearest]=v3_detection(nav,world);
assert(observed(4,1)==1 && observed(4,2)==0 && ...
    nearest(1)<35,'Sensor failed to detect the near circle.');
fprintf('[V3-01] Synthetic range sensing PASS\n');

% Online replan: persistent map must acquire previously unseen obstacle.
clear v3_replanner
[target,info]=v3_replanner(nav,zeros(4,2),[100;80]);
assert(info(1)==0 && norm(target-[100;80])<1e-9, ...
    'No observation should mean direct target.');
[target,info]=v3_replanner(nav,observed,[100;80]);
assert(info(1)==1 && info(2)==1 && ...
    norm(target-[100;80])>3, ...
    'New hazard must trigger an online detour.');
[target,info]=v3_replanner(nav,observed,[100;80]);
assert(info(1)==0 && info(2)==1, ...
    'Known hazard must not retrigger replanning at every step.');
fprintf('[V3-02] Persistent discovered map and reroute PASS\n');

% Regulator: accelerations and braking speed limits.
cmd=v3_control(nav,[100;80]);
assert(numel(cmd)==2 && all(isfinite(cmd)) && norm(cmd)<=3+1e-9, ...
    'V3 acceleration command violates constraint.');
fprintf('[V3-03] Tracking limits PASS\n');

% Safety: immediate threat must cause evasive or braking action.
[safe,code]=v3_safety([2;0],[0;0;5;0], ...
    [1;3;0;2],[0.1;90;0]);
assert(code==1 && norm(safe)<=3+1e-9, ...
    'Safety failed to intervene.');
[safe,code]=v3_safety([2;0],[0;0;5;0], ...
    [1000;0;0;0],[0.1;4;1]);
assert(code==2 && safe(1)<0, ...
    'Critical battery must trigger braking.');
fprintf('[V3-04] Safety hazard / low battery PASS\n');

% Nav and energy must preserve finite shapes under dropout.
clear v3_navigation
nn=v3_navigation([0;0;0;0;100],1);
nn2=v3_navigation([1;0;1;0;100],0);
assert(numel(nn)==4 && numel(nn2)==4 && all(isfinite(nn2)), ...
    'GPS loss produced invalid navigation.');
eng=v3_energy([0;0;1;0;100],[1;0]);
assert(numel(eng)==3 && eng(1)>0 && eng(2)==100, ...
    'Energy dimensions or drain invalid.');
fprintf('[V3-05] Navigation dropout and energy PASS\n');

% Fixed-size ground station contract.
telem=v3_ground(nav,eng,nearest,0,[1;1;1],1);
assert(numel(telem)==9 && all(isfinite(telem)), ...
    'Telemetry shape invalid.');
fprintf('[V3-06] Ground station frame PASS\n');
fprintf('V3 algorithm unit tests: 6/6 PASS\n');
