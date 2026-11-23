function [safe, safety] = advanced_safety_supervisor(nav, obstacles, cmd, energy, cfg)
%ADVANCED_SAFETY_SUPERVISOR 06: conservative collision/geofence control.
% Uses only sensor-visible obstacle geometry; does not claim real safety.
% Existing safety implementation remains unchanged and is reused here.
local = cfg;
local.safety.warningDistance = max(cfg.safety.warningDistance, ...
    cfg.advanced.replanClearance+1);
local.safety.emergencyDistance = max(cfg.safety.emergencyDistance, ...
    cfg.advanced.replanClearance-1);
local.safety.predictionHorizon = max(cfg.safety.predictionHorizon,2.5);

detections = subsystem_object_detection(nav,obstacles,local);
[safe,safety] = subsystem_flight_safety(nav,detections,cmd,energy,local);
safety.geofence = false;
p = nav.position;
g = cfg.advanced.geofence;
if p(1) <= g(1) || p(1) >= g(2) || ...
        p(2) <= g(3) || p(2) >= g(4)
    safe.acceleration = limit_norm(-2.0*nav.velocity,cfg.maxAccel);
    safe.yawRate = 0;
    safety.status = 'GEOFENCE_BRAKE';
    safety.intervened = true;
    safety.geofence = true;
end
end
