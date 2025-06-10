# If /opt/homebrew/bin is not in PATH, add it
if not contains $PATH /opt/homebrew/bin
    fish_add_path /opt/homebrew/bin
end

set -gx MAKE_OPTS -j(sysctl -n hw.ncpu) # set MAKE_OPTS to number of cores minus 1
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# pnpm
set -gx PNPM_HOME $HOME/Library/pnpm
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
