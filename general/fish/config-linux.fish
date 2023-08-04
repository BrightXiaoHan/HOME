# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f ~/.cache/homecli/miniconda/bin/conda
    eval ~/.cache/homecli/miniconda/bin/conda "shell.fish" "hook" $argv | source
end
# <<< conda initialize <<<

if nvim --headless -c quit 2>/dev/null
    alias nvim='nvim --appimage-extract-and-run'
    alias tmux='tmux --appimage-extract-and-run'
end
