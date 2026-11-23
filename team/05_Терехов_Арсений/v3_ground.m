function telemetry = v3_ground(nav,energy,nearest,safetyCode,planStatus,gpsValid)
%V3_GROUND Fixed-size 9-value ground-station status frame.
% [x;y;speed;battery;nearestDistance;safetyCode;newReplan;
%  knownObstacleCount;gpsAvailable].
%#codegen
telemetry=zeros(9,1);
telemetry(1:2)=nav(1:2);
telemetry(3)=sqrt(sum(nav(3:4).^2));
telemetry(4)=energy(2);
telemetry(5)=nearest(1);
telemetry(6)=safetyCode;
telemetry(7)=planStatus(1);
telemetry(8)=planStatus(2);
telemetry(9)=gpsValid;
end
