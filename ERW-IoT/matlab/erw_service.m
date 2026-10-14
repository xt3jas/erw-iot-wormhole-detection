function erw_service(port)
%ERW_SERVICE Connect to the LabVIEW host and answer one request per line.
if nargin < 1, port = 47001; end
state = [];
client = [];
for attempt = 1:30
    try
        client = tcpclient("127.0.0.1", port, Timeout=5);
        break;
    catch
        pause(0.25);
    end
end
if isempty(client)
    error("ERW:Connect", "Could not connect to LabVIEW on localhost:%d.", port);
end
cleanup = onCleanup(@() delete(client));
configureTerminator(client, "CR/LF");
writeline(client, jsonencode(struct("type", "READY", "protocol", 1)));
while true
    try
        request = jsondecode(char(readline(client)));
        command = upper(string(request.command));
        switch command
            case "RESET"
                state = erw_init(double(request.seed), string(request.scenario));
                reply = struct("type", "RESET", "ok", true, ...
                    "node_count", size(state.positions,1), ...
                    "radio_range_m", state.radio_range_m);
            case "NEXT"
                if isempty(state), error("ERW:NotReady", "Send RESET first."); end
                [state, event] = erw_next(state);
                reply = struct("type", "EVENT", "ok", true, "event", event);
            case "ANALYZE"
                if isempty(state), error("ERW:NotReady", "Send RESET first."); end
                if isfield(request, "event")
                    event = request.event;
                elseif isfield(request, "event_id") && ~isempty(state.pending) && ...
                        request.event_id == state.pending.event_id
                    event = state.pending;
                else
                    error("ERW:EventOrder", "Event is missing, stale, or out of order.");
                end
                [state, result] = erw_analyze(state, event);
                reply = struct("type", "RESULT", "ok", true, "result", result);
            case "STOP"
                writeline(client, jsonencode(struct("type", "STOP", "ok", true)));
                return;
            otherwise
                error("ERW:Command", "Unknown command: %s", command);
        end
    catch ME
        reply = struct("type", "ERROR", "ok", false, ...
            "identifier", string(ME.identifier), "message", string(ME.message));
    end
    writeline(client, jsonencode(reply));
end
end
