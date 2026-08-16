#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

require_cmd tar
require_cmd file
require_cmd readelf
require_cmd python3

archive=${1:-$ARTIFACTS_ROOT/codex-package-${TARGET_TRIPLE}.tar.gz}
[[ -f "$archive" ]] || { echo "missing package archive: $archive" >&2; exit 1; }

listing=$(tar -tzf "$archive")
if awk 'BEGIN { bad = 0 } /(^\/|(^|\/)\.\.($|\/))/ { print; bad = 1 } END { exit bad ? 0 : 1 }' <<<"$listing"; then
  echo "package archive contains an unsafe path" >&2
  exit 1
fi

required_entries=(
  bin/codex
  bin/codex-code-mode-host
  codex-path/rg
  codex-resources/bwrap
  codex-package.json
)
for entry in "${required_entries[@]}"; do
  grep -Fxq "$entry" <<<"$listing" || {
    echo "package archive is missing $entry" >&2
    exit 1
  }
done

mkdir -p "$WORK_ROOT"
verify_root=$(mktemp -d "$WORK_ROOT/verify-release.XXXXXX")
cleanup() {
  rm -rf "$verify_root"
}
trap cleanup EXIT
tar -xzf "$archive" -C "$verify_root"

verify_static_elf() {
  local binary=$1
  [[ -f "$binary" && -x "$binary" ]] || {
    echo "package entry is not an executable regular file: $binary" >&2
    exit 1
  }
  file "$binary" | grep -q 'statically linked' || {
    echo "expected a statically linked ELF binary: $binary" >&2
    file "$binary" >&2
    exit 1
  }
  if readelf -lW "$binary" | grep -q ' INTERP '; then
    echo "unexpected ELF interpreter in $binary" >&2
    exit 1
  fi
  if readelf -dW "$binary" 2>/dev/null | grep -q '(NEEDED)'; then
    echo "unexpected dynamic dependency in $binary" >&2
    exit 1
  fi
}

verify_static_elf "$verify_root/bin/codex"
verify_static_elf "$verify_root/bin/codex-code-mode-host"
verify_static_elf "$verify_root/codex-path/rg"
verify_static_elf "$verify_root/codex-resources/bwrap"

python3 - "$verify_root/codex-package.json" "$TARGET_TRIPLE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as package_file:
    package = json.load(package_file)

expected = {
    "layoutVersion": 1,
    "target": sys.argv[2],
    "variant": "codex",
    "entrypoint": "bin/codex",
    "resourcesDir": "codex-resources",
    "pathDir": "codex-path",
}
for key, value in expected.items():
    if package.get(key) != value:
        raise SystemExit(f"unexpected codex-package.json {key}: {package.get(key)!r}")
if not package.get("version"):
    raise SystemExit("codex-package.json has no version")
PY

"$verify_root/bin/codex" --version
"$verify_root/bin/codex-code-mode-host" --help >/dev/null
"$verify_root/codex-path/rg" --version >/dev/null
"$verify_root/codex-resources/bwrap" --version >/dev/null
python3 "$REPO_ROOT/scripts/smoke-code-mode-host.py" \
  "$verify_root/bin/codex-code-mode-host"

log "Release package verification passed: $archive"
