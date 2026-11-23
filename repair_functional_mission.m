function backupFile = repair_functional_mission()
%REPAIR_FUNCTIONAL_MISSION Add mission stop/status to existing functional .slx.
% Backs up top-level binary before edit; preserves 7 referenced components.
root = fileparts(mfilename('fullpath'));
setup_paths();
cfg = config_uav();
scenario = init_scenario(cfg);
model = 'UAVF_Team_Model';
file = fullfile(root,'models','functional','generated',[model '.slx']);
assert(isfile(file),'UAV:MissingFunctionalModel', ...
    'Generate UAVF_Team_Model.slx first.');
load_system(file);
sourceFile = fullfile(root,'models','functional','mission_supervisor.m');
if getSimulinkBlockHandle([model '/Mission Supervisor']) ~= -1
    fprintf('Mission Supervisor already exists; nothing changed.\n');
    backupFile = '';
    return;
end
assert(strcmp(get_param(model,'Dirty'),'off'), ...
    'UAV:UnsavedEdits','Save or revert changes in UAVF_Team_Model first.');

backupDir = fullfile(root,'models','functional','backups');
if ~exist(backupDir,'dir'),mkdir(backupDir);end
backupFile = fullfile(backupDir, ...
    ['UAVF_Team_Model_before_mission_' datestr(now,'yyyymmdd_HHMMSSFFF') '.slx']);
[ok,msg] = copyfile(file,backupFile);
assert(ok,'UAV:BackupFailed','Failed to copy original model: %s',msg);

added = add_functional_mission_supervisor(model,scenario.goal(1:2), ...
    sourceFile);
assert(added,'UAV:MissionNotAdded','The terminal monitor was not added.');
save_system(model);
fprintf('Mission Supervisor installed with Stop Simulation block.\n');
fprintf('Backup: %s\n',backupFile);
open_system(model);
end
