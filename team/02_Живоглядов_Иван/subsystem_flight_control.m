function control = subsystem_flight_control(nav, targetWaypoint, cfg)
%SUBSYSTEM_FLIGHT_CONTROL Каскадный P-регулятор с торможением у waypoint.
% Вход: nav (оценка), targetWaypoint [x y z], cfg; выход: control.

positionError = targetWaypoint - nav.position;
distance = norm(positionError);
desiredVelocity = cfg.kpPosition * positionError;

% Скорость плавно снижается вблизи цели: v^2 <= 2*a*distance.
maxApproachSpeed = cfg.control.brakingFactor * sqrt(2 * cfg.maxAccel * distance);
desiredVelocity = limit_norm(desiredVelocity, min(cfg.maxSpeed, maxApproachSpeed));

velocityError = desiredVelocity - nav.velocity;
accelCommand = limit_norm(cfg.kpVelocity * velocityError, cfg.maxAccel);

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
control.distanceToTarget = distance;
end
