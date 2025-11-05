# Ensure Homebrew binaries are available
fish_add_path --path /opt/homebrew/bin

set -gx MAKE_OPTS -j(sysctl -n hw.ncpu) # set MAKE_OPTS to number of cores minus 1
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# pnpm
set -gx PNPM_HOME $HOME/Library/pnpm
fish_add_path --path $PNPM_HOME
# pnpm end
