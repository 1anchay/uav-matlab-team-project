function plot_robustness_study(study)
%PLOT_ROBUSTNESS_STUDY Render actual measured results without extrapolation.
records=study.records;
groups=study.scenarios;
rates=study.missRates;
successPct=zeros(numel(groups),numel(rates));
distance=zeros(numel(groups),numel(rates));
replans=zeros(numel(groups),numel(rates));
for s=1:numel(groups)
    for k=1:numel(rates)
        mask=strcmp({records.scenario},groups{s}) & ...
            abs([records.missRate]-rates(k))<1e-10;
        slice=records(mask);
        successPct(s,k)=100*mean([slice.success]);
        good=[slice.success] & isfinite([slice.minClearance]);
        if any(good)
            distance(s,k)=min([slice(good).minClearance]);
        else
            distance(s,k)=NaN;
        end
        replans(s,k)=mean([slice.replans]);
    end
end

figure('Name','UAV V2 - robustness under missed obstacle detections', ...
    'NumberTitle','off','Position',[90 65 1180 680]);
tt=tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
title(tt,sprintf('V2 robustness | %d measured runs | %.1f%% goal arrivals', ...
    study.total,study.successRate));
nexttile;
bar(categorical(groups),successPct);grid on;ylim([0 105]);
ylabel('Reached goal (%)');title('Success rate by sensor miss probability');
legend(compose('Miss %.0f%%',100*rates),'Location','best');

nexttile;
bar(categorical(groups),distance);grid on;
ylabel('Closest boundary clearance (m)');
title('Minimum clearance among successful flights');
legend(compose('Miss %.0f%%',100*rates),'Location','best');

nexttile;
bar(categorical(groups),replans);grid on;
ylabel('Mean route updates');title('Planning load');
legend(compose('Miss %.0f%%',100*rates),'Location','best');

nexttile;
isCollision=strcmp({records.status},'COLLISION');
isFailed=~[records.success];
bar([sum(isCollision),sum(isFailed & ~isCollision),study.successCount]);
set(gca,'XTickLabel',{'Collision','Other failure','Goal reached'});
ylabel('Number of runs');grid on;
title('Observed outcomes — no probability guarantee');
end
