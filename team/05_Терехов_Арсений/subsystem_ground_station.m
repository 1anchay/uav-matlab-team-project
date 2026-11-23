function packet = subsystem_ground_station(nav, trueState, control, waypointIndex, detections, cfg, varargin)
%SUBSYSTEM_GROUND_STATION Телеметрия и имитация потерь пакетов (модуль 05).
% Необязательные аргументы: safety, energy. Старый контракт сохранён.

packet.linkOK = rand >= cfg.comms.packetLossProbability;
packet.timeStamp = NaN; % проставляет интегратор
packet.position = nav.position;
packet.altitude = nav.altitude;
packet.speed = nav.speed;
packet.course = nav.course;
packet.battery = trueState.battery;
packet.waypointIndex = waypointIndex;
packet.detectedObjects = numel(detections);
packet.commandedAcceleration = control.acceleration;
packet.navValid = nav.positionValid && nav.headingValid;

packet.safetyStatus = 'NOT_AVAILABLE';
packet.batteryWarning = false;
packet.criticalBattery = false;
packet.estimatedRemainingTime = NaN;
packet.safetyIntervention = false;

if numel(varargin) >= 1 && ~isempty(varargin{1})
    safety = varargin{1};
    packet.safetyStatus = safety.status;
    packet.safetyIntervention = safety.intervened;
end
if numel(varargin) >= 2 && ~isempty(varargin{2})
    energy = varargin{2};
    packet.batteryWarning = energy.lowBattery;
    packet.criticalBattery = energy.criticalBattery;
    packet.estimatedRemainingTime = energy.estimatedRemainingSeconds;
end
end
