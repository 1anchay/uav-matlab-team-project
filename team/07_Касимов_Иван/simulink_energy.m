function energy = simulink_energy(state, command)
%SIMULINK_ENERGY 07: процентный расход заряда по скорости/ускорению.
% energy = [drainPercentPerSecond; currentBattery; lowBatteryFlag].
%#codegen
speed = sqrt(sum(state(3:4).^2));
accel = sqrt(sum(command.^2));
drain = 0.08 + 0.012*speed + 0.002*accel;
energy = [drain;state(5);double(state(5)<=20)];
end
