#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

scripts=(
  "$REPO_ROOT/scripts/install-deps.sh"
  "$REPO_ROOT/scripts/materialize.sh"
  "$REPO_ROOT/scripts/install.sh"
  "$REPO_ROOT/scripts/update.sh"
  "$REPO_ROOT/scripts/doctor.sh"
  "$REPO_ROOT/ryoku/session/session-start.sh"
  "$REPO_ROOT/tests/run.sh"
  "$REPO_ROOT/tests/shellcheck.sh"
  "$REPO_ROOT/tests/validate.sh"
  "$REPO_ROOT/tests/dry-run.sh"
)

for file in "${scripts[@]}"; do
  bash -n "$file"
done

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${scripts[@]}"
else
  echo "shellcheck not found; skipped"
fi

echo "shellcheck.sh: ok"
