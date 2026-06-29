#!/usr/bin/env bash
# Configuration link helpers for HOME.

homecli_link_configs() {
	local source_dir=$1
	local install_dir=$2
	local config_home=$3
	local home_dir=${4:-$HOME}

	mkdir -p "$config_home" "$config_home/git" "$install_dir/etc"

	ln -sfn "$source_dir/nvim" "$config_home/nvim"
	ln -sfn "$source_dir/tmux" "$config_home/tmux"
	ln -sfn "$source_dir/fish" "$config_home/fish"
	if [ -f "$source_dir/starship.toml" ]; then
		ln -sfn "$source_dir/starship.toml" "$config_home/starship.toml"
	fi

	if [ -d "$source_dir/zsh" ]; then
		ln -sfn "$source_dir/zsh" "$config_home/zsh"
		if [ ! -e "$home_dir/.zshenv" ] || [ -L "$home_dir/.zshenv" ]; then
			ln -sfn "$source_dir/zsh/.zshenv" "$home_dir/.zshenv"
		else
			echo "zshenv already exists. Skip it."
		fi
	fi

	ln -sfn "$source_dir/gitconfig" "$config_home/git/config"
	ln -sfn "$source_dir/ssh" "$install_dir/etc/ssh"
	ln -sfn "$source_dir/mambarc" "$install_dir/etc/mambarc"

	if [ -d "$source_dir/agents" ]; then
		if [ ! -e "$home_dir/.agents" ] || [ -L "$home_dir/.agents" ]; then
			ln -sfn "$source_dir/agents" "$home_dir/.agents"
		else
			echo ".agents already exists. Skip it."
		fi
	fi
}

homecli_add_authorized_key() {
	local pubkey_file=$1
	local ssh_dir=${2:-$HOME/.ssh}
	local authorized_keys="$ssh_dir/authorized_keys"

	[ -f "$pubkey_file" ] || return 0
	mkdir -p "$ssh_dir"
	[ -f "$authorized_keys" ] || touch "$authorized_keys"

	if ! grep -qxF "$(cat "$pubkey_file")" "$authorized_keys"; then
		cat "$pubkey_file" >>"$authorized_keys"
	fi
}
