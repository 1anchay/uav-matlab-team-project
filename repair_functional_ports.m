function backupDir = repair_functional_ports()
%REPAIR_FUNCTIONAL_PORTS Исправляет размеры входов существующих UAVF .slx.
% Создаёт резервную копию КАЖДОЙ .slx перед записью; не переписывает
% MATLAB Function-код и не трогает исходную MATLAB-симуляцию/старую схему.
%
% Запуск из корня проекта: repair_functional_ports

root = fileparts(mfilename('fullpath'));
setup_paths();
generated = fullfile(root,'models','functional','generated');
assert(exist(generated,'dir')==7,'UAVF:ModelsNotGenerated', ...
    'First run build_functional_simulink_model.');

cfg = config_uav();
scene = init_scenario(cfg);
route = subsystem_route_planning(scene.start,scene.goal,scene.obstacles,cfg);
portSizes = functional_port_dimensions(size(route,1),numel(scene.obstacles));

models = {'UAVF_Navigation_01','UAVF_FlightControl_02', ...
    'UAVF_Waypoint_03','UAVF_Detection_04', ...
    'UAVF_GroundStation_05','UAVF_Safety_06', ...
    'UAVF_Energy_07','UAVF_Dynamics_Overview'};
inputs = { ...
    {'State'}, ...
    {'Navigation','Target'}, ...
    {'Navigation','Waypoints'}, ...
    {'Navigation','Obstacles'}, ...
    {'Navigation','Detection','Energy','SafetyStatus','State'}, ...
    {'Control','Detection','Navigation','Energy'}, ...
    {'State','Control'}, ...
    {'SafeControl','Energy'} ...
    };

% Откажемся от обновления, если что-то не сохранено в открытых моделях.
for k = 1:numel(models)
    target = fullfile(generated,[models{k} '.slx']);
    assert(exist(target,'file')==2,'UAVF:MissingModel', ...
        'Missing generated model: %s',target);
    load_system(target);
    assert(strcmp(get_param(models{k},'Dirty'),'off'), ...
        'UAVF:UnsavedChanges','Save or revert unsaved edits in %s first.', ...
        models{k});
end

backupRoot = fullfile(root,'models','functional','backups');
if ~exist(backupRoot,'dir'), mkdir(backupRoot); end
backupDir = fullfile(backupRoot,datestr(now,'yyyymmdd_HHMMSSFFF'));
assert(~exist(backupDir,'dir'),'UAVF:BackupExists', ...
    'Backup directory already exists. Retry.');
mkdir(backupDir);

% Полные бинарные копии до изменения любых портов.
for k = 1:numel(models)
    original = fullfile(generated,[models{k} '.slx']);
    [success,message] = copyfile(original,backupDir);
    assert(success,'UAVF:BackupFailed','%s',message);
end

for k = 1:numel(models)
    assert(numel(inputs{k})==numel(portSizes{k}), ...
        'UAVF:PortContractMismatch','Port contract mismatch: %s',models{k});
    for j = 1:numel(inputs{k})
        block = [models{k} '/' inputs{k}{j}];
        set_param(block,'PortDimensions',portSizes{k}{j}, ...
            'OutDataTypeStr','double');
    end
    save_system(models{k});
    fprintf('Updated port dimensions: %s\n',models{k});
end
fprintf('Backups saved at: %s\n',backupDir);
end
