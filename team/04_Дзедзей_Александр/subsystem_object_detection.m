function detections = subsystem_object_detection(nav, obstacles, cfg)
%SUBSYSTEM_OBJECT_DETECTION Дальномер круговых препятствий (модуль 04).
% Данные сценария имитируют сенсор. Это не компьютерное зрение.
% distanceToBoundary и relativeXY используются модулем безопасности.

detections = struct('name', {}, 'distanceToBoundary', {}, ...
    'bearing', {}, 'relativeXY', {}, 'isWarning', {}, ...
    'confidence', {}, 'closingSpeed', {}, 'timeToCollision', {}, ...
    'penetrationDepth', {});
if ~nav.positionValid || ~nav.headingValid
    return;
end

for i = 1:numel(obstacles)
    rel = obstacles(i).center - nav.position(1:2);
    dCenter = norm(rel);
    boundary = dCenter - obstacles(i).radius;

    if boundary <= cfg.objectDetection.sensorRange
        d = max(0, boundary);
        item.name = obstacles(i).name;
        item.distanceToBoundary = d;
        item.penetrationDepth = max(0, -boundary);
        item.relativeXY = rel;
        item.bearing = wrap_angle(atan2(rel(2), rel(1)) - nav.course);
        item.isWarning = d <= cfg.objectDetection.warningDistance;
        item.confidence = max(cfg.objectDetection.confidenceFloor, ...
            1 - d / max(cfg.objectDetection.sensorRange, eps));

        if dCenter > 1e-9
            item.closingSpeed = max(0, dot(nav.velocity(1:2), rel / dCenter));
        else
            item.closingSpeed = 0;
        end
        if item.closingSpeed > 1e-9
            item.timeToCollision = d / item.closingSpeed;
        else
            item.timeToCollision = inf;
        end
        detections(end+1) = item; %#ok<AGROW>
    end
end
end
