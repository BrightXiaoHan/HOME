#!/usr/bin/env bash
# Component installer: mihoro.

homecli_is_musl() {
	if ! command -v ldd >/dev/null 2>&1; then
		return 1
	fi
	ldd --version 2>&1 | grep -qi musl
}


homecli_mihoro_target_triple() {
	local arch=$HOMECLI_ARCH
	local libc=${HOMECLI_MIHORO_LIBC:-musl}

	case "$arch" in
	amd64) arch=x86_64 ;;
	arm64) arch=aarch64 ;;
	esac

	case "$libc" in
	auto)
		if homecli_is_musl; then
			libc=musl
		else
			libc=gnu
		fi
		;;
	gnu | musl) ;;
	*) homecli_die "Unsupported mihoro libc target: $libc" ;;
	esac

	printf '%s-unknown-linux-%s\n' "$arch" "$libc"
}


homecli_select_mihoro_asset() {
	local assets_file=$1
	local target=$2
	local suffix name url

	for suffix in .tar.gz .zip; do
		while IFS=$'\t' read -r name url; do
			[ -n "$name" ] || continue
			[[ "$name" == mihoro-* ]] || continue
			[[ "$name" == *"$suffix" ]] || continue
			[[ "$name" == *"$target"* ]] || continue
			printf '%s\t%s\n' "$name" "$url"
			return 0
		done <"$assets_file"
	done

	return 1
}


homecli_extract_mihoro_archive() {
	local archive=$1
	local archive_name=$2
	local dest=$3

	if [[ "$archive_name" == *.tar.gz ]]; then
		homecli_tar_member_to_file "$archive" mihoro "$dest"
	elif [[ "$archive_name" == *.zip ]]; then
		homecli_zip_member_to_file "$archive" mihoro "$dest"
	else
		cp "$archive" "$dest"
	fi
}


homecli_install_mihoro() {
	local overwrite=${1:-true}
	local bin_file="$HOMECLI_BIN_DIR/mihoro"
	local assets_file asset archive_name url target tmp

	homecli_log "Installing mihoro..."
	if [ -e "$bin_file" ] && [ "$overwrite" != "true" ]; then
		return 0
	fi

	target=$(homecli_mihoro_target_triple)
	homecli_temp_file assets_file
	homecli_release_assets_to_file spencerwooo mihoro "$assets_file"
	if ! asset=$(homecli_select_mihoro_asset "$assets_file" "$target"); then
		homecli_die "Unable to find a suitable mihoro release asset for $target"
	fi
	IFS=$'\t' read -r archive_name url <<<"$asset"

	homecli_temp_file tmp
	homecli_curl "$tmp" "$url"
	homecli_extract_mihoro_archive "$tmp" "$archive_name" "$bin_file"
	chmod 755 "$bin_file"
	homecli_log "Installing mihoro done."
}
