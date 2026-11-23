function [safeCommand,safetyCode] = v3_safety(command,nav,nearest,energy)
%V3_SAFETY Reactive brake/steer for threat or critical battery.
% Safety is a guard, not a mathematical safety guarantee.
% code 0=normal,1=avoid,2=low battery,3=invalid estimate.
%#codegen
safeCommand=command;
safetyCode=0.0;
if any(~isfinite(nav)) || any(~isfinite(command))
    safeCommand=zeros(2,1);
    safetyCode=3.0;
    return;
end
if energy(2)<=5.0
    safeCommand=-1.5*nav(3:4);
    safetyCode=2.0;
else
    r=nearest(2:3);
    d=nearest(1);
    speed2=dot(nav(3:4),nav(3:4));
    approach=0.0;
    if speed2>1e-9
        approach=max(0.0,min(2.0,dot(r,nav(3:4))/speed2));
    end
    prediction=sqrt(sum((r-approach*nav(3:4)).^2))-nearest(4);
    if d<4.0 || (approach>0.0 && prediction<4.0)
        away=-r-0.6*nav(3:4);
        m=sqrt(sum(away.^2));
        if m>1e-9
            safeCommand=3.0*away/m;
        else
            safeCommand=-1.5*nav(3:4);
        end
        safetyCode=1.0;
    end
end
a=sqrt(sum(safeCommand.^2));
if a>3.0
    safeCommand=3.0*safeCommand/a;
end
end
