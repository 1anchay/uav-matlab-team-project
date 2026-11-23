function scan = advanced_sensor_scan(nav, obstacles, knownMask, cfg)
%ADVANCED_SENSOR_SCAN 04: bounded synthetic obstacle range sensor.
% This knows obstacle geometry in the simulator, NOT real computer vision.
n = numel(obstacles);
assert(numel(knownMask)==n,'UAV:Advanced:KnownMaskSize', ...
    'Known-obstacle mask must match the obstacle array.');
scan.visible = false(1,n);
scan.newlyDetected = false(1,n);
scan.known = logical(knownMask);
scan.nearestBoundary = inf;
scan.visibleCount = 0;
scan.missedCount = 0;
if ~nav.positionValid
    return;
end

for k = 1:n
    boundary = norm(obstacles(k).center-nav.position(1:2)) - ...
        obstacles(k).radius;
    if boundary <= cfg.advanced.sensorRange
        scan.nearestBoundary = min(scan.nearestBoundary,boundary);
        if rand >= cfg.advanced.missProbability
            scan.visible(k) = true;
            scan.visibleCount = scan.visibleCount+1;
        else
            scan.missedCount = scan.missedCount+1;
        end
    end
end
scan.newlyDetected = scan.visible & ~scan.known;
scan.known = scan.known | scan.visible;
end
