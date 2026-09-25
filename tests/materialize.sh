#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT

HOME="$tmp_home" \
XDG_CONFIG_HOME="$tmp_home/.config" \
XDG_DATA_HOME="$tmp_home/.local/share" \
  "$REPO_ROOT/scripts/materialize.sh"

assert_file() {
  local path="$1"
  [[ -f "$path" ]] || {
    echo "missing expected file: $path" >&2
    exit 1
  }
}

assert_exec() {
  local path="$1"
  [[ -x "$path" ]] || {
    echo "missing executable bit: $path" >&2
    exit 1
  }
}

assert_file "$tmp_home/.config/ryoku-fedora/hypr/hyprland.conf"
assert_file "$tmp_home/.config/ryoku-fedora/theme/palette.conf"
assert_file "$tmp_home/.config/ryoku-fedora/shell/main.qml"
assert_file "$tmp_home/.config/ryoku-fedora/waybar/config.jsonc"
assert_file "$tmp_home/.config/ryoku-fedora/waybar/style.css"
assert_file "$tmp_home/.config/ryoku-fedora/mako/config"
assert_file "$tmp_home/.config/ryoku-fedora/wofi/config"
assert_exec "$tmp_home/.local/share/ryoku-fedora/bin/session-start.sh"
assert_exec "$tmp_home/.local/share/ryoku-fedora/bin/ryoku-app"
assert_file "$tmp_home/.local/share/wayland-sessions/ryoku-fedora.desktop"

echo "stale" > "$tmp_home/.config/ryoku-fedora/waybar/stale.conf"
HOME="$tmp_home" \
XDG_CONFIG_HOME="$tmp_home/.config" \
XDG_DATA_HOME="$tmp_home/.local/share" \
  "$REPO_ROOT/scripts/materialize.sh"
[[ ! -e "$tmp_home/.config/ryoku-fedora/waybar/stale.conf" ]] || {
  echo "stale waybar file should be replaced by materialize" >&2
  exit 1
}

echo "materialize.sh test: ok"
