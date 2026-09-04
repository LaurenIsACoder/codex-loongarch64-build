# Upload Checklist

## Before uploading

- [ ] `scripts/build-codex-loongarch64.sh` completed successfully
- [ ] `scripts/build-ripgrep-loongarch64.sh` completed successfully
- [ ] `scripts/package-release.sh` completed successfully
- [ ] `artifacts/v0.153.2/` contains all expected release files
- [ ] `SHA256SUMS` and `codex-package_SHA256SUMS` are regenerated
- [ ] `VERSION.txt` matches the built binary version
- [ ] `ldd.txt` was generated from the same binary being released
- [ ] `codex --version` reports `codex-cli 0.153.2`
- [ ] Code Mode IPC/JavaScript smoke test passed
- [ ] packaged sandbox smoke test passed
- [ ] all four packaged executables have no ELF interpreter or dynamic `NEEDED` entry

## Suggested release payload

- [ ] `codex-loongarch64-unknown-linux-musl`
- [ ] `codex-loongarch64-unknown-linux-musl.tar.gz`
- [ ] `codex-code-mode-host-loongarch64-unknown-linux-musl`
- [ ] `codex-code-mode-host-loongarch64-unknown-linux-musl.tar.gz`
- [ ] `codex-package-loongarch64-unknown-linux-musl.tar.gz`
- [ ] `codex-package_SHA256SUMS`
- [ ] `SHA256SUMS`
- [ ] `install-system.sh`
- [ ] `VERSION.txt`
- [ ] `ldd.txt`
- [ ] `README.md`
- [ ] `README.zh-CN.md`
