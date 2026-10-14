# Native LabVIEW host: wiring contract

This is the implementation checklist for `ERW-IoT Host Draft.vi`. The draft
is not wired or executable as the interactive host. The working
`ERW-IoT MATLAB Batch.vi` remains the executable joint demonstration.

## Front panel

Add Start, Stop, and Acknowledge Alarm buttons; scenario (`benign`, `mixed`,
`wormhole`) and numeric seed controls; event ID, RTT, hop count, proposed
path, trusted path, connection status, fault text, and a latched Alarm LED.
The node map should show current coordinates and physical radio links, with
the accepted route distinguished from the proposed route and suspect edges
drawn in red. Label the display **Synthetic RPL-like telemetry**.

## Block diagram order

1. Launch `start_matlab_service.sh 47001` with `System Exec.vi`, setting
   `wait until completion?` to false. Sequence TCP Listen after System Exec
   returns; MATLAB retries its localhost connection during startup.
2. Use `String To IP` on `127.0.0.1` and wire its net address to `TCP
   Listen.vi`; a zero net address listens on all interfaces. Set port
   `47001` and a finite timeout. Keep the accepted connection ID for
   subsequent reads, writes, and cleanup.
3. Accept the connection, then read one CRLF-terminated JSON line with
   `TCP Read` in **CRLF** mode, `bytes to read = 8192`, and a finite timeout.
   Require `{"type":"READY","protocol":1}` before continuing.
4. Send `{"command":"RESET","seed":42,"scenario":"mixed"}` followed by
   CRLF with `TCP Write`. Read and validate the `RESET` response.
5. In a one-second loop, send `NEXT` plus CRLF. Read the `EVENT` reply. Write
   its raw `event` fields to `telemetry.csv` before requesting analysis.
   Send `ANALYZE` with that `event_id`, read `RESULT`, write `verdicts.csv`,
   then update the map, indicators, and alarm from the result. `ANALYZE`
   without a pending `NEXT` is invalid. Never use the generator's hidden
   attack label as detector input.
6. If `result.alarm` is true, set the Alarm LED and retain it until
   Acknowledge Alarm is pressed. On a rejected event, display
   `result.trusted_path` unchanged. `type=ERROR`, invalid JSON, timeout, or
   disconnect must set the fault indicator and stop the normal event loop;
   they are not benign verdicts.
7. On Stop or fault, attempt `STOP` plus CRLF if connected; close the TCP
   connection, listener, and open files. A new Start makes new CSV files and
   resets the alarm. Preserve prior runs.

Use LabVIEW's `Unflatten From JSON` on each line after stripping CRLF. The
installed LabVIEW distribution includes a JSON example at
`examples/Strings/Unflatten From JSON.vi`. The `EVENT` reply carries nested
arrays (`path`, `parents`, `ranks`, `positions_m`); the `RESULT` reply carries
`suspect_edges` as an array of node pairs. Confirm the JSON cluster types
against a real `EVENT` and `RESULT` captured by `tests/test_service.py`.

## Native acceptance check

Run 100 `mixed` events in LabVIEW. Confirm the first alarm at event 9, a red
12→2 suspect edge, unchanged trusted path and baseline version across that
rejection, an alarm that stays on during later benign events until
acknowledged, and clean Stop/Start. Check the CSV rows and a screenshot of
the map. These results describe the seeded simulation only.
