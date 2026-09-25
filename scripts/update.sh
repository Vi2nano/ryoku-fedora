#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
WITH_OPTIONAL=0

usage() {
  echo "Usage: $(basename "$0") [--dry-run] [--with-optional]"
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --with-optional) WITH_OPTIONAL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

dep_args=()
mat_args=()
(( DRY_RUN )) && dep_args+=("--dry-run") && mat_args+=("--dry-run")
(( WITH_OPTIONAL )) && dep_args+=("--with-optional")

"$SCRIPT_DIR/install-deps.sh" "${dep_args[@]}"
"$SCRIPT_DIR/materialize.sh" "${mat_args[@]}"
