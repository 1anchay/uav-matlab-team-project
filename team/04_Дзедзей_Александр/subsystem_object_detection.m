function detections = subsystem_object_detection(nav, obstacles, cfg)
%SUBSYSTEM_OBJECT_DETECTION Участник 4 — обнаружение объектов.
% Упрощенная модель камеры/датчика: обнаруживает круговые препятствия,
% попавшие в дальность сенсора, и вычисляет относительное положение.

empty = struct('name', {}, 'distanceToBoundary', {}, 'bearing', {}, ...
               'relativeXY', {}, 'isWarning', {});
detections = empty;

for i = 1:numel(obstacles)
    rel = obstacles(i).center - nav.position(1:2);
    dCenter = norm(rel);
    dBoundary = dCenter - obstacles(i).radius;

    if dBoundary <= cfg.objectDetection.sensorRange
        item.name = obstacles(i).name;
        item.distanceToBoundary = max(0, dBoundary);
        item.relativeXY = rel;
        item.bearing = wrap_angle(atan2(rel(2), rel(1)) - nav.course);
        item.isWarning = dBoundary <= cfg.objectDetection.warningDistance;
        detections(end+1) = item; %#ok<AGROW>
    end
end
end
