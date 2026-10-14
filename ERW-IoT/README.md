# ERW-IoT classroom MVP

Open `labview/ERW-IoT MATLAB Batch.vi` in LabVIEW and choose **Operate > Run**.
The VI calls `run_matlab_demo.sh`, which runs the MATLAB simulator and detector,
then returns a short alarm report to LabVIEW. The front panel includes a
**static example** comparing a normal route with the seeded wormhole event.
MATLAB writes the CSV log in this MVP; LabVIEW launches the run and displays
its result.

The VI's saved command still uses its original workspace path. On this Mac,
that path is a symbolic link to this Desktop project folder; the moved VI was
run successfully through the link. If you copy the folder to another computer,
update the command control to that computer's `run_matlab_demo.sh` path.

For each new run MATLAB writes its own current `topology_comparison.png`, raw
`telemetry.csv`, `verdicts.csv`, and separate `ground_truth.csv` under a new
folder in `demo_output/`. The example on the LabVIEW panel illustrates the
fixed seed 42 run; it does not animate or reload the image at runtime.

The presentation sequence is: show the green accepted route for event 8,
show the red dashed 12→2 tunnel proposed in event 9, run the VI, read the
LabVIEW alarm output, then open the new CSVs and topology PNG if detail is
needed. The current seed 42, 100-event run produced 30 true positives, 70
true negatives, and no false results **on synthetic traffic only**. This is
not a measurement of real wireless packets or a claim of deployment accuracy.

The original live TCP host and animated dashboard are outside this classroom
MVP. `PLAN.md` and `labview/NATIVE_HOST_BUILD.md` preserve that optional
extension plan; `labview/ERW-IoT Host Draft.vi` is not the file to present.

| Presentation element | MVP evidence |
| --- | --- |
| RPL-like route, mobility, fading | `erw_dodag.m` and `erw_next.m` |
| Packet logger | Per-run `telemetry.csv` |
| Path consistency and threshold reset | `erw_analyze.m` and `baseline_version` in `verdicts.csv` |
| Wormhole injection and alarm | Event 9's 12→2 tunnel and LabVIEW `ALARM=TRUE` result |
| Topology map | Seeded example on the VI plus each run's generated PNG |

Allow about half a minute for MATLAB to start and finish after pressing Run.
The VI output field is intentionally a compact alarm readout; the full report
and the current run's output folder are available in the MATLAB process output
and CSV/PNG files. No radio hardware or live packet capture is used.

## Earlier full-system implementation notes

The MATLAB simulation and detector are implemented in `matlab/`. A native
LabVIEW VI in `labview/ERW-IoT MATLAB Batch.vi` launches the MATLAB demo,
waits for it to finish, and receives its process output. This batch path is
a working joint LabVIEW–MATLAB demonstration. The interactive LabVIEW
dashboard and persistent TCP host VI are **not implemented yet**. A partial
`labview/ERW-IoT Host Draft.vi` has been started, with connection and launch
wiring still to be completed. The native host's wiring checklist is in
`labview/NATIVE_HOST_BUILD.md`.

## MATLAB model

- `erw_init.m` creates a seeded 12-node, one-root RPL-like DODAG setting.
- `erw_dodag.m` computes each node's preferred parent and rank-like route
  cost, giving the host the full topology to draw.
- `erw_next.m` moves nodes, varies link cost, proposes a route, and injects a
  distant-node tunnel during six events in each 20-event mixed cycle.
- `erw_analyze.m` checks link reachability, minimum physical hop count, and
  a lower RTT bound derived from a rolling clean-event baseline. It rejects
  suspicious reroutes without changing the trusted path or baseline. An
  accepted route change resets the baseline to its first new-path sample.
- `erw_service.m` is the persistent base-MATLAB TCP client for LabVIEW.
- `start_matlab_service.sh` launches that worker for the LabVIEW host after
  its TCP listener is ready.
- `erw_run_demo.m` exports raw telemetry, verdicts, and separate ground-truth
  labels as CSV files. `erw_evaluate.m` computes a confusion matrix.

Run from MATLAB:

```matlab
addpath(fullfile(pwd, 'matlab'))
erw_selftest
erw_run_demo(fullfile(pwd, 'erw_demo_output'), 42, 100, 'mixed')
```

From a terminal, `./run_matlab_demo.sh` runs the self-test and a 100-event
mixed scenario. `python3 tests/test_service.py` checks the localhost JSON
exchange that the planned LabVIEW host will use. To run the joint batch
demonstration, open `labview/ERW-IoT.lvproj` in LabVIEW, open
`ERW-IoT MATLAB Batch.vi`, and press Run. The command control defaults to
this project's `run_matlab_demo.sh`. LabVIEW waits for MATLAB and displays
its process output; every run writes new CSV files under `demo_output/`.

The detector uses a conservative synthetic demonstration rule. Coordinates
and radio range are known to the simulator. A link longer than the radio
range plus 3 m tolerance is anomalous. A path with fewer hops than the
shortest physical path is also anomalous if its RTT falls below the lower
bound calibrated from accepted traffic. A path difference by itself does
not trigger an alarm because benign parent changes are expected.

`labview/ERW-IoT.lvproj` opens the native batch-call starter. To use another
local MATLAB installation, set `MATLAB_BIN` to its `bin/matlab` executable
before running either shell script.

## LabVIEW integration contract

The planned LabVIEW 2026 Community Edition dashboard listens on
`127.0.0.1:47001`. MATLAB connects using base-MATLAB `tcpclient` and sends
`{"type":"READY","protocol":1}`. Each TCP message is one JSON object and
ends with CRLF. LabVIEW can use TCP Read in CRLF mode with an 8192-byte
maximum for each response. LabVIEW sends one request and reads one response
at a time:

| Request | Response | LabVIEW action |
| --- | --- | --- |
| `{"command":"RESET","seed":42,"scenario":"mixed"}` | `RESET` | Clear log, alarm, and map. |
| `{"command":"NEXT"}` | `EVENT` with `event` | Append the raw event to `telemetry.csv`. |
| `{"command":"ANALYZE","event_id":9}` | `RESULT` with `result` | Analyze the pending event after logging it; reject a stale ID. |
| `{"command":"STOP"}` | `STOP` | Close the client and listener. |

The worker also accepts the original full-event `ANALYZE` request and
validates its contents against the pending event. The raw event carries
`event_id`, `sim_time_s`, `source`, `root`, `path`,
`parents`, `ranks`, `hop_count`, `rtt_ms`, `positions_m`, and `radio_range_m`.
The result carries
`alarm`, `accepted`, `trusted_path`, `trusted_parents`, `proposed_path`, `suspect_edges`,
`minimum_physical_hops`, `lower_rtt_ms`, and `baseline_version`. A response
with `type=ERROR` contains an identifier and message; it must not be shown
as a benign verdict. LabVIEW should keep its alarm latched until operator
acknowledgement, even after later benign events.
`suspect_edges` is always a JSON array of `[from_node,to_node]` pairs, even
when only one edge is suspect.

## Current verification and remaining work

The installed MATLAB R2026b runs successfully. `mlint` reported no
diagnostics for the `.m` files. The MATLAB self-test and 100-event mixed
scenario completed. The localhost protocol integration test passed against
the real MATLAB worker. Running the native LabVIEW VI launched MATLAB and
produced a second set of 100-row telemetry, verdict, and truth CSVs in
`demo_output/20261012T193837Z-19070/`; the first alarm was event 9.

These results establish the batch integration. The planned interactive
LabVIEW host still needs its listener wired to the MATLAB launch and TCP
read/write nodes, plus the per-event loop, CSV logger, map, and latched
alarm. Its protocol is implemented and tested from a Python
client, but has not been exercised from a LabVIEW TCP VI. Accuracy measured
on this seeded synthetic traffic must not be presented as accuracy on a
physical network or as the paper's reported result.
