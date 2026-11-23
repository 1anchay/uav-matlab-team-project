function cfg = advanced_config()
%ADVANCED_CONFIG Separate settings for seven-module Advanced Mission V2.
% Preserve config_uav.m, run_project.m and existing Simulink model unchanged.
cfg = config_uav();
cfg.advanced.cruiseSpeed = 7.0;
cfg.advanced.sensorRange = 35.0;          % m, idealized circular range
cfg.advanced.missProbability = 0.0;       % nominal sensor detection loss
cfg.advanced.replanClearance = 7.0;       % m, stricter than baseline
cfg.advanced.maxReplans = 12;
cfg.advanced.maxDeadReckonSteps = 12;     % steps without GPS before invalid
cfg.advanced.gpsOutageFirst = inf;
cfg.advanced.gpsOutageLast = -inf;
cfg.advanced.packetLatencySteps = 3;
cfg.advanced.packetLossProbability = 0.03;
cfg.advanced.missionMaxTime = 120;
cfg.advanced.goalRadius = 3.0;
cfg.advanced.goalSpeed = 1.3;
cfg.advanced.groundReservePercent = 5;
cfg.advanced.geofence = [-15 120 -15 105]; % [xmin xmax ymin ymax]
cfg.advanced.seed = 420;
end
