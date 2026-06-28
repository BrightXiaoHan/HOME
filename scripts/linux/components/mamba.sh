#!/usr/bin/env bash
# Component installer: mamba.

homecli_install_mamba() {
	local overwrite=${1:-true}
	local bin_file="$HOMECLI_BIN_DIR/mamba"
	local micromamba_file="$HOMECLI_BIN_DIR/micromamba"
	local url tmp tmpdir

	homecli_log "Installing mamba..."
	homecli_require_command bzip2
	case "$HOMECLI_ARCH" in
	x86_64 | amd64) url="https://micro.mamba.pm/api/micromamba/linux-64/latest" ;;
	*) url="https://micro.mamba.pm/api/micromamba/linux-aarch64/latest" ;;
	esac

	if [ ! -e "$bin_file" ] || [ "$overwrite" = "true" ]; then
		homecli_temp_file tmp
		homecli_temp_dir tmpdir
		homecli_curl "$tmp" "$url"
		tar -xjf "$tmp" -C "$tmpdir" bin/micromamba
		cp "$tmpdir/bin/micromamba" "$bin_file"
		chmod 755 "$bin_file"
	fi

	if [ "$overwrite" = "true" ] || [ ! -e "$micromamba_file" ]; then
		rm -f "$micromamba_file"
		ln -s mamba "$micromamba_file" || {
			cp "$bin_file" "$micromamba_file"
			chmod 755 "$micromamba_file"
		}
	fi
	homecli_log "Installing micromamba done."
}
