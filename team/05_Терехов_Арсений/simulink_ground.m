function telemetry = simulink_ground(nav, detection, energy, safetyFlag, state)
%SIMULINK_GROUND 05: фиксированный вектор диагностической телеметрии.
% [x;y;vx;vy;battery;distanceToObstacle;safetyIntervention].
%#codegen
telemetry = zeros(7,1);
telemetry(1:4) = nav;
telemetry(5) = state(5);
telemetry(6) = detection(1);
telemetry(7) = safetyFlag;
% energy передан как часть проверяемого контракта; расход логируется отдельно.
if energy(2) < 0
    telemetry(5) = 0;
end
end
