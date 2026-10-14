function erw_mvp_report(output_dir)
%ERW_MVP_REPORT Summarize one seeded classroom run and draw its two routes.
telemetry = readtable(fullfile(output_dir, "telemetry.csv"), TextType="string");
verdicts = readtable(fullfile(output_dir, "verdicts.csv"));
labels = readtable(fullfile(output_dir, "ground_truth.csv"));
first_attack = find(labels.attack_truth, 1);
if isempty(first_attack) || first_attack == 1
    error("ERW:MVP", "The mixed demo needs a clean event before the first tunnel.");
end
clean = first_attack - 1;
alert = find(verdicts.alarm, 1);
if isempty(alert)
    error("ERW:MVP", "The mixed demo produced no alarm.");
end
if verdicts.alarm(first_attack)
    alarm_status = "TRUE";
else
    error("ERW:MVP", "The first tunnel event was not detected.");
end
attack_path = str2double(split(telemetry.path(first_attack), "-"))';
clean_path = str2double(split(telemetry.path(clean), "-"))';
positions = jsondecode(telemetry.positions_m(first_attack));
tunnel_length = norm(positions(attack_path(1),:) - positions(attack_path(2),:));
tp = sum(verdicts.alarm & labels.attack_truth);
fp = sum(verdicts.alarm & ~labels.attack_truth);
tn = sum(~verdicts.alarm & ~labels.attack_truth);
fn = sum(~verdicts.alarm & labels.attack_truth);

fprintf("ALARM=%s\n", alarm_status);
fprintf("ERW-IoT | SYNTHETIC CLASSROOM DEMONSTRATION\n");
fprintf("Clean event %d: route %s | %d hops | %.1f ms RTT | alarm OFF\n", ...
    telemetry.event_id(clean), telemetry.path(clean), telemetry.hop_count(clean), ...
    telemetry.rtt_ms(clean));
fprintf("Tunnel event %d: route %s | %d hops | %.1f ms RTT | alarm ON\n", ...
    telemetry.event_id(first_attack), telemetry.path(first_attack), ...
    telemetry.hop_count(first_attack), telemetry.rtt_ms(first_attack));
fprintf("Suspect link %d -> %d: %.1f m separation; radio limit 35 m (+3 m tolerance).\n", ...
    attack_path(1), attack_path(2), tunnel_length);
fprintf("Trusted baseline version: %d before; %d after rejection.\n", ...
    verdicts.baseline_version(clean), verdicts.baseline_version(first_attack));
fprintf("First attack event: %d | first alarm event: %d\n", ...
    telemetry.event_id(first_attack), telemetry.event_id(alert));
fprintf("Seeded %d-event result: TP=%d TN=%d FP=%d FN=%d\n", ...
    height(telemetry), tp, tn, fp, fn);
fprintf("CSV packet log and verdicts: %s\n", output_dir);

fig = figure(Visible="off", Color="w", Position=[100 100 1200 480]);
draw_route(1, telemetry, clean, clean_path, [0.08 0.48 0.24], "Normal route - accepted");
draw_route(2, telemetry, first_attack, attack_path, [0.82 0.12 0.12], ...
    "Wormhole shortcut - rejected");
exportgraphics(fig, fullfile(output_dir, "topology_comparison.png"), Resolution=100);
close(fig);
end

function draw_route(panel, telemetry, row, path, route_color, caption)
subplot(1, 2, panel);
positions = jsondecode(telemetry.positions_m(row));
set(gca, Color="w", XColor="k", YColor="k", GridColor=[0.78 0.80 0.83]);
hold on;
for a = 1:size(positions, 1)
    for b = a+1:size(positions, 1)
        if norm(positions(a,:) - positions(b,:)) <= 35
            plot(positions([a b],1), positions([a b],2), "-", ...
                Color=[0.85 0.87 0.89], LineWidth=1);
        end
    end
end
for edge = 1:numel(path)-1
    style = "-";
    if panel == 2 && edge == 1, style = "--"; end
    plot(positions(path(edge:edge+1),1), positions(path(edge:edge+1),2), style, ...
        Color=route_color, LineWidth=3);
end
scatter(positions(:,1), positions(:,2), 110, [0.16 0.36 0.62], "filled");
scatter(positions(1,1), positions(1,2), 130, [0.08 0.58 0.30], "filled");
scatter(positions(12,1), positions(12,2), 130, [0.92 0.54 0.07], "filled");
for node = 1:size(positions, 1)
    text(positions(node,1)+2, positions(node,2)+2, string(node), ...
        FontWeight="bold", Color="k");
end
title(sprintf("%s\nEvent %d | %d hops | %.1f ms RTT", caption, ...
    telemetry.event_id(row), telemetry.hop_count(row), telemetry.rtt_ms(row)), Color="k");
xlabel("x position (m)", Color="k"); ylabel("y position (m)", Color="k");
axis equal; xlim([-7 105]); ylim([-8 75]); grid on;
end
