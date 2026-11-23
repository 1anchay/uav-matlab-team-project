%% Mission Lifecycle Supervisor: isolated unit tests (no Simulink needed).
clear; clc;
root = fileparts(fileparts(mfilename('fullpath')));
addpath(root);
addpath(fullfile(root,'models','functional'));
setup_paths();

cfg = config_uav();
scenario = init_scenario(cfg);
obstacles = zeros(3,numel(scenario.obstacles));
for k=1:numel(scenario.obstacles)
    obstacles(:,k) = [scenario.obstacles(k).center(:); ...
        scenario.obstacles(k).radius];
end
goal = scenario.goal(1:2)';

[stop,code] = mission_supervisor([100;80;0;0;90],goal,obstacles);
assert(stop && code==1,'Goal should terminate with code 1');

[stop,code] = mission_supervisor([35;25;0;0;90],goal,obstacles);
assert(stop && code==2,'Collision has priority and code 2');

[stop,code] = mission_supervisor([0;0;0;0;4],goal,obstacles);
assert(stop && code==3,'Low battery should terminate with code 3');

[stop,code] = mission_supervisor([NaN;0;0;0;90],goal,obstacles);
assert(stop && code==4,'Invalid state should terminate with code 4');

[stop,code] = mission_supervisor([100;80;4;0;90],goal,obstacles);
assert(~stop && code==0,'Too-fast arrival must not count as stable landing');

[stop,code] = mission_supervisor([0;0;0;0;90],goal,obstacles);
assert(~stop && code==0,'Start must remain in FLYING state');

fprintf('Mission Lifecycle Supervisor unit tests: 6/6 PASS\n');
