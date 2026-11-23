function modelNames = build_component_models()
%BUILD_COMPONENT_MODELS Создаёт семь ОТДЕЛЬНЫХ эталонных файлов моделей.
% Важно: это контрактные заглушки портов, а НЕ исполняемые алгоритмы БПЛА.
% Реальные расчёты пока выполняются функциями в team/ и simulate_uav.m.
% Файлы .slx не перезаписываются, чтобы не уничтожить работу участников.

root = setup_paths();
if ~license('test','Simulink')
    error('UAV:MBD:MissingSimulink','Simulink license is required.');
end
outputDir = fullfile(root,'models','generated');
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end
addpath(outputDir);
modelNames = {'UAV_Navigation_01', 'UAV_FlightControl_02', ...
    'UAV_RoutePlanning_03', 'UAV_ObjectDetection_04', ...
    'UAV_GroundStation_05', 'UAV_FlightSafety_06', ...
    'UAV_Energy_07', 'UAV_Dynamics_Overview'};
nInputs = [1 2 2 1 5 4 1 1];

for j = 1:numel(modelNames)
    model = modelNames{j};
    targetFile = fullfile(outputDir,[model '.slx']);
    if exist(targetFile,'file')
        load_system(targetFile);
        continue; % сохраняем ручные доработки отдельной модели
    end
    new_system(model);
    set_param(model,'Solver','FixedStepDiscrete','FixedStep','0.1');
    for k = 1:nInputs(j)
        block = sprintf('%s/In%d',model,k);
        add_block('simulink/Sources/In1',block, ...
            'Port',num2str(k),'Position',[30 30+65*(k-1) 60 44+65*(k-1)]);
    end
    add_block('simulink/Sinks/Out1',[model '/Out1'], ...
        'Position',[280 40 310 54]);
    if j == 8
        % Unit Delay разрывает обратную связь ОБЗОРНОГО контура.
        add_block('simulink/Discrete/Unit Delay',[model '/StateMemory'], ...
            'Position',[120 30 170 70]);
        add_line(model,'In1/1','StateMemory/1');
        add_line(model,'StateMemory/1','Out1/1');
    else
        add_block('simulink/Signal Attributes/Signal Conversion', ...
            [model '/InterfacePlaceholder'],'Position',[120 30 170 70]);
        add_line(model,'In1/1','InterfacePlaceholder/1');
        add_line(model,'InterfacePlaceholder/1','Out1/1');
    end
    save_system(model,targetFile);
    fprintf('Generated placeholder model: %s\n',targetFile);
end
end
