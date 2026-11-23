function result = run_v3_scenario(name,makePlots)
%RUN_V3_SCENARIO Simulate V3 with reversible fault injections.
% Does NOT modify or save main or referenced .slx files. SimInput overrides
% the top-level World Map, Goal, feedback delay and Dynamics Memory IC.
if nargin<1 || isempty(name),name='baseline';end
if nargin<2,makePlots=false;end
root=fileparts(mfilename('fullpath'));
addpath(root);
setup_paths();
scenario=v3_scenario_settings(name);
filename=build_v3_simulink_model();
[~,model]=fileparts(filename);

simIn=Simulink.SimulationInput(model);
simIn=simIn.setBlockParameter([model '/World Map'], ...
    'Value',mat2str(scenario.world,16));
simIn=simIn.setBlockParameter([model '/Mission Goal'], ...
    'Value',mat2str(scenario.goal,16));
initialValue=mat2str(scenario.initialState,16);
simIn=simIn.setBlockParameter([model '/Feedback Delay'], ...
    'InitialCondition',initialValue);
simIn=simIn.setBlockParameter('UAV3_Dynamics/Dynamics Memory', ...
    'InitialCondition',initialValue);
simIn=simIn.setModelParameter('StopTime','90');
out=sim(simIn);

stateTs=get(out,'uav3_state');
planTs=get(out,'uav3_plan');
telemTs=get(out,'uav3_telemetry');
missionTs=get(out,'uav3_mission');
result.name=scenario.name;
result.scenario=scenario;
result.time=stateTs.Time(:);
result.state=v3_scenario_rows(stateTs,5);
result.plan=v3_scenario_rows(planTs,3);
result.telemetry=v3_scenario_rows(telemTs,9);
result.missionCodes=double(missionTs.Data(:));
result.terminalCode=result.missionCodes(end);
result.expectedCode=scenario.expectedCode;
result.duration=result.time(end);
result.goalDistance=norm(result.state(end,1:2)-scenario.goal(:).');
result.replans=sum(result.plan(:,1)>0.5);
result.knownCount=result.plan(end,2);
result.minimumSweptClearance=v3_swept_clearance( ...
    result.state(:,1:2),scenario.world);
result.gpsDropoutSamples=sum(result.telemetry(:,9)<0.5);
result.safeToClaimCollisionFree=isfinite(result.minimumSweptClearance) ...
    && result.minimumSweptClearance>0;
result.expectedStatusMatched=result.terminalCode==scenario.expectedCode;
result.accepted=result.expectedStatusMatched;
if scenario.requiresClearance
    result.accepted=result.accepted && ...
        result.safeToClaimCollisionFree && result.duration<90 && ...
        result.replans>=scenario.expectedReplans && ...
        result.knownCount>=scenario.expectedKnown;
end
if strcmp(scenario.name,'critical_battery') || ...
        strcmp(scenario.name,'collision_at_start') || ...
        strcmp(scenario.name,'invalid_state') || ...
        strcmp(scenario.name,'goal_at_start')
    result.accepted=result.accepted && result.duration<=0.2;
end
fprintf('V3 %-19s expected=%d observed=%d replans=%d ', ...
    result.name,result.expectedCode,result.terminalCode,result.replans);
fprintf('clearance=%7.3f m time=%6.2f s  %s\n', ...
    result.minimumSweptClearance,result.duration, ...
    v3_pass_label(result.accepted));
if makePlots
    figure('Name',['V3 Integration Challenge — ' result.name], ...
        'NumberTitle','off');
    hold on;axis equal;grid on;
    th=linspace(0,2*pi,180);
    for k=1:2
        if scenario.world(3,k)>0
            c=scenario.world(1:2,k);radius=scenario.world(3,k);
            plot(c(1)+radius*cos(th),c(2)+radius*sin(th), ...
                'r--','HandleVisibility','off');
        end
    end
    plot(result.state(:,1),result.state(:,2),'LineWidth',2, ...
        'DisplayName','V3 actual state');
    changes=find(result.plan(:,1)>0.5);
    if ~isempty(changes)
        plot(result.state(changes,1),result.state(changes,2),'o', ...
            'DisplayName','Online replans');
    end
    plot(scenario.goal(1),scenario.goal(2),'kp','MarkerSize',11, ...
        'DisplayName','Goal');
    title(sprintf('V3 %s | code %d | %d replans | clearance %.2f m', ...
        result.name,result.terminalCode,result.replans, ...
        result.minimumSweptClearance));
    xlabel('X (m)'); ylabel('Y (m)');legend('Location','best');
end
end

function rows = v3_scenario_rows(signal,n)
raw=squeeze(signal.Data);
if size(raw,2)==n
    rows=raw;
elseif size(raw,1)==n
    rows=raw.';
else
    error('UAV3:InvalidLog','Expected signal with %d columns.',n);
end
end

function str=v3_pass_label(ok)
if ok,str='PASS';else,str='FAIL';end
end
