function [state, event, truth] = erw_next(state)
%ERW_NEXT Generate the next telemetry event; truth stays outside the event.
if ~isempty(state.pending)
    error("ERW:Pending", "Analyze the pending event before requesting another.");
end
state.tick = state.tick + 1;
t = state.tick;
state.positions = state.base_positions;
state.positions(:,1) = state.positions(:,1) + 1.5 * sin(t/4 + (1:12)'/3);
state.positions(:,2) = state.positions(:,2) + 1.5 * cos(t/5 + (1:12)'/4);
state.positions(state.root,:) = state.base_positions(state.root,:);
fading = max(0, 0.3 * randn(12));
[parents, ranks] = erw_dodag(state.positions, state.root, ...
    state.radio_range_m, fading);
path = state.source;
while path(end) ~= state.root
    path(end+1) = parents(path(end)); %#ok<AGROW>
end
truth = state.scenario ~= "benign" && mod(t - 1, 20) >= 8 && ...
    mod(t - 1, 20) <= 13;
if truth
    % Node 12 is tunneled to distant node 2, which is near the root.
    path = [state.source, 2, state.root];
    parents(state.source) = 2;
    ranks(state.source) = ranks(2) + 1;
    rtt_ms = 2 * (numel(path)-1) * 8 + 2 + randn;
else
    rtt_ms = 2 * (numel(path)-1) * 8 + 2 + 2 * randn;
end
event = struct( ...
    "event_id", t, ...
    "sim_time_s", t, ...
    "source", state.source, ...
    "root", state.root, ...
    "path", path, ...
    "hop_count", numel(path)-1, ...
    "rtt_ms", max(0.1, rtt_ms), ...
    "positions_m", state.positions, ...
    "parents", parents, ...
    "ranks", ranks, ...
    "radio_range_m", state.radio_range_m);
state.pending = event;
state.pending_truth = truth;
end
