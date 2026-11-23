function evidence=run_defense_showcase(includeV3)
%RUN_DEFENSE_SHOWCASE Assemble a reproducible demonstration evidence folder.
% Default: the already validated MATLAB Advanced V2 (not the untested V3).
% Optional V3 only after its own Simulink acceptance suite has been checked.
if nargin<1,includeV3=false;end
root=fileparts(mfilename('fullpath'));
addpath(root);
setup_paths();
destination=fullfile(root,'results','defense');
if ~exist(destination,'dir'),mkdir(destination);end

[scene,cfg]=advanced_scenario('unexpected');
mission=run_advanced_mission('unexpected',true);
localReport=export_advanced_report(mission,scene,cfg);

dashboard=findobj('Type','figure', ...
    'Name',['UAV Advanced V2 - ' mission.scenario]);
if ~isempty(dashboard)
    exportgraphics(dashboard(1), ...
        fullfile(destination,'v2_online_replanning.png'),'Resolution',170);
end

campaign=run_advanced_campaign(true);
campaignFig=findobj('Type','figure', ...
    'Name','UAV Advanced V2 - Scenario Campaign');
if ~isempty(campaignFig)
    exportgraphics(campaignFig(1), ...
        fullfile(destination,'v2_campaign.png'),'Resolution',170);
end

v3=[];
if includeV3
    v3=run_v3_simulink_demo(true);
    figureObj=findobj('Type','figure', ...
        'Name','UAV V3 — online replanning inside Simulink');
    if ~isempty(figureObj)
        exportgraphics(figureObj(1), ...
            fullfile(destination,'v3_model_references.png'), ...
            'Resolution',170);
    end
end

f=fopen(fullfile(destination,'DEMONSTRATION_SUMMARY.md'),'w');
assert(f>0,'UAV:ShowcaseWriteFailed', ...
    'Cannot write the demonstration summary.');
guard=onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'# University UAV — reproducible demonstration\n\n');
fprintf(f,'V2 dynamic replanning: **%s**, after %.2f s.\n\n', ...
    mission.status,mission.duration);
fprintf(f,'- Unknown obstacles discovered: **%d**\n', ...
    mission.discoveredObstacles);
fprintf(f,'- Online route replans: **%d**\n',mission.replanCount);
fprintf(f,'- Final goal error: **%.3f m**\n',mission.goalDistance);
fprintf(f,'- Minimum circle clearance: **%.3f m**\n', ...
    mission.minimumClearance);
fprintf(f,'- Battery at end: **%.2f %%**\n',mission.finalBattery);
fprintf(f,'- Navigation RMSE: **%.3f m**\n',mission.navRMSE);
fprintf(f,'- Delivered telemetry: **%.1f %%**\n\n', ...
    mission.packetDeliveryRate);
fprintf(f,'Campaign: %d/%d goal arrivals; critical battery is a valid ');
fprintf(f,'terminal scenario, not a failed goal-arrival test.\n\n', ...
    campaign.goalsReached,campaign.total);
if includeV3
    fprintf(f,'V3 independent Simulink references: mission code **%d**, ', ...
        v3.terminalCode);
    fprintf(f,'**%d** online replans; closest circle clearance %.3f m.\n\n', ...
        v3.replans,v3.minimumClearance);
else
    fprintf(f,'V3 independent Simulink demonstrator: not executed ');
    fprintf(f,'by this showcase run (includeV3=false).\n\n');
end
fprintf(f,'This is a synthetic academic UAV simulator. ');
fprintf(f,'It is not flight software and does not certify physical safety.\n');

evidence.directory=destination;
evidence.v2=mission;
evidence.campaign=campaign;
evidence.v3=v3;
evidence.v2MachineReadableReport=localReport;
fprintf('Defense evidence directory: %s\n',destination);
end
