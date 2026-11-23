function plan = advanced_replan_route(position, goal, obstacles, cfg)
%ADVANCED_REPLAN_ROUTE 03: actual on-demand geometric route calculation.
% Reuses strict 3D waypoint clearance checks; obstacles are circles in XY.
% Planning is done each time the synthetic sensor reveals a NEW obstacle.
plan.ok = false;
plan.route = zeros(0,3);
plan.reason = '';
plan.waypoints = 0;
plan.length = NaN;

local = cfg;
local.route.clearance = cfg.advanced.replanClearance;
try
    route = subsystem_route_planning(position,goal,obstacles,local);
    for k = 1:size(route,1)-1
        assert(segment_is_safe(route(k,:),route(k+1,:), ...
            obstacles,local.route.clearance), ...
            'UAV:Advanced:PlannerUnsafe','Planner returned unsafe segment.');
    end
    plan.route = route;
    plan.waypoints = size(route,1);
    plan.length = sum(sqrt(sum(diff(route,1,1).^2,2)));
    plan.ok = true;
    plan.reason = 'OK';
catch ME
    % Do not guess a route if geometry is blocked.
    plan.reason = [ME.identifier ': ' ME.message];
end
end
