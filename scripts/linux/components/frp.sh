#!/usr/bin/env bash
# Component installer: frp.

homecli_select_frp_asset() {
	local assets_file=$1
	local wanted_arch name url

	case "$HOMECLI_ARCH" in
	x86_64 | amd64) wanted_arch=amd64 ;;
	aarch64 | arm64) wanted_arch=arm64 ;;
	*) return 1 ;;
	esac

	while IFS=$'\t' read -r name url; do
		[ -n "$name" ] || continue
		[[ "$name" == frp_*_linux_"$wanted_arch".tar.gz ]] || continue
		printf '%s\t%s\n' "$name" "$url"
		return 0
	done <"$assets_file"

	return 1
}


homecli_install_frp() {
	local overwrite=${1:-true}
	local assets_file asset archive_name url extracted_dir tmp binary

	homecli_log "Installing frp..."
	if [ -e "$HOMECLI_BIN_DIR/frpc" ] && [ "$overwrite" != "true" ]; then
		return 0
	fi

	homecli_temp_file assets_file
	homecli_release_assets_to_file fatedier frp "$assets_file"
	if ! asset=$(homecli_select_frp_asset "$assets_file"); then
		homecli_die "Unable to find a suitable frp release asset"
	fi
	IFS=$'\t' read -r archive_name url <<<"$asset"

	homecli_temp_file tmp
	homecli_curl "$tmp" "$url"
	extracted_dir="$HOMECLI_CACHE_DIR/${archive_name%.tar.gz}"
	rm -rf "$extracted_dir"
	tar -xzf "$tmp" -C "$HOMECLI_CACHE_DIR"

	for binary in frpc frps; do
		rm -f "$HOMECLI_BIN_DIR/$binary"
		mv "$extracted_dir/$binary" "$HOMECLI_BIN_DIR/"
	done
}
