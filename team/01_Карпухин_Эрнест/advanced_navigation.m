function nav = advanced_navigation(trueState, previous, gpsAvailable, cfg)
%ADVANCED_NAVIGATION 01: GPS dropout + predictive state estimation.
% A transparent alpha filter; not a calibrated GPS/INS or Kalman filter.
% True velocity is used only for generating synthetic sensor measurements.
dt = cfg.dt;
if isempty(previous)
    previous = struct('position',trueState.position, ...
        'velocity',trueState.velocity,'outageSteps',0);
end
nav.outageSteps = previous.outageSteps;
nav.gpsAvailable = logical(gpsAvailable);
if gpsAvailable
    zPos = trueState.position + cfg.sensor.positionNoiseStd*randn(1,3);
    zVel = trueState.velocity + cfg.sensor.velocityNoiseStd*randn(1,3);
    prediction = previous.position + previous.velocity * dt;
    alphaP = cfg.sensor.positionFilterGain;
    alphaV = cfg.sensor.velocityFilterGain;
    nav.position = alphaP*zPos + (1-alphaP)*prediction;
    nav.velocity = alphaV*zVel + (1-alphaV)*previous.velocity;
    nav.outageSteps = 0;
else
    nav.position = previous.position + previous.velocity*dt;
    nav.velocity = previous.velocity;
    nav.outageSteps = previous.outageSteps+1;
end
nav.positionValid = nav.outageSteps <= cfg.advanced.maxDeadReckonSteps && ...
    all(isfinite(nav.position)) && all(isfinite(nav.velocity));
nav.headingValid = nav.positionValid;
nav.quality = max(0,1-nav.outageSteps/(cfg.advanced.maxDeadReckonSteps+1));
nav.speed = norm(nav.velocity);
nav.altitude = nav.position(3);
if nav.speed > 0.1
    nav.course = atan2(nav.velocity(2),nav.velocity(1));
else
    nav.course = trueState.yaw;
end
nav.yaw = trueState.yaw;
nav.measurementValid = logical(gpsAvailable);
end
