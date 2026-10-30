function packet = subsystem_ground_station(nav, trueState, control, waypointIndex, detections, cfg, varargin)
%SUBSYSTEM_GROUND_STATION Участник 5 — Арсений Терехов.
% Телеметрия и канал связи. Доп. параметры safety/energy необязательны.

packet.linkOK = rand >= cfg.comms.packetLossProbability;
packet.timeStamp = NaN;
packet.position = nav.position;
packet.altitude = nav.altitude;
packet.speed = nav.speed;
packet.course = nav.course;
packet.battery = trueState.battery;
packet.waypointIndex = waypointIndex;
packet.detectedObjects = numel(detections);
packet.commandedAcceleration = control.acceleration;

packet.safetyStatus = 'NOT_AVAILABLE';
packet.batteryWarning = false;
packet.estimatedRemainingTime = NaN;

if numel(varargin) >= 1 && ~isempty(varargin{1})
    safety = varargin{1};
    packet.safetyStatus = safety.status;
end
if numel(varargin) >= 2 && ~isempty(varargin{2})
    energy = varargin{2};
    packet.batteryWarning = energy.lowBattery;
    packet.estimatedRemainingTime = energy.estimatedRemainingSeconds;
end
end
