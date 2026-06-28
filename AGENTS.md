# AGENTS.md

HOME is a personal, portable development environment manager. It combines dotfiles, tool installation, packaging, and CI release automation.

## Responsibilities

- `configs/`: versioned configuration files for shells, editor, tmux, git, SSH, and PowerShell.
- `scripts/`: platform-specific script directories and shared helpers.
- `scripts/linux/`: Linux `homecli` command entrypoint, installation, update, packaging, uninstall, validation, and XDG-isolated relink logic.
- `scripts/linux/components.sh`: Linux component dispatcher.
- `scripts/linux/components/`: per-component installers for micromamba, conda environment, Neovim plugins, and standalone binaries.
- `scripts/macos/`: macOS installer and host-level dotfile relink script.
- `scripts/windows/`: Windows installer and host-level dotfile relink script.
- `scripts/common/`: shared shell helper functions.
- `.github/workflows/`: CI jobs that install, test, package, and publish release artifacts and Docker images.

## Installation model

Linux installations are self-contained under `HOMECLI_INSTALL_DIR`, defaulting to `~/.homecli`:

- `config/`: XDG config root
- `data/`: XDG data root
- `state/`: XDG state root
- `cache/`: XDG cache root
- `bin/`: wrapper and standalone binaries
- `miniconda/`: micromamba base environment
- `HOME/`: checked-out HOME repository

The shell wrappers `homecli-fish` and `homecli-zsh` enter this isolated environment by exporting the XDG roots and tool paths.

## Refactoring direction

Keep these areas separate:

1. Configuration files in `configs/`.
2. Platform/package installation logic under `scripts/linux/`, `scripts/macos/`, and `scripts/windows/`.
3. Download and component logic in smaller reusable libraries under `scripts/common/` and `scripts/linux/components/`.
4. Personal/private overrides in local files that are not committed.

