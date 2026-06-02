# Upload Checklist

## Before uploading

- [ ] `scripts/build-codex-loongarch64.sh` completed successfully
- [ ] `scripts/package-release.sh` completed successfully
- [ ] `artifacts/v0.135.0/` contains all expected release files
- [ ] `SHA256SUMS` and `codex-package_SHA256SUMS` are regenerated
- [ ] `VERSION.txt` matches the built binary version
- [ ] `ldd.txt` was generated from the same binary being released
- [ ] `codex --version` reports `codex-cli 0.135.0`

## Suggested release payload

- [ ] `codex-loongarch64-unknown-linux-gnu`
- [ ] `codex-loongarch64-unknown-linux-gnu.tar.gz`
- [ ] `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- [ ] `codex-package_SHA256SUMS`
- [ ] `SHA256SUMS`
- [ ] `VERSION.txt`
- [ ] `ldd.txt`
