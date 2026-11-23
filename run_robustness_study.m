function study = run_robustness_study(seedCount,makePlots,scenarioNames,missRates)
%RUN_ROBUSTNESS_STUDY Evaluate V2 against repeated sensor detection misses.
% Returns every measured outcome, including failures. NOT a safety proof.
% Defaults: 10 seeds x 3 miss rates x 2 unknown-obstacle worlds = 60 runs.
if nargin<1 || isempty(seedCount),seedCount=10;end
if nargin<2,makePlots=true;end
if nargin<3 || isempty(scenarioNames), ...
        scenarioNames={'unexpected','two_unknown'};end
if nargin<4 || isempty(missRates),missRates=[0 0.15 0.35];end
validateattributes(seedCount,{'numeric'}, ...
    {'scalar','integer','positive','<=',1000});
validateattributes(missRates,{'numeric'}, ...
    {'vector','>=',0,'<=',1});
assert(iscell(scenarioNames) && ~isempty(scenarioNames), ...
    'UAV:StudyBadScenario','Provide a non-empty scenario cell list.');
setup_paths();

template=struct('scenario','','missRate',0,'seed',0,'status','', ...
    'success',false,'replans',0,'discovered',0, ...
    'minClearance',NaN,'goalDistance',NaN, ...
    'duration',NaN,'navRMSE',NaN,'cpuSeconds',NaN,'error','');
records=repmat(template,1,numel(scenarioNames)*numel(missRates)*seedCount);
idx=0;
for s=1:numel(scenarioNames)
    for m=1:numel(missRates)
        for k=1:seedCount
            idx=idx+1;
            cfg=advanced_config();
            cfg.advanced.seed=cfg.advanced.seed+1000+101*k;
            cfg.advanced.missProbability=missRates(m);
            [scene,cfg]=advanced_scenario(scenarioNames{s},cfg);
            records(idx).scenario=scenarioNames{s};
            records(idx).missRate=missRates(m);
            records(idx).seed=cfg.advanced.seed;
            ticStart=tic;
            try
                result=simulate_advanced_uav(scene,cfg);
                records(idx).status=result.status;
                records(idx).success=result.success;
                records(idx).replans=result.replanCount;
                records(idx).discovered=result.discoveredObstacles;
                records(idx).minClearance=result.minimumClearance;
                records(idx).goalDistance=result.goalDistance;
                records(idx).duration=result.duration;
                records(idx).navRMSE=result.navRMSE;
            catch ME
                records(idx).status='ERROR';
                records(idx).error=[ME.identifier ': ' ME.message];
            end
            records(idx).cpuSeconds=toc(ticStart);
        end
    end
end
study.records=records;
study.total=numel(records);
study.successCount=sum([records.success]);
study.successRate=100*study.successCount/study.total;
study.scenarios=scenarioNames;
study.missRates=missRates;
study.seedCount=seedCount;
study.failures=study.total-study.successCount;
study.hasCollision=any(strcmp({records.status},'COLLISION'));
study.medianCpuSeconds=median([records.cpuSeconds]);

fprintf('\n=== UAV V2 ROBUSTNESS STUDY ===\n');
fprintf('%d runs, %d goal arrivals, %.1f%% observed success\n', ...
    study.total,study.successCount,study.successRate);
fprintf('Observed collisions: %d | median runtime %.3f s\n', ...
    sum(strcmp({records.status},'COLLISION')), ...
    study.medianCpuSeconds);
for s=1:numel(scenarioNames)
    for m=1:numel(missRates)
        mask=strcmp({records.scenario},scenarioNames{s}) & ...
            abs([records.missRate]-missRates(m))<1e-10;
        success=sum([records(mask).success]);
        fprintf('%-18s missed=%.0f%% -> goal %d/%d\n', ...
            scenarioNames{s},100*missRates(m),success,sum(mask));
    end
end

if makePlots
    plot_robustness_study(study);
end
end
