function [observations,nearest] = v3_detection(nav,world)
%V3_DETECTION Fixed-size two-obstacle virtual range sensor (35 m).
% world [3x2] = [x;y;radius]. No real optics or computer vision.
% observations [4x2], nearest [boundaryDistance;dx;dy;radius].
%#codegen
observations=zeros(4,2);
nearest=[1000;0;0;0];
for k=1:2
    delta=world(1:2,k)-nav(1:2);
    d=sqrt(sum(delta.^2))-world(3,k);
    if d<=35.0
        observations(:,k)=[world(:,k);1];
        if d<nearest(1)
            nearest=[d;delta(1);delta(2);world(3,k)];
        end
    end
end
end
