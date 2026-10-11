# Local Daemon on LoongArch64

Codex 0.162.1 automatically starts a shared local app-server for eligible
interactive launches. The upstream package-target mapping omits LoongArch64,
which makes an initial launch fail with `unsupported packaged daemon platform
linux/loongarch64`.

The 0.162.1 patch set adds GNU and musl package-target mappings. The daemon
copies the complete invoking package into its managed releases directory and
uses the existing Unix process, locking, and socket implementation. It requires
the standard package, including Code Mode host, ripgrep, and bubblewrap; a bare
Codex executable cannot initialize a new daemon installation.

## Updates

Official installers do not publish LoongArch64 packages. The patch retains the
upstream automatic-update target allowlist and makes an explicit official
daemon update return JSON with `status: "unsupported"` without starting an
updater. No third-party update channel is added.

After installing a newer complete CLI package from this repository, explicitly
replace the daemon package:

```bash
codex app-server daemon update --from-cli
```

This command asks for confirmation, pins the selected package, and restarts a
running daemon. Active or queued work may be interrupted. For unattended use,
`--yes` accepts the replacement. Updating the CLI alone does not replace the
daemon copy.

To restore automatic daemon startup after a previous workaround:

```bash
codex features enable daemon_auto_start
```

## Validation

Run the upstream daemon unit tests on a native LoongArch host after applying
the patch set:

```bash
cd work/src/codex-rust-v0.162.1/codex-rs
cargo test -p codex-app-server-daemon --lib
```

Run the package lifecycle smoke test with temporary state outside the normal
Codex home:

```bash
mkdir -p work/tmp
TMPDIR="$PWD/work/tmp" python3 scripts/smoke-daemon.py /path/to/package/bin/codex
```

The per-command timeout defaults to 90 seconds. Unoptimized local builds can
spend longer hashing the complete package; set `CODEX_DAEMON_SMOKE_TIMEOUT=300`
for those validation builds.

The test checks initial staging, idempotent start, two concurrent version
clients (each performs a real initialize handshake), restart, stop, official
update rejection, and pinned package replacement while stopped. It makes no
model requests and enables no remote control. Release verification runs it for
0.162.1 packages on LoongArch hosts.

This lifecycle smoke does not prove background model turns, saved-thread
continuation, remote pairing, or a third-party automatic update service. GNU
validation alone does not prove the static musl release; validate each release
package on its intended host before publishing it.

## Adaptation Validation

The patch was tested against upstream tag `rust-v0.162.1` (commit `7a078f6`)
with Rust 1.95.0 on a native LoongArch64 Linux host:

- `cargo test -p codex-app-server-daemon --lib`: 82 passed, 0 failed.
- `cargo build -p codex-cli --bin codex`: native GNU development build passed.
- The unpatched 0.162.1 musl package fails the lifecycle smoke with the original
  unsupported-platform error; the patched GNU validation package passes.
- Default interactive startup initializes the daemon and reaches folder
  onboarding. After exiting that client, a version probe still reports the
  daemon running.
- Two WebSocket clients see the same empty thread. After both disconnect, a
  new client lists and reads that thread successfully, without a model turn.
- `thread/resume` for a never-used empty thread returns `no rollout found`;
  persisted turn continuation was not validated.
- The patched GNU validation binary SHA-256 is
  `d96b7055f8f122c7bda6e7968dea11ee506766b8ad88208851400a6efc16003a`.

The GNU validation package reused the 0.162.1 musl Code Mode host, ripgrep, and
bubblewrap. A patched static musl release rebuild and its complete package
verification remain required before publishing new release assets.
