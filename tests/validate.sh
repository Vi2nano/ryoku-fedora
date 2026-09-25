#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

required_files=(
  "README.md"
  "NOTICE"
  "fedora/packages-required.txt"
  "fedora/packages-optional.txt"
  "ryoku/hypr/hyprland.conf"
  "ryoku/session/ryoku-fedora.desktop"
  "scripts/install.sh"
  "scripts/update.sh"
  "scripts/doctor.sh"
  "scripts/materialize.sh"
)

for rel in "${required_files[@]}"; do
  [[ -f "$REPO_ROOT/$rel" ]] || { echo "missing file: $rel" >&2; exit 1; }
done

required_pkgs=(hyprland xdg-desktop-portal pipewire wireplumber mako wl-clipboard)
for pkg in "${required_pkgs[@]}"; do
  grep -qx "$pkg" "$REPO_ROOT/fedora/packages-required.txt" || {
    echo "required package missing: $pkg" >&2
    exit 1
  }
done

if grep -RIEq '(pacman|yay|pacstrap|limine)' "$REPO_ROOT/ryoku/hypr"; then
  echo "arch-only token found in hypr config" >&2
  exit 1
fi

echo "validate.sh: ok"
