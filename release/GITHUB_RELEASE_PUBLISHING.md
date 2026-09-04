# GitHub Release Publishing

Repository:

- `git@github.com:LaurenIsACoder/codex-loongarch64-build.git`

Planned release tag:

- `v0.153.2-loongarch64-musl.1`

Artifacts directory:

- `artifacts/v0.153.2/`

Do not publish until the native LoongArch64 build, package verification, and
maintainer review are complete.

## Release title

```text
Codex CLI LoongArch64 Community Build v0.153.2 (static musl)
```

## Release body

Use `release/RELEASE_NOTES_v0.153.2-loongarch64-musl.1.md` after replacing any
pending validation fields with the final native results.

## Required assets

- `codex-loongarch64-unknown-linux-musl`
- `codex-loongarch64-unknown-linux-musl.tar.gz`
- `codex-code-mode-host-loongarch64-unknown-linux-musl`
- `codex-code-mode-host-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package-loongarch64-unknown-linux-musl.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `install-system.sh`
- `VERSION.txt`
- `ldd.txt`
- `README.md`
- `README.zh-CN.md`

## Publication sequence

1. Review the local commit and native validation evidence.
2. Push the reviewed commit and the `build/0.153.2-musl` branch.
3. Create the tag `v0.153.2-loongarch64-musl.1` from that reviewed commit.
4. Create a draft GitHub Release and upload all required assets.
5. Compare uploaded asset names, sizes, and SHA-256 values with the local set.
6. Publish only after the draft audit passes.
7. Re-download the public package and verify checksum, package layout, and
   native smoke tests once more.
