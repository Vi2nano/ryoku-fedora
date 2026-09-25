#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=0
DO_UNINSTALL=0
WITH_OPTIONAL=0

usage() {
  cat <<USAGE
Usage: $(basename "$0") [--dry-run] [--uninstall] [--with-optional]
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --uninstall) DO_UNINSTALL=1 ;;
    --with-optional) WITH_OPTIONAL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

run() {
  if (( DRY_RUN )); then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

log() {
  printf '%s\n' "$*"
}

is_fedora() {
  local os_release_path="${RYOKU_OS_RELEASE_PATH:-/etc/os-release}"
  [[ -f "$os_release_path" ]] && grep -q '^ID=fedora$' "$os_release_path"
}

require_platform() {
  if ! is_fedora; then
    echo "This installer currently supports Fedora only." >&2
    exit 1
  fi

  if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "Only x86_64 is supported at this stage." >&2
    exit 1
  fi

  if [[ "${EUID}" -eq 0 ]]; then
    echo "Run as a regular user; sudo will be used when required." >&2
    exit 1
  fi
}

backup_file() {
  local path="$1"
  if [[ -e "$path" ]]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    run cp -a "$path" "${path}.ryoku-fedora.bak.${stamp}"
  fi
}

install_user_overrides_file() {
  local hypr_dir="$1"
  local overrides_file="${hypr_dir}/ryoku-user-overrides.conf"
  if [[ ! -f "$overrides_file" ]]; then
    run mkdir -p "$hypr_dir"
    if (( DRY_RUN )); then
      echo "[DRY-RUN] create $overrides_file"
    else
      cat > "$overrides_file" <<'OVERRIDES'
# User overrides for ryoku-fedora Hyprland integration
# Example monitor line:
# monitor = ,preferred,auto,1
OVERRIDES
    fi
  fi
}

deploy() {
  local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
  local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"

  local target_cfg="${xdg_config}/ryoku-fedora"
  local target_hypr="${xdg_config}/hypr/hyprland.conf"
  local target_data="${xdg_data}/ryoku-fedora"
  local target_session_dir="${xdg_data}/wayland-sessions"
  local target_session="${target_session_dir}/ryoku-fedora.desktop"

  run mkdir -p "$target_cfg" "$target_data/bin" "$target_session_dir"

  backup_file "$target_hypr"
  backup_file "$target_session"

  run cp -a "$REPO_ROOT/ryoku/hypr" "$target_cfg/"
  run cp -a "$REPO_ROOT/ryoku/theme" "$target_cfg/"
  run cp -a "$REPO_ROOT/ryoku/shell" "$target_cfg/"

  run cp -a "$REPO_ROOT/ryoku/session/session-start.sh" "$target_data/bin/session-start.sh"
  run chmod +x "$target_data/bin/session-start.sh"

  run cp -a "$REPO_ROOT/ryoku/session/ryoku-fedora.desktop" "$target_session"

  install_user_overrides_file "${xdg_config}/hypr"

  if [[ ! -L "$target_hypr" ]]; then
    backup_file "$target_hypr"
    run ln -sfn "$target_cfg/hypr/hyprland.conf" "$target_hypr"
  fi
}

remove_installation() {
  local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
  local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"

  local target_cfg="${xdg_config}/ryoku-fedora"
  local target_hypr="${xdg_config}/hypr/hyprland.conf"
  local target_data="${xdg_data}/ryoku-fedora"
  local target_session="${xdg_data}/wayland-sessions/ryoku-fedora.desktop"

  if [[ -L "$target_hypr" ]]; then
    local link_target
    link_target="$(readlink "$target_hypr" || true)"
    if [[ "$link_target" == *"/ryoku-fedora/hypr/hyprland.conf" ]]; then
      run rm -f "$target_hypr"
    fi
  fi

  run rm -f "$target_session"
  run rm -rf "$target_data"
  run rm -rf "$target_cfg"
}

main() {
  require_platform

  if (( DO_UNINSTALL )); then
    log "Uninstalling ryoku-fedora user-space layer"
    remove_installation
    return 0
  fi

  local dep_cmd=("$SCRIPT_DIR/install-deps.sh")
  (( DRY_RUN )) && dep_cmd+=("--dry-run")
  (( WITH_OPTIONAL )) && dep_cmd+=("--with-optional")

  "${dep_cmd[@]}"
  deploy

  log "Install completed. Re-login and choose 'Ryoku Fedora (Hyprland)' if your display manager exposes user wayland sessions."
}

main "$@"
