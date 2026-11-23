function control = subsystem_flight_control(nav, targetWaypoint, cfg)
%SUBSYSTEM_FLIGHT_CONTROL Участник 2 — управление полетом.
% Упрощенный каскадный P-регулятор: позиция -> желаемая скорость -> ускорение.

positionError = targetWaypoint - nav.position;
desiredVelocity = cfg.kpPosition * positionError;
desiredVelocity = limit_norm(desiredVelocity, cfg.maxSpeed);

velocityError = desiredVelocity - nav.velocity;
accelCommand = cfg.kpVelocity * velocityError;
accelCommand = limit_norm(accelCommand, cfg.maxAccel);

if norm(desiredVelocity(1:2)) > 0.1
    desiredYaw = atan2(desiredVelocity(2), desiredVelocity(1));
else
    desiredYaw = nav.course;
end

yawError = wrap_angle(desiredYaw - nav.course);
yawRateCommand = max(-cfg.maxYawRate, min(cfg.maxYawRate, cfg.kpYaw * yawError));

control.target = targetWaypoint;
control.desiredVelocity = desiredVelocity;
control.acceleration = accelCommand;
control.yawRate = yawRateCommand;
control.positionError = positionError;
end
