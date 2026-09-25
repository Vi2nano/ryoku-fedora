#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=0

run() {
  if (( DRY_RUN )); then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

usage() {
  echo "Usage: $(basename "$0") [--dry-run]"
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
TARGET_CONFIG_DIR="${XDG_CONFIG_HOME}/ryoku-fedora"
TARGET_BIN_DIR="${XDG_DATA_HOME}/ryoku-fedora/bin"
TARGET_SESSION_DIR="${XDG_DATA_HOME}/wayland-sessions"

run mkdir -p "$TARGET_CONFIG_DIR" "$TARGET_BIN_DIR" "$TARGET_SESSION_DIR"
run rm -rf "$TARGET_CONFIG_DIR/hypr" "$TARGET_CONFIG_DIR/theme" "$TARGET_CONFIG_DIR/shell"
run cp -a "$REPO_ROOT/ryoku/hypr" "$TARGET_CONFIG_DIR/"
run cp -a "$REPO_ROOT/ryoku/theme" "$TARGET_CONFIG_DIR/"
run cp -a "$REPO_ROOT/ryoku/shell" "$TARGET_CONFIG_DIR/"
run cp -a "$REPO_ROOT/ryoku/session/session-start.sh" "$TARGET_BIN_DIR/session-start.sh"
run cp -a "$REPO_ROOT/ryoku/session/session-launch.sh" "$TARGET_BIN_DIR/session-launch.sh"
run chmod +x "$TARGET_BIN_DIR/session-start.sh"
run chmod +x "$TARGET_BIN_DIR/session-launch.sh"
run cp -a "$REPO_ROOT/ryoku/session/ryoku-fedora.desktop" "$TARGET_SESSION_DIR/ryoku-fedora.desktop"
