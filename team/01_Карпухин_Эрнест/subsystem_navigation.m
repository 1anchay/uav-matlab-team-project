function nav = subsystem_navigation(trueState, cfg, previousNav)
%SUBSYSTEM_NAVIGATION Оценка координат, скорости и курса (модуль 01).
% Датчики синтетические. Опциональный previousNav позволяет сглаживать шум.
% Вход: истинное состояние модели, cfg, оценка с предыдущего шага.
% Выход: nav с полями position, velocity, speed, course, yaw, validity.

if nargin < 3
    previousNav = [];
end
p = trueState.position;
v = trueState.velocity;

rawPosition = p + [randn * cfg.sensor.positionNoiseStd, ...
    randn * cfg.sensor.positionNoiseStd, randn * cfg.sensor.altitudeNoiseStd];
rawVelocity = v + randn(1,3) * cfg.sensor.velocityNoiseStd;
positionValid = numel(p) == 3 && all(isfinite(rawPosition));
velocityValid = numel(v) == 3 && all(isfinite(rawVelocity));
validPrevious = ~isempty(previousNav) && isfield(previousNav, 'positionValid') && ...
    previousNav.positionValid && all(isfinite(previousNav.position)) && ...
    all(isfinite(previousNav.velocity));

nav.rawPosition = rawPosition;
nav.rawVelocity = rawVelocity;
if positionValid && velocityValid
    nav.position = rawPosition;
    nav.velocity = rawVelocity;
    if validPrevious
        alphaP = cfg.sensor.positionFilterGain;
        alphaV = cfg.sensor.velocityFilterGain;
        predictedPosition = previousNav.position + previousNav.velocity * cfg.dt;
        nav.position = alphaP * rawPosition + (1 - alphaP) * predictedPosition;
        nav.velocity = alphaV * rawVelocity + (1 - alphaV) * previousNav.velocity;
    end
elseif validPrevious
    % При некорректном измерении возвращаем последнюю оценку и флаг отказа.
    nav.position = previousNav.position;
    nav.velocity = previousNav.velocity;
else
    nav.position = [0 0 0];
    nav.velocity = [0 0 0];
end

nav.speed = norm(nav.velocity);
nav.altitude = nav.position(3);
if norm(nav.velocity(1:2)) > 0.15
    baseCourse = atan2(nav.velocity(2), nav.velocity(1));
else
    baseCourse = trueState.yaw;
end
if ~isfinite(baseCourse)
    baseCourse = 0;
end
nav.course = wrap_angle(baseCourse + randn * cfg.sensor.courseNoiseStd);
nav.yaw = trueState.yaw; % курс корпуса, отдельно от направления скорости
nav.positionValid = positionValid && velocityValid;
nav.headingValid = isfinite(trueState.yaw) && isfinite(nav.course);
nav.quality = double(nav.positionValid && nav.headingValid);
end
