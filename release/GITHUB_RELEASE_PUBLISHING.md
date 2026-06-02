# GitHub Release Publishing

Repository:

- `git@github.com:LaurenIsACoder/codex-loongarch64-build.git`

Current release tag:

- `v0.135.0-loongarch64.1`

Artifacts directory:

- `artifacts/v0.135.0/`

## 1. Push commits and tag

```bash
cd ~/AI/codex-loongarch64-build-repo
git push origin main
git push origin v0.135.0-loongarch64.1
```

## 2. Release title

Recommended title:

```text
Codex CLI 0.135.0 for LoongArch64 Linux
```

## 3. Release body

Use:

- `release/RELEASE_NOTES_v0.135.0-loongarch64.1.md`

or start from:

- `release/RELEASE_NOTES_TEMPLATE.md`

## 4. Upload these assets

From `artifacts/v0.135.0/` upload:

- `codex-loongarch64-unknown-linux-gnu`
- `codex-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
- `codex-package_SHA256SUMS`
- `SHA256SUMS`
- `install-system.sh`
- `VERSION.txt`
- `ldd.txt`

Optional:

- `README.md`
- `README.zh-CN.md`

## 5. Recommended asset description order

1. `codex-package-loongarch64-unknown-linux-gnu.tar.gz`
   Recommended package-style install target for most users.
2. `install-system.sh`
   One-click system-wide installer.
3. `codex-loongarch64-unknown-linux-gnu.tar.gz`
   Direct binary tarball for advanced/manual installs.
4. `codex-loongarch64-unknown-linux-gnu`
   Raw binary only.
5. `codex-package_SHA256SUMS`
6. `SHA256SUMS`
7. `VERSION.txt`
8. `ldd.txt`

## 6. Recommended install command to publish in the release page

Latest release:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
```

Specific release:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.135.0-loongarch64.1
```

## 7. Manual upload checklist

- [ ] `git push origin main`
- [ ] `git push origin v0.135.0-loongarch64.1`
- [ ] create GitHub Release from tag `v0.135.0-loongarch64.1`
- [ ] paste `release/RELEASE_NOTES_v0.135.0-loongarch64.1.md`
- [ ] upload all required assets from `artifacts/v0.135.0/`
- [ ] verify `install-system.sh` is attached
- [ ] verify `codex-package-loongarch64-unknown-linux-gnu.tar.gz` is attached
- [ ] verify `SHA256SUMS` and `codex-package_SHA256SUMS` are attached

## 8. Post-release smoke test

On a LoongArch64 target machine:

```bash
curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.135.0-loongarch64.1
codex --version
codex --help
```
