function target = simulink_waypoint(nav, routeXY)
%SIMULINK_WAYPOINT 03: выбирает waypoint из заранее построенного MATLAB-маршрута.
% routeXY [2xN], N >= 2; автономный геометрический поиск здесь не выполняется.
%#codegen
persistent waypointIndex
if isempty(waypointIndex)
    waypointIndex = int32(2);
end
n = int32(size(routeXY,2));
if waypointIndex > n
    waypointIndex = n;
end
target = routeXY(:,waypointIndex);
difference = target - nav(1:2);
if waypointIndex < n && sqrt(sum(difference.^2)) < 2.5
    waypointIndex = waypointIndex + int32(1);
    target = routeXY(:,waypointIndex);
end
end
