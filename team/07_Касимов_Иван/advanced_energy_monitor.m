function energy = advanced_energy_monitor(state, command, distanceToGoal, cfg)
%ADVANCED_ENERGY_MONITOR 07: battery drain and mission reserve estimate.
% Still a percentage surrogate, not a battery electrochemical model.
energy = subsystem_energy(state,cfg,command);
rate = max(energy.drainRate,eps);
energy.estimatedMinutesToCritical = energy.estimatedRemainingSeconds/60;
estimateTravelTime = distanceToGoal/max(cfg.advanced.cruiseSpeed,0.1);
energy.estimatedPercentToGoal = estimateTravelTime*rate;
energy.reserveAtGoalPercent = energy.currentBattery - ...
    energy.estimatedPercentToGoal;
energy.returnReserveWarning = ...
    energy.reserveAtGoalPercent <= cfg.advanced.groundReservePercent;
energy.measuredPowerProxy = 1 + 0.20*norm(state.velocity) + ...
    0.05*norm(command.acceleration); % arbitrary educational units
end
