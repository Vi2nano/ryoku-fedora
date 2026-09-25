#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

required_files=(
  "README.md"
  "LICENSE"
  "NOTICE"
  "fedora/packages-required.txt"
  "fedora/packages-optional.txt"
  "ryoku/bin/ryoku-app"
  "ryoku/hypr/hyprland.conf"
  "ryoku/mako/config"
  "ryoku/session/ryoku-fedora.desktop"
  "ryoku/waybar/config.jsonc"
  "ryoku/waybar/style.css"
  "ryoku/wofi/config"
  "scripts/install.sh"
  "scripts/update.sh"
  "scripts/doctor.sh"
  "scripts/materialize.sh"
)

for rel in "${required_files[@]}"; do
  [[ -f "$REPO_ROOT/$rel" ]] || { echo "missing file: $rel" >&2; exit 1; }
done

required_pkgs=(hyprland xdg-desktop-portal pipewire wireplumber mako wl-clipboard jq)
for pkg in "${required_pkgs[@]}"; do
  grep -qx "$pkg" "$REPO_ROOT/fedora/packages-required.txt" || {
    echo "required package missing: $pkg" >&2
    exit 1
  }
done

if grep -RIEq --exclude='doctor.sh' '(pacman|yay|pacstrap|limine)' "$REPO_ROOT/ryoku" "$REPO_ROOT/scripts"; then
  echo "arch-only token found in tracked runtime configs/scripts" >&2
  exit 1
fi

if find "$REPO_ROOT/ryoku" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.svg' -o -iname '*.ico' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.woff' -o -iname '*.woff2' \) | grep -q .; then
  echo "non-code visual/font assets detected under ryoku/; keep only clearly-licensed code/config in this milestone" >&2
  exit 1
fi

if grep -RIEq 'https?://[^[:space:]]+' "$REPO_ROOT/ryoku"; then
  echo "remote URL detected in runtime files; keep runtime assets local only" >&2
  exit 1
fi

echo "validate.sh: ok"
