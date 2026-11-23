function control = advanced_tracking_control(nav, target, cfg)
%ADVANCED_TRACKING_CONTROL 02: speed-limited waypoint tracking + fail-safe.
% Uses the approved baseline controller and limits the V2 cruise speed.
local = cfg;
local.maxSpeed = min(cfg.maxSpeed,cfg.advanced.cruiseSpeed);
if ~nav.positionValid
    control.target = target;
    control.positionError = target-nav.position;
    control.distanceToTarget = norm(control.positionError);
    control.desiredVelocity = [0 0 0];
    control.acceleration = limit_norm(-1.8*nav.velocity,cfg.maxAccel);
    control.yawRate = 0;
    control.mode = 'DEGRADED';
else
    control = subsystem_flight_control(nav,target,local);
    control.mode = 'TRACK';
end
end
