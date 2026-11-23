function result = run_v3_simulink_demo(makePlots)
%RUN_V3_SIMULINK_DEMO Generate and simulate isolated V3 Model References.
% Unlike Advanced MATLAB V2, route updates happen INSIDE Simulink.
% A fixed two-slot circular world and an idealized range sensor are used.
if nargin<1, makePlots=true;end
root=fileparts(mfilename('fullpath'));
addpath(root);
setup_paths();
filename=build_v3_simulink_model();
[~,main]=fileparts(filename);
out=sim(main);
stateTs=get(out,'uav3_state');
telemetryTs=get(out,'uav3_telemetry');
planTs=get(out,'uav3_plan');
missionTs=get(out,'uav3_mission');

result.model=main;
result.time=stateTs.Time(:);
result.state=v3_unpack(stateTs,5);
result.telemetry=v3_unpack(telemetryTs,9);
result.plan=v3_unpack(planTs,3);
result.missionCode=double(missionTs.Data(:));
result.terminalCode=result.missionCode(end);
result.duration=result.time(end);
result.finalPosition=result.state(end,1:2);
result.goalDistance=norm(result.finalPosition-[100 80]);
result.minimumBattery=min(result.state(:,5));
result.maximumSpeed=max(sqrt(sum(result.state(:,3:4).^2,2)));
result.replans=sum(result.plan(:,1)>0.5);
result.knownObstacleCount=result.plan(end,2);
result.minimumClearance=min( ...
    sqrt((result.state(:,1)-50).^2+(result.state(:,2)-40).^2)-7);
result.safetyActions=sum(result.telemetry(:,6)>0.5);
result.gpsOutageSamples=sum(result.telemetry(:,9)<0.5);
result.goalReached=result.terminalCode==1 && result.goalDistance<=3;

fprintf('=== UAV V3 | LIVE SIMULINK MODEL REFERENCES ===\n');
fprintf('Mission code: %d (1=goal,2=collision,3=low battery,4=invalid)\n', ...
    result.terminalCode);
fprintf('Time: %.2f s | goal distance: %.2f m\n', ...
    result.duration,result.goalDistance);
fprintf('Online replans: %d | known obstacles: %.0f\n', ...
    result.replans,result.knownObstacleCount);
fprintf('Safety samples: %d | GPS outage samples: %d\n', ...
    result.safetyActions,result.gpsOutageSamples);
fprintf('Max speed: %.2f m/s | min battery: %.2f %%\n', ...
    result.maximumSpeed,result.minimumBattery);
fprintf('Minimum circle-boundary clearance: %.2f m\n', ...
    result.minimumClearance);
if result.goalReached
    fprintf('V3 Simulink live-replanning mission: GOAL_REACHED\n');
else
    fprintf('V3 Simulink live-replanning mission: NOT_REACHED\n');
end

if makePlots
    figure('Name','UAV V3 — online replanning inside Simulink', ...
        'NumberTitle','off','Position',[65 65 1220 735]);
    tiledlayout(2,2,'Padding','compact','TileSpacing','compact');
    nexttile;hold on;grid on;axis equal;
    ang=linspace(0,2*pi,180);
    plot(50+7*cos(ang),40+7*sin(ang), ...
        '--','Color',[0.81 0.3 0.24],'HandleVisibility','off');
    plot(50+12*cos(ang),40+12*sin(ang), ...
        ':','Color',[0.89 0.5 0.3],'HandleVisibility','off');
    plot(result.state(:,1),result.state(:,2), ...
        'LineWidth',2,'DisplayName','Simulink flight');
    changes=find(result.plan(:,1)>0.5);
    if ~isempty(changes)
        plot(result.state(changes,1),result.state(changes,2), ...
            'o','MarkerSize',8,'LineWidth',1.7, ...
            'DisplayName','Online replan');
    end
    plot(100,80,'kp','MarkerSize',13, ...
        'MarkerFaceColor',[0.93 0.72 0.12],'HandleVisibility','off');
    xlabel('X (m)');ylabel('Y (m)');
    title(sprintf('07 modules | %d route changes',result.replans));
    legend('Location','best');

    nexttile;
    stairs(result.time,result.plan(:,2), ...
        'LineWidth',1.4);
    hold on;
    stairs(result.time,result.telemetry(:,9), ...
        '--','LineWidth',1.2);
    grid on;ylim([-0.15 2.2]);xlabel('Time (s)');
    title('Detection map and GPS loss');
    legend('Known obstacles','GPS available','Location','best');

    nexttile;
    plot(result.time,sqrt(sum(result.state(:,3:4).^2,2)), ...
        'LineWidth',1.5);
    hold on;yline(10,'--','Speed limit');
    grid on;xlabel('Time (s)');ylabel('Speed (m/s)');
    title('Flight control');

    nexttile;
    plot(result.time,result.state(:,5),'LineWidth',1.5);
    grid on;xlabel('Time (s)');ylabel('Battery (%)');
    title(sprintf('Energy | %.2f %% remaining', ...
        result.state(end,5)));
end
end

function x=v3_unpack(ts,n)
x=squeeze(ts.Data);
if size(x,2)==n
    return;
elseif size(x,1)==n
    x=x.';
else
    error('UAV3:BadLogShape', ...
        'Expected %d signal columns; got size [%s].',n, ...
        num2str(size(x)));
end
end
