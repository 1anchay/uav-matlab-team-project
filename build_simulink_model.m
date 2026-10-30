function build_simulink_model()
%BUILD_SIMULINK_MODEL Обзорная схема семи командных подсистем.
% Эта блок-схема иллюстрирует интерфейсы, не заменяет simulate_uav.m.

setup_paths();
if ~license('test','Simulink')
    error('Simulink is not available. run_project.m can still be used in MATLAB.');
end

model = 'UAV_Team_Model';
if bdIsLoaded(model), close_system(model, 0); end
if exist([model '.slx'], 'file'), delete([model '.slx']); end
new_system(model);
open_system(model);
set_param(model, 'StopTime', '120');

% Общая модель динамики — НЕ восьмой участник
make_subsystem(model, 'UAV Dynamics Environment', 1, 1, [940 40 1180 110]);

% Семь модулей: пять исходных + два новых
make_subsystem(model, '1 Navigation',        1, 1, [100 80 300 150]);
make_subsystem(model, '2 Flight Control',    2, 1, [590 120 800 200]);
make_subsystem(model, '3 Route Planning',    2, 1, [330 240 540 320]);
make_subsystem(model, '4 Object Detection',  1, 1, [100 270 300 350]);
make_subsystem(model, '5 Ground Station',    5, 1, [940 460 1180 580]);
make_subsystem(model, '6 Flight Safety',     4, 1, [940 210 1180 340]);
make_subsystem(model, '7 Energy Management', 1, 1, [590 420 800 500]);

% Расчётные сигналы (схема взаимодействия)
add_line(model, 'UAV Dynamics Environment/1', '1 Navigation/1', 'autorouting','on');
add_line(model, 'UAV Dynamics Environment/1', '7 Energy Management/1', 'autorouting','on');
add_line(model, '1 Navigation/1', '2 Flight Control/1', 'autorouting','on');
add_line(model, '1 Navigation/1', '4 Object Detection/1', 'autorouting','on');
add_line(model, '1 Navigation/1', '3 Route Planning/1', 'autorouting','on');
add_line(model, '4 Object Detection/1', '3 Route Planning/2', 'autorouting','on');
add_line(model, '3 Route Planning/1', '2 Flight Control/2', 'autorouting','on');
add_line(model, '2 Flight Control/1', '6 Flight Safety/1', 'autorouting','on');
add_line(model, '4 Object Detection/1', '6 Flight Safety/2', 'autorouting','on');
add_line(model, '7 Energy Management/1', '6 Flight Safety/3', 'autorouting','on');
add_line(model, '1 Navigation/1', '6 Flight Safety/4', 'autorouting','on');
add_line(model, '6 Flight Safety/1', 'UAV Dynamics Environment/1', 'autorouting','on');

% Мониторинг
add_line(model, '1 Navigation/1', '5 Ground Station/1', 'autorouting','on');
add_line(model, '4 Object Detection/1', '5 Ground Station/2', 'autorouting','on');
add_line(model, '6 Flight Safety/1', '5 Ground Station/3', 'autorouting','on');
add_line(model, '7 Energy Management/1', '5 Ground Station/4', 'autorouting','on');
add_line(model, 'UAV Dynamics Environment/1', '5 Ground Station/5', 'autorouting','on');

% Не запускаем модель: расчёт реализован MATLAB-скриптом.
save_system(model);
open_system(model);
fprintf('Created %s.slx (architecture overview for 7 modules)\n', model);
end

function make_subsystem(model, name, nIn, nOut, pos)
path = [model '/' name];
add_block('simulink/Ports & Subsystems/Subsystem', path, 'Position', pos);

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

if nIn > 0 && nOut > 0
    add_block('simulink/Signal Attributes/Signal Conversion', [path '/Interface'], ...
        'Position', [95 25 135 55]);
    add_line(path, 'In1/1', 'Interface/1');
    add_line(path, 'Interface/1', 'Out1/1');
end

set_param(path, 'AttributesFormatString', ...
    sprintf('Team subsystem\nInputs: %d Outputs: %d', nIn, nOut));
end
