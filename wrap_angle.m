function a = wrap_angle(a)
%WRAP_ANGLE Нормализация угла в диапазон [-pi, pi].
a = mod(a + pi, 2*pi) - pi;
end
