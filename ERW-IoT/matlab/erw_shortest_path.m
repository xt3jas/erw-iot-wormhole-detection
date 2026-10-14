function path = erw_shortest_path(positions, source, root, range_m, weights)
%ERW_SHORTEST_PATH Find a route using only physically reachable links.
n = size(positions, 1);
if nargin < 5, weights = zeros(n); end
distance = hypot(positions(:,1) - positions(:,1)', positions(:,2) - positions(:,2)');
adjacent = distance <= range_m & distance > 0;
cost = inf(1, n);
previous = zeros(1, n);
visited = false(1, n);
cost(source) = 0;
for step = 1:n
    remaining = cost;
    remaining(visited) = inf;
    [best, u] = min(remaining);
    if isinf(best) || u == root, break; end
    visited(u) = true;
    for v = find(adjacent(u,:))
        candidate = cost(u) + 1 + weights(u,v);
        if candidate < cost(v)
            cost(v) = candidate;
            previous(v) = u;
        end
    end
end
if isinf(cost(root))
    error("ERW:Disconnected", "The simulated source has no route to the root.");
end
path = root;
while path(1) ~= source
    path = [previous(path(1)), path]; %#ok<AGROW>
end
end
