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

cat > "$tmp_home/bin/dnf" <<'EOF_DNF'
#!/usr/bin/env bash
echo "dnf $*"
EOF_DNF
chmod +x "$tmp_home/bin/dnf"

mkdir -p "$tmp_home/bin-dnf-only"
ln -s /usr/bin/bash "$tmp_home/bin-dnf-only/bash"
ln -s /usr/bin/dirname "$tmp_home/bin-dnf-only/dirname"
ln -s /usr/bin/grep "$tmp_home/bin-dnf-only/grep"
ln -s "$tmp_home/bin/uname" "$tmp_home/bin-dnf-only/uname"
ln -s "$tmp_home/bin/sudo" "$tmp_home/bin-dnf-only/sudo"
ln -s "$tmp_home/bin/dnf" "$tmp_home/bin-dnf-only/dnf"

run_install() {
  local path_value="$1"
  shift

  HOME="$tmp_home" \
    XDG_CONFIG_HOME="$tmp_home/.config" \
    XDG_DATA_HOME="$tmp_home/.local/share" \
    PATH="$path_value" \
    RYOKU_OS_RELEASE_PATH="$tmp_home/os-release" \
    "$REPO_ROOT/scripts/install.sh" "$@" 2>&1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  grep -Fq "$needle" <<<"$haystack" || {
    echo "$message" >&2
    exit 1
  }
}

output_install="$(run_install "$tmp_home/bin:$PATH" --dry-run)"

assert_contains "$output_install" '[DRY-RUN] sudo dnf5 install -y' "expected dnf5 dry-run output not found"
assert_contains "$output_install" '[DRY-RUN] ln -sfn' "expected symlink dry-run output not found"

output_install_fallback="$(run_install "$tmp_home/bin-dnf-only" --dry-run)"

assert_contains "$output_install_fallback" '[DRY-RUN] sudo dnf install -y' "expected dnf fallback dry-run output not found"

output_install_optional="$(run_install "$tmp_home/bin:$PATH" --dry-run --with-optional)"

assert_contains "$output_install_optional" 'quickshell' "expected optional package in dry-run output not found"

output_uninstall="$(run_install "$tmp_home/bin:$PATH" --dry-run --uninstall)"

assert_contains "$output_uninstall" 'Uninstalling ryoku-fedora user-space layer' "expected uninstall message not found"
assert_contains "$output_uninstall" '[DRY-RUN] rm -f' "expected uninstall session cleanup plan not found"
assert_contains "$output_uninstall" '[DRY-RUN] rm -rf' "expected uninstall data cleanup plan not found"

echo "dry-run.sh: ok"
