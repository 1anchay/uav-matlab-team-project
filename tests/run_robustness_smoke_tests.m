%% Fast regression of robustness-study shape and seed discipline.
% This does not assert zero failures under high miss probability.
clear;clc;
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root);
setup_paths();
study=run_robustness_study(2,false,{'unexpected'},[0 0.2]);
assert(study.total==4 && numel(study.records)==4, ...
    'Robustness study did not create 4 independent runs.');
assert(all(isfinite([study.records.cpuSeconds])), ...
    'Measured runtime must be finite.');
assert(all(isfinite([study.records.seed])) && ...
    numel(unique([study.records.seed]))==2, ...
    'Seed repetitions across miss rates are intentional and controlled.');
assert(all(strcmp({study.records.scenario},'unexpected')), ...
    'Scenario tracking failed.');
for k=1:numel(study.records)
    if study.records(k).success
        assert(study.records(k).minClearance>0, ...
            'Successful trajectory must not intersect an obstacle.');
    end
end
fprintf('V2 robustness smoke tests: 4/4 measured runs PASS\n');
