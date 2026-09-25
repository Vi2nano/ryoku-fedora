#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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
  local hypr_dir="${xdg_config}/hypr"
  local target_hypr_main="${hypr_dir}/hyprland.conf"
  local target_hypr_include="${hypr_dir}/ryoku-fedora.conf"
  local include_line="source = ~/.config/hypr/ryoku-fedora.conf"
  local expected_include_target="${target_cfg}/hypr/hyprland.conf"
  local target_data="${xdg_data}/ryoku-fedora"
  local target_session_dir="${xdg_data}/wayland-sessions"
  local target_session="${target_session_dir}/ryoku-fedora.desktop"

  run mkdir -p "$hypr_dir" "$target_session_dir"

  backup_file "$target_session"

  local materialize_args=()
  (( DRY_RUN )) && materialize_args+=("--dry-run")
  "$SCRIPT_DIR/materialize.sh" "${materialize_args[@]}"

  install_user_overrides_file "$hypr_dir"

  if [[ -L "$target_hypr_include" ]]; then
    local link_target
    link_target="$(readlink "$target_hypr_include" || true)"
    if [[ "$link_target" != "$expected_include_target" ]]; then
      backup_file "$target_hypr_include"
      run ln -sfn "$expected_include_target" "$target_hypr_include"
    fi
  else
    backup_file "$target_hypr_include"
    run ln -sfn "$expected_include_target" "$target_hypr_include"
  fi

  if [[ -f "$target_hypr_main" ]]; then
    if ! grep -Fxq "$include_line" "$target_hypr_main"; then
      backup_file "$target_hypr_main"
      if (( DRY_RUN )); then
        echo "[DRY-RUN] append include to $target_hypr_main"
      else
        printf '\n%s\n' "$include_line" >> "$target_hypr_main"
      fi
    fi
  else
    if (( DRY_RUN )); then
      echo "[DRY-RUN] create $target_hypr_main"
    else
      cat > "$target_hypr_main" <<EOF
$include_line
EOF
    fi
  fi
}

remove_installation() {
  local xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"
  local xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"

  local target_cfg="${xdg_config}/ryoku-fedora"
  local hypr_dir="${xdg_config}/hypr"
  local target_hypr_main="${hypr_dir}/hyprland.conf"
  local target_hypr_include="${hypr_dir}/ryoku-fedora.conf"
  local include_line="source = ~/.config/hypr/ryoku-fedora.conf"
  local target_data="${xdg_data}/ryoku-fedora"
  local target_session="${xdg_data}/wayland-sessions/ryoku-fedora.desktop"

  if [[ -L "$target_hypr_include" ]]; then
    run rm -f "$target_hypr_include"
  fi

  if [[ -f "$target_hypr_main" ]] && grep -Fxq "$include_line" "$target_hypr_main"; then
    backup_file "$target_hypr_main"
    if (( DRY_RUN )); then
      echo "[DRY-RUN] remove include from $target_hypr_main"
    else
      sed -i '\|^source = ~/.config/hypr/ryoku-fedora\.conf$|d' "$target_hypr_main"
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
