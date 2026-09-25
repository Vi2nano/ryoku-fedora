#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/shellcheck.sh"
"$SCRIPT_DIR/validate.sh"
"$SCRIPT_DIR/dry-run.sh"
