function backupFile = polish_functional_model()
%POLISH_FUNCTIONAL_MODEL Color-code independent Simulink Model References.
% Only presentation/style changes. Saves backup of top-level .slx first.
% Never edits the actual flight algorithms or overwrites the 8 components.
root = fileparts(mfilename('fullpath'));
setup_paths();
model = 'UAVF_Team_Model';
file = fullfile(root,'models','functional','generated',[model '.slx']);
assert(isfile(file),'UAV:MissingDiagram', ...
    'Run build_functional_simulink_model before styling.');
load_system(file);
assert(strcmp(get_param(model,'Dirty'),'off'), ...
    'UAV:UnsavedChanges','Save or revert existing diagram edits first.');

backupDir = fullfile(root,'models','functional','backups');
if ~exist(backupDir,'dir'),mkdir(backupDir);end
backupFile = fullfile(backupDir, ...
    ['UAVF_Team_Model_before_styling_' datestr(now,'yyyymmdd_HHMMSSFFF') '.slx']);
[ok,msg] = copyfile(file,backupFile);
assert(ok,'UAV:BackupFailed','Cannot copy the original .slx: %s',msg);

blocks = { ...
    '01 Navigation',      'lightBlue', 'blue'; ...
    '02 Flight Control',  'lightBlue', 'blue'; ...
    '03 Waypoint Planning','orange', 'black'; ...
    '04 Object Detection','cyan', 'darkGreen'; ...
    '05 Ground Station',  'gray', 'black'; ...
    '06 Flight Safety',   'yellow', 'black'; ...
    '07 Energy',          'green', 'darkGreen'; ...
    'Dynamics',           'lightBlue', 'black' ...
    };
for i = 1:size(blocks,1)
    path = [model '/' blocks{i,1}];
    assert(getSimulinkBlockHandle(path)~=-1, ...
        'UAV:MissingComponent','Missing block: %s',path);
    set_param(path,'BackgroundColor',blocks{i,2}, ...
        'ForegroundColor',blocks{i,3});
end

% Idempotent title/subtitle: don't add another copy on repeat calls.
header = 'UAV SYSTEM | 7 INDEPENDENT COMPONENTS + DYNAMICS';
footer = '2D TEACHING MODEL | ROUTE COMPUTED BEFORE FLIGHT | MATLAB / Simulink';
notes = find_system(model,'FindAll','on','Type','annotation');
labels = cell(1,numel(notes));
for i = 1:numel(notes)
    labels{i} = char(get_param(notes(i),'PlainText'));
end
if ~any(strcmp(labels,header))
    a = Simulink.Annotation(model,header);
    a.Position = [90 18 950 50];
    a.FontSize = 16;
    a.ForegroundColor = 'blue';
end
if ~any(strcmp(labels,footer))
    a = Simulink.Annotation(model,footer);
    a.Position = [90 615 1030 647];
    a.FontSize = 11;
    a.ForegroundColor = 'darkGreen';
end

save_system(model);
open_system(model);
fprintf('Styled diagram saved: %s\n',file);
fprintf('Previous version safely backed up: %s\n',backupFile);
end
