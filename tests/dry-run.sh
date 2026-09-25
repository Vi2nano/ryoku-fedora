#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT

mkdir -p "$tmp_home/.config" "$tmp_home/.local/share"

cat > "$tmp_home/os-release" <<'OS'
ID=fedora
OS

mkdir -p "$tmp_home/bin"
cat > "$tmp_home/bin/uname" <<'EOF_U'
#!/usr/bin/env bash
echo x86_64
EOF_U
chmod +x "$tmp_home/bin/uname"

cat > "$tmp_home/bin/sudo" <<'EOF_S'
#!/usr/bin/env bash
# sudo passthrough for tests
exec "$@"
EOF_S
chmod +x "$tmp_home/bin/sudo"

cat > "$tmp_home/bin/dnf5" <<'EOF_D'
#!/usr/bin/env bash
echo "dnf5 $*"
EOF_D
chmod +x "$tmp_home/bin/dnf5"

output_install="$(HOME="$tmp_home" XDG_CONFIG_HOME="$tmp_home/.config" XDG_DATA_HOME="$tmp_home/.local/share" PATH="$tmp_home/bin:$PATH" RYOKU_OS_RELEASE_PATH="$tmp_home/os-release" "$REPO_ROOT/scripts/install.sh" --dry-run 2>&1)"

echo "$output_install" | grep -q '\[DRY-RUN\] sudo dnf5 install -y' || {
  echo "expected dnf5 dry-run output not found" >&2
  exit 1
}

echo "$output_install" | grep -q '\[DRY-RUN\] ln -sfn' || {
  echo "expected symlink dry-run output not found" >&2
  exit 1
}

output_install_optional="$(HOME="$tmp_home" XDG_CONFIG_HOME="$tmp_home/.config" XDG_DATA_HOME="$tmp_home/.local/share" PATH="$tmp_home/bin:$PATH" RYOKU_OS_RELEASE_PATH="$tmp_home/os-release" "$REPO_ROOT/scripts/install.sh" --dry-run --with-optional 2>&1)"

echo "$output_install_optional" | grep -q 'quickshell' || {
  echo "expected optional package in dry-run output not found" >&2
  exit 1
}

output_uninstall="$(HOME="$tmp_home" XDG_CONFIG_HOME="$tmp_home/.config" XDG_DATA_HOME="$tmp_home/.local/share" PATH="$tmp_home/bin:$PATH" RYOKU_OS_RELEASE_PATH="$tmp_home/os-release" "$REPO_ROOT/scripts/install.sh" --dry-run --uninstall 2>&1)"

echo "$output_uninstall" | grep -q 'Uninstalling ryoku-fedora user-space layer' || {
  echo "expected uninstall message not found" >&2
  exit 1
}

echo "dry-run.sh: ok"
