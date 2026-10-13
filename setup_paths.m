function root = setup_paths()
%SETUP_PATHS Добавляет общие и персональные папки команды в MATLAB path.
% Каждый участник редактирует функцию только в своей папке team/.

root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root, 'team', '01_ernesto_horserofl_navigation'));
addpath(fullfile(root, 'team', '02_ivan_zhivoglyadov_flight_control'));
addpath(fullfile(root, 'team', '03_bodya_lemchenko_route_planning'));
addpath(fullfile(root, 'team', '04_aleksandr_lzedzei_object_detection'));
addpath(fullfile(root, 'team', '05_arseniy_terekhov_ground_station'));
addpath(fullfile(root, 'tests'));
end
