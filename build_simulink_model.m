function build_simulink_model()
%BUILD_SIMULINK_MODEL Создает архитектурную Simulink-модель пяти подсистем.
% Скриптовая симуляция выполняется run_project.m; эта модель нужна для
% наглядного представления модельно-ориентированной архитектуры команды.

setup_paths();

if ~license('test','Simulink')
    error('Simulink is not available. run_project.m can still be used in MATLAB.');
end

model = 'UAV_Team_Model';
if bdIsLoaded(model)
    close_system(model, 0);
end
if exist([model '.slx'], 'file')
    delete([model '.slx']);
end

new_system(model);
open_system(model);
set_param(model, 'StopTime', '120');

% Вспомогательная модель объекта БПЛА (не отдельный участник команды)
make_subsystem(model, 'UAV Dynamics Environment', 1, 1, [850 80 1050 150]);

% Пять подсистем = пять участников
make_subsystem(model, '1 Navigation',       1, 1, [80 70 270 140]);
make_subsystem(model, '4 Object Detection', 1, 1, [80 230 270 300]);
make_subsystem(model, '3 Route Planning',   2, 1, [360 210 550 290]);
make_subsystem(model, '2 Flight Control',   2, 1, [620 80 810 160]);
make_subsystem(model, '5 Ground Station',   3, 1, [850 240 1050 330]);

% Замыкание контура управления
add_line(model, 'UAV Dynamics Environment/1', '1 Navigation/1', 'autorouting','on');
add_line(model, '1 Navigation/1', '3 Route Planning/1', 'autorouting','on');
add_line(model, '1 Navigation/1', '4 Object Detection/1', 'autorouting','on');
add_line(model, '4 Object Detection/1', '3 Route Planning/2', 'autorouting','on');
add_line(model, '1 Navigation/1', '2 Flight Control/1', 'autorouting','on');
add_line(model, '3 Route Planning/1', '2 Flight Control/2', 'autorouting','on');
add_line(model, '2 Flight Control/1', 'UAV Dynamics Environment/1', 'autorouting','on');

% Мониторинг: ответвления сигналов в наземную станцию
add_line(model, '1 Navigation/1', '5 Ground Station/1', 'autorouting','on');
add_line(model, '2 Flight Control/1', '5 Ground Station/2', 'autorouting','on');
add_line(model, 'UAV Dynamics Environment/1', '5 Ground Station/3', 'autorouting','on');


set_param(model, 'SimulationCommand', 'update');
save_system(model);
open_system(model);
fprintf('Created %s.slx\n', model);
end

function make_subsystem(model, name, nIn, nOut, pos)
path = [model '/' name];
add_block('simulink/Ports & Subsystems/Subsystem', path, 'Position', pos);

% Удаляем стандартные блоки внутри и создаем требуемые порты.
try delete_line(path, 'In1/1', 'Out1/1'); catch, end
try delete_block([path '/In1']); catch, end
try delete_block([path '/Out1']); catch, end

for i = 1:nIn
    add_block('simulink/Sources/In1', sprintf('%s/In%d', path, i), ...
        'Position', [30 25+45*(i-1) 60 39+45*(i-1)]);
end
for i = 1:nOut
    add_block('simulink/Sinks/Out1', sprintf('%s/Out%d', path, i), ...
        'Position', [170 45+45*(i-1) 200 59+45*(i-1)]);
end

% Чтобы архитектурная схема компилировалась, объединяем первый вход с
% первым выходом через Signal Conversion. Остальные входы отображают
% интерфейсы команды и не участвуют в вычислении этой обзорной модели.
if nIn > 0 && nOut > 0
    add_block('simulink/Signal Attributes/Signal Conversion', [path '/Interface'], ...
        'Position', [95 25 135 55]);
    add_line(path, 'In1/1', 'Interface/1');
    add_line(path, 'Interface/1', 'Out1/1');
end

set_param(path, 'AttributesFormatString', sprintf('Team subsystem\nInputs: %d  Outputs: %d', nIn, nOut));
end
