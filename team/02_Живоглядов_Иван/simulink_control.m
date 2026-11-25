function command = simulink_control(nav, target)
%SIMULINK_CONTROL 02: насыщаемый PD-регулятор движения к waypoint в XY.
%#codegen
error = target - nav(1:2);
distance = sqrt(sum(error.^2));
desired = 0.65 * error;
maxDesired = min(10.0, 0.9*sqrt(2.0*3.0*distance));
v = sqrt(sum(desired.^2));
if v > maxDesired && v > 1e-9
    desired = desired * (maxDesired/v);
end
command = 1.25 * (desired - nav(3:4));
a = sqrt(sum(command.^2));
if a > 3.0
    command = command*(3.0/a);
end
end
