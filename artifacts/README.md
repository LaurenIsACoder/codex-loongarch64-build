# Generated Release Assets

This directory is for generated release assets only.

Expected pattern:

- `artifacts/v0.135.0/...`

Large binaries and archives under versioned subdirectories are intentionally
ignored by git. Generate them with `scripts/package-release.sh` and upload them
as GitHub release assets instead of committing them into repository history.
