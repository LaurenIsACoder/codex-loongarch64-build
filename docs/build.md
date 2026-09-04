# Build Guide

## Scope

This guide covers the reproducible, fully static
`loongarch64-unknown-linux-musl` build of Codex CLI `0.153.2` on a native
LoongArch64 Linux host. The pinned upstream inputs are:

- Codex tag `rust-v0.153.2`
- `rusty_v8` tag `v150.4.0`
- `seccompiler` crate `0.5.0`
- Codex Rust `1.95.0`
- native V8 Rust compiler `1.96.0`, paired with Chromium's exact vendored
  stdlib source snapshot `4c4205163abcbd08948b3efab796c543ba1ea687-4`

## Isolation from the host system

Run the repository from a user-owned directory with enough free space. All
downloaded packages, extracted compilers, Rust installations, sysroots, native
libraries, source trees, and build outputs stay below `toolchains/`, `work/`,
and `artifacts/` in this repository. The setup flow uses `apt-get download` and
`dpkg-deb -x`; it does not run `sudo`, install a system package, or modify
`/usr`, `/opt`, the system Rust installation, or the system dynamic loader.

The only host commands assumed by the setup flow are common download/archive
tools plus `gcc`, `make`, `python3`, `protoc`, and `dpkg-deb`. The locally extracted
toolchain then supplies Clang/LLD 20, GN, Ninja, Node.js, ccache, pkgconf, musl,
libcap, Rust, and Cargo.

## Build flow

```bash
scripts/setup-local-toolchains.sh
scripts/fetch-sources.sh
scripts/apply-patches.sh
scripts/build-codex-loongarch64.sh
scripts/build-ripgrep-loongarch64.sh
scripts/package-release.sh
```

The steps do the following:

1. Build an isolated static-musl compiler/sysroot environment under
   `toolchains/`.
2. Fetch the pinned Codex, `rusty_v8`, `seccompiler`, and Cargo Git sources.
3. Apply the LoongArch64 landlock/seccomp patches, prefer the host `PROTOC`
   binary where the vendored protoc crate has no LoongArch64 payload, apply the
   `rusty_v8` source build patches, then use local Cargo path overrides.
4. Build a static bubblewrap resource, embed its SHA-256 digest in Codex, then
   build `codex` and its required `codex-code-mode-host` companion in one Cargo
   invocation using target-only `+crt-static`, `-static`, medium code model,
   and LLD flags.
5. Build static ripgrep and create both bare-binary and canonical package
   archives.

## Why `rusty_v8` needs patches

`rusty_v8` does not publish a LoongArch64 prebuilt archive. Building V8 from
source also exposes Chromium assumptions that are absent from the upstream
LoongArch64 path: a usable GN Clang toolchain label, target-specific unsupported
Clang flags, musl target selection, and an externally supplied native Rust
toolchain. Chromium's generated GN rules additionally name files from its exact
vendored Rust stdlib snapshot; the ordinary `rust-src` component is not a safe
substitute. Setup therefore verifies and extracts only that architecture-neutral
source tree from Chromium's checksummed Linux archive, combines it with a native
LoongArch64 Rust 1.96 compiler under `toolchains/`, and never executes the
archive's x86_64 binaries. The patches in `patches/rusty_v8/150.4.0/` address
only these build-plumbing gaps.

The `codex` entrypoint does not directly link V8, but a complete `0.153.2`
package must also contain `codex-code-mode-host`, whose Code Mode runtime does
depend on `rusty_v8`. Building only `codex` can pass ordinary CLI smoke tests
while still failing as soon as Code Mode is enabled. Release builds therefore
compile, package, and verify the entrypoint and host as one group.

## Expected outputs

- Unstripped build binary:
  `work/build/target-codex-0.153.2/loongarch64-unknown-linux-musl/release/codex`
- Unstripped Code Mode host: the adjacent `codex-code-mode-host` file
- Static bubblewrap resource: the adjacent `bwrap` file
- Static ripgrep: `toolchains/ripgrep/bin/rg`
- Stripped release assets: `artifacts/v0.153.2/`

`scripts/package-release.sh` rejects `codex`, the Code Mode host, ripgrep, or
bubblewrap if any contains an ELF interpreter or dynamic `NEEDED` dependency.
It then extracts the archive into a temporary directory, checks the canonical
layout, and exercises the host through a real IPC handshake, session creation,
JavaScript execution, and session shutdown.

## Useful overrides

All important directories and versions can be overridden without editing the
scripts, including `TOOLCHAIN_ROOT`, `WORK_ROOT`, `ARTIFACTS_ROOT`,
`MUSL_SYSROOT`, `STABLE_TOOLCHAIN`, `V8_RUST_TOOLCHAIN`, `V8_RUST_SYSROOT`,
`NIGHTLY_SYSROOT`, and `RIPGREP_VERSION`. The defaults are the pinned,
repository-local configuration documented above.
