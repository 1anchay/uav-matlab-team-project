function packet = subsystem_ground_station(nav, trueState, control, waypointIndex, detections, cfg)
%SUBSYSTEM_GROUND_STATION Участник 5 — связь, мониторинг и наземное управление.
% Формирует пакет телеметрии и имитирует потерю части пакетов связи.

packet.linkOK = rand >= cfg.comms.packetLossProbability;
packet.timeStamp = NaN; % время присваивается в основном цикле
packet.position = nav.position;
packet.altitude = nav.altitude;
packet.speed = nav.speed;
packet.course = nav.course;
packet.battery = trueState.battery;
packet.waypointIndex = waypointIndex;
packet.detectedObjects = numel(detections);
packet.commandedAcceleration = control.acceleration;
end
