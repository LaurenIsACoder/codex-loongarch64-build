#!/usr/bin/env python3
"""Check packaged daemon lifecycle in an isolated CODEX_HOME without model calls."""

from __future__ import annotations

import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} PATH-TO-PACKAGED-CODEX", file=sys.stderr)
        return 2
    binary = Path(sys.argv[1]).resolve()
    if not binary.is_file():
        raise RuntimeError(f"missing Codex executable: {binary}")
    with tempfile.TemporaryDirectory(prefix="daemon-smoke-") as directory:
        home = Path(directory) / "home"
        home.mkdir()
        temporary = Path(directory) / "tmp"
        temporary.mkdir()
        env = os.environ.copy()
        env["TMPDIR"] = str(temporary)
        env["CODEX_HOME"] = str(home)
        env["CODEX_SQLITE_HOME"] = str(home / "sqlite")
        env.pop("CODEX_EXEC_SERVER_URL", None)
        state = home / "app-server-daemon"
        state.mkdir()
        (state / "settings.json").write_text(
            json.dumps({"remoteControlEnabled": False, "shutdownGraceSeconds": 5,
                        "updater": {"autoUpdateEnabled": False}}), encoding="utf-8"
        )

        def command(*args: str) -> dict:
            process = subprocess.run(
                [str(binary), "app-server", "daemon", *args], env=env,
                cwd=directory, text=True, capture_output=True,
                timeout=float(env.get("CODEX_DAEMON_SMOKE_TIMEOUT", "90")),
            )
            if process.returncode:
                raise RuntimeError(f"daemon {args} failed: {process.stderr}")
            result = json.loads(process.stdout)
            if not isinstance(result, dict):
                raise RuntimeError(f"unexpected daemon response: {result!r}")
            return result

        def digest(path: Path) -> str:
            hasher = hashlib.sha256()
            with path.open("rb") as executable:
                for chunk in iter(lambda: executable.read(1024 * 1024), b""):
                    hasher.update(chunk)
            return hasher.hexdigest()

        def process_record() -> dict:
            return json.loads((state / "daemon.pid").read_text(encoding="utf-8"))

        started = False
        failed = False
        try:
            started = True
            first = command("start")
            assert first["status"] == "started", first
            assert Path(first["managedCodexPath"]).is_relative_to(home), first
            assert digest(binary) == digest(Path(first["managedCodexPath"])), first
            assert first["appServerVersion"] == first["managedCodexVersion"], first
            original_process = process_record()
            assert original_process["pid"] == first["pid"], original_process
            again = command("start")
            assert again["status"] == "alreadyRunning", again
            assert process_record() == original_process
            with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
                clients = list(pool.map(lambda _: command("version"), range(2)))
            for client in clients:
                assert client["status"] == "running", client
                assert client["socketPath"] == first["socketPath"], client
                assert client["appServerVersion"] == first["appServerVersion"], client
            update = command("update")
            assert update["status"] == "unsupported", update
            assert "--from-cli" in update["message"], update
            assert command("start")["status"] == "alreadyRunning"
            assert process_record() == original_process
            assert not (state / "daemon-updater.pid").exists()
            restarted = command("restart")
            assert restarted["status"] == "restarted", restarted
            assert restarted["pid"] != first["pid"], (first, restarted)
            stopped = command("stop")
            assert stopped["status"] == "stopped", stopped
            assert command("stop")["status"] == "notRunning"
            replacement = command("update", "--from-cli", "--yes")
            assert replacement["status"] == "updated", replacement
            assert replacement["runningVersion"] is None, replacement
            assert not (home / "packages/app-server-daemon/auto-update-version").exists()
            final = command("start")
            assert final["status"] == "started", final
            assert final["appServerVersion"] == first["appServerVersion"], final
            print("Daemon smoke passed: package staging, shared clients, restart, stop, "
                  "official-update rejection, and pinned CLI-package replacement")
        except BaseException:
            failed = True
            raise
        finally:
            if started:
                try:
                    command("stop")
                except Exception as error:
                    if not failed:
                        raise
                    print(f"cleanup failed: {error}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
