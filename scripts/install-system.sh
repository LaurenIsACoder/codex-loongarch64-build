#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG=${CODEX_LOONGARCH_REPO:-LaurenIsACoder/codex-loongarch64-build}
RELEASE=${CODEX_RELEASE:-latest}
INSTALL_ROOT=${CODEX_INSTALL_ROOT:-/opt/codex-loongarch64}
BIN_LINK=${CODEX_BIN_LINK:-/usr/local/bin/codex}
FORCE=${CODEX_FORCE_INSTALL:-0}
PROXY=${CODEX_PROXY:-}

PACKAGE_ASSET=codex-package-loongarch64-unknown-linux-gnu.tar.gz
CHECKSUM_ASSET=codex-package_SHA256SUMS

tmp_dir=""

step() {
  printf '==> %s
' "$1"
}

fail() {
  printf 'ERROR: %s
' "$1" >&2
  exit 1
}

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    fail "Please run this installer as root, for example: curl -fsSL <url> | sudo bash"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

normalize_release() {
  case "$1" in
    ''|latest)
      printf 'latest
'
      ;;
    v*)
      printf '%s
' "$1"
      ;;
    *)
      printf 'v%s
' "$1"
      ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --release)
        [[ $# -ge 2 ]] || fail "--release requires a value"
        RELEASE="$2"
        shift 2
        ;;
      --install-root)
        [[ $# -ge 2 ]] || fail "--install-root requires a value"
        INSTALL_ROOT="$2"
        shift 2
        ;;
      --bin-link)
        [[ $# -ge 2 ]] || fail "--bin-link requires a value"
        BIN_LINK="$2"
        shift 2
        ;;
      --repo)
        [[ $# -ge 2 ]] || fail "--repo requires a value"
        REPO_SLUG="$2"
        shift 2
        ;;
      --proxy)
        [[ $# -ge 2 ]] || fail "--proxy requires a value"
        PROXY="$2"
        shift 2
        ;;
      --force)
        FORCE=1
        shift
        ;;
      -h|--help)
        cat <<EOF
Usage: install-system.sh [--release TAG] [--install-root DIR] [--bin-link PATH] [--repo OWNER/REPO] [--proxy URL] [--force]

Options:
  --release TAG       Install a specific GitHub release tag
  --install-root DIR  Installation directory (default: /opt/codex-loongarch64)
  --bin-link PATH     Symlink path for the codex command (default: /usr/local/bin/codex)
  --repo OWNER/REPO   GitHub repository slug (default: LaurenIsACoder/codex-loongarch64-build)
  --proxy URL         HTTP(S) proxy for curl, e.g. http://proxy:8080
  --force             Overwrite existing installation

Note on proxy:
  When running behind a firewall, use --proxy to pass proxy settings.
  Environment variables (http_proxy, https_proxy, all_proxy) are also
  respected if preserved via sudo -E or configured in sudoers.

Examples:
  curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash
  curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo bash -s -- --release v0.140.0-loongarch64.1
  curl -fsSL https://raw.githubusercontent.com/LaurenIsACoder/codex-loongarch64-build/main/scripts/install-system.sh | sudo -E bash -s -- --proxy http://proxy:8080
EOF
        exit 0
        ;;
      *)
        fail "unknown argument: $1"
        ;;
    esac
  done
}

check_host() {
  [[ $(uname -s) == Linux ]] || fail "this installer only supports Linux"
  case "$(uname -m)" in
    loongarch64|loong64) ;;
    *) fail "this installer only supports LoongArch64" ;;
  esac
}

resolve_proxy() {
  # --proxy flag takes highest priority.
  if [[ -n "${PROXY:-}" ]]; then
    printf '%s' "$PROXY"
    return
  fi
  # Fall back to environment variables (may not survive sudo without -E).
  if [[ -n "${https_proxy:-}" ]]; then
    printf '%s' "$https_proxy"
  elif [[ -n "${http_proxy:-}" ]]; then
    printf '%s' "$http_proxy"
  elif [[ -n "${all_proxy:-}" ]]; then
    printf '%s' "$all_proxy"
  fi
}

curl_with_proxy() {
  local proxy
  proxy="$(resolve_proxy)"
  if [[ -n "$proxy" ]]; then
    curl --proxy "$proxy" "$@"
  else
    curl "$@"
  fi
}

latest_release_tag() {
  local url
  url=$(curl_with_proxy -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/$REPO_SLUG/releases/latest")
  [[ -n "$url" ]] || fail "unable to resolve latest release URL"
  basename "$url"
}

release_tag() {
  local requested
  requested=$(normalize_release "$RELEASE")
  if [[ "$requested" == latest ]]; then
    latest_release_tag
  else
    printf '%s
' "$requested"
  fi
}

download_asset() {
  local tag="$1"
  local asset="$2"
  local out="$3"
  curl_with_proxy -fL "https://github.com/$REPO_SLUG/releases/download/$tag/$asset" -o "$out"
}

cleanup() {
  if [[ -n "${tmp_dir:-}" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

main() {
  parse_args "$@"
  require_root
  check_host
  require_cmd curl
  require_cmd tar
  require_cmd sha256sum
  require_cmd ln
  require_cmd install

  local tag release_dir current_link
  tag=$(release_tag)
  release_dir="$INSTALL_ROOT/releases/$tag"
  current_link="$INSTALL_ROOT/current"
  tmp_dir=$(mktemp -d)
  trap cleanup EXIT

  step "Installing Codex LoongArch64 release $tag"
  step "Downloading release assets"
  download_asset "$tag" "$PACKAGE_ASSET" "$tmp_dir/$PACKAGE_ASSET"
  download_asset "$tag" "$CHECKSUM_ASSET" "$tmp_dir/$CHECKSUM_ASSET"

  step "Verifying package checksum"
  (cd "$tmp_dir" && sha256sum -c "$CHECKSUM_ASSET")

  mkdir -p "$INSTALL_ROOT/releases"
  if [[ -d "$release_dir" ]]; then
    if [[ "$FORCE" == 1 ]]; then
      rm -rf "$release_dir"
    else
      step "Release already exists at $release_dir; reusing it"
    fi
  fi

  if [[ ! -d "$release_dir" ]]; then
    mkdir -p "$release_dir"
    step "Extracting package to $release_dir"
    tar -xzf "$tmp_dir/$PACKAGE_ASSET" -C "$release_dir"
  fi

  ln -sfn "$release_dir" "$current_link"
  mkdir -p "$(dirname "$BIN_LINK")"
  ln -sfn "$current_link/bin/codex" "$BIN_LINK"

  step "Installed binary"
  "$BIN_LINK" --version

  cat <<EOF
Installed system-wide:
  package root: $release_dir
  current link: $current_link
  command path: $BIN_LINK

You can now run:
  codex --version
  codex

Project repository:
  https://github.com/LaurenIsACoder/codex-loongarch64-build
EOF
}

main "$@"
