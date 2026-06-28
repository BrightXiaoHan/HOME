#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

. "$SCRIPT_DIR/../common/components-common.sh"
. "$SCRIPT_DIR/components/frp.sh"
. "$SCRIPT_DIR/components/trzsz.sh"
. "$SCRIPT_DIR/components/mihomo.sh"
. "$SCRIPT_DIR/components/mihoro.sh"
. "$SCRIPT_DIR/components/mamba.sh"
. "$SCRIPT_DIR/components/conda.sh"
. "$SCRIPT_DIR/components/neovim.sh"

homecli_usage() {
	cat <<'EOF'
Usage: components.sh [-c|--component] <component...>

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
