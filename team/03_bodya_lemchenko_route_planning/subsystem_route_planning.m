function route = subsystem_route_planning(startPos, goalPos, obstacles, cfg)
%SUBSYSTEM_ROUTE_PLANNING Участник 3 — построение маршрута.
% Формирует контрольные точки из A в B и добавляет обходные точки,
% если прямой участок пересекает безопасную область вокруг препятствия.

route = [startPos; goalPos];
clearance = cfg.route.clearance;

for pass = 1:cfg.route.maxPasses
    changed = false;

    for s = 1:size(route,1)-1
        p1 = route(s,:);
        p2 = route(s+1,:);

        hitIdx = 0;
        for k = 1:numel(obstacles)
            d = segment_circle_clearance(p1(1:2), p2(1:2), obstacles(k).center);
            if d < obstacles(k).radius + clearance
                hitIdx = k;
                break;
            end
        end

        if hitIdx == 0
            continue;
        end

        obs = obstacles(hitIdx);
        dir = p2(1:2) - p1(1:2);
        L = norm(dir);
        if L < 1e-9
            continue;
        end
        u = dir / L;
        n = [-u(2) u(1)];
        R = obs.radius + clearance + cfg.route.detourExtra;

        % Две альтернативы обхода: слева и справа от исходного направления.
        candidates = cell(1,2);
        for side = 1:2
            signSide = 1;
            if side == 2, signSide = -1; end
            offset = signSide * n * R;
            beforeXY = obs.center - u * R + offset;
            afterXY  = obs.center + u * R + offset;
            z = mean([p1(3), p2(3)]);
            candidates{side} = [beforeXY z; afterXY z];
        end

        best = [];
        bestCost = inf;
        for side = 1:2
            c = candidates{side};
            pts = [p1; c; p2];
            ok = true;
            cost = 0;
            for q = 1:size(pts,1)-1
                % На этапе выбора допускаем проверку против всех препятствий.
                if ~segment_is_safe(pts(q,:), pts(q+1,:), obstacles, clearance)
                    % Точки вокруг текущего препятствия могут касаться его
                    % безопасной зоны. Проверим отдельно с небольшим допуском.
                    dCurrent = segment_circle_clearance(pts(q,1:2), pts(q+1,1:2), obs.center);
                    if dCurrent < obs.radius + clearance - 1e-6
                        ok = false;
                        break;
                    end
                end
                cost = cost + norm(pts(q+1,1:2) - pts(q,1:2));
            end
            if ok && cost < bestCost
                best = c;
                bestCost = cost;
            end
        end

        % Если обе строгие альтернативы не прошли, берем геометрически
        % более короткий вариант; следующая итерация при необходимости
        % добавит еще одну обходную точку.
        if isempty(best)
            c1 = candidates{1}; c2 = candidates{2};
            cost1 = norm(c1(1,1:2)-p1(1:2)) + norm(c1(2,1:2)-c1(1,1:2)) + norm(p2(1:2)-c1(2,1:2));
            cost2 = norm(c2(1,1:2)-p1(1:2)) + norm(c2(2,1:2)-c2(1,1:2)) + norm(p2(1:2)-c2(2,1:2));
            if cost1 <= cost2, best = c1; else, best = c2; end
        end

        route = [route(1:s,:); best; route(s+1:end,:)]; %#ok<AGROW>
        changed = true;
        break;
    end

    if ~changed
        break;
    end
end

% Удаляем лишние точки, если между соседями можно пройти напрямую.
i = 2;
while i < size(route,1)
    if segment_is_safe(route(i-1,:), route(i+1,:), obstacles, clearance)
        route(i,:) = [];
    else
        i = i + 1;
    end
end

% Финальная защита от чрезмерного числа точек при неудачной геометрии.
if size(route,1) > 60
    warning('Planner produced many waypoints. Check obstacle geometry.');
end
end
