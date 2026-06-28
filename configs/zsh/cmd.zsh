emulate -L zsh

if [[ -n ${__HOMECLI_ZSH_CMD_LOADED:-} ]]; then
  return
fi
typeset -g __HOMECLI_ZSH_CMD_LOADED=1

osc52-copy() {
  if [[ -n "${SSH_CONNECTION:-}" ]]; then
    return
  fi

  local data esc
  data="$(printf '%s' "$*" | base64 | tr -d '\n')"
  esc=$'\033]52;c;'"$data"$'\a'

  if [[ -n "${TMUX:-}" ]]; then
    printf '\033Ptmux;\033%s\033\\' "$esc"
  else
    printf '%s' "$esc"
  fi
}

export ALIYUN_REGISTRY=crpi-lgqv70s6wfdw4zdl.cn-hangzhou.personal.cr.aliyuncs.com

docker-aliyun-push() {
  local image="$1"
  docker tag "$image" "$ALIYUN_REGISTRY/yuyi_docker_cn/$image"
  docker push "$ALIYUN_REGISTRY/yuyi_docker_cn/$image"
  docker rmi "$ALIYUN_REGISTRY/yuyi_docker_cn/$image"
}

docker-aliyun-pull() {
  local image="$1"
  docker pull "$ALIYUN_REGISTRY/yuyi_docker_cn/$image"
  docker tag "$ALIYUN_REGISTRY/yuyi_docker_cn/$image" "$image"
  docker rmi "$ALIYUN_REGISTRY/yuyi_docker_cn/$image"
}

start-proxy() {
  shadowsocksr-cli --setting-url https://xxjcdy.cfd/link/suKDLaU0nUv6Ye1d
  shadowsocksr-cli -u
  shadowsocksr-cli --fast-node
  shadowsocksr-cli --http-proxy start
}

setproxy() {
  export ALL_PROXY='socks5://127.0.0.1:1080'
}

unsetproxy() {
  unset ALL_PROXY
}

alias ip='curl "http://ip-api.com/json/?lang=zh-CN"'

sethttpproxy() {
  export HTTPS_PROXY='http://127.0.0.1:7890'
}

unsethttpproxy() {
  unset HTTPS_PROXY
}

vscode-server-upload() {
  if (( $# < 1 )); then
    echo "Usage: vscode-server-upload user@host [commit_id]"
    return 1
  fi

  local host="$1"
  local commit_id="${2:-}"

  if [[ -z "$commit_id" ]] && command -v code >/dev/null 2>&1; then
    local code_version commit_line
    code_version="$(command code --version 2>/dev/null)"
    commit_line="$(printf '%s\n' "$code_version" | sed -n '2p')"
    [[ -n "$commit_line" ]] && commit_id="$commit_line"
  fi

  if [[ -z "$commit_id" ]]; then
    local -a product_paths
    product_paths=(
      "/Applications/Visual Studio Code.app/Contents/Resources/app/product.json"
      "/usr/share/code/resources/app/product.json"
      "/usr/lib/code/resources/app/product.json"
      "/usr/lib64/code/resources/app/product.json"
      "/opt/visual-studio-code/resources/app/product.json"
      "/snap/code/current/usr/share/code/resources/app/product.json"
    )

    local p
    for p in "${product_paths[@]}"; do
      if [[ -f "$p" ]]; then
        if command -v python3 >/dev/null 2>&1; then
          commit_id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("commit",""))' "$p")"
        elif command -v python >/dev/null 2>&1; then
          commit_id="$(python -c 'import json,sys; print(json.load(open(sys.argv[1])).get("commit",""))' "$p")"
        fi
        [[ -n "$commit_id" ]] && break
      fi
    done
  fi

  if [[ -z "$commit_id" ]]; then
    echo "Unable to determine VS Code commit id. Provide it as the second argument."
    return 1
  fi

  local url="https://update.code.visualstudio.com/commit:$commit_id/server-linux-x64/stable"
  local tmpdir tarball status
  tmpdir="$(mktemp -d)" || return 1
  tarball="$tmpdir/vscode-server-linux-x64.tar.gz"

  echo "Downloading VS Code server: $url"
  curl -sSL "$url" -o "$tarball" || {
    status=$?
    rm -rf "$tmpdir"
    return $status
  }

  echo "Uploading to $host"
  scp "$tarball" "$host:~/vscode-server-linux-x64.tar.gz" || {
    status=$?
    rm -rf "$tmpdir"
    return $status
  }

  echo "Installing on $host"
  ssh "$host" "set -e; commit_id=$commit_id; mkdir -p ~/.vscode-server/bin/\$commit_id; tar zxvf ~/vscode-server-linux-x64.tar.gz -C ~/.vscode-server/bin/\$commit_id --strip 1; touch ~/.vscode-server/bin/\$commit_id/0; rm -f ~/vscode-server-linux-x64.tar.gz"
  status=$?

  rm -rf "$tmpdir"
  return $status
}

restore-ssh-key() {
  if (( $# < 1 )); then
    echo "Usage: restore-ssh-key <path-to-gpg-private-key>"
    echo "Example: restore-ssh-key ~/Downloads/gpg-private-key.asc"
    return 1
  fi

  local gpg_key_path="$1"

  if [[ ! -f "$gpg_key_path" ]]; then
    echo "Error: GPG key file not found: $gpg_key_path"
    return 1
  fi

  echo "Importing GPG private key from $gpg_key_path..."
  gpg --import "$gpg_key_path"
  if (( $? != 0 )); then
    echo "Error: Failed to import GPG key"
    return 1
  fi

  local key_id
  key_id="$(gpg --list-secret-keys --with-colons | grep fpr | head -1 | cut -d: -f10)"
  if [[ -z "$key_id" ]]; then
    echo "Error: Could not determine GPG key ID"
    return 1
  fi

  echo "Setting ultimate trust for key $key_id..."
  printf '5\ny\n' | gpg --command-fd 0 --edit-key "$key_id" trust >/dev/null 2>&1

  local pass_dir="${PASSWORD_STORE_DIR:-$HOME/.password-store}"
  if [[ ! -d "$pass_dir" ]]; then
    echo "Cloning password store..."
    git clone https://github.com/BrightXiaoHan/password-store.git "$pass_dir"
  fi

  pass init "$key_id" >/dev/null 2>&1

  echo "Restoring SSH keys from password store..."

  if [[ ! -d "$HOME/.ssh" ]]; then
    mkdir -p "$HOME/.ssh"
  fi

  if pass show ssh/id_rsa >/dev/null 2>&1; then
    pass show ssh/id_rsa > "$HOME/.ssh/id_rsa"
    chmod 600 "$HOME/.ssh/id_rsa"
    echo "Restored ~/.ssh/id_rsa"
  else
    echo "ssh/id_rsa not found in password store"
  fi

  if pass show ssh/id_rsa.pub >/dev/null 2>&1; then
    pass show ssh/id_rsa.pub > "$HOME/.ssh/id_rsa.pub"
    chmod 644 "$HOME/.ssh/id_rsa.pub"
    echo "Restored ~/.ssh/id_rsa.pub"
  else
    echo "ssh/id_rsa.pub not found in password store"
  fi

  if pass show ssh/id_rsa_git >/dev/null 2>&1; then
    pass show ssh/id_rsa_git > "$HOME/.ssh/id_rsa_git"
    chmod 600 "$HOME/.ssh/id_rsa_git"
    echo "Restored ~/.ssh/id_rsa_git"
  else
    echo "ssh/id_rsa_git not found in password store"
  fi

  if pass show ssh/id_rsa_git.pub >/dev/null 2>&1; then
    pass show ssh/id_rsa_git.pub > "$HOME/.ssh/id_rsa_git.pub"
    chmod 644 "$HOME/.ssh/id_rsa_git.pub"
    echo "Restored ~/.ssh/id_rsa_git.pub"
  else
    echo "ssh/id_rsa_git.pub not found in password store"
  fi

  echo ""
  echo "SSH key restoration complete!"
  echo "You may need to add the new SSH key to your GitHub account:"
  echo "  cat ~/.ssh/id_rsa_git.pub"
}

switch-claude-code-to-kimi() {
  export ANTHROPIC_BASE_URL=https://api.kimi.com/coding/
  export ANTHROPIC_AUTH_TOKEN="$(pass show llm/kimi/kimi-code)"
}

switch-claude-code-to-deepseek() {
  export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic
  export ANTHROPIC_AUTH_TOKEN="$(pass show llm/deepseek)"
  export ANTHROPIC_MODEL='deepseek-v4-pro[1m]'
  export ANTHROPIC_DEFAULT_OPUS_MODEL='deepseek-v4-pro[1m]'
  export ANTHROPIC_DEFAULT_SONNET_MODEL='deepseek-v4-pro[1m]'
  export ANTHROPIC_DEFAULT_HAIKU_MODEL=deepseek-v4-flash
  export CLAUDE_CODE_SUBAGENT_MODEL=deepseek-v4-flash
  export CLAUDE_CODE_EFFORT_LEVEL=max
}

switch-claude-code-to-glm() {
  export ANTHROPIC_BASE_URL=https://open.bigmodel.cn/api/anthropic
  export ANTHROPIC_AUTH_TOKEN="$(pass show llm/glm/glm-code)"
  export ANTHROPIC_MODEL=glm-5.1
  export ANTHROPIC_SMALL_FAST_MODEL=glm-5.1
}

switch-claude-code-to-aiberm() {
  export ANTHROPIC_BASE_URL=https://aiberm.com
  if ! command -v pass >/dev/null 2>&1; then
    return 0
  fi
  export ANTHROPIC_AUTH_TOKEN="$(pass show lighthunter/aiberm/hanbing)"
}

claude-code-reset() {
  unset DEEPSEEK_API_KEY
  unset ANTHROPIC_BASE_URL
  unset ANTHROPIC_AUTH_TOKEN
  unset ANTHROPIC_MODEL
  unset ANTHROPIC_SMALL_FAST_MODEL
}
