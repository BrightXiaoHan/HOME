#!/usr/bin/env bash
# Component installer: mihomo.

homecli_mihomo_score() {
	local name=$1
	local base token penalty=0 score
	local tokens=()

	case "$name" in
	mihomo-*.tar.gz | mihomo-*.gz) ;;
	*) return 1 ;;
	esac

	base=$name
	if [[ "$base" == *.tar.gz ]]; then
		base=${base%.tar.gz}
	elif [[ "$base" == *.gz ]]; then
		base=${base%.gz}
	fi

	IFS='-' read -r -a tokens <<<"$base"
	homecli_has_token linux "${tokens[@]}" || return 1

	for token in "${tokens[@]}"; do
		case "$token" in
		go120 | compatible) penalty=$((penalty - 1)) ;;
		esac
	done

	case "$HOMECLI_ARCH" in
	x86_64 | amd64)
		homecli_has_token amd64 "${tokens[@]}" || return 1
		if homecli_has_token v1 "${tokens[@]}"; then
			score=30
		elif homecli_has_token v2 "${tokens[@]}"; then
			score=20
		elif homecli_has_token v3 "${tokens[@]}"; then
			score=10
		else
			score=0
		fi
		;;
	aarch64 | arm64)
		if ! homecli_has_token arm64 "${tokens[@]}" && ! homecli_has_token aarch64 "${tokens[@]}"; then
			return 1
		fi
		score=0
		if homecli_has_token arm64 "${tokens[@]}"; then
			score=$((score + 2))
		fi
		if homecli_has_token v8 "${tokens[@]}"; then
			score=$((score + 1))
		fi
		;;
	*) return 1 ;;
	esac

	printf '%s\n' $((score + penalty))
}


homecli_select_mihomo_asset() {
	local assets_file=$1
	local name url score
	local best_name="" best_url="" best_score=""

	while IFS=$'\t' read -r name url; do
		[ -n "$name" ] || continue
		if score=$(homecli_mihomo_score "$name"); then
			if [ -z "$best_score" ] || [ "$score" -gt "$best_score" ]; then
				best_score=$score
				best_name=$name
				best_url=$url
			fi
		fi
	done <"$assets_file"

	[ -n "$best_url" ] || return 1
	printf '%s\t%s\n' "$best_name" "$best_url"
}


homecli_extract_mihomo_archive() {
	local archive=$1
	local archive_name=$2
	local dest=$3

	if [[ "$archive_name" == *.tar.gz ]]; then
		homecli_tar_member_to_file "$archive" mihomo "$dest"
	elif [[ "$archive_name" == *.gz ]]; then
		gzip -dc "$archive" >"$dest"
	else
		cp "$archive" "$dest"
	fi
}


homecli_install_mihomo() {
	local overwrite=${1:-true}
	local bin_file="$HOMECLI_BIN_DIR/mihomo"
	local assets_file asset archive_name url tmp

	homecli_log "Installing mihomo..."
	if [ -e "$bin_file" ] && [ "$overwrite" != "true" ]; then
		return 0
	fi

	homecli_temp_file assets_file
	homecli_release_assets_to_file MetaCubeX mihomo "$assets_file"
	if ! asset=$(homecli_select_mihomo_asset "$assets_file"); then
		homecli_die "Unable to find a suitable mihomo release asset"
	fi
	IFS=$'\t' read -r archive_name url <<<"$asset"

	homecli_temp_file tmp
	homecli_curl "$tmp" "$url"
	homecli_extract_mihomo_archive "$tmp" "$archive_name" "$bin_file"
	chmod 755 "$bin_file"
	homecli_log "Installing mihomo done."
}
