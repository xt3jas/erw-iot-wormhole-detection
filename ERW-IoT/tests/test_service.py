"""Exercise the MATLAB worker through the same JSON lines used by LabVIEW."""

import json
import os
from pathlib import Path
import socket
import subprocess


PROJECT = Path(__file__).resolve().parents[1]


def exchange(connection, command):
    connection.write(json.dumps(command).encode() + b"\r\n")
    connection.flush()
    reply = connection.readline()
    if not reply:
        raise RuntimeError("MATLAB closed the connection before replying")
    assert reply.endswith(b"\r\n"), reply
    return json.loads(reply)


def main():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as listener:
        listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        listener.bind(("127.0.0.1", 0))
        listener.listen(1)
        listener.settimeout(180)
        port = listener.getsockname()[1]
        process = subprocess.Popen(
            [str(PROJECT / "start_matlab_service.sh"), str(port)],
            cwd=PROJECT,
            env=os.environ.copy(),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        try:
            client, _ = listener.accept()
            with client:
                client.settimeout(30)
                with client.makefile("rwb") as connection:
                    ready = connection.readline()
                    assert ready.endswith(b"\r\n")
                    assert json.loads(ready) == {"type": "READY", "protocol": 1}
                    reset = exchange(connection, {
                        "command": "RESET", "seed": 42, "scenario": "mixed"
                    })
                    assert reset["type"] == "RESET" and reset["ok"]
                    for event_id in range(1, 9):
                        event_reply = exchange(connection, {"command": "NEXT"})
                        assert event_reply["type"] == "EVENT"
                        event = event_reply["event"]
                        assert event["event_id"] == event_id
                        result_reply = exchange(connection, {
                            "command": "ANALYZE", "event_id": event_id
                        })
                        assert result_reply["type"] == "RESULT"
                        result = result_reply["result"]
                        assert result["accepted"] and not result["alarm"]
                        assert result["suspect_edge_count"] == 0
                    trusted_path = result["trusted_path"]
                    baseline_version = result["baseline_version"]
                    event = exchange(connection, {"command": "NEXT"})["event"]
                    assert event["event_id"] == 9
                    stale = exchange(connection, {
                        "command": "ANALYZE", "event_id": 10
                    })
                    assert stale["type"] == "ERROR"
                    assert stale["identifier"] == "ERW:EventOrder"
                    result = exchange(connection, {
                        "command": "ANALYZE", "event_id": 9
                    })["result"]
                    assert result["alarm"] and not result["accepted"]
                    assert result["trusted_path"] == trusted_path
                    assert result["baseline_version"] == baseline_version
                    assert [12, 2] in result["suspect_edges"]
                    assert result["suspect_edge_count"] == len(result["suspect_edges"])
                    event = exchange(connection, {"command": "NEXT"})["event"]
                    assert event["event_id"] == 10
                    assert exchange(connection, {
                        "command": "ANALYZE", "event": event
                    })["type"] == "RESULT"
                    assert exchange(connection, {"command": "STOP"})["type"] == "STOP"
            return_code = process.wait(timeout=30)
            assert return_code == 0, process.stdout.read()
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)

    print("MATLAB TCP protocol test passed.")


if __name__ == "__main__":
    main()
