function root = setup_paths()
%SETUP_PATHS Добавляет семь персональных подсистем и общие файлы в MATLAB path.

root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root, 'team', '01_ernesto_horserofl_navigation'));
addpath(fullfile(root, 'team', '02_ivan_zhivoglyadov_flight_control'));
addpath(fullfile(root, 'team', '03_bodya_lemchenko_route_planning'));
addpath(fullfile(root, 'team', '04_aleksandr_lzedzei_object_detection'));
addpath(fullfile(root, 'team', '05_arseniy_terekhov_ground_station'));
addpath(fullfile(root, 'team', '06_artem_puchkov_flight_safety'));
addpath(fullfile(root, 'team', '07_ivan_kasimov_energy'));
addpath(fullfile(root, 'tests'));
end
