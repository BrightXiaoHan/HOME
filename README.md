# HOME

[![Build and Push Multi-Arch Docker Image](https://github.com/BrightXiaoHan/HOME/actions/workflows/docker.yml/badge.svg)](https://github.com/BrightXiaoHan/HOME/actions/workflows/docker.yml)
[![Main Linux Workflow](https://github.com/BrightXiaoHan/HOME/actions/workflows/main.yml/badge.svg)](https://github.com/BrightXiaoHan/HOME/actions/workflows/main.yml)

My Personal Home Directory Configuration Manager - A cross-platform dotfiles and environment setup tool.

## Features

- 🚀 Single-command installation across Linux, macOS, and Windows
- 🔄 Easy environment synchronization between machines
- 🐟 Fish shell configuration with helpful aliases and utilities
- 🧰 Pre-configured development tools (NeoVim, tmux, Git, etc.)
- 🐍 Python environment management with micromamba and uv
- 🔒 SSH configuration management
- 📦 Docker support with convenient workflow
- 💻 Cross-platform compatibility (Linux, macOS, Windows)

## Quick Start

Choose the installation method for your platform:

### Linux

**Install**

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install.sh)"
```

**Update**

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/update.sh)"
```

**Uninstall**

```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/uninstall.sh)"
```

**Install from pre-built package**

1. Download pre-packed run file from [Releases](https://github.com/BrightXiaoHan/HOME/releases) (e.g., `home-cli-x86_64.run`)
2. Install with:
   ```bash
   bash home-cli-x86_64.run -- -m install --install-dir $HOME/.homecli
   ```

**Additional Operations**

Uninstall without deleting installation cache (for future relink):
```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli bash scripts/uninstall.sh --remove-cache false
```

Relink existing installation:
```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli bash scripts/install.sh relink
```

Pack your current setup for distribution:
```bash
HOMECLI_INSTALL_DIR=$HOME/.homecli /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/pack.sh)"
```

### macOS

**Prerequisites**

Install Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Install Packages**
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install_macos.sh)"
```

### Windows

**Prerequisites**

Upgrade PowerShell:
```powershell
iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Quiet"
```

**Install Packages**
```powershell
iex (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BrightXiaoHan/HOME/main/scripts/install.ps1").Content
```

## Docker Development Environment

It's recommended to use Podman for building and running the container. This allows you to mount your home directory without permission issues.

**Build image**
```shell
podman build -t home .
```

**Build with custom arguments**
```shell
podman build -t home --build-arg "VERSION=20.04" --network=host --build-arg "HTTPS_PROXY=http://127.0.0.1:7890" .
```

**Run Container**
```shell
podman run -v $HOME:/workspace --name home -itd home
```

## Included Tools & Configurations

- **Shell**: Fish shell with custom prompt and useful aliases
- **Editor**: NeoVim with NvChad configuration
- **Terminal Multiplexer**: tmux with custom keybindings
- **Package Management**: micromamba (conda), uv (Python)
- **Git**: Custom aliases and configuration
- **Utilities**: fzf, ripgrep, zoxide, starship prompt, and more
- **SSH**: Configuration management with built-in profiles
- **Windows**: PowerShell configuration with Oh-My-Posh

## Directory Structure

- `general/` - Configuration files for various tools
  - `fish/` - Fish shell configuration
  - `ssh/` - SSH configuration and keys
  - `tmux/` - Tmux configuration
  - `NvChad/` - NeoVim configuration
  - `gitconfig` - Global Git configuration
- `homecli/` - Python package for installation and management
- `scripts/` - Installation and utility scripts for different platforms

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
