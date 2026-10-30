function energy = subsystem_energy(state, cfg)
%SUBSYSTEM_ENERGY Участник 7 — Иван Касимов.
% Учебная модель расхода заряда батареи на очередном шаге симуляции.
% Вход: state (position, velocity, battery), cfg.
% Выход: energy (расход, прогноз заряда, предупреждения).

speed = norm(state.velocity);
assert(isfinite(speed) && isfinite(state.battery), ...
    'Energy: invalid state');

drainRate = cfg.battery.baseDrainPerSecond + ...
    cfg.battery.motionDrainFactor * speed;  % процентных пунктов в секунду
energy.currentBattery = state.battery;
energy.drainRate = drainRate;
energy.nextBattery = max(0, state.battery - drainRate * cfg.dt);
energy.lowBattery = state.battery <= cfg.battery.lowWarningPercent;
energy.criticalBattery = state.battery <= cfg.safety.criticalBatteryPercent;
energy.estimatedRemainingSeconds = state.battery / max(drainRate, eps);
end
