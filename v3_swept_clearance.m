function clearance = v3_swept_clearance(positions,world)
%V3_SWEPT_CLEARANCE Minimum swept center-to-circle boundary distance.
% Checks discrete trajectory segments to detect crossing between samples.
% NaN/Inf positions cannot be verified and return NaN, never +Inf/pass.
assert(size(positions,2)==2 && isequal(size(world),[3 2]), ...
    'UAV3:ClearanceShape','Expected positions Nx2 and world 3x2.');
if isempty(positions) || any(~isfinite(positions(:)))
    clearance=NaN;
    return;
end
clearance=inf;
for k=1:size(world,2)
    c=world(1:2,k).';
    radius=world(3,k);
    if radius<=0,continue;end
    for j=1:size(positions,1)
        d=norm(positions(j,:)-c)-radius;
        clearance=min(clearance,d);
        if j<size(positions,1)
            a=positions(j,:);
            seg=positions(j+1,:)-a;
            denom=dot(seg,seg);
            if denom>1e-12
                u=max(0,min(1,dot(c-a,seg)/denom));
                d=norm(a+u*seg-c)-radius;
                clearance=min(clearance,d);
            end
        end
    end
end
end
