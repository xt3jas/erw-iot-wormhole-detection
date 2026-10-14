function state = erw_init(seed, scenario)
%ERW_INIT Set up a reproducible RPL-like network demonstration.
if nargin < 1, seed = 42; end
if nargin < 2, scenario = "mixed"; end
scenario = string(scenario);
if ~ismember(scenario, ["benign", "wormhole", "mixed"])
    error("ERW:Scenario", "Scenario must be benign, wormhole, or mixed.");
end
rng(seed, "twister");
[x, y] = meshgrid(0:30:90, 0:30:60);
state.base_positions = [x(:), y(:)];
state.positions = state.base_positions;
state.radio_range_m = 35;
state.range_tolerance_m = 3;
state.root = 1;
state.source = 12;
state.tick = 0;
state.scenario = scenario;
state.trusted_path = [];
state.trusted_parents = zeros(12, 1);
state.pending = [];
state.pending_truth = false;
state.last_analyzed_id = 0;
state.baseline_ms_per_hop = 16 + randn(1, 30);
state.baseline_version = 1;
end
