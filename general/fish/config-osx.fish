# If /opt/homebrew/bin is not in PATH, add it
if not contains $PATH "/opt/homebrew/bin"
  fish_add_path /opt/homebrew/bin
end

if test -f ~/anaconda3/bin/conda
    eval ~/anaconda3/bin/conda "shell.fish" "hook" $argv | source
end

if command -q pyenv 1>/dev/null 2>&1; and status --is-interactive
  pyenv init - | source
end

set -gx MAKE_OPTS -j(sysctl -n hw.ncpu)  # pyenv set MAKE_OPTS to number of cores minus 1
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8
