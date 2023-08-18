if type -q exa
  alias ll "exa -l -g --icons"
  alias lla "ll -a"
end

# If /opt/homebrew/bin is not in PATH, add it
if not contains $PATH "/opt/homebrew/bin"
  fish_add_path /opt/homebrew/bin
end

if test -f ~/anaconda3/bin/conda
    eval ~/anaconda3/bin/conda "shell.fish" "hook" $argv | source
end

