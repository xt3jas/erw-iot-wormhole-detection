function metrics = erw_evaluate(seed, count, scenario)
%ERW_EVALUATE Measure detector behavior against generator-only labels.
if nargin < 1, seed = 42; end
if nargin < 2, count = 100; end
if nargin < 3, scenario = "mixed"; end
state = erw_init(seed, scenario);
truths = false(count,1);
alerts = false(count,1);
for k = 1:count
    [state, event, truths(k)] = erw_next(state);
    [state, result] = erw_analyze(state, event);
    alerts(k) = result.alarm;
end
metrics = struct( ...
    "true_positive", sum(alerts & truths), ...
    "false_positive", sum(alerts & ~truths), ...
    "true_negative", sum(~alerts & ~truths), ...
    "false_negative", sum(~alerts & truths), ...
    "first_attack_event", find(truths, 1, "first"), ...
    "first_detection_event", find(alerts & truths, 1, "first"));
if ~isempty(metrics.first_attack_event) && ~isempty(metrics.first_detection_event)
    metrics.detection_delay_s = metrics.first_detection_event - metrics.first_attack_event;
else
    metrics.detection_delay_s = NaN;
end
disp(metrics);
end
