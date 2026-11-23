function [safeControl, safety] = subsystem_flight_safety(nav, detections, control, energy, cfg)
%SUBSYSTEM_FLIGHT_SAFETY Проверка команд и прогноз опасного сближения.
% Демонстрационная защита, НЕ система безопасности реального аппарата.
% Используются относительные координаты и скорость, не только расстояние.

assert(numel(control.acceleration) == 3 && all(isfinite(control.acceleration)), ...
    'Safety: invalid acceleration command');
assert(isscalar(control.yawRate) && isfinite(control.yawRate), ...
    'Safety: invalid yaw rate');

safeControl = control;
safeControl.acceleration = limit_norm(control.acceleration, cfg.maxAccel);
safeControl.yawRate = max(-cfg.maxYawRate, min(cfg.maxYawRate, control.yawRate));

navValid = nav.positionValid && nav.headingValid && all(isfinite(nav.velocity));
nearest = inf;
predictedNearest = inf;
avoidVector = [0 0];
hazard = false;

for k = 1:numel(detections)
    d = detections(k).distanceToBoundary;
    rel = detections(k).relativeXY;
    if ~isscalar(d) || ~isfinite(d) || numel(rel) ~= 2 || ~all(isfinite(rel))
        continue;
    end
    nearest = min(nearest, d);
    % Восстанавливаем радиус по distanceToBoundary; если объект внутри,
    % здесь используем максимально осторожную оценку.
    radiusEstimate = max(0, norm(rel) - d);
    tClosest = 0;
    if navValid
        v = nav.velocity(1:2);
        vv = dot(v,v);
        if vv > 1e-9
            tClosest = max(0, min(cfg.safety.predictionHorizon, dot(rel,v) / vv));
        end
        predictedBoundary = norm(rel - v*tClosest) - radiusEstimate;
    else
        predictedBoundary = d;
    end
    predictedNearest = min(predictedNearest, predictedBoundary);
    dangerous = d <= cfg.safety.emergencyDistance || ...
        (tClosest > 0 && predictedBoundary <= cfg.safety.emergencyDistance);
    if dangerous
        hazard = true;
        if norm(rel) > 1e-9
            avoidVector = avoidVector - rel/norm(rel);
        end
    end
end

if ~navValid
    % В случае потери оценки состояния — торможение вместо слепого манёвра.
    safeControl.acceleration = limit_norm( ...
        -cfg.safety.invalidNavBrakeGain * nav.velocity, cfg.maxAccel);
    safeControl.yawRate = 0;
    status = 'NAV_INVALID';
    intervened = true;
elseif hazard
    braking = -0.5 * nav.velocity(1:2);
    direction = avoidVector + braking;
    if norm(direction) > 1e-9
        safeControl.acceleration(1:2) = cfg.maxAccel * direction / norm(direction);
        safeControl.acceleration = limit_norm(safeControl.acceleration, cfg.maxAccel);
    else
        safeControl.acceleration(1:2) = [0 0];
    end
    status = 'OBSTACLE_AVOIDANCE';
    intervened = true;
elseif energy.criticalBattery
    status = 'CRITICAL_BATTERY';
    intervened = false; % статус: прекращение миссии делает интегратор
elseif energy.lowBattery
    status = 'LOW_BATTERY';
    intervened = false;
elseif nearest <= cfg.safety.warningDistance
    status = 'OBSTACLE_WARNING';
    intervened = false;
else
    status = 'OK';
    intervened = false;
end

safety.status = status;
safety.intervened = intervened;
safety.obstacleWarning = nearest <= cfg.safety.warningDistance;
safety.nearestObstacleDistance = nearest;
safety.predictedNearestDistance = predictedNearest;
safety.predictedConflict = hazard;
safety.lowBattery = energy.lowBattery;
safety.criticalBattery = energy.criticalBattery;
safety.navValid = navValid;
end
