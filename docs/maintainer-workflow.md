# Maintainer Workflow

## What should be committed

Commit these categories:

- repository-level docs
- build scripts
- packaging scripts
- reusable patch files
- release templates
- stable metadata files such as `VERSION.txt`

## What should not be committed

Do not commit these categories:

- `work/` contents
- generated release payloads under `artifacts/v*/`
- locally generated build caches
- machine-private notes
- local-only upstreaming drafts that are kept in `.git/info/exclude`

## Local-only files currently excluded

These are intentionally kept private on the current machine via
`.git/info/exclude` and are not meant to be committed:

- `docs/upstreaming.md`
- `docs/upstreaming.zh-CN.md`

If another maintainer wants their own local-only notes, they should also use
`.git/info/exclude` rather than changing `.gitignore`.

## Recommended commit split

To keep history readable, use small themed commits.

Suggested order:

1. `docs: redesign repository readmes and build/release docs`
2. `build: add LoongArch source-build and patch application scripts`
3. `release: add packaging scripts and release templates`
4. `patches: add codex, seccompiler, and rusty_v8 patch set`

## Before committing

Run:

```bash
git status --short --untracked-files=all
```

Check that:

- `artifacts/v*/` is not listed
- `work/` is not listed
- local-only upstreaming docs are not listed
- only docs, scripts, patches, and stable metadata remain

## Before tagging a release

1. Rebuild with `scripts/build-codex-loongarch64.sh`
2. Regenerate assets with `scripts/package-release.sh`
3. Upload assets from `artifacts/v<version>/`
4. Do not commit the generated binaries or archives into git history
