#!/usr/bin/env bash
# Component installer: neovim.

homecli_prune_neovim_plugins() {
	local nvim_bin=$1
	local config_home=$2
	local data_home=$3
	local lockfile="$config_home/nvim/nvim-pack-lock.json"
	local pack_dir="$data_home/nvim/site/pack/core/opt"
	local keep_file
	local plugin_dir
	local plugin_name
	local removed=0

	[ -f "$lockfile" ] || return
	[ -d "$pack_dir" ] || return

	homecli_temp_file keep_file
	env HOMECLI_NVIM_LOCKFILE="$lockfile" HOMECLI_NVIM_KEEPFILE="$keep_file" "$nvim_bin" --headless --clean \
		"+lua local input = assert(io.open(vim.env.HOMECLI_NVIM_LOCKFILE, 'r')); local lock = vim.json.decode(input:read('*a')); input:close(); local names = {}; for name in pairs(lock.plugins or {}) do names[#names + 1] = name end; table.sort(names); local output = assert(io.open(vim.env.HOMECLI_NVIM_KEEPFILE, 'w')); for _, name in ipairs(names) do output:write(name, '\\n') end; output:close()" \
		+qa

	while IFS= read -r plugin_dir; do
		plugin_name=${plugin_dir##*/}
		if ! grep -Fxq "$plugin_name" "$keep_file"; then
			rm -rf "$plugin_dir"
			removed=$((removed + 1))
		fi
	done < <(find "$pack_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

	if [ "$removed" -gt 0 ]; then
		homecli_log "Pruned $removed stale neovim plugin(s)."
	fi
}


homecli_install_neovim() {
	local nvim_bin="$HOMECLI_CACHE_DIR/miniconda/bin/nvim"
	local data_home="${XDG_DATA_HOME:-$HOMECLI_CACHE_DIR/data}"
	local config_home="${XDG_CONFIG_HOME:-$HOMECLI_CACHE_DIR/config}"
	local state_home="${XDG_STATE_HOME:-$HOMECLI_CACHE_DIR/state}"
	local cache_home="${XDG_CACHE_HOME:-$HOMECLI_CACHE_DIR/cache}"
	local git_config
	local _

	[ -x "$nvim_bin" ] || homecli_die "nvim is required but not installed at $nvim_bin"

	homecli_log "Installing neovim plugins with vim.pack..."
	mkdir -p "$data_home/nvim/site/pack/core/opt" "$data_home/nvim/mason/bin"
	homecli_prune_neovim_plugins "$nvim_bin" "$config_home" "$data_home"
	homecli_temp_file git_config
	cat >"$git_config" <<'EOF'
[url "https://github.com/"]
	insteadOf = git@github.com:
	insteadOf = ssh://git@github.com/
EOF

	for _ in 1 2 3; do
		if env \
			XDG_CONFIG_HOME="$config_home" \
			XDG_DATA_HOME="$data_home" \
			XDG_STATE_HOME="$state_home" \
			XDG_CACHE_HOME="$cache_home" \
			GIT_CONFIG_GLOBAL="$git_config" \
			"$nvim_bin" --headless \
			"+lua assert(vim.fn.has('nvim-0.12') == 1 and vim.pack, 'Neovim 0.12+ with vim.pack is required')" \
			"+lua vim.pack.update(nil, { target = 'lockfile', offline = true, force = true })" \
			+qa &&
			find "$data_home/nvim/site/pack/core/opt" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | grep -q .; then
			homecli_log "Installing neovim plugins done."
			return
		fi
	done

	homecli_die "failed to install neovim plugins with vim.pack"
}
