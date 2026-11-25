function detection = simulink_detection(nav, obstacles)
%SIMULINK_DETECTION 04: ближайшая окружность в поле действия дальномера.
% obstacles [3xN] = [centerX;centerY;radius].
% detection = [distanceToBoundary;relativeX;relativeY;radius].
%#codegen
detection = [1.0e3;0;0;0];
for k = 1:size(obstacles,2)
    rel = obstacles(1:2,k)-nav(1:2);
    distance = sqrt(sum(rel.^2)) - obstacles(3,k);
    if distance < detection(1) && distance <= 25.0
        detection = [distance;rel(1);rel(2);obstacles(3,k)];
    end
end
end
