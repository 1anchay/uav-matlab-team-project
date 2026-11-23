function valid = v3_gps_schedule(timeSeconds)
%V3_GPS_SCHEDULE Synthetic GPS loss between 8 and 10 seconds.
% This is a simulation stimulus, not a physical satellite receiver.
%#codegen
valid=double(timeSeconds<8.0 || timeSeconds>=10.0);
end
