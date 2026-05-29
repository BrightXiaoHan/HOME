#!/usr/bin/env bash
set -euo pipefail

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

homecli_usage() {
	cat <<'EOF'
Usage: install_components.sh [-c|--component] <component...>

Components:
  all       Install frp, trzsz, mihomo, mihoro, mamba, conda, and neovim
  update    Update frp, trzsz, mihomo, and mihoro
  frp       Install frp binaries
  trzsz     Install trzsz binaries
  mihomo    Install mihomo binary
  mihoro    Install mihoro binary
  mamba     Install micromamba wrapper
  conda     Create and populate the base micromamba environment
  neovim    Install Neovim plugins with vim.pack
EOF
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

homecli_is_musl() {
	if ! command -v ldd >/dev/null 2>&1; then
		return 1
	fi
	ldd --version 2>&1 | grep -qi musl
}

homecli_mihoro_target_triple() {
	local arch=$HOMECLI_ARCH
	local libc=gnu

	case "$arch" in
	amd64) arch=x86_64 ;;
	arm64) arch=aarch64 ;;
	esac

	if homecli_is_musl; then
		libc=musl
	fi

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

homecli_install_conda() {
	local mamba_path="$HOMECLI_BIN_DIR/mamba"
	local package
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
	homecli_log "Installing other packages done."
}

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

homecli_install_components() {
	local components=("$@")
	local selected=()
	local component

	if [ "${#components[@]}" -eq 0 ]; then
		components=(all)
	fi

	for component in "${components[@]}"; do
		case "$component" in
		all)
			selected=(frp trzsz mihomo mihoro mamba conda neovim)
			break
			;;
		update)
			selected=(frp trzsz mihomo mihoro)
			break
			;;
		frp | trzsz | mihomo | mihoro | mamba | conda | neovim)
			selected+=("$component")
			;;
		*)
			homecli_die "Unknown component: $component"
			;;
		esac
	done

	for component in "${selected[@]}"; do
		"homecli_install_$component"
	done
}

main() {
	trap homecli_cleanup EXIT

	case "${1:-}" in
	-h | --help)
		homecli_usage
		exit 0
		;;
	esac

	if [ "${1:-}" = "-c" ] || [ "${1:-}" = "--component" ]; then
		shift
	fi

	homecli_prepare
	homecli_install_components "$@"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi
