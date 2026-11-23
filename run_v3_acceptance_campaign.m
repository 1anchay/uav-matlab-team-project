function campaign = run_v3_acceptance_campaign(makePlots)
%RUN_V3_ACCEPTANCE_CAMPAIGN Extended integrated V3 Simulink acceptance.
% All scenarios run through SimulationInput without overwriting .slx.
% Reports failures and simulation errors exactly; NEVER fabricates PASS.
if nargin<1,makePlots=false;end
names={'baseline','two_unknown','collision_at_start', ...
    'critical_battery','invalid_state','goal_at_start'};
template=struct('name','','expected',NaN,'observed',NaN, ...
    'replans',NaN,'known',NaN,'clearance',NaN, ...
    'duration',NaN,'accepted',false,'error','');
rows=repmat(template,1,numel(names));
runs=cell(1,numel(names));
for k=1:numel(names)
    rows(k).name=names{k};
    scenario=v3_scenario_settings(names{k});
    rows(k).expected=scenario.expectedCode;
    try
        % Only the first two cases have useful route plots.
        draw=makePlots && (k<=2);
        r=run_v3_scenario(names{k},draw);
        runs{k}=r;
        rows(k).observed=r.terminalCode;
        rows(k).replans=r.replans;
        rows(k).known=r.knownCount;
        rows(k).clearance=r.minimumSweptClearance;
        rows(k).duration=r.duration;
        rows(k).accepted=r.accepted;
        if ~r.accepted
            rows(k).error='Incorrect terminal/clearance/replanning condition';
        end
    catch ME
        rows(k).error=[ME.identifier ' ' ME.message];
        fprintf('V3 %-19s ERROR: %s\n',names{k},rows(k).error);
    end
end
campaign.rows=rows;
campaign.runs=runs;
campaign.total=numel(rows);
campaign.passed=sum([rows.accepted]);
campaign.failed=campaign.total-campaign.passed;
fprintf('V3 extended Simulink acceptance: %d/%d PASS\n', ...
    campaign.passed,campaign.total);
if campaign.failed>0
    fprintf('WARNING: %d V3 scenario(s) require correction/review.\n', ...
        campaign.failed);
end
end
