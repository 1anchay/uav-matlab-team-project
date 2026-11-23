function nav = v3_navigation(state,gpsValid)
%V3_NAVIGATION Codegen-compatible XY observer with simulated GPS outage.
% state [x;y;vx;vy;battery]; GPS valid = scalar 0/1.
% This is an educational estimator, NOT real GPS/IMU sensor fusion.
%#codegen
persistent lastEstimate
if isempty(lastEstimate)
    lastEstimate = zeros(4,1);
end
if gpsValid >= 0.5 && all(isfinite(state(1:4)))
    nav = 0.9*state(1:4) + 0.1*lastEstimate;
else
    nav = [lastEstimate(1:2)+0.1*lastEstimate(3:4); ...
        lastEstimate(3:4)];
end
lastEstimate = nav;
end
