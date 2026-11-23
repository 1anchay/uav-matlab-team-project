function build_simulink_model()
%BUILD_SIMULINK_MODEL Собирает обзорную архитектуру из Model Reference.
% Каждый модуль хранится в отдельном .slx после build_component_models().
% Это НЕ модель физических алгоритмов — рабочая симуляция: run_project.

root = setup_paths();
if ~license('test','Simulink')
    error('UAV:MBD:MissingSimulink','Simulink license is required.');
end
models = build_component_models();
outputDir = fullfile(root,'models','generated');
mainName = 'UAV_Team_Model';
targetFile = fullfile(outputDir,[mainName '.slx']);
if exist(targetFile,'file')
    load_system(targetFile);
    open_system(mainName);
    fprintf('Opened existing overview model (not overwritten): %s\n',targetFile);
    return;
end

new_system(mainName);
cfg = config_uav();
set_param(mainName,'Solver','FixedStepDiscrete','FixedStep',num2str(cfg.dt), ...
    'StopTime',num2str(cfg.totalTime));
add_ref(mainName,'Dynamics',models{8},[970 60 1180 140]);
add_ref(mainName,'01 Navigation',models{1},[70 75 265 145]);
add_ref(mainName,'04 Object Detection',models{4},[70 300 265 370]);
add_ref(mainName,'03 Route Planning',models{3},[340 285 545 365]);
add_ref(mainName,'02 Flight Control',models{2},[610 125 815 205]);
add_ref(mainName,'07 Energy',models{7},[610 450 815 520]);
add_ref(mainName,'06 Flight Safety',models{6},[970 245 1180 345]);
add_ref(mainName,'05 Ground Station',models{5},[1320 400 1545 515]);

% Учебная схема потоков. Блоки моделей передают только условный scalar.
add_line(mainName,'Dynamics/1','01 Navigation/1','autorouting','on');
add_line(mainName,'Dynamics/1','07 Energy/1','autorouting','on');
add_line(mainName,'01 Navigation/1','04 Object Detection/1','autorouting','on');
add_line(mainName,'01 Navigation/1','03 Route Planning/1','autorouting','on');
add_line(mainName,'04 Object Detection/1','03 Route Planning/2','autorouting','on');
add_line(mainName,'01 Navigation/1','02 Flight Control/1','autorouting','on');
add_line(mainName,'03 Route Planning/1','02 Flight Control/2','autorouting','on');
add_line(mainName,'02 Flight Control/1','06 Flight Safety/1','autorouting','on');
add_line(mainName,'04 Object Detection/1','06 Flight Safety/2','autorouting','on');
add_line(mainName,'07 Energy/1','06 Flight Safety/3','autorouting','on');
add_line(mainName,'01 Navigation/1','06 Flight Safety/4','autorouting','on');
add_line(mainName,'06 Flight Safety/1','Dynamics/1','autorouting','on');
add_line(mainName,'01 Navigation/1','05 Ground Station/1','autorouting','on');
add_line(mainName,'04 Object Detection/1','05 Ground Station/2','autorouting','on');
add_line(mainName,'06 Flight Safety/1','05 Ground Station/3','autorouting','on');
add_line(mainName,'07 Energy/1','05 Ground Station/4','autorouting','on');
add_line(mainName,'Dynamics/1','05 Ground Station/5','autorouting','on');

save_system(mainName,targetFile);
open_system(mainName);
fprintf('Created overview Model References: %s\n',targetFile);
fprintf('IMPORTANT: real UAV algorithms run in MATLAB via run_project.\n');
end

function add_ref(parent,label,refName,position)
path = [parent '/' label];
add_block('simulink/Ports & Subsystems/Model',path, ...
    'ModelName',refName,'Position',position);
end
