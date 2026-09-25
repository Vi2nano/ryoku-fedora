#!/usr/bin/env bash
set -euo pipefail

wait_for_service() {
  local service="$1"
  local tries="${2:-25}"
  local delay="${3:-0.2}"

  for _ in $(seq 1 "$tries"); do
    if systemctl --user is-active --quiet "$service"; then
      return 0
    fi
    sleep "$delay"
  done

  return 1
}

wait_for_service pipewire.service || true
wait_for_service wireplumber.service || true
wait_for_service xdg-desktop-portal.service || true

if pgrep -u "$USER" -f 'quickshell .*ryoku-fedora' >/dev/null 2>&1; then
  exit 0
fi

if command -v quickshell >/dev/null 2>&1; then
  exec quickshell --path "$HOME/.config/ryoku-fedora/shell/main.qml" --identifier ryoku-fedora
fi

if command -v makoctl >/dev/null 2>&1; then
  makoctl dismiss --all >/dev/null 2>&1 || true
fi
