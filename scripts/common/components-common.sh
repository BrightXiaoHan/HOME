#!/usr/bin/env bash
# Shared helpers for Linux component installation.

HOMECLI_TEMP_PATHS=()

homecli_cleanup() {
	set +u
	local path
	for path in "${HOMECLI_TEMP_PATHS[@]}"; do
		rm -rf "$path"
	done
}


homecli_temp_file() {
	local __var=$1
	local __tmp
	__tmp=$(mktemp)
	HOMECLI_TEMP_PATHS+=("$__tmp")
	printf -v "$__var" '%s' "$__tmp"
}


homecli_temp_dir() {
	local __var=$1
	local __tmp
	__tmp=$(mktemp -d)
	HOMECLI_TEMP_PATHS+=("$__tmp")
	printf -v "$__var" '%s' "$__tmp"
}


homecli_log() {
	printf '[homecli] %s\n' "$*" >&2
}


homecli_die() {
	printf 'Error: %s\n' "$*" >&2
	exit 1
}


homecli_require_command() {
	local command_name=$1
	if ! command -v "$command_name" >/dev/null 2>&1; then
		homecli_die "$command_name is required but not installed"
	fi
}


homecli_prepare() {
	local platform
	platform=$(uname -s)
	if [ "$platform" != "Linux" ]; then
		homecli_die "Unsupported platform: $platform"
	fi

	HOMECLI_ARCH=${HOMECLI_ARCH:-$(uname -m)}
	case "$HOMECLI_ARCH" in
	x86_64 | amd64 | aarch64 | arm64) ;;
	*) homecli_die "Unsupported architecture: $HOMECLI_ARCH" ;;
	esac

	HOMECLI_INSTALL_DIR=${HOMECLI_INSTALL_DIR:-${INSTALL_DIR:-$HOME/.homecli}}
	HOMECLI_CACHE_DIR=$HOMECLI_INSTALL_DIR
	HOMECLI_BIN_DIR=$HOMECLI_CACHE_DIR/bin
	mkdir -p "$HOMECLI_BIN_DIR"
	export HOMECLI_INSTALL_DIR HOMECLI_ARCH

	homecli_require_command awk
	homecli_require_command curl
	homecli_require_command gzip
	homecli_require_command tar
}


homecli_curl() {
	local output=$1
	local url=$2
	local curl_args=(-fL --retry 3 --retry-delay 1 -H "User-Agent: homecli-installer")

	case "${HOMECLI_PRINT_PROGRESS:-true}" in
	false | False | FALSE | 0 | no | NO)
		curl_args+=(-sS)
		;;
	*)
		curl_args+=(--progress-bar)
		;;
	esac

	curl "${curl_args[@]}" -o "$output" "$url"
}


homecli_fetch_latest_release_json() {
	local owner=$1
	local repo=$2
	local output=$3
	local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
	local curl_args=(
		-fL
		-sS
		--retry 3
		--retry-delay 1
		-H "Accept: application/vnd.github+json"
		-H "User-Agent: homecli-installer"
	)

	if [ -n "$token" ]; then
		curl_args+=(-H "Authorization: Bearer $token")
	fi

	curl "${curl_args[@]}" "https://api.github.com/repos/$owner/$repo/releases/latest" >"$output"
}


homecli_latest_release_tag_from_redirect() {
	local owner=$1
	local repo=$2
	local effective tag

	effective=$(curl -fsSIL -o /dev/null -w '%{url_effective}' -H "User-Agent: homecli-installer" "https://github.com/$owner/$repo/releases/latest")
	effective=${effective%/}
	tag=${effective##*/}
	if [ -z "$tag" ] || [ "$tag" = "latest" ]; then
		return 1
	fi
	printf '%s\n' "$tag"
}


homecli_latest_release_tag() {
	local owner=$1
	local repo=$2
	local json_file tag
	homecli_temp_file json_file
	tag=""

	if command -v jq >/dev/null 2>&1; then
		if homecli_fetch_latest_release_json "$owner" "$repo" "$json_file" 2>/dev/null; then
			tag=$(jq -r '.tag_name // empty' "$json_file")
		fi
	fi

	if [ -z "$tag" ]; then
		if ! tag=$(homecli_latest_release_tag_from_redirect "$owner" "$repo"); then
			tag=""
		fi
	fi

	if [ -z "$tag" ]; then
		homecli_die "Unable to determine latest release for $owner/$repo"
	fi
	printf '%s\n' "$tag"
}


homecli_release_assets_from_file() {
	local json_file=$1
	if command -v jq >/dev/null 2>&1; then
		jq -r '.assets[] | [.name, .browser_download_url] | @tsv' "$json_file"
	else
		awk '
			/"assets"[[:space:]]*:/ { in_assets = 1 }
			in_assets && /"name"[[:space:]]*:/ {
				line = $0
				sub(/^[^"]*"name"[[:space:]]*:[[:space:]]*"/, "", line)
				sub(/".*$/, "", line)
				name = line
			}
			in_assets && /"browser_download_url"[[:space:]]*:/ {
				line = $0
				sub(/^[^"]*"browser_download_url"[[:space:]]*:[[:space:]]*"/, "", line)
				sub(/".*$/, "", line)
				if (name != "") {
					print name "\t" line
					name = ""
				}
			}
		' "$json_file"
	fi
}


homecli_release_assets_to_file() {
	local owner=$1
	local repo=$2
	local output=$3
	local json_file
	homecli_temp_file json_file
	if command -v jq >/dev/null 2>&1 && homecli_fetch_latest_release_json "$owner" "$repo" "$json_file" 2>/dev/null; then
		if homecli_release_assets_from_file "$json_file" >"$output" && [ -s "$output" ]; then
			return 0
		fi
	fi

	homecli_log "GitHub API unavailable for $owner/$repo; falling back to release page."
	homecli_release_assets_from_html "$owner" "$repo" >"$output"
	if [ ! -s "$output" ]; then
		homecli_die "Unable to determine release assets for $owner/$repo"
	fi
}


homecli_release_assets_from_html() {
	local owner=$1
	local repo=$2
	local tag page_file

	tag=$(homecli_latest_release_tag_from_redirect "$owner" "$repo")
	homecli_temp_file page_file
	curl -fsSL --retry 3 --retry-delay 1 -H "User-Agent: homecli-installer" "https://github.com/$owner/$repo/releases/expanded_assets/$tag" >"$page_file"
	awk -v prefix="https://github.com" '
		{
			line = $0
			while (match(line, /href="[^"]+"/)) {
				href = substr(line, RSTART + 6, RLENGTH - 7)
				if (href ~ /\/releases\/download\//) {
					name = href
					sub(/^.*\//, "", name)
					gsub(/&amp;/, "\\&", href)
					print name "\t" prefix href
				}
				line = substr(line, RSTART + RLENGTH)
			}
		}
	' "$page_file"
}


homecli_has_token() {
	local needle=$1
	shift
	local token
	for token in "$@"; do
		if [ "$token" = "$needle" ]; then
			return 0
		fi
	done
	return 1
}


homecli_tar_member_to_file() {
	local archive=$1
	local wanted_name=$2
	local dest=$3
	local list_file member

	homecli_temp_file list_file
	tar -tzf "$archive" >"$list_file"
	member=$(awk -F/ -v wanted="$wanted_name" '$0 !~ /\/$/ && $NF == wanted { print; exit }' "$list_file")
	if [ -z "$member" ]; then
		member=$(awk '$0 !~ /\/$/ { print; exit }' "$list_file")
	fi
	if [ -z "$member" ]; then
		homecli_die "$wanted_name archive has no files"
	fi

	tar -xOf "$archive" "$member" >"$dest"
}


homecli_zip_member_to_file() {
	local archive=$1
	local wanted_name=$2
	local dest=$3
	local list_file member

	if ! command -v unzip >/dev/null 2>&1; then
		homecli_die "unzip is required to extract $archive"
	fi

	homecli_temp_file list_file
	unzip -Z1 "$archive" >"$list_file"
	member=$(awk -F/ -v wanted="$wanted_name" '$0 !~ /\/$/ && $NF == wanted { print; exit }' "$list_file")
	if [ -z "$member" ]; then
		member=$(awk '$0 !~ /\/$/ { print; exit }' "$list_file")
	fi
	if [ -z "$member" ]; then
		homecli_die "$wanted_name archive has no files"
	fi

	unzip -p "$archive" "$member" >"$dest"
}
