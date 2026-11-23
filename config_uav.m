function cfg = config_uav()
%CONFIG_UAV Общие параметры учебного проекта БПЛА (7 подсистем).

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
cfg.sensor.positionNoiseStd = 0.15;
cfg.sensor.altitudeNoiseStd = 0.08;
cfg.sensor.velocityNoiseStd = 0.05;
cfg.sensor.courseNoiseStd = deg2rad(0.8);

% Обнаружение объектов
cfg.objectDetection.sensorRange = 25.0;
cfg.objectDetection.warningDistance = 8.0;

% Планирование маршрута
cfg.route.clearance = 5.0;
cfg.route.detourExtra = 2.0;
cfg.route.maxPasses = 30;

% Батарея и связь
cfg.battery.initialPercent = 100.0;
cfg.battery.baseDrainPerSecond = 0.08;
cfg.battery.motionDrainFactor = 0.012;
cfg.battery.lowWarningPercent = 20.0;
cfg.comms.packetLossProbability = 0.03;

% Контроль безопасности
cfg.safety.warningDistance = 8.0;
cfg.safety.emergencyDistance = 3.0;
cfg.safety.criticalBatteryPercent = 5.0;

% Сценарий
cfg.scenario.start = [0 0 20];
cfg.scenario.goal = [100 80 20];
cfg.scenario.bounds = [-10 115 -10 95];
end
