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

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ryoku-fedora"
mkdir -p "$state_dir"
startup_log="${state_dir}/session-start.log"

start_if_missing() {
  local match="$1"
  local label="$2"
  shift
  shift
  pgrep -u "$USER" -f "$match" >/dev/null 2>&1 && return 0
  "$@" >>"$startup_log" 2>&1 &
  sleep 0.2
  if ! pgrep -u "$USER" -f "$match" >/dev/null 2>&1; then
    printf '[warn] failed to start %s\n' "$label" >>"$startup_log"
  fi
}

if command -v mako >/dev/null 2>&1; then
  start_if_missing '^mako($| )' mako mako --config "$HOME/.config/ryoku-fedora/mako/config"
fi

if command -v waybar >/dev/null 2>&1; then
  start_if_missing '^waybar($| )' waybar waybar -c "$HOME/.config/ryoku-fedora/waybar/config.jsonc" -s "$HOME/.config/ryoku-fedora/waybar/style.css"
fi

if command -v nm-applet >/dev/null 2>&1; then
  start_if_missing '^nm-applet($| )' nm-applet nm-applet --indicator
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
