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

start_if_missing() {
  local match="$1"
  shift
  pgrep -u "$USER" -f "$match" >/dev/null 2>&1 && return 0
  "$@" >/dev/null 2>&1 &
}

if command -v mako >/dev/null 2>&1; then
  start_if_missing '^mako($| )' mako --config "$HOME/.config/ryoku-fedora/mako/config"
fi

if command -v waybar >/dev/null 2>&1; then
  start_if_missing '^waybar($| )' waybar -c "$HOME/.config/ryoku-fedora/waybar/config.jsonc" -s "$HOME/.config/ryoku-fedora/waybar/style.css"
fi

if command -v nm-applet >/dev/null 2>&1; then
  start_if_missing '^nm-applet($| )' nm-applet --indicator
fi

if command -v quickshell >/dev/null 2>&1; then
  if pgrep -u "$USER" -f 'quickshell .*ryoku-fedora' >/dev/null 2>&1; then
    exit 0
  fi
  exec quickshell --path "$HOME/.config/ryoku-fedora/shell/main.qml" --identifier ryoku-fedora
fi

if command -v makoctl >/dev/null 2>&1; then
  makoctl dismiss --all >/dev/null 2>&1 || true
fi
