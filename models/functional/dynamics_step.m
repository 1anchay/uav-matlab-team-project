function nextState = dynamics_step(previousState, safeCommand, energy)
%DYNAMICS_STEP Общая двумерная модель точки массой 1 условная единица.
% State [x;y;vx;vy;battery]; discrete step = 0.1 seconds.
%#codegen
dt = 0.1;
velocity = previousState(3:4) + safeCommand*dt;
speed = sqrt(sum(velocity.^2));
if speed > 10
    velocity = velocity * (10/speed);
end
position = previousState(1:2) + velocity*dt;
battery = max(0, previousState(5)-max(0,energy(1))*dt);
nextState = [position;velocity;battery];
end
