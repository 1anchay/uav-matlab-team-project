function command = v3_control(nav,target)
%V3_CONTROL Limited XY tracking controller for fixed-step 2D flight.
% nav=[x;y;vx;vy], target=[x;y], acceleration limits 3 m/s^2.
%#codegen
delta = target-nav(1:2);
d = sqrt(sum(delta.^2));
desired = 0.75*delta;
vmax = min(7.0,0.9*sqrt(6.0*d));
current = sqrt(sum(desired.^2));
if current > vmax && current > 1.0e-9
    desired = desired*(vmax/current);
end
command = 1.45*(desired-nav(3:4));
a = sqrt(sum(command.^2));
if a>3.0
    command = command*(3.0/a);
end
end
