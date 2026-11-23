function [target,planStatus] = v3_replanner(nav,observations,goal)
%V3_REPLANNER True online target replacement from newly observed circles.
% Observations: fixed [4x2] = [cx;cy;r;isVisible] per column.
% Keeps a fixed-size known map, picks a geometric detour when new threats
% intersect the direct path. This does not call the richer V2 MATLAB planner.
% planStatus [newEvent;knownCount;detourActive].
%#codegen
persistent known centers radii detour detourActive
if isempty(known)
    known = false(1,2);
    centers = zeros(2,2);
    radii = zeros(1,2);
    detour = zeros(2,1);
    detourActive = false;
end
newEvent = 0.0;
for k=1:2
    if observations(4,k)>0.5 && ~known(k)
        known(k)=true;
        centers(:,k)=observations(1:2,k);
        radii(k)=observations(3,k);
        newEvent=1.0;
    end
end

pos=nav(1:2);
if newEvent>0.5
    detourActive=false;
    direction=goal-pos;
    squared=dot(direction,direction);
    bestForward=2.0;
    selected=int32(0);
    if squared>1e-10
        for k=1:2
            if known(k)
                t=dot(centers(:,k)-pos,direction)/squared;
                tClip=max(0.0,min(1.0,t));
                nearest=pos+tClip*direction;
                clearance=sqrt(sum((centers(:,k)-nearest).^2));
                if t>0 && t<1 && clearance < radii(k)+7.0 && t<bestForward
                    selected=int32(k);
                    bestForward=t;
                end
            end
        end
    end
    if selected>0
        u=direction/sqrt(squared);
        perp=[-u(2);u(1)];
        bestCost=1.0e12;
        bestPoint=zeros(2,1);
        validCandidate=false;
        for side=-1:2:1
            candidate=centers(:,selected)+side*perp*(radii(selected)+15.0);
            feasible=true;
            cost=sqrt(sum((candidate-pos).^2))+ ...
                sqrt(sum((goal-candidate).^2));
            for j=1:2
                if known(j)
                    seg1=candidate-pos;
                    denom1=max(dot(seg1,seg1),1.0e-12);
                    s1=max(0.0,min(1.0, ...
                        dot(centers(:,j)-pos,seg1)/denom1));
                    d1=sqrt(sum((centers(:,j)-(pos+s1*seg1)).^2));
                    seg2=goal-candidate;
                    denom2=max(dot(seg2,seg2),1.0e-12);
                    s2=max(0.0,min(1.0, ...
                        dot(centers(:,j)-candidate,seg2)/denom2));
                    d2=sqrt(sum((centers(:,j)-(candidate+s2*seg2)).^2));
                    if d1<radii(j)+4.0 || d2<radii(j)+4.0
                        feasible=false;
                    end
                end
            end
            if feasible && cost<bestCost
                bestCost=cost;
                bestPoint=candidate;
                validCandidate=true;
            end
        end
        if validCandidate
            detour=bestPoint;
            detourActive=true;
        end
    end
end

if detourActive && sqrt(sum((pos-detour).^2))<=2.5
    detourActive=false;
end
target=goal;
if detourActive
    target=detour;
end
planStatus=[newEvent;double(sum(known));double(detourActive)];
end
