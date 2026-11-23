function [safeControl, safety] = subsystem_flight_safety(nav, detections, control, energy, cfg)
%SUBSYSTEM_FLIGHT_SAFETY Участник 6 — Артём Пучков.
% Проверяет ограничения управления и реагирует на слишком близкие препятствия.
% Вход: nav, detections, control, energy, cfg.
% Выход: safeControl (та же структура, что control), safety (статус защиты).
% Учебная демонстрация: не заменяет полноценную систему предотвращения столкновений.

safeControl = control;
assert(numel(control.acceleration) == 3 && all(isfinite(control.acceleration)), ...
    'Safety: invalid acceleration command');
assert(isscalar(control.yawRate) && isfinite(control.yawRate), ...
    'Safety: invalid yaw rate');

safeControl.acceleration = limit_norm(control.acceleration, cfg.maxAccel);
safeControl.yawRate = max(-cfg.maxYawRate, min(cfg.maxYawRate, control.yawRate));

nearest = inf;
away = [0 0];
for k = 1:numel(detections)
    d = detections(k).distanceToBoundary;
    nearest = min(nearest, d);
    if d <= cfg.safety.emergencyDistance
        rel = detections(k).relativeXY; % вектор ОТ БПЛА К препятствию
        if all(isfinite(rel)) && norm(rel) > 1e-9
            away = away - rel / norm(rel); % уводим ОТ препятствия
        end
    end
end

intervened = norm(away) > 1e-9;
if intervened
    safeControl.acceleration = cfg.maxAccel * [away / norm(away), 0];
    status = 'OBSTACLE_AVOIDANCE';
elseif nearest <= cfg.safety.warningDistance
    status = 'OBSTACLE_WARNING';
elseif energy.criticalBattery
    status = 'CRITICAL_BATTERY';
elseif energy.lowBattery
    status = 'LOW_BATTERY';
else
    status = 'OK';
end

safety.status = status;
safety.obstacleWarning = nearest <= cfg.safety.warningDistance;
safety.nearestObstacleDistance = nearest;
safety.intervened = intervened;
safety.lowBattery = energy.lowBattery;
safety.criticalBattery = energy.criticalBattery;
safety.navValid = nav.positionValid && nav.headingValid;
end
