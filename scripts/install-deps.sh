#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REQUIRED_MANIFEST="${REPO_ROOT}/fedora/packages-required.txt"
OPTIONAL_MANIFEST="${REPO_ROOT}/fedora/packages-optional.txt"

DRY_RUN=0
INCLUDE_OPTIONAL=0

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--dry-run] [--with-optional]

Install Fedora package manifests using dnf5 when available and dnf fallback.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --with-optional) INCLUDE_OPTIONAL=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if command -v dnf5 >/dev/null 2>&1; then
  DNF_BIN="dnf5"
elif command -v dnf >/dev/null 2>&1; then
  DNF_BIN="dnf"
else
  echo "Neither dnf5 nor dnf found." >&2
  exit 1
fi

if [[ ! -f "$REQUIRED_MANIFEST" ]]; then
  echo "Missing manifest: $REQUIRED_MANIFEST" >&2
  exit 1
fi

mapfile -t REQUIRED_PACKAGES < <(grep -Ev '^(#|$)' "$REQUIRED_MANIFEST")
OPTIONAL_PACKAGES=()
if (( INCLUDE_OPTIONAL )); then
  if [[ ! -f "$OPTIONAL_MANIFEST" ]]; then
    echo "Missing optional manifest: $OPTIONAL_MANIFEST" >&2
    exit 1
  fi
  mapfile -t OPTIONAL_PACKAGES < <(grep -Ev '^(#|$)' "$OPTIONAL_MANIFEST")
fi

if (( INCLUDE_OPTIONAL )); then
  PACKAGES=("${REQUIRED_PACKAGES[@]}" "${OPTIONAL_PACKAGES[@]}")
else
  PACKAGES=("${REQUIRED_PACKAGES[@]}")
fi

if (( ${#PACKAGES[@]} == 0 )); then
  echo "No packages to install." >&2
  exit 1
fi

CMD=(sudo "$DNF_BIN" install -y "${PACKAGES[@]}")
if (( DRY_RUN )); then
  echo "[DRY-RUN] ${CMD[*]}"
  exit 0
fi

"${CMD[@]}"
