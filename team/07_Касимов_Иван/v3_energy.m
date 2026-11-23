function energy = v3_energy(state,command)
%V3_ENERGY Lightweight percent-per-second battery model.
% energy=[drainPercentPerSecond;stateBattery;lowFlag].
%#codegen
speed=sqrt(sum(state(3:4).^2));
accel=sqrt(sum(command.^2));
drain=0.08+0.012*speed+0.002*accel;
energy=[drain;state(5);double(state(5)<=20.0)];
end
