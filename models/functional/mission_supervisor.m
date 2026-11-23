function [stopNow, missionCode] = mission_supervisor(state, goal, obstacles)
%MISSION_SUPERVISOR Terminal state machine for 2D training simulation.
% state [x;y;vx;vy;battery]; goal [x;y]; obstacles [3xN].
% Codes: 0=FLYING, 1=GOAL_REACHED, 2=COLLISION,
%        3=LOW_BATTERY, 4=INVALID_STATE.
%#codegen
missionCode = 0;
stopNow = false;

if any(~isfinite(state)) || any(~isfinite(goal))
    missionCode = 4;
    stopNow = true;
    return;
end

% Collision has priority over goal arrival (no false success on collision).
for k = 1:size(obstacles,2)
    if norm(state(1:2)-obstacles(1:2,k)) <= obstacles(3,k)
        missionCode = 2;
        stopNow = true;
        return;
    end
end

if state(5) <= 5.0
    missionCode = 3;
    stopNow = true;
    return;
end

distanceToGoal = norm(state(1:2)-goal);
speed = norm(state(3:4));
if distanceToGoal <= 3.0 && speed <= 1.0
    missionCode = 1;
    stopNow = true;
end
end
