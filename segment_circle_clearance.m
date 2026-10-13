function d = segment_circle_clearance(p1, p2, center)
%SEGMENT_CIRCLE_CLEARANCE Минимальное расстояние от отрезка p1-p2 до точки.
v = p2 - p1;
vv = dot(v,v);
if vv < 1e-12
    d = norm(center - p1);
    return;
end
t = dot(center - p1, v) / vv;
t = max(0, min(1, t));
closest = p1 + t * v;
d = norm(center - closest);
end
