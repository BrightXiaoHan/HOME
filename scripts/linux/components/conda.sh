#!/usr/bin/env bash
# Component installer: conda.

homecli_install_conda() {
	local mamba_path="$HOMECLI_BIN_DIR/mamba"
	local package
	local npm_global_packages=(
		@earendil-works/pi-coding-agent
		@tencent-qqmail/agently-cli
	)
	local command=(
		install
		-n
		base
		-c
		conda-forge
		-y
		python=3.13.*
		fish
		ncurses
		fzf
		ripgrep
		make
		ninja
		cmake
		git
		git-lfs
		tmux=3.5a
		libcurl
		libgit2
		uv
		compilers
		zlib
		nodejs
		jq
		zoxide
		starship
		"nvim>=0.12"
		lua-language-server
		stylua
		prettier
		pyright
		ruff
		typescript-language-server
		conda-pack
	)

	homecli_log "Installing conda..."
	if [ "$HOMECLI_ARCH" = "x86_64" ] || [ "$HOMECLI_ARCH" = "amd64" ]; then
		command+=(docker-compose)
	fi

	env PYTHONPATH= MAMBA_ROOT_PREFIX="$HOMECLI_CACHE_DIR/miniconda" "$mamba_path" create -n base

	homecli_log "Installing conda packages..."
	env PYTHONPATH= MAMBA_ROOT_PREFIX="$HOMECLI_CACHE_DIR/miniconda" "$mamba_path" "${command[@]}"

	for package in kimi-cli huggingface_hub modelscope; do
		env \
			UV_TOOL_DIR="$HOMECLI_CACHE_DIR/uv/tool" \
			UV_TOOL_BIN_DIR="$HOMECLI_CACHE_DIR/bin" \
			UV_PYTHON_INSTALL_DIR="$HOMECLI_CACHE_DIR/uv/python" \
			UV_PYTHON_PREFERENCE=only-system \
			"$HOMECLI_CACHE_DIR/miniconda/bin/uv" tool install \
			--force \
			--python-preference \
			only-managed \
			"$package"
	done

	homecli_log "Installing npm global packages..."
	env \
		npm_config_audit=false \
		npm_config_fund=false \
		npm_config_update_notifier=false \
		npm_config_cache="$HOMECLI_CACHE_DIR/cache/npm" \
		"$HOMECLI_CACHE_DIR/miniconda/bin/npm" install \
		--global \
		--prefix "$HOMECLI_CACHE_DIR/miniconda" \
		--ignore-scripts \
		"${npm_global_packages[@]}"

	homecli_log "Installing other packages done."
}
