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
