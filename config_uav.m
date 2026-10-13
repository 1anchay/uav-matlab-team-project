function cfg = config_uav()
%CONFIG_UAV Общие параметры учебного проекта БПЛА.
% Проект не требует специальных MATLAB-toolbox'ов для скриптовой симуляции.

cfg.dt = 0.1;                 % шаг моделирования, с
cfg.totalTime = 120;          % максимальное время, с
cfg.seed = 42;                % воспроизводимость шумов датчиков

% Ограничения БПЛА
cfg.maxSpeed = 10.0;          % м/с
cfg.maxAccel = 3.0;           % м/с^2
cfg.maxYawRate = deg2rad(60); % рад/с
cfg.minAltitude = 3.0;        % м
cfg.maxAltitude = 60.0;       % м

% Параметры регулятора
cfg.kpPosition = 0.65;
cfg.kpVelocity = 1.25;
cfg.kpYaw = 2.0;
cfg.waypointTolerance = 2.5;  % м
cfg.goalTolerance = 3.0;      % м

% Имитация навигационных датчиков
cfg.sensor.positionNoiseStd = 0.15;      % м
cfg.sensor.altitudeNoiseStd = 0.08;      % м
cfg.sensor.velocityNoiseStd = 0.05;      % м/с
cfg.sensor.courseNoiseStd = deg2rad(0.8);% рад

% Обнаружение объектов
cfg.objectDetection.sensorRange = 25.0;  % м от границы препятствия
cfg.objectDetection.warningDistance = 8.0;

% Планирование маршрута
cfg.route.clearance = 5.0;      % дополнительный безопасный зазор, м
cfg.route.detourExtra = 2.0;    % запас для обходной точки, м
cfg.route.maxPasses = 30;

% Батарея и связь
cfg.battery.initialPercent = 100.0;
cfg.battery.baseDrainPerSecond = 0.08;
cfg.battery.motionDrainFactor = 0.012;
cfg.comms.packetLossProbability = 0.03;

% Сценарий
cfg.scenario.start = [0 0 20];
cfg.scenario.goal  = [100 80 20];
cfg.scenario.bounds = [-10 115 -10 95]; % xmin xmax ymin ymax
end
