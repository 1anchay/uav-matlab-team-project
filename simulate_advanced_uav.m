function result = simulate_advanced_uav(scenario,cfg)
%SIMULATE_ADVANCED_UAV Seven-module online discovery/replanning MATLAB twin.
% This is an independent, synthetic XYZ/XY hybrid. Physics is educational.
% No code, SLX or interface of the validated original model is overwritten.
setup_paths();
if nargin < 2 || isempty(cfg)
    cfg = advanced_config();
end
if nargin < 1 || isempty(scenario)
    [scenario,cfg] = advanced_scenario('unexpected',cfg);
end
assert(isfield(scenario,'knownMask') && ...
    numel(scenario.knownMask)==numel(scenario.obstacles), ...
    'UAV:Advanced:BadScenario','Known obstacle mask is missing/invalid.');

rng(cfg.advanced.seed);
dt = cfg.dt;
steps = floor(cfg.advanced.missionMaxTime/dt)+1;
time = (0:steps-1)'*dt;
position = nan(steps,3);
velocity = nan(steps,3);
battery = nan(steps,1);
navError = nan(steps,1);
gpsOKLog = false(steps,1);
navValidLog = false(steps,1);
safetyLog = false(steps,1);
linkDeliveredLog = false(steps,1);
obstacleDistance = inf(steps,1);
replanLog = false(steps,1);
knownCountLog = zeros(steps,1);
targetLog = nan(steps,3);
statusLog = cell(steps,1);

state = scenario.initialState;
state.position = reshape(state.position,1,3);
state.velocity = reshape(state.velocity,1,3);
known = logical(scenario.knownMask);
previous = [];
channel = [];
replans = 0;
detectionsMade = 0;
routeEvents = struct('time',{},'route',{},'newCount',{});
lastSafety = 'OK';
status = 'TIME_LIMIT';
nSteps = steps;

initial = advanced_replan_route(state.position,scenario.goal, ...
    scenario.obstacles(known),cfg);
if ~initial.ok
    error('UAV:Advanced:InitialPlanFailed','%s',initial.reason);
end
route = initial.route;
routeEvents(1) = struct('time',0,'route',route,'newCount',0);
waypointIndex = min(2,size(route,1));

% A separate telemetry config prevents the legacy station from applying
% packet loss twice; the new radio module owns all packet loss/delay.
telemetryCfg = cfg;
telemetryCfg.comms.packetLossProbability = 0;

for step = 1:steps
    t = time(step);
    gpsOK = step < cfg.advanced.gpsOutageFirst || ...
        step > cfg.advanced.gpsOutageLast;
    nav = advanced_navigation(state,previous,gpsOK,cfg);
    previous = nav;

    % 04 -> 03: new detections alter the PLANNED route during flight.
    scan = advanced_sensor_scan(nav,scenario.obstacles,known,cfg);
    added = find(scan.newlyDetected);
    if ~isempty(added)
        known = scan.known;
        detectionsMade = detectionsMade+numel(added);
        if replans >= cfg.advanced.maxReplans
            status = 'REPLAN_LIMIT';
        else
            proposal = advanced_replan_route(nav.position, ...
                scenario.goal,scenario.obstacles(known),cfg);
            if ~proposal.ok
                status = 'PLAN_FAILED';
            else
                route = proposal.route;
                waypointIndex = min(2,size(route,1));
                replans = replans+1;
                routeEvents(end+1) = struct('time',t, ...
                    'route',route,'newCount',numel(added)); %#ok<AGROW>
                replanLog(step) = true;
            end
        end
    end

    while waypointIndex < size(route,1) && ...
            norm(nav.position-route(waypointIndex,:)) <= cfg.waypointTolerance
        waypointIndex = waypointIndex+1;
    end
    target = route(waypointIndex,:);
    cmd = advanced_tracking_control(nav,target,cfg);
    visibleObs = scenario.obstacles(scan.visible);
    energy = advanced_energy_monitor(state,cmd, ...
        norm(state.position-scenario.goal),cfg);
    [safe,safety] = advanced_safety_supervisor(nav,visibleObs,cmd,energy,cfg);
    energy = advanced_energy_monitor(state,safe, ...
        norm(state.position-scenario.goal),cfg);

    % 05: explicit delayed packets and deterministic reproducibility.
    detections = subsystem_object_detection(nav,visibleObs,cfg);
    packet = subsystem_ground_station(nav,state,safe,waypointIndex, ...
        detections,telemetryCfg,safety,energy);
    packet.timeStamp = t;
    [channel,delivered] = advanced_comms_step(channel,packet,step,cfg);

    position(step,:) = state.position;
    velocity(step,:) = state.velocity;
    battery(step) = state.battery;
    navError(step) = norm(nav.position-state.position);
    gpsOKLog(step) = nav.gpsAvailable;
    navValidLog(step) = nav.positionValid;
    safetyLog(step) = safety.intervened;
    linkDeliveredLog(step) = ~isempty(delivered);
    targetLog(step,:) = target;
    knownCountLog(step) = sum(known);
    statusLog{step} = safety.status;

    % Real geometry: not only the estimated obstacle distance.
    for k = 1:numel(scenario.obstacles)
        d = norm(state.position(1:2)-scenario.obstacles(k).center)- ...
            scenario.obstacles(k).radius;
        obstacleDistance(step) = min(obstacleDistance(step),d);
    end

    if ~strcmp(status,'TIME_LIMIT')
        nSteps = step;
        break;
    end
    if obstacleDistance(step) <= 0
        status = 'COLLISION';
        nSteps = step;
        break;
    end
    if state.battery <= cfg.safety.criticalBatteryPercent
        status = 'LOW_BATTERY';
        nSteps = step;
        break;
    end
    if norm(state.position-scenario.goal)<=cfg.advanced.goalRadius && ...
            norm(state.velocity)<=cfg.advanced.goalSpeed
        status = 'GOAL_REACHED';
        nSteps = step;
        break;
    end
    if t>=cfg.advanced.missionMaxTime
        status = 'TIME_LIMIT';
        nSteps = step;
        break;
    end

    % Shared dynamics. Segment geometry detects tunnelling through circles.
    newVelocity = limit_norm(state.velocity+safe.acceleration*dt, ...
        cfg.advanced.cruiseSpeed);
    newPosition = state.position+newVelocity*dt;
    newPosition(3) = max(cfg.minAltitude,min(cfg.maxAltitude,newPosition(3)));
    for k=1:numel(scenario.obstacles)
        obs = scenario.obstacles(k);
        % Segment clearance (not only sampled endpoints) catches tunnelling.
        segmentClearance = segment_circle_clearance( ...
            state.position(1:2),newPosition(1:2),obs.center)-obs.radius;
        obstacleDistance(step) = min(obstacleDistance(step),segmentClearance);
        if segmentClearance <= 0
            status = 'COLLISION';
        end
    end
    state.position = newPosition;
    state.velocity = newVelocity;
    state.yaw = wrap_angle(state.yaw+safe.yawRate*dt);
    state.battery = energy.nextBattery;
    if strcmp(status,'COLLISION')
        nSteps = step;
        break;
    end
end

ii = 1:nSteps;
result.scenario = scenario.name;
result.status = status;
result.time = time(ii);
result.position = position(ii,:);
result.velocity = velocity(ii,:);
result.battery = battery(ii);
result.navError = navError(ii);
result.gpsAvailable = gpsOKLog(ii);
result.navValid = navValidLog(ii);
result.safetyIntervention = safetyLog(ii);
result.linkDelivered = linkDeliveredLog(ii);
result.minObstacleDistance = obstacleDistance(ii);
result.replanEvents = replanLog(ii);
result.knownObstacles = knownCountLog(ii);
result.target = targetLog(ii,:);
result.safetyStatus = statusLog(ii);
result.routeEvents = routeEvents;
result.activeRoute = route;
result.replanCount = replans;
result.discoveredObstacles = detectionsMade;
result.packetsSent = channel.sent;
result.packetsDelivered = channel.deliveredCount;
result.packetsLost = channel.lost;
result.packetDeliveryRate = 100*channel.deliveredCount/max(1,channel.sent);
result.meanPacketLatencySteps = NaN;
if ~isempty(channel.delaySamples)
    result.meanPacketLatencySteps = mean(channel.delaySamples);
end
result.finalBattery = state.battery;
result.finalPosition = state.position;
result.goalDistance = norm(state.position-scenario.goal);
result.duration = time(nSteps);
result.navRMSE = sqrt(mean(navError(ii).^2));
result.minimumClearance = min(obstacleDistance(ii));
result.totalSafetyActions = sum(safetyLog(ii));
result.success = strcmp(status,'GOAL_REACHED');
end
