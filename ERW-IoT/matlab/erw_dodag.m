function [parents, ranks] = erw_dodag(positions, root, range_m, fading)
%ERW_DODAG Select a preferred parent and route cost for every non-root node.
n = size(positions, 1);
parents = zeros(n, 1);
ranks = zeros(n, 1);
for node = 1:n
    if node == root, continue; end
    path = erw_shortest_path(positions, node, root, range_m, fading);
    parents(node) = path(2);
    for edge = 1:numel(path)-1
        ranks(node) = ranks(node) + 1 + fading(path(edge), path(edge+1));
    end
end
end
