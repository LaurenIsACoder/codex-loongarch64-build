# Build Guide

## Scope

This guide covers the reproducible, fully static
`loongarch64-unknown-linux-musl` build of Codex CLI `0.147.0` on a native
LoongArch64 Linux host. The pinned upstream inputs are:

- Codex tag `rust-v0.147.0`
- `rusty_v8` tag `v150.4.0`
- `seccompiler` crate `0.5.0`
- Rust `1.95.0`

## Isolation from the host system

Run the repository from a user-owned directory with enough free space. All
downloaded packages, extracted compilers, Rust installations, sysroots, native
libraries, source trees, and build outputs stay below `toolchains/`, `work/`,
and `artifacts/` in this repository. The setup flow uses `apt-get download` and
`dpkg-deb -x`; it does not run `sudo`, install a system package, or modify
`/usr`, `/opt`, the system Rust installation, or the system dynamic loader.

The only host commands assumed by the setup flow are common download/archive
tools plus `gcc`, `make`, `python3`, and `dpkg-deb`. The locally extracted
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
3. Apply the LoongArch64 landlock/seccomp patches and the `rusty_v8` source
   build patches, then use local Cargo path overrides.
4. Build a static bubblewrap resource, embed its SHA-256 digest in Codex, and
   link Codex using target-only `+crt-static`, `-static`, medium code model, and
   LLD flags.
5. Build static ripgrep and create both bare-binary and canonical package
   archives.

## Why `rusty_v8` needs patches

`rusty_v8` does not publish a LoongArch64 prebuilt archive. Building V8 from
source also exposes Chromium assumptions that are absent from the upstream
LoongArch64 path: a usable GN Clang toolchain label, target-specific unsupported
Clang flags, musl target selection, and an externally supplied native Rust
toolchain. The patches in `patches/rusty_v8/150.4.0/` address only these build
plumbing gaps.

The `0.147.0` `codex-cli` dependency graph does not include the standalone
`codex-v8-poc` workspace crate, so the default CLI build does not compile or
link V8. The patch set is prepared for that optional component and should not
be mistaken for a validation requirement of the CLI artifact.

## Expected outputs

- Unstripped build binary:
  `work/build/target-codex-0.147.0/loongarch64-unknown-linux-musl/release/codex`
- Static bubblewrap resource: the adjacent `bwrap` file
- Static ripgrep: `toolchains/ripgrep/bin/rg`
- Stripped release assets: `artifacts/v0.147.0/`

`scripts/package-release.sh` rejects any of the three packaged executables if
it contains an ELF interpreter or a dynamic `NEEDED` dependency.

## Useful overrides

All important directories and versions can be overridden without editing the
scripts, including `TOOLCHAIN_ROOT`, `WORK_ROOT`, `ARTIFACTS_ROOT`,
`MUSL_SYSROOT`, `STABLE_TOOLCHAIN`, `NIGHTLY_SYSROOT`, and `RIPGREP_VERSION`.
The defaults are the pinned, repository-local configuration documented above.
