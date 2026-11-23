function outputDir = export_v3_acceptance_report(campaign)
%EXPORT_V3_ACCEPTANCE_REPORT Export actual runs (including errors/FAIL).
% Does NOT update verification status or certify a UAV.
root=fileparts(mfilename('fullpath'));
outputDir=fullfile(root,'results','v3','extended');
if ~exist(outputDir,'dir'),mkdir(outputDir);end
rows=struct2table(campaign.rows);
writetable(rows,fullfile(outputDir,'acceptance.csv'));
f=fopen(fullfile(outputDir,'RESULTS.md'),'w');
assert(f>0,'UAV3:ReportWrite','Cannot create V3 validation report.');
cleanup=onCleanup(@()fclose(f)); %#ok<NASGU>
fprintf(f,'# Extended V3 Simulink acceptance (actual measured runs)\n\n');
fprintf(f,'**Status: %d/%d PASS.** Failures are kept in the results.\n\n', ...
    campaign.passed,campaign.total);
fprintf(f,'| Scenario | Expected code | Observed code | Replans | Clearance (m) | Verdict |\n');
fprintf(f,'|---|---:|---:|---:|---:|---|\n');
for k=1:campaign.total
    row=campaign.rows(k);
    verdict='FAIL';
    if row.accepted,verdict='PASS';end
    fprintf(f,'| %s | %g | %g | %g | %.3f | %s |\n', ...
        row.name,row.expected,row.observed, ...
        row.replans,row.clearance,verdict);
    if ~isempty(row.error)
        fprintf(f,'\n- %s — diagnostic: %s\n',row.name,row.error);
    end
end
fprintf(f,'\nThe experiment uses a simplified two-circle fixed-size ');
fprintf(f,'2D world. No hardware safety certification is implied.\n');
fprintf('Extended V3 evidence exported: %s\n',outputDir);
end
