function campaign = run_advanced_campaign(makePlots)
%RUN_ADVANCED_CAMPAIGN Execute and compare several V2 regression scenarios.
if nargin<1,makePlots=true;end
setup_paths();
names={'clear','unexpected','gps_outage','radio_blackout', ...
    'critical_battery','two_unknown'};
cases=repmat(struct('name','','status','','success',false, ...
    'replans',0,'clearance',NaN,'deliveryRate',NaN, ...
    'duration',NaN,'gpsRMSE',NaN,'error',''),1,numel(names));
for k=1:numel(names)
    [scene,cfg]=advanced_scenario(names{k});
    cases(k).name=names{k};
    try
        r=simulate_advanced_uav(scene,cfg);
        cases(k).status=r.status;
        cases(k).success=r.success;
        cases(k).replans=r.replanCount;
        cases(k).clearance=r.minimumClearance;
        cases(k).deliveryRate=r.packetDeliveryRate;
        cases(k).duration=r.duration;
        cases(k).gpsRMSE=r.navRMSE;
    catch ME
        cases(k).status='ERROR';
        cases(k).error=[ME.identifier ': ' ME.message];
    end
    fprintf('%-18s %-16s replans=%2d clearance=%7.2f m time=%6.1f s\n', ...
        cases(k).name,cases(k).status,cases(k).replans, ...
        cases(k).clearance,cases(k).duration);
end
campaign.cases=cases;
campaign.goalsReached=sum([cases.success]);
campaign.total=numel(names);
fprintf('Goal reach: %d/%d scenario definitions (not all expect success)\n', ...
    campaign.goalsReached,campaign.total);
if makePlots
    cats=categorical({cases.name});
    figure('Name','UAV Advanced V2 - Scenario Campaign');
    tl=tiledlayout(2,2,'TileSpacing','compact');
    title(tl,'Advanced mission verification campaign - reported outcomes');
    nexttile;bar(cats,[cases.replans]);grid on;ylabel('Replans');
    nexttile;bar(cats,[cases.duration]);grid on;ylabel('Duration (s)');
    nexttile;bar(cats,[cases.deliveryRate]);grid on;ylabel('Delivery (%)');
    nexttile;bar(cats,[cases.gpsRMSE]);grid on;ylabel('Navigation RMSE (m)');
end
end
