function sizes = functional_port_dimensions(waypointCount,obstacleCount)
%FUNCTIONAL_PORT_DIMENSIONS Фиксированные формы сигналов Model Reference.
% Каждая строка соответствует модели в build_functional_simulink_model.
% Колонковые векторы задаются как [N 1], матрицы как [R C].
%
% Причина: при наследуемом размере модель-ссылка может скомпилировать
% внешний вход как scalar, что приводит к ошибке obstacles(3,k).

validateattributes(waypointCount,{'numeric'},{'scalar','integer','>=',2});
validateattributes(obstacleCount,{'numeric'},{'scalar','integer','>=',1});

sizes = { ...
    {'[5 1]'}; ...                                        % Navigation
    {'[4 1]','[2 1]'}; ...                              % Flight Control
    {'[4 1]',sprintf('[2 %d]',waypointCount)}; ...       % Waypoint
    {'[4 1]',sprintf('[3 %d]',obstacleCount)}; ...       % Detection
    {'[4 1]','[4 1]','[3 1]','1','[5 1]'}; ...         % Ground Station
    {'[2 1]','[4 1]','[4 1]','[3 1]'}; ...             % Safety
    {'[5 1]','[2 1]'}; ...                              % Energy
    {'[2 1]','[3 1]'} ...                               % Dynamics
    };
end
