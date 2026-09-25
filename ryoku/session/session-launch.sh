#!/usr/bin/env bash
set -euo pipefail

session_start="$HOME/.local/share/ryoku-fedora/bin/session-start.sh"

if [[ -x "$session_start" ]]; then
  "$session_start" &
fi

exec Hyprland
