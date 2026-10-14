function erw_selftest
%ERW_SELFTEST Exercise the behavior required by the demonstration.
s = erw_init(42, "mixed");
for k = 1:8
    [s, event, truth] = erw_next(s);
    assert(~truth);
    previous_path = s.trusted_path;
    previous_version = s.baseline_version;
    [s, result] = erw_analyze(s, event);
    assert(~result.alarm && result.accepted);
    if ~isequal(previous_path, event.path)
        assert(s.baseline_version == previous_version + 1);
        assert(isscalar(s.baseline_ms_per_hop));
    end
end
trusted = s.trusted_path;
trusted_parents = s.trusted_parents;
version = s.baseline_version;
baseline = s.baseline_ms_per_hop;
[s, event, truth] = erw_next(s);
assert(truth);
tampered = event;
tampered.positions_m(1,1) = tampered.positions_m(1,1) + 100;
rejected = false;
try
    erw_analyze(s, tampered);
catch ME
    rejected = strcmp(ME.identifier, "ERW:EventChanged");
end
assert(rejected);
[s, result] = erw_analyze(s, event);
assert(result.alarm && ~result.accepted && result.nonlocal_link);
assert(isequal(s.trusted_path, trusted));
assert(isequal(s.trusted_parents, trusted_parents));
assert(s.baseline_version == version);
assert(isequal(s.baseline_ms_per_hop, baseline));
assert(~isempty(result.suspect_edges));
m = erw_evaluate(42, 100, "mixed");
assert(m.true_positive > 0 && m.false_positive == 0);
disp("ERW-IoT MATLAB self-test passed.");
end
