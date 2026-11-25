function backupFile = repair_functional_feedback()
%REPAIR_FUNCTIONAL_FEEDBACK Разрывает алгебраическую петлю в созданной .slx.
% Сохраняет копию UAVF_Team_Model.slx перед изменением. Код семи
% подсистем и исходная 3D MATLAB-симуляция не изменяются.
%
% Запуск: repair_functional_feedback

root = fileparts(mfilename('fullpath'));
setup_paths();
cfg = config_uav();
model = 'UAVF_Team_Model';
generated = fullfile(root,'models','functional','generated');
mainFile = fullfile(generated,[model '.slx']);
assert(isfile(mainFile),'UAVF:MainModelMissing', ...
    'Missing functional model; first run build_functional_simulink_model.');

load_system(mainFile);
delay = [model '/State Feedback Delay'];
if getSimulinkBlockHandle(delay) ~= -1
    fprintf('Feedback delay already present; model unchanged.\n');
    backupFile = '';
    return;
end
assert(strcmp(get_param(model,'Dirty'),'off'), ...
    'UAVF:UnsavedModel', ...
    'Save or revert unsaved edits in UAVF_Team_Model first.');

% Проверяем предсказуемую форму старой схемы до резервирования.
navPath = [model '/01 Navigation'];
energyPath = [model '/07 Energy'];
dynPath = [model '/Dynamics'];
for path = {navPath,energyPath,dynPath}
    assert(getSimulinkBlockHandle(path{1}) ~= -1, ...
        'UAVF:UnexpectedTopology','Missing expected model block: %s',path{1});
end
navPort = get_param(navPath,'PortHandles');
energyPort = get_param(energyPath,'PortHandles');
dynPort = get_param(dynPath,'PortHandles');
for port = [navPort.Inport(1),energyPort.Inport(1)]
    lineHandle = get_param(port,'Line');
    assert(lineHandle ~= -1,'UAVF:MissingFeedback', ...
        'Expected feedback connection is missing.');
    assert(get_param(lineHandle,'SrcPortHandle') == dynPort.Outport(1), ...
        'UAVF:UnexpectedFeedback', ...
        'Expected Navigation and Energy to receive state from Dynamics.');
end

backupDir = fullfile(root,'models','functional','backups');
if ~exist(backupDir,'dir'), mkdir(backupDir); end
name = ['UAVF_Team_Model_before_feedback_' datestr(now,'yyyymmdd_HHMMSSFFF') '.slx'];
backupFile = fullfile(backupDir,name);
[ok,msg] = copyfile(mainFile,backupFile);
assert(ok,'UAVF:BackupFailed','Cannot back up main model: %s',msg);

% Добавить явную дискретную задержку для feedback на уровне верхней схемы.
% Она разрывает контур direct-feedthrough для referenced components.
add_block('simulink/Discrete/Unit Delay',delay, ...
    'InitialCondition','[0;0;0;0;100]', ...
    'SampleTime',num2str(cfg.dt), ...
    'Position',[1480 335 1535 380]);
delete_line(model,'Dynamics/1','01 Navigation/1');
delete_line(model,'Dynamics/1','07 Energy/1');
add_line(model,'Dynamics/1','State Feedback Delay/1','autorouting','on');
add_line(model,'State Feedback Delay/1','01 Navigation/1','autorouting','on');
add_line(model,'State Feedback Delay/1','07 Energy/1','autorouting','on');

save_system(model);
fprintf('Added top-level State Feedback Delay (sample time %.3f s).\n',cfg.dt);
fprintf('Original top-level model backed up: %s\n',backupFile);
end
