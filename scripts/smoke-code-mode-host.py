#!/usr/bin/env python3
"""Exercise the packaged Code Mode host over its real length-prefixed protocol."""

from __future__ import annotations

import json
import os
import select
import struct
import subprocess
import sys
import time


TIMEOUT_SECONDS = 20.0
MAX_FRAME_BYTES = 64 * 1024 * 1024


def fail(message: str) -> None:
    raise RuntimeError(message)


def write_frame(process: subprocess.Popen[bytes], message: dict[str, object]) -> None:
    payload = json.dumps(message, separators=(",", ":")).encode()
    if len(payload) > MAX_FRAME_BYTES:
        fail("smoke-test request exceeds the Code Mode frame limit")
    assert process.stdin is not None
    process.stdin.write(struct.pack("<I", len(payload)) + payload)
    process.stdin.flush()


def read_exact(fd: int, length: int) -> bytes:
    output = bytearray()
    deadline = time.monotonic() + TIMEOUT_SECONDS
    while len(output) < length:
        remaining = deadline - time.monotonic()
        if remaining <= 0 or not select.select([fd], [], [], remaining)[0]:
            fail("timed out reading a Code Mode host frame")
        chunk = os.read(fd, length - len(output))
        if not chunk:
            fail("Code Mode host closed stdout before completing a frame")
        output.extend(chunk)
    return bytes(output)


def read_frame(process: subprocess.Popen[bytes]) -> dict[str, object]:
    assert process.stdout is not None
    fd = process.stdout.fileno()
    (length,) = struct.unpack("<I", read_exact(fd, 4))
    if length > MAX_FRAME_BYTES:
        fail(f"Code Mode host returned an oversized frame: {length} bytes")
    decoded = json.loads(read_exact(fd, length))
    if not isinstance(decoded, dict):
        fail(f"Code Mode host returned a non-object frame: {decoded!r}")
    return decoded


def expect_ok_response(message: dict[str, object], request_id: int, value_type: str) -> dict[str, object]:
    if message.get("type") != "operation/response" or message.get("id") != request_id:
        fail(f"unexpected response for request {request_id}: {message!r}")
    result = message.get("result")
    if not isinstance(result, dict) or result.get("status") != "ok":
        fail(f"Code Mode request {request_id} failed: {message!r}")
    value = result.get("value")
    if not isinstance(value, dict) or value.get("type") != value_type:
        fail(f"unexpected value for request {request_id}: {message!r}")
    return value


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} PATH-TO-CODEX-CODE-MODE-HOST", file=sys.stderr)
        return 2

    process = subprocess.Popen(
        [sys.argv[1], "--listen", "stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    try:
        write_frame(
            process,
            {
                "type": "connection/hello",
                "supportedVersions": [1],
                "requiredCapabilities": [],
                "optionalCapabilities": [],
            },
        )
        hello = read_frame(process)
        if hello.get("type") != "connection/ready" or hello.get("selectedVersion") != 1:
            fail(f"Code Mode protocol handshake failed: {hello!r}")

        write_frame(
            process,
            {
                "type": "operation/request",
                "id": 1,
                "request": {"method": "session/open", "sessionId": "release-smoke"},
            },
        )
        session = expect_ok_response(read_frame(process), 1, "session/ready")
        if session.get("sessionId") != "release-smoke":
            fail(f"Code Mode host opened the wrong session: {session!r}")

        write_frame(
            process,
            {
                "type": "operation/request",
                "id": 2,
                "request": {
                    "method": "session/execute",
                    "sessionId": "release-smoke",
                    "request": {
                        "tool_call_id": "release-smoke-call",
                        "enabled_tools": [],
                        "source": 'text("code-mode-smoke-ok");',
                        "yield_time_ms": 10_000,
                        "max_output_tokens": 100,
                    },
                },
            },
        )

        execute_messages = []
        operation_response = None
        initial_response = None
        for _ in range(32):
            message = read_frame(process)
            execute_messages.append(message)
            message_type = message.get("type")
            if message_type == "operation/response":
                operation_response = message
            elif message_type == "execute/initialResponse":
                initial_response = message
            elif message_type == "cell/closed":
                if message.get("sessionId") != "release-smoke":
                    fail(f"Code Mode host closed a cell in the wrong session: {message!r}")
            else:
                fail(f"unexpected Code Mode execution message: {message!r}")
            if operation_response is not None and initial_response is not None:
                break
        if operation_response is None or initial_response is None:
            fail(f"incomplete Code Mode execution response: {execute_messages!r}")
        expect_ok_response(operation_response, 2, "execution/started")

        if initial_response.get("id") != 2:
            fail(f"Code Mode initial response has the wrong request id: {initial_response!r}")
        result = initial_response.get("result")
        if not isinstance(result, dict) or result.get("status") != "ok":
            fail(f"Code Mode execution failed: {initial_response!r}")
        runtime = result.get("value")
        if not isinstance(runtime, dict) or "Result" not in runtime:
            fail(f"Code Mode execution did not finish: {initial_response!r}")
        result_value = runtime["Result"]
        if not isinstance(result_value, dict) or result_value.get("error_text") is not None:
            fail(f"Code Mode execution returned an error: {initial_response!r}")
        if {"type": "input_text", "text": "code-mode-smoke-ok"} not in result_value.get(
            "content_items", []
        ):
            fail(f"Code Mode execution returned unexpected output: {initial_response!r}")

        write_frame(
            process,
            {
                "type": "operation/request",
                "id": 3,
                "request": {"method": "session/shutdown", "sessionId": "release-smoke"},
            },
        )
        # A completed cell is closed asynchronously. Its notification can race
        # with the shutdown response, so drain that event without confusing it
        # for the response to request 3.
        shutdown_response = None
        for _ in range(16):
            message = read_frame(process)
            if message.get("type") == "cell/closed":
                if message.get("sessionId") != "release-smoke":
                    fail(f"Code Mode host closed a cell in the wrong session: {message!r}")
                continue
            shutdown_response = message
            break
        if shutdown_response is None:
            fail("Code Mode host did not return a shutdown response")
        expect_ok_response(shutdown_response, 3, "session/closed")
        assert process.stdin is not None
        process.stdin.close()
        process.wait(timeout=5)
        if process.returncode != 0:
            fail(f"Code Mode host exited with status {process.returncode}")
    except Exception:
        process.kill()
        process.wait()
        assert process.stderr is not None
        stderr = process.stderr.read().decode(errors="replace").strip()
        if stderr:
            print(f"Code Mode host stderr:\n{stderr}", file=sys.stderr)
        raise

    print("Code Mode host protocol smoke test passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
