function result = run_advanced_mission(scenarioName,makePlots)
%RUN_ADVANCED_MISSION Execute V2 without altering validated UAVF_Team_Model.
if nargin < 1 || isempty(scenarioName),scenarioName='unexpected';end
if nargin < 2,makePlots=true;end
setup_paths();
[scene,cfg] = advanced_scenario(scenarioName);
result = simulate_advanced_uav(scene,cfg);
fprintf('=== ADVANCED MISSION V2 | %s ===\n',upper(scenarioName));
fprintf('Status: %s | duration: %.2f s\n',result.status,result.duration);
fprintf('Goal distance: %.2f m | battery: %.2f %%\n', ...
    result.goalDistance,result.finalBattery);
fprintf('Discovered: %d | Replans: %d | Safety actions: %d\n', ...
    result.discoveredObstacles,result.replanCount,result.totalSafetyActions);
fprintf('Navigation RMSE: %.3f m | packet delivery: %.1f %%\n', ...
    result.navRMSE,result.packetDeliveryRate);
fprintf('Minimum actual clearance: %.2f m\n',result.minimumClearance);
if makePlots
    plot_advanced_mission(result,scene,cfg);
end
end
