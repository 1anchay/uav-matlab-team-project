function y = limit_norm(x, maxNorm)
%LIMIT_NORM Ограничение нормы вектора без изменения направления.
n = norm(x);
if n > maxNorm && n > 0
    y = x * (maxNorm / n);
else
    y = x;
end
end
