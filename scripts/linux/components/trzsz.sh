#!/usr/bin/env bash
# Component installer: trzsz.

homecli_install_trzsz() {
	local overwrite=${1:-true}
	local latest_version url archive_name extracted_dir src tmp moved=0

	latest_version=$(homecli_latest_release_tag trzsz trzsz-go)
	if [ "$HOMECLI_ARCH" = "x86_64" ] || [ "$HOMECLI_ARCH" = "amd64" ]; then
		url="https://github.com/trzsz/trzsz-go/releases/download/$latest_version/trzsz_${latest_version#v}_linux_x86_64.tar.gz"
	else
		url="https://github.com/trzsz/trzsz-go/releases/download/$latest_version/trzsz_${latest_version#v}_linux_aarch64.tar.gz"
	fi

	homecli_log "Installing trzsz..."
	if [ -e "$HOMECLI_BIN_DIR/trzsz" ] && [ "$overwrite" != "true" ]; then
		return 0
	fi

	homecli_temp_file tmp
	homecli_curl "$tmp" "$url"
	archive_name=${url##*/}
	extracted_dir="$HOMECLI_CACHE_DIR/${archive_name%.tar.gz}"
	rm -rf "$extracted_dir"
	tar -xzf "$tmp" -C "$HOMECLI_CACHE_DIR"

	for src in "$extracted_dir"/*; do
		[ -e "$src" ] || continue
		if [ -f "$src" ]; then
			rm -f "$HOMECLI_BIN_DIR/${src##*/}"
			mv "$src" "$HOMECLI_BIN_DIR/"
			moved=1
		fi
	done
	[ "$moved" -eq 1 ] || homecli_die "trzsz archive has no files"
}
