function nav = subsystem_navigation(trueState, cfg)
%SUBSYSTEM_NAVIGATION Участник 1 — навигация и ориентирование.
% Имитирует объединенный результат GPS/ГЛОНАСС + IMU + компас.
% Вход: истинное состояние модели БПЛА.
% Выход: оцененные координаты, высота, курс, скорость.

p = trueState.position;
v = trueState.velocity;

nav.position = p + [ ...
    randn * cfg.sensor.positionNoiseStd, ...
    randn * cfg.sensor.positionNoiseStd, ...
    randn * cfg.sensor.altitudeNoiseStd];

nav.velocity = v + randn(1,3) * cfg.sensor.velocityNoiseStd;
nav.speed = norm(nav.velocity);
nav.altitude = nav.position(3);

if norm(nav.velocity(1:2)) > 0.15
    baseCourse = atan2(nav.velocity(2), nav.velocity(1));
else
    baseCourse = trueState.yaw;
end
nav.course = wrap_angle(baseCourse + randn * cfg.sensor.courseNoiseStd);

% Упрощенный показатель качества решения навигации.
nav.positionValid = all(isfinite(nav.position));
nav.headingValid = isfinite(nav.course);
end
