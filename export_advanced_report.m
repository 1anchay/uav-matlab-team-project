function directory = export_advanced_report(r,scene,cfg)
%EXPORT_ADVANCED_REPORT Write reproducible machine-readable V2 evidence.
% Exports CSV and Markdown, no dependencies beyond base MATLAB.
% All generated outputs remain local under results/v2 (Git-ignored).
root = fileparts(mfilename('fullpath'));
directory = fullfile(root,'results','v2',r.scenario);
if ~exist(directory,'dir'),mkdir(directory);end
log = table(r.time,r.position(:,1),r.position(:,2), ...
    r.velocity(:,1),r.velocity(:,2),r.battery, ...
    r.navError,r.gpsAvailable,r.navValid, ...
    r.safetyIntervention,r.linkDelivered, ...
    r.minObstacleDistance,r.replanEvents,r.knownObstacles, ...
    'VariableNames',{'Time_s','X_m','Y_m','VX_mps','VY_mps', ...
    'Battery_pct','NavigationError_m','GPSAvailable','NavigationValid', ...
    'SafetyActive','PacketReceived','ObstacleClearance_m', ...
    'NewRoute','KnownObstacles'});
writetable(log,fullfile(directory,'telemetry.csv'));
f = fopen(fullfile(directory,'summary.md'),'w');
assert(f>0,'UAV:Advanced:ReportWriteFailed','Cannot write report.');
guard=onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'# Advanced Mission V2 — %s\n\n',r.scenario);
fprintf(f,'Generated from MATLAB simulation. Educational point-mass model.\n\n');
fprintf(f,'| Metric | Result |\n|---|---|\n');
fprintf(f,'| Status | %s |\n',r.status);
fprintf(f,'| Time | %.2f s |\n',r.duration);
fprintf(f,'| Goal distance | %.3f m |\n',r.goalDistance);
fprintf(f,'| Battery at end | %.2f %% |\n',r.finalBattery);
fprintf(f,'| Newly discovered obstacles | %d |\n',r.discoveredObstacles);
fprintf(f,'| Online replans | %d |\n',r.replanCount);
fprintf(f,'| Minimum physical clearance | %.3f m |\n',r.minimumClearance);
fprintf(f,'| Safety interventions | %d |\n',r.totalSafetyActions);
fprintf(f,'| Navigation RMSE | %.3f m |\n',r.navRMSE);
fprintf(f,'| Packet delivery | %.2f %% |\n',r.packetDeliveryRate);
fprintf(f,'| Lost packets | %d |\n',r.packetsLost);
fprintf(f,'| Mean radio latency | %.2f steps |\n\n', ...
    r.meanPacketLatencySteps);
fprintf(f,'## Route replanning events\n\n');
for k=1:numel(r.routeEvents)
    entry = r.routeEvents(k);
    fprintf(f,'- Time %.2f s: %d waypoints, %d new obstacles.\n', ...
        entry.time,size(entry.route,1),entry.newCount);
end
fprintf(f,'\n## Scenario parameters\n\n');
fprintf(f,'Sensor range: %.2f m; cruise limit: %.2f m/s; dt: %.3f s.\n', ...
    cfg.advanced.sensorRange,cfg.advanced.cruiseSpeed,cfg.dt);
fprintf(f,'World obstacles: %d. This experiment is NOT a safety certification.\n', ...
    numel(scene.obstacles));
fprintf('Advanced report written: %s\n',directory);
end
