# ERW-IoT build and verification plan

**Scope update:** The classroom MVP is the batch LabVIEW–MATLAB demonstration
documented in `README.md`. The TCP host, live packet logger, and animated map
below describe an optional later extension and are not required for this MVP.

The eight-slide presentation is the product specification. The attached
research paper supplies background only. This package is a **synthetic
demonstration**, not an implementation of the paper's Contiki/Cooja experiment
or a claim of its reported detection accuracy.

## Demonstration contract

At one simulated event per second, MATLAB proposes a path from node 12 to the
root (node 1) in a 12-node RPL-like network. It varies node positions and
radio-link cost and recomputes each node's preferred parent and rank-like
route cost. In the mixed scenario, events 9–14 of each 20-event cycle
replace the physical route with a tunnel from node 12 to distant node 2.
The attack label remains inside the generator/evaluator and is never part of
the telemetry submitted to the detector.

The ERW-IoT check runs **before** the host changes its trusted topology or
threshold state. It rejects a proposed route when an edge exceeds the radio
range plus tolerance, or when its hop count is physically impossible and its
RTT is below the rolling clean-traffic lower bound. An alarm leaves the
trusted route and latency baseline unchanged. Accepted routes may update both.
An accepted route change resets the latency baseline and increments its
version; subsequent clean events on that route rebuild the rolling window.

In the target interactive build, LabVIEW is the host. It owns the CSV packet
logger, topology map, and a latched visual alarm. MATLAB is a persistent
localhost worker. LabVIEW sends commands and receives JSON lines over TCP;
the operator never needs to call MATLAB functions manually during a run.
The current working integration is the smaller batch VI described in README.

## Build order

1. **MATLAB engine** — Implement `erw_init`, `erw_dodag`, `erw_next`, `erw_analyze`,
   `erw_evaluate`, and `erw_service`. Verify deterministic benign, mixed, and
   wormhole scenarios with `erw_selftest`; run `erw_run_demo` to inspect raw
   events, verdicts, and separate truth labels. **Done and run in MATLAB.**
2. **LabVIEW host VI** — Create `ERW-IoT Host.vi` and a LabVIEW project. The
   front panel needs Start, Stop, Reset/Acknowledge, scenario and seed controls,
   a 2D node/link plot, current proposed and trusted paths, event/RTT/hop
   indicators, link/latency check indicators, and a large Alarm LED. Keep raw
   telemetry and verdict fields visually separate.
3. **Connection and loop** — On Start, listen on `127.0.0.1:47001`, launch
   MATLAB once using `start_matlab_service.sh 47001` with System Exec set to
   *not wait for completion*, and wait for `READY`. Send `RESET`.
   Each one-second loop iteration sends `NEXT`, writes the returned raw event
   to `telemetry.csv`, sends its `event_id` in `ANALYZE`, and then updates the
   dashboard from `RESULT`. Use TCP Read in CRLF mode with an 8192-byte
   maximum; the worker also expects CRLF on requests. Give every request a
   timeout; treat
   `ERROR`, disconnect, or malformed JSON as an operator-visible fault.
4. **CSV and display** — Write CSV headers once, append one raw row per event,
   and write verdicts to a second file after analysis. Plot all current nodes,
   physical links, accepted path, and red suspect edges. Latch the alarm on
   any suspicious result until the operator acknowledges it; a subsequent
   benign event must not silently clear it. The trusted path display must
   remain unchanged on rejection.
5. **Close and reset** — On Stop, send `STOP`, close TCP, stop the worker, and
   close CSV references. On a new Start, create a fresh session, clear the
   alarm and map, and preserve previous CSVs under a new run identifier.
6. **End-to-end evidence** — Run 100 mixed events and inspect the two CSVs,
   screen map/alarm, and confusion matrix against the hidden truth labels.
   Demonstrate a benign reroute without alarm, the first tunnel event with
   alarm and highlighted 12→2 edge, no threshold update on rejected events,
   alarm acknowledgement, and clean stop/restart. Record actual measured
   results from this implementation; do not copy paper metrics.

## Wire protocol (one JSON object followed by CRLF)

| Direction | Message | Expected action |
| --- | --- | --- |
| MATLAB → LabVIEW | `{"type":"READY","protocol":1}` | Confirm compatible worker. |
| LabVIEW → MATLAB | `{"command":"RESET","seed":42,"scenario":"mixed"}` | Create reproducible state. |
| LabVIEW → MATLAB | `{"command":"NEXT"}` | Receive `EVENT`; append raw CSV before analysis. |
| LabVIEW → MATLAB | `{"command":"ANALYZE","event_id":9}` | Receive `RESULT`; update trusted path or latch alarm. |
| LabVIEW → MATLAB | `{"command":"STOP"}` | Receive `STOP`; release connection. |

For native LabVIEW, `ANALYZE` references the worker's pending event by ID
after the host logs the raw `NEXT` response. The original request containing
the full unmodified event is also supported; MATLAB checks its order and
content, including node coordinates. On an error it returns
`{"type":"ERROR","ok":false,"identifier":"...","message":"..."}`.

## Decisions needed before hardware or live telemetry

The presentation specifies a packet logger but does not identify an actual
radio, sniffer, packet format, positioning source, or measured RTT source.
Synthetic traffic is therefore the defined demonstration input. A live
deployment needs those interfaces and independent positions or distance
estimates; otherwise the physical-link test cannot be claimed as a real
network measurement. The grid size, 35 m range, 3 m tolerance, and 16 ms/hop
baseline are demonstration parameters, not measured values from the paper.

## Current gate

LabVIEW 2026 Community Edition and MATLAB R2026b both run. The native
batch-call VI launched MATLAB and produced a complete 100-event CSV set.
The MATLAB self-test, batch simulation, and localhost protocol test pass.
The remaining gate is the interactive LabVIEW TCP host and dashboard in
steps 2–6; the protocol has only been driven by the Python integration
probe so far. Keep the synthetic demonstration label on all reported
results until live telemetry and distance sources are defined.
