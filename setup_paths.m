function root = setup_paths()
%SETUP_PATHS Подключает семь личных папок участников MATLAB-проекта.
% Функции подсистем находятся строго в одном экземпляре каждая.

root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root, 'team', '01_Карпухин_Эрнест'));
addpath(fullfile(root, 'team', '02_Живоглядов_Иван'));
addpath(fullfile(root, 'team', '03_Лемченко_Богдан'));
addpath(fullfile(root, 'team', '04_Дзедзей_Александр'));
addpath(fullfile(root, 'team', '05_Терехов_Арсений'));
addpath(fullfile(root, 'team', '06_Пучков_Артём'));
addpath(fullfile(root, 'team', '07_Касимов_Иван'));
addpath(fullfile(root, 'tests'));
end
