function estimate = simulink_nav(state, previousEstimate)
%SIMULINK_NAV 01: дискретная фильтрация идеализированной 2D навигации.
% state = [x;y;vx;vy;battery], estimate = [x;y;vx;vy].
% Это НЕ GPS/IMU; сглаживание без случайного шума демонстрационное.
%#codegen
estimate = zeros(4,1);
prediction = previousEstimate;
prediction(1:2) = previousEstimate(1:2) + 0.1*previousEstimate(3:4);
estimate(1:2) = 0.8*state(1:2) + 0.2*prediction(1:2);
estimate(3:4) = 0.8*state(3:4) + 0.2*previousEstimate(3:4);
end
