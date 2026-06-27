# Ensure Homebrew binaries are available when they are not already on PATH.
_homecli_fish_add_path /opt/homebrew/bin

export MAKE_OPTS="-j$(sysctl -n hw.ncpu)"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
_homecli_fish_add_path "$PNPM_HOME"
