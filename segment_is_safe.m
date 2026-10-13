function safe = segment_is_safe(p1, p2, obstacles, clearance)
%SEGMENT_IS_SAFE Проверяет отрезок XY на пересечение с безопасными зонами.
safe = true;
for i = 1:numel(obstacles)
    required = obstacles(i).radius + clearance;
    d = segment_circle_clearance(p1(1:2), p2(1:2), obstacles(i).center);
    if d < required
        safe = false;
        return;
    end
end
end
