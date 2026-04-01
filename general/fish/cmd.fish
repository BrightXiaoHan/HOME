function osc52-copy
    # if not in ssh environment, return
    if test -n "$SSH_CONNECTION"
        return
    end
    set -l data (echo -n $argv | base64 | tr -d '\n')
    set -l esc "\033]52;c;$data\a"
    if test -n "$TMUX"
        printf "\033Ptmux;\033$esc\033\\"
    else
        printf $esc
    end
end

set -gx ALIYUN_REGISTRY crpi-lgqv70s6wfdw4zdl.cn-hangzhou.personal.cr.aliyuncs.com


function docker-aliyun-push
    # The function takes one argument, which is the name of the person to greet
    set -l image $argv[1]
    docker tag $image $ALIYUN_REGISTRY/yuyi_docker_cn/$image
    docker push $ALIYUN_REGISTRY/yuyi_docker_cn/$image
    docker rmi $ALIYUN_REGISTRY/yuyi_docker_cn/$image
end


function docker-aliyun-pull
    # The function takes one argument, which is the name of the person to greet
    set -l image $argv[1]
    docker pull $ALIYUN_REGISTRY/yuyi_docker_cn/$image
    docker tag $ALIYUN_REGISTRY/yuyi_docker_cn/$image $image
    docker rmi $ALIYUN_REGISTRY/yuyi_docker_cn/$image
end

function start-proxy
    shadowsocksr-cli --setting-url https://xxjcdy.cfd/link/suKDLaU0nUv6Ye1d
    shadowsocksr-cli -u
    shadowsocksr-cli --fast-node
    shadowsocksr-cli --http-proxy start
end

# proxy alias
alias setproxy="set ALL_PROXY 'socks5://127.0.0.1:1080'"
alias unsetproxy="set -e ALL_PROXY"
alias ip="curl http://ip-api.com/json/?lang=zh-CN"
alias sethttpproxy="set -gx HTTPS_PROXY 'http://127.0.0.1:7890'"
alias unsethttpproxy="set -e HTTPS_PROXY"

function vscode-server-upload
    # Usage: vscode-server-upload user@host [commit_id]
    # Gets local VS Code commit id (macOS/Linux), downloads server tarball, uploads, and installs on remote host.
    if test (count $argv) -lt 1
        echo "Usage: vscode-server-upload user@host [commit_id]"
        return 1
    end

    set -l host $argv[1]
    set -l commit_id ""
    if test (count $argv) -ge 2
        set commit_id $argv[2]
    end

    if test -z "$commit_id"
        if type -q code
            set -l code_version (command code --version 2>/dev/null)
            set -l commit_line (string split \n -- $code_version)[2]
            if test -n "$commit_line"
                set commit_id $commit_line
            end
        end
    end

    if test -z "$commit_id"
        set -l product_paths \
            "/Applications/Visual Studio Code.app/Contents/Resources/app/product.json" \
            "/usr/share/code/resources/app/product.json" \
            "/usr/lib/code/resources/app/product.json" \
            "/usr/lib64/code/resources/app/product.json" \
            "/opt/visual-studio-code/resources/app/product.json" \
            "/snap/code/current/usr/share/code/resources/app/product.json"

        for p in $product_paths
            if test -f $p
                if type -q python3
                    set commit_id (python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("commit",""))' $p)
                else if type -q python
                    set commit_id (python -c 'import json,sys; print(json.load(open(sys.argv[1])).get("commit",""))' $p)
                end
                if test -n "$commit_id"
                    break
                end
            end
        end
    end

    if test -z "$commit_id"
        echo "Unable to determine VS Code commit id. Provide it as the second argument."
        return 1
    end

    set -l url "https://update.code.visualstudio.com/commit:$commit_id/server-linux-x64/stable"
    set -l tmpdir (mktemp -d)
    set -l tarball "$tmpdir/vscode-server-linux-x64.tar.gz"

    echo "Downloading VS Code server: $url"
    curl -sSL "$url" -o "$tarball"

    echo "Uploading to $host"
    scp "$tarball" "$host:~/vscode-server-linux-x64.tar.gz"

    echo "Installing on $host"
    ssh "$host" "set -e; commit_id=$commit_id; mkdir -p ~/.vscode-server/bin/\$commit_id; tar zxvf ~/vscode-server-linux-x64.tar.gz -C ~/.vscode-server/bin/\$commit_id --strip 1; touch ~/.vscode-server/bin/\$commit_id/0; rm -f ~/vscode-server-linux-x64.tar.gz"

    rm -rf "$tmpdir"
end

function restore-ssh-key
    # Restore SSH private key from GPG key file
    # Usage: restore-ssh-key <path-to-gpg-private-key>
    # 
    # This function imports the GPG private key, then decrypts ssh/id_rsa from pass
    # and restores it to ~/.ssh/id_rsa
    
    if test (count $argv) -lt 1
        echo "Usage: restore-ssh-key <path-to-gpg-private-key>"
        echo "Example: restore-ssh-key ~/Downloads/gpg-private-key.asc"
        return 1
    end
    
    set -l gpg_key_path $argv[1]
    
    if not test -f $gpg_key_path
        echo "Error: GPG key file not found: $gpg_key_path"
        return 1
    end
    
    echo "Importing GPG private key from $gpg_key_path..."
    gpg --import $gpg_key_path
    if test $status -ne 0
        echo "Error: Failed to import GPG key"
        return 1
    end
    
    # Get the key ID (assumes the first secret key)
    set -l key_id (gpg --list-secret-keys --with-colons | grep fpr | head -1 | cut -d: -f10)
    if test -z "$key_id"
        echo "Error: Could not determine GPG key ID"
        return 1
    end
    
    echo "Setting ultimate trust for key $key_id..."
    echo -e "5\ny\n" | gpg --command-fd 0 --edit-key $key_id trust >/dev/null 2>&1
    
    # Clone password store if not exists
    if not test -d "$HOME/.password-store"
        echo "Cloning password store..."
        git clone https://github.com/BrightXiaoHan/password-store.git "$HOME/.password-store"
    end
    
    # Initialize pass
    pass init $key_id >/dev/null 2>&1
    
    # Decrypt and restore ssh keys
    echo "Restoring SSH keys from password store..."
    
    # Create .ssh directory if not exists
    if not test -d "$HOME/.ssh"
        mkdir -p "$HOME/.ssh"
    end
    
    # Restore id_rsa
    if pass show ssh/id_rsa >/dev/null 2>&1
        pass show ssh/id_rsa > "$HOME/.ssh/id_rsa"
        chmod 600 "$HOME/.ssh/id_rsa"
        echo "✅ Restored ~/.ssh/id_rsa"
    else
        echo "⚠️  ssh/id_rsa not found in password store"
    end
    
    # Restore id_rsa.pub
    if pass show ssh/id_rsa.pub >/dev/null 2>&1
        pass show ssh/id_rsa.pub > "$HOME/.ssh/id_rsa.pub"
        chmod 644 "$HOME/.ssh/id_rsa.pub"
        echo "✅ Restored ~/.ssh/id_rsa.pub"
    else
        echo "⚠️  ssh/id_rsa.pub not found in password store"
    end
    
    # Restore id_rsa_git
    if pass show ssh/id_rsa_git >/dev/null 2>&1
        pass show ssh/id_rsa_git > "$HOME/.ssh/id_rsa_git"
        chmod 600 "$HOME/.ssh/id_rsa_git"
        echo "✅ Restored ~/.ssh/id_rsa_git"
    else
        echo "⚠️  ssh/id_rsa_git not found in password store"
    end
    
    # Restore id_rsa_git.pub
    if pass show ssh/id_rsa_git.pub >/dev/null 2>&1
        pass show ssh/id_rsa_git.pub > "$HOME/.ssh/id_rsa_git.pub"
        chmod 644 "$HOME/.ssh/id_rsa_git.pub"
        echo "✅ Restored ~/.ssh/id_rsa_git.pub"
    else
        echo "⚠️  ssh/id_rsa_git.pub not found in password store"
    end
    
    echo ""
    echo "SSH key restoration complete!"
    echo "You may need to add the new SSH key to your GitHub account:"
    echo "  cat ~/.ssh/id_rsa_git.pub"
end


function switch-claude-code-to-kimi
    set -gx ANTHROPIC_BASE_URL https://api.kimi.com/coding/
    set -gx ANTHROPIC_AUTH_TOKEN (pass show llm/kimi/kimi-code)
end

function switch-claude-code-to-deepseek
    set -gx ANTHROPIC_BASE_URL https://api.deepseek.com/anthropic
    set -gx ANTHROPIC_AUTH_TOKEN (pass show llm/deepseek)
    set -gx ANTHROPIC_MODEL deepseek-reasoner
    set -gx ANTHROPIC_SMALL_FAST_MODEL deepseek-chat
end

function switch-claude-code-to-glm
    set -gx ANTHROPIC_BASE_URL https://open.bigmodel.cn/api/anthropic
    set -gx ANTHROPIC_AUTH_TOKEN (pass show llm/glm/glm-code)
    set -gx ANTHROPIC_MODEL glm-5.1
    set -gx ANTHROPIC_SMALL_FAST_MODEL glm-5.1
end

function switch-claude-code-to-openrouter
    set -gx OPENROUTER_API_KEY (pass show lighthunter/openrouter/hanbing)
    set -gx ANTHROPIC_BASE_URL "https://openrouter.ai/api"
    set -gx ANTHROPIC_AUTH_TOKEN (pass show lighthunter/openrouter/hanbing)
    set -gx ANTHROPIC_API_KEY "" # Important: Must be explicitly empty
    set -gx ANTHROPIC_DEFAULT_OPUS_MODEL "anthropic/claude-opus-4.6"
    set -gx ANTHROPIC_DEFAULT_SONNET_MODEL "anthropic/claude-sonnet-4.6"
    set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL "anthropic/claude-haiku-4.5"
    set -gx CLAUDE_CODE_SUBAGENT_MODEL "anthropic/claude-opus-4.6"
end

function switch-claude-code-to-aiberm
    set -gx ANTHROPIC_BASE_URL https://aiberm.com
    set -gx ANTHROPIC_AUTH_TOKEN (pass show lighthunter/aiberm/hanbing)
end

function claude-code-reset
    set -e DEEPSEEK_API_KEY
    set -e ANTHROPIC_BASE_URL
    set -e ANTHROPIC_AUTH_TOKEN
    set -e ANTHROPIC_MODEL
    set -e ANTHROPIC_SMALL_FAST_MODEL
end

set -gx GEMINI_API_KEY (pass show llm/google/ai-studio)