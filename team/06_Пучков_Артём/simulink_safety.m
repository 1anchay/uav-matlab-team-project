function [safeCommand, safetyFlag] = simulink_safety(command, detection, nav, energy)
%SIMULINK_SAFETY 06: реакция на близость и прогноз столкновения в 2D.
% Это локальная эвристика: не доказывает безопасность маршрута или БПЛА.
%#codegen
safeCommand = command;
safetyFlag = 0;
if any(~isfinite(nav)) || any(~isfinite(command))
    safeCommand = [0;0];
    safetyFlag = 3;
    return;
end
if energy(2) <= 5.0
    safeCommand = -1.6*nav(3:4);
    safetyFlag = 2;
else
    rel = detection(2:3);
    radius = detection(4);
    d = detection(1);
    speedSquared = sum(nav(3:4).^2);
    tClosest = 0;
    if speedSquared > 1e-9
        tClosest = max(0, min(1.5, dot(rel,nav(3:4))/speedSquared));
    end
    futureDistance = sqrt(sum((rel-tClosest*nav(3:4)).^2)) - radius;
    if d <= 3.0 || (tClosest > 0 && futureDistance <= 2.5)
        away = -rel - 0.5*nav(3:4);
        m = sqrt(sum(away.^2));
        if m > 1e-9
            safeCommand = 3.0*away/m;
        else
            safeCommand = -nav(3:4);
        end
        safetyFlag = 1;
    end
end
a = sqrt(sum(safeCommand.^2));
if a > 3.0
    safeCommand = 3.0*safeCommand/a;
end
end
