# ryoku-fedora

`ryoku-fedora` is an early Fedora-native foundation for a Ryoku-inspired desktop layer on top of Fedora + Hyprland.

## Status

> **Early development milestone**
>
> This project is not a finished shell port. Test only in a VM or disposable installation.

## Scope of this milestone

- Fedora-first desktop bootstrap for Hyprland sessions
- Fedora package manifests (required + optional)
- Safe user-space install/uninstall/update/materialize scripts
- Modular project-owned Hyprland configuration with user override entrypoints
- Fedora-adapted launcher/session helpers (`ryoku-app`, Waybar/Mako/Wofi runtime bootstrap)
- Initial theme integration points (palette + hooks), without bundling upstream copyrighted art
- Validation checks and CI for shell scripts and repository invariants

## Non-goals (current milestone)

- No pacman/AUR/pacstrap logic
- No Limine or Arch installer/repository behavior
- No forced replacement of an existing desktop environment or display manager
- No automatic proprietary NVIDIA driver installation
- No disabling of SELinux, Secure Boot, firewall, Fedora kernel, or systemd defaults

## Upstream and licensing

This repository is an original Fedora port foundation with selectively adapted GPL-3.0 code/config from `Ryoku-dev/ryoku` where Fedora-compatible.

Licensing guardrails for this repository:

- Only code/configuration with clear redistribution rights is copied/adapted.
- No uncertain/proprietary/trademarked artwork packs, logos, wallpapers, or external image hotlinks are bundled.
- Runtime files intentionally avoid remote image fetch URLs.
- File-level provenance for reused upstream portions is tracked in [NOTICE](NOTICE).

## Fedora assumptions

- Fedora workstation-style host
- `x86_64` architecture only (for now)
- User-level install into XDG paths (`~/.config`, `~/.local/share`)
- `dnf5` preferred, `dnf` fallback

## Repository layout

- `fedora/` — package manifests
- `ryoku/` — project-owned Hyprland/session/theme scaffolding
- `scripts/` — lifecycle scripts (`install`, `update`, `doctor`, `materialize`)
- `tests/` — validation checks used locally and in CI
- `.github/workflows/` — CI workflow

## Installation

Clone the repository and run the installer on an already-configured Fedora system:

```bash
git clone https://github.com/Vi2nano/ryoku-fedora.git
cd ryoku-fedora
```

### Verify your system

Before installing, check that your system meets requirements:

```bash
scripts/doctor.sh
```

### Dry-run installation

Preview what the installer will do without making changes:

```bash
scripts/install.sh --dry-run
```

### Install

Install the Ryoku Fedora layer to user-space XDG paths:

```bash
scripts/install.sh
```

Install with optional packages:

```bash
scripts/install.sh --with-optional
```

After installation, re-login and select **"Ryoku Fedora (Hyprland)"** from your display manager's session menu.

### Uninstall

Remove the Ryoku Fedora layer and restore previous configurations:

```bash
scripts/install.sh --uninstall
```

Preview uninstall before running:

```bash
scripts/install.sh --dry-run --uninstall
```

## Installation warnings

- Do **not** run on your primary workstation without backups.
- Current scripts intentionally avoid destructive system-wide changes.
- Existing files are backed up before writes.

## Current limitations

- Full upstream Ryoku shell behavior is **not** ported yet.
- Quickshell integration remains optional and currently uses a placeholder `main.qml`; Fedora bootstrap uses practical user-space defaults (Waybar/Mako/Wofi + Hyprland bindings) while upstream parity is incremental.
- Theme assets are starter originals/integration points, not full upstream art/theme packs.
- Upstream visual assets with unclear licensing/trademark status are intentionally excluded.
