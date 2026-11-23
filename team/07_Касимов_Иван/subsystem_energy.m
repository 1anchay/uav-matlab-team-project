function energy = subsystem_energy(state, cfg, control)
%SUBSYSTEM_ENERGY Расход батареи и оценка остатка ресурса (модуль 07).
% Процентная учебная модель, не описание электрохимии аккумулятора.
% Необязательный control позволяет учитывать предстоящее ускорение.

if nargin < 3
    acceleration = [0 0 0];
else
    acceleration = control.acceleration;
end
assert(numel(state.velocity) == 3 && all(isfinite(state.velocity)) && ...
    isscalar(state.battery) && isfinite(state.battery) && ...
    numel(acceleration) == 3 && all(isfinite(acceleration)), ...
    'Energy: invalid state or command');

battery = max(0, min(100, state.battery));
predictedVelocity = limit_norm(state.velocity + acceleration * cfg.dt, cfg.maxSpeed);
speed = norm(predictedVelocity);
climbSpeed = max(0, predictedVelocity(3));

drainRate = cfg.battery.baseDrainPerSecond + ...
    cfg.battery.motionDrainFactor * speed + ...
    cfg.battery.accelDrainFactor * norm(acceleration) + ...
    cfg.battery.climbDrainFactor * climbSpeed;

energy.currentBattery = battery;
energy.drainRate = drainRate;
energy.nextBattery = max(0, battery - drainRate * cfg.dt);
energy.lowBattery = battery <= cfg.battery.lowWarningPercent;
energy.criticalBattery = battery <= cfg.safety.criticalBatteryPercent;
energy.estimatedRemainingSeconds = max(0, ...
    battery - cfg.safety.criticalBatteryPercent) / max(drainRate, eps);
energy.predictedSpeed = speed;
end
