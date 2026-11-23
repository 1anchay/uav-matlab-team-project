function modelFile = build_functional_simulink_model()
%BUILD_FUNCTIONAL_SIMULINK_MODEL Создаёт работающую учебную Simulink-модель.
% Восемь ИСПОЛНЯЕМЫХ Model Reference: 7 участников + общая Dynamics.
% В отличие от старой UAV_Team_Model, внутри реальные MATLAB Function.
%
% Это двумерный (XY) демонстрационный аппарат-точка: не заменяет
% исходный полноценнее описанный MATLAB-проект в XYZ.
%
% ВНИМАНИЕ: существующие файлы моделей НЕ ПЕРЕЗАПИСЫВАЮТСЯ.
% Для существующих .slx: repair_functional_ports (с резервной копией).
%
% Из корня проекта: build_functional_simulink_model

root = fileparts(mfilename('fullpath'));
setup_paths();
assert(license('test','Simulink') == 1, ...
    'UAVF:MissingSimulink','Requires a Simulink license.');

outDir = fullfile(root,'models','functional','generated');
if ~exist(outDir,'dir'), mkdir(outDir); end
addpath(outDir);

cfg = config_uav();
scene = init_scenario(cfg);
waypoints = subsystem_route_planning(scene.start,scene.goal,scene.obstacles,cfg);
routeXY = waypoints(:,1:2)'; % [2 x N], start + targets
obstacleXY = zeros(3,numel(scene.obstacles));
for k = 1:numel(scene.obstacles)
    obstacleXY(:,k) = [scene.obstacles(k).center(:);scene.obstacles(k).radius];
end

spec = { ...
    'UAVF_Navigation_01', {'State'}, {'Navigation'}, ...
        fullfile(root,'team','01_Карпухин_Эрнест','simulink_nav.m'); ...
    'UAVF_FlightControl_02', {'Navigation','Target'}, {'Control'}, ...
        fullfile(root,'team','02_Живоглядов_Иван','simulink_control.m'); ...
    'UAVF_Waypoint_03', {'Navigation','Waypoints'}, {'Target'}, ...
        fullfile(root,'team','03_Лемченко_Богдан','simulink_waypoint.m'); ...
    'UAVF_Detection_04', {'Navigation','Obstacles'}, {'Detection'}, ...
        fullfile(root,'team','04_Дзедзей_Александр','simulink_detection.m'); ...
    'UAVF_GroundStation_05', {'Navigation','Detection','Energy', ...
        'SafetyStatus','State'}, {'Telemetry'}, ...
        fullfile(root,'team','05_Терехов_Арсений','simulink_ground.m'); ...
    'UAVF_Safety_06', {'Control','Detection','Navigation','Energy'}, ...
        {'SafeControl','SafetyStatus'}, ...
        fullfile(root,'team','06_Пучков_Артём','simulink_safety.m'); ...
    'UAVF_Energy_07', {'State','Control'}, {'Energy'}, ...
        fullfile(root,'team','07_Касимов_Иван','simulink_energy.m'); ...
    'UAVF_Dynamics_Overview', {'SafeControl','Energy'}, {'State'}, ...
        fullfile(root,'models','functional','dynamics_step.m') ...
    };

% Явно задаём размеры сигналов на границах Model Reference.
% Без этого Simulink может принять входы за скаляры (ошибка obstacles(3,k)).
portSizes = functional_port_dimensions(size(routeXY,2),size(obstacleXY,2));
for k = 1:size(spec,1)
    make_reference_model(spec{k,1},spec{k,2},spec{k,3},spec{k,4}, ...
        outDir,cfg.dt,k == 1,k == 8,portSizes{k});
end

main = 'UAVF_Team_Model';
modelFile = fullfile(outDir,[main '.slx']);
if exist(modelFile,'file')
    load_system(modelFile);
    open_system(main);
    fprintf('Opened existing functional model, not overwritten: %s\n',modelFile);
    return;
end
new_system(main);
set_param(main,'Solver','FixedStepDiscrete','FixedStep',num2str(cfg.dt), ...
    'StopTime',num2str(cfg.totalTime),'ReturnWorkspaceOutputs','on');

% Источники сценария — зафиксированные при построении модели данные.
add_block('simulink/Sources/Constant',[main '/Planned Waypoints'], ...
    'Value',mat2str(routeXY,12),'Position',[80 60 260 100]);
add_block('simulink/Sources/Constant',[main '/Obstacle Map'], ...
    'Value',mat2str(obstacleXY,12),'Position',[80 365 260 405]);

add_reference(main,'01 Navigation',spec{1,1},[100 220 290 290]);
add_reference(main,'03 Waypoint Planning',spec{3,1},[350 65 565 140]);
add_reference(main,'02 Flight Control',spec{2,1},[625 65 840 140]);
add_reference(main,'06 Flight Safety',spec{6,1},[910 60 1140 155]);
add_reference(main,'Dynamics',spec{8,1},[1225 215 1450 300]);
add_reference(main,'04 Object Detection',spec{4,1},[350 345 565 420]);
add_reference(main,'07 Energy',spec{7,1},[625 345 840 420]);
add_reference(main,'05 Ground Station',spec{5,1},[925 455 1160 555]);

% Контур движения: Unit Delay в Dynamics разрывает алгебраическую петлю.
wire(main,'Dynamics/1','01 Navigation/1','true state');
wire(main,'Dynamics/1','07 Energy/1','battery + velocity');
wire(main,'01 Navigation/1','03 Waypoint Planning/1','estimated nav');
wire(main,'Planned Waypoints/1','03 Waypoint Planning/2','route XY');
wire(main,'01 Navigation/1','02 Flight Control/1','nav');
wire(main,'03 Waypoint Planning/1','02 Flight Control/2','target XY');
wire(main,'02 Flight Control/1','06 Flight Safety/1','control');
wire(main,'01 Navigation/1','04 Object Detection/1','nav for sensor');
wire(main,'Obstacle Map/1','04 Object Detection/2','obstacles');
wire(main,'04 Object Detection/1','06 Flight Safety/2','nearest obstacle');
wire(main,'01 Navigation/1','06 Flight Safety/3','state estimate');
wire(main,'02 Flight Control/1','07 Energy/2','demand');
wire(main,'07 Energy/1','06 Flight Safety/4','battery state');
wire(main,'06 Flight Safety/1','Dynamics/1','safe control');
wire(main,'07 Energy/1','Dynamics/2','drain rate');

% Мониторинг отделён от вычислительного контура.
wire(main,'01 Navigation/1','05 Ground Station/1','nav telemetry');
wire(main,'04 Object Detection/1','05 Ground Station/2','obstacle telemetry');
wire(main,'07 Energy/1','05 Ground Station/3','battery telemetry');
wire(main,'06 Flight Safety/2','05 Ground Station/4','safety status');
wire(main,'Dynamics/1','05 Ground Station/5','true state');

add_log(main,'05 Ground Station/1','Telemetry Log','uavf_telemetry', ...
    [1250 470 1440 505]);
add_log(main,'Dynamics/1','State Log','uavf_state', ...
    [1510 220 1690 250]);
add_log(main,'03 Waypoint Planning/1','Target Log','uavf_target', ...
    [640 180 830 210]);
add_block('simulink/Sinks/Scope',[main '/Telemetry Scope'], ...
    'Position',[1250 530 1300 570]);
wire(main,'05 Ground Station/1','Telemetry Scope/1','');

save_system(main,modelFile);
open_system(main);
fprintf('Created EXECUTABLE 2D Model Reference diagram: %s\n',modelFile);
fprintf('Run run_functional_demo for numerical results and graphs.\n');
end

function make_reference_model(name,ins,outs,sourceFile,outDir,dt,isNav,isDynamics,inputSizes)
file = fullfile(outDir,[name '.slx']);
if exist(file,'file')
    load_system(file);
    fprintf('Existing module not overwritten: %s\n',name);
    return;
end
assert(exist(sourceFile,'file')==2, ...
    'UAVF:MissingSource','Missing function source: %s',sourceFile);
new_system(name);
set_param(name,'Solver','FixedStepDiscrete','FixedStep',num2str(dt));

for k = 1:numel(ins)
    add_block('simulink/Sources/In1',[name '/' ins{k}], ...
        'Port',num2str(k), ...
        'PortDimensions',inputSizes{k},'OutDataTypeStr','double', ...
        'Position',[30 45+70*(k-1) 85 65+70*(k-1)]);
end
for k = 1:numel(outs)
    add_block('simulink/Sinks/Out1',[name '/' outs{k}], ...
        'Port',num2str(k), ...
        'Position',[530 45+70*(k-1) 585 65+70*(k-1)]);
end

logic = [name '/Algorithm'];
add_block('simulink/User-Defined Functions/MATLAB Function',logic, ...
    'Position',[260 80 425 165]);
chart = find(sfroot,'-isa','Stateflow.EMChart','Path',logic);
assert(~isempty(chart),'UAVF:MissingChart','Cannot locate MATLAB Function chart');
chart.Script = fileread(sourceFile);
chart.SupportVariableSizing = false;

if isNav || isDynamics
    delay = [name '/State Memory'];
    if isNav
        ic = '[0;0;0;0]';
    else
        ic = '[0;0;0;0;100]';
    end
    add_block('simulink/Discrete/Unit Delay',delay, ...
        'InitialCondition',ic,'SampleTime',num2str(dt), ...
        'Position',[455 230 495 270]);
end

if isDynamics
    % Dynamics: output state BEFORE update -> feedback is causal.
    add_line(name,'State Memory/1','State/1','autorouting','on');
    add_line(name,'State Memory/1','Algorithm/1','autorouting','on');
    add_line(name,'SafeControl/1','Algorithm/2','autorouting','on');
    add_line(name,'Energy/1','Algorithm/3','autorouting','on');
    add_line(name,'Algorithm/1','State Memory/1','autorouting','on');
elseif isNav
    add_line(name,'State/1','Algorithm/1','autorouting','on');
    add_line(name,'State Memory/1','Algorithm/2','autorouting','on');
    add_line(name,'Algorithm/1','Navigation/1','autorouting','on');
    add_line(name,'Algorithm/1','State Memory/1','autorouting','on');
else
    for k = 1:numel(ins)
        add_line(name,sprintf('%s/1',ins{k}),sprintf('Algorithm/%d',k), ...
            'autorouting','on');
    end
    for k = 1:numel(outs)
        add_line(name,sprintf('Algorithm/%d',k),sprintf('%s/1',outs{k}), ...
            'autorouting','on');
    end
end
save_system(name,file);
fprintf('Generated functional module: %s\n',name);
end

function add_reference(model,label,modelName,position)
add_block('simulink/Ports & Subsystems/Model', ...
    [model '/' label],'ModelName',modelName,'Position',position);
end

function wire(model,from,to,label)
h = add_line(model,from,to,'autorouting','on');
if ~isempty(label)
    try
        set_param(h,'Name',label);
    catch
        % Сигнальные имена декоративные; не мешаем созданию модели.
    end
end
end

function add_log(model,from,name,varName,position)
add_block('simulink/Sinks/To Workspace',[model '/' name], ...
    'VariableName',varName,'SaveFormat','Timeseries','Position',position);
wire(model,from,[name '/1'],'');
end
