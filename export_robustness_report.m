function dirOut=export_robustness_report(study)
%EXPORT_ROBUSTNESS_REPORT CSV and Markdown with measured (not invented) rates.
root=fileparts(mfilename('fullpath'));
dirOut=fullfile(root,'results','robustness');
if ~exist(dirOut,'dir'),mkdir(dirOut);end
rows=struct2table(study.records);
writetable(rows,fullfile(dirOut,'runs.csv'));

f=fopen(fullfile(dirOut,'report.md'),'w');
assert(f>0,'UAV:StudyReportWrite','Cannot create robustness report.');
cleanup=onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'# V2 Robustness Report\n\n');
fprintf(f,'This is an observational simulated study, not a safety guarantee.\n\n');
fprintf(f,'Total runs: **%d**; goal arrivals: **%d** (%.1f%%).\n\n', ...
    study.total,study.successCount,study.successRate);
fprintf(f,'Observed collision outcomes: **%d**.\n\n', ...
    sum(strcmp({study.records.status},'COLLISION')));
fprintf(f,'## Scenarios and outcomes\n\n');
fprintf(f,'| Scenario | Sensor miss rate | Goal reached | Runs |\n');
fprintf(f,'|---|---:|---:|---:|\n');
for s=1:numel(study.scenarios)
    for m=1:numel(study.missRates)
        mask=strcmp({study.records.scenario},study.scenarios{s}) & ...
            abs([study.records.missRate]-study.missRates(m))<1e-10;
        fprintf(f,'| %s | %.0f%% | %d | %d |\n', ...
            study.scenarios{s},100*study.missRates(m), ...
            sum([study.records(mask).success]),sum(mask));
    end
end
fprintf(f,'\nSimulated world: fixed circular XY obstacles; noise and sensor ');
fprintf(f,'dropouts are synthetic. Do not extrapolate to physical UAVs.\n');
fprintf('Report and CSV created: %s\n',dirOut);
end
