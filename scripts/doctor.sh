#!/usr/bin/env bash
set -euo pipefail

required_cmds=(bash grep sed awk)
required_files=(
  "fedora/packages-required.txt"
  "ryoku/hypr/hyprland.conf"
  "ryoku/bin/ryoku-app"
  "scripts/install.sh"
  "scripts/install-deps.sh"
)
runtime_cmds=(hyprland waybar wofi mako nm-applet)

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

status=0

if [[ -f /etc/os-release ]] && grep -q '^ID=fedora$' /etc/os-release; then
  echo "[ok] Fedora detected"
else
  echo "[warn] Non-Fedora environment detected"
fi

if [[ "$(uname -m)" == "x86_64" ]]; then
  echo "[ok] x86_64 architecture"
else
  echo "[warn] non-x86_64 architecture"
fi

for cmd in "${required_cmds[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[ok] command found: $cmd"
  else
    echo "[error] missing command: $cmd"
    status=1
  fi
done

for rel in "${required_files[@]}"; do
  if [[ -f "$REPO_ROOT/$rel" ]]; then
    echo "[ok] file present: $rel"
  else
    echo "[error] missing file: $rel"
    status=1
  fi
done

for cmd in "${runtime_cmds[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[ok] runtime command found: $cmd"
  else
    echo "[warn] runtime command missing (install dependencies first): $cmd"
  fi
done

if grep -Eq '(pacman|yay|pacstrap|limine)' "$REPO_ROOT/ryoku/hypr/hyprland.conf"; then
  echo "[error] hyprland.conf contains arch-only command tokens"
  status=1
else
  echo "[ok] hyprland.conf is free of arch-only command tokens"
fi

exit "$status"
