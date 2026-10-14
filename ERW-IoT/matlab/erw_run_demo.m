function metrics = erw_run_demo(output_dir, seed, count, scenario)
%ERW_RUN_DEMO Export a deterministic telemetry and verdict demonstration.
if nargin < 1, output_dir = fullfile(pwd, "demo_output"); end
if nargin < 2, seed = 42; end
if nargin < 3, count = 100; end
if nargin < 4, scenario = "mixed"; end
if ~isfolder(output_dir), mkdir(output_dir); end
state = erw_init(seed, scenario);
event_id = zeros(count,1);
sim_time_s = zeros(count,1);
source = zeros(count,1);
root = zeros(count,1);
path = strings(count,1);
parents = strings(count,1);
ranks = strings(count,1);
positions_m = strings(count,1);
hop_count = zeros(count,1);
rtt_ms = zeros(count,1);
attack_truth = false(count,1);
alarm = false(count,1);
accepted = false(count,1);
minimum_physical_hops = zeros(count,1);
lower_rtt_ms = zeros(count,1);
baseline_version = zeros(count,1);
for k = 1:count
    [state, event, attack_truth(k)] = erw_next(state);
    [state, result] = erw_analyze(state, event);
    event_id(k) = event.event_id;
    sim_time_s(k) = event.sim_time_s;
    source(k) = event.source;
    root(k) = event.root;
    path(k) = strjoin(string(event.path), "-");
    parents(k) = strjoin(string(event.parents(:)'), "-");
    ranks(k) = strjoin(string(event.ranks(:)'), "-");
    positions_m(k) = string(jsonencode(event.positions_m));
    hop_count(k) = event.hop_count;
    rtt_ms(k) = event.rtt_ms;
    alarm(k) = result.alarm;
    accepted(k) = result.accepted;
    minimum_physical_hops(k) = result.minimum_physical_hops;
    lower_rtt_ms(k) = result.lower_rtt_ms;
    baseline_version(k) = result.baseline_version;
end
raw = table(event_id, sim_time_s, source, root, path, parents, ranks, ...
    positions_m, hop_count, rtt_ms);
verdicts = table(event_id, alarm, accepted, minimum_physical_hops, ...
    lower_rtt_ms, baseline_version);
labels = table(event_id, attack_truth);
writetable(raw, fullfile(output_dir, "telemetry.csv"));
writetable(verdicts, fullfile(output_dir, "verdicts.csv"));
writetable(labels, fullfile(output_dir, "ground_truth.csv"));
metrics = struct( ...
    "true_positive", sum(alarm & attack_truth), ...
    "false_positive", sum(alarm & ~attack_truth), ...
    "true_negative", sum(~alarm & ~attack_truth), ...
    "false_negative", sum(~alarm & attack_truth));
disp(metrics);
end
