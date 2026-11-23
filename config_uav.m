function cfg = config_uav()
%CONFIG_UAV Единые настройки демонстрационной модели БПЛА (7 модулей).
% Все координаты — метры (XYZ), скорость — м/с, время — секунды.

cfg.dt = 0.1;
cfg.totalTime = 120;
cfg.seed = 42;

cfg.maxSpeed = 10.0;
cfg.maxAccel = 3.0;
cfg.maxYawRate = deg2rad(60);
cfg.minAltitude = 3;
cfg.maxAltitude = 60;

cfg.kpPosition = 0.65;
cfg.kpVelocity = 1.25;
cfg.kpYaw = 2.0;
cfg.waypointTolerance = 2.5;
cfg.goalTolerance = 3;
cfg.control.brakingFactor = 0.9; % ограничение скорости при приближении к цели

cfg.sensor.positionNoiseStd = 0.15;
cfg.sensor.altitudeNoiseStd = 0.08;
cfg.sensor.velocityNoiseStd = 0.05;
cfg.sensor.courseNoiseStd = deg2rad(0.8);
cfg.sensor.positionFilterGain = 0.6; % 1 = только новое измерение
cfg.sensor.velocityFilterGain = 0.65;

cfg.objectDetection.sensorRange = 25;
cfg.objectDetection.warningDistance = 8;
cfg.objectDetection.confidenceFloor = 0.2;

cfg.route.clearance = 5;
cfg.route.detourExtra = 2;
cfg.route.maxPasses = 30;

cfg.battery.initialPercent = 100;
cfg.battery.baseDrainPerSecond = 0.08;
cfg.battery.motionDrainFactor = 0.012;
cfg.battery.accelDrainFactor = 0.002; % процентных пунктов на м/с^2 в секунду
cfg.battery.climbDrainFactor = 0.01;
cfg.battery.lowWarningPercent = 20;
cfg.comms.packetLossProbability = 0.03;

cfg.safety.warningDistance = 8;
cfg.safety.emergencyDistance = 3;
cfg.safety.predictionHorizon = 2; % секунды предсказания опасного сближения
cfg.safety.invalidNavBrakeGain = 1.8;
cfg.safety.criticalBatteryPercent = 5;

cfg.scenario.start = [0 0 20];
cfg.scenario.goal = [100 80 20];
cfg.scenario.bounds = [-10 115 -10 95];
end
