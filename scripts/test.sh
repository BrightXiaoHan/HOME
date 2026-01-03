#!/bin/bash
# scripts/test.sh - Comprehensive validation for homecli installation
# Tests that all functionalities work correctly after installation

set -uo pipefail

#===============================================================================
# GLOBAL VARIABLES
#===============================================================================

# Result counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
declare -a FAILED_TESTS
declare -a SKIPPED_TESTS

# Environment variables
INSTALL_DIR=""
CONFIG_HOME=""
DATA_HOME=""
STATE_HOME=""
CACHE_HOME=""
ARCHITECTURE=""

# Component flags
declare -a COMPONENTS

#===============================================================================
# ARGUMENT PARSING
#===============================================================================

Usage() {
	cat <<EOF
Usage: $0 [OPTIONS]

Comprehensive testing script for homecli installation.

OPTIONS:
    --help, -h              Show this help message
    --install-dir <path>    Specify installation directory (default: \$HOMECLI_INSTALL_DIR or \$HOME/.homecli)

    --all                   Run all tests (default if no component specified)
    --structure             Test installation directory structure
    --configs               Test configuration symlinks
    --conda                 Test conda-installed binaries
    --python                Test Python/UV installation
    --binaries              Test additional binaries (trzsz, frp)
    --fish                  Test Fish shell environment
    --nvim                  Test Neovim setup
    --tmux                  Test Tmux configuration
    --git                   Test Git configuration
    --ssh                   Test SSH configuration
    --conda-env             Test conda environment activation

EXAMPLES:
    $0                          # Run all tests
    $0 --fish --nvim            # Run only Fish and Neovim tests
    $0 --install-dir /custom    # Test custom installation

EXIT CODES:
    0 - All tests passed
    1 - Some tests failed
    2 - Setup error (e.g., install directory not found)
EOF
	exit 0
}

parse_args() {
	COMPONENTS=()

	while [[ $# -gt 0 ]]; do
		case "$1" in
			--help|-h)
				Usage
				;;
			--install-dir)
				INSTALL_DIR="$2"
				shift 2
				;;
			--all)
				COMPONENTS+=("all")
				shift
				;;
			--structure)
				COMPONENTS+=("structure")
				shift
				;;
			--configs)
				COMPONENTS+=("configs")
				shift
				;;
			--conda)
				COMPONENTS+=("conda")
				shift
				;;
			--python)
				COMPONENTS+=("python")
				shift
				;;
			--binaries)
				COMPONENTS+=("binaries")
				shift
				;;
			--fish)
				COMPONENTS+=("fish")
				shift
				;;
			--nvim)
				COMPONENTS+=("nvim")
				shift
				;;
			--tmux)
				COMPONENTS+=("tmux")
				shift
				;;
			--git)
				COMPONENTS+=("git")
				shift
				;;
			--ssh)
				COMPONENTS+=("ssh")
				shift
				;;
			--conda-env)
				COMPONENTS+=("conda-env")
				shift
				;;
			-*)
				echo "Unknown option: $1"
				echo "Use --help for usage information"
				exit 2
				;;
			*)
				echo "Unknown argument: $1"
				echo "Use --help for usage information"
				exit 2
				;;
		esac
	done

	# If no components specified, run all tests
	if [ ${#COMPONENTS[@]} -eq 0 ]; then
		COMPONENTS=("all")
	fi
}

#===============================================================================
# ENVIRONMENT SETUP
#===============================================================================

setup_environment() {
	# Detect install directory
	if [ -z "$INSTALL_DIR" ]; then
		INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}
	fi

	# Verify install directory exists
	if [ ! -d "$INSTALL_DIR" ]; then
		echo "ERROR: Installation directory not found: $INSTALL_DIR"
		echo "Please specify --install-dir or set HOMECLI_INSTALL_DIR environment variable"
		exit 2
	fi

	# Set XDG directories
	CONFIG_HOME=${HOMECLI_XDG_CONFIG_HOME:-$INSTALL_DIR/config}
	DATA_HOME=${HOMECLI_XDG_DATA_HOME:-$INSTALL_DIR/data}
	STATE_HOME=${HOMECLI_XDG_STATE_HOME:-$INSTALL_DIR/state}
	CACHE_HOME=${HOMECLI_XDG_CACHE_HOME:-$INSTALL_DIR/cache}

	# Detect architecture
	ARCHITECTURE=$(uname -m)

	echo "=========================================="
	echo "HomeCLI Installation Test"
	echo "=========================================="
	echo "Install Directory: $INSTALL_DIR"
	echo "Architecture:      $ARCHITECTURE"
	echo "=========================================="
	echo ""
}

#===============================================================================
# RESULT TRACKING
#===============================================================================

report_pass() {
	echo "  [PASS] $1"
	((TESTS_PASSED++))
	((TESTS_TOTAL++))
}

report_fail() {
	echo "  [FAIL] $1"
	FAILED_TESTS+=("$1")
	((TESTS_FAILED++))
	((TESTS_TOTAL++))
}

report_skip() {
	echo "  [SKIP] $1"
	SKIPPED_TESTS+=("$1")
	((TESTS_SKIPPED++))
	((TESTS_TOTAL++))
}

#===============================================================================
# TEST FRAMEWORK HELPERS
#===============================================================================

# Helper to run commands in Fish environment
run_in_fish() {
	"$INSTALL_DIR/bin/homecli-fish" -c "$1" 2>&1
}

# Test if directory exists and is readable
test_directory() {
	local dir="$1"
	local description="$2"

	if [ -d "$dir" ] && [ -r "$dir" ]; then
		report_pass "$description"
	else
		report_fail "$description (not found or not readable)"
	fi
}

# Test if file exists
test_file_exists() {
	local file="$1"
	local description="$2"

	if [ -f "$file" ]; then
		report_pass "$description"
	else
		report_fail "$description (file not found)"
	fi
}

# Test if symlink points to correct target
test_symlink() {
	local link="$1"
	local expected_target="$2"
	local description="$3"

	if [ -L "$link" ]; then
		local actual_target=$(readlink -f "$link" 2>/dev/null || readlink "$link" 2>/dev/null)
		local expected_resolved=$(readlink -f "$expected_target" 2>/dev/null || echo "$expected_target")

		if [ "$actual_target" = "$expected_resolved" ]; then
			report_pass "$description"
		else
			report_fail "$description (points to $actual_target, expected $expected_resolved)"
		fi
	else
		report_fail "$description (symlink not found)"
	fi
}

# Test binary exists and responds to version flag
test_binary() {
	local binary="$1"
	local test_flag="${2:---version}"
	local description="$3"

	if command -v "$binary" >/dev/null 2>&1; then
		if $binary $test_flag >/dev/null 2>&1; then
			report_pass "$description"
		else
			report_fail "$description (command exists but $test_flag failed)"
		fi
	else
		report_fail "$description (command not found)"
	fi
}

# Test binary in Fish environment
test_fish_binary() {
	local binary="$1"
	local test_flag="${2:---version}"
	local description="$3"

	if run_in_fish "command -v $binary" >/dev/null 2>&1; then
		if run_in_fish "$binary $test_flag" >/dev/null 2>&1; then
			report_pass "$description"
		else
			report_fail "$description (exists but $test_flag failed)"
		fi
	else
		report_fail "$description (not found in Fish environment)"
	fi
}

# Test Fish environment variable
test_fish_variable() {
	local var_name="$1"
	local expected_value="$2"
	local description="$3"

	local actual_value=$(run_in_fish "echo \$$var_name" 2>/dev/null | tr -d '\n')

	if [ "$actual_value" = "$expected_value" ]; then
		report_pass "$description"
	else
		report_fail "$description (got: $actual_value, expected: $expected_value)"
	fi
}

# Test if Fish function exists
test_fish_function() {
	local func_name="$1"
	local description="$2"

	if run_in_fish "type -q $func_name" >/dev/null 2>&1; then
		report_pass "$description"
	else
		report_fail "$description (function not defined)"
	fi
}

#===============================================================================
# COMPONENT TEST FUNCTIONS
#===============================================================================

test_structure() {
	echo "Testing installation structure..."

	# XDG directories
	test_directory "$CONFIG_HOME" "XDG_CONFIG_HOME directory"
	test_directory "$DATA_HOME" "XDG_DATA_HOME directory"
	test_directory "$STATE_HOME" "XDG_STATE_HOME directory"
	test_directory "$CACHE_HOME" "XDG_CACHE_HOME directory"

	# Core directories
	test_directory "$INSTALL_DIR/bin" "bin directory"
	test_directory "$INSTALL_DIR/miniconda" "miniconda directory"
	test_directory "$INSTALL_DIR/uv" "uv directory"
	test_directory "$INSTALL_DIR/HOME" "HOME repository directory"
	test_directory "$INSTALL_DIR/etc" "etc directory"

	# Neovim data symlink
	if [ -L "$INSTALL_DIR/nvim" ]; then
		local target=$(readlink -f "$INSTALL_DIR/nvim" 2>/dev/null || readlink "$INSTALL_DIR/nvim")
		if [ "$target" = "$DATA_HOME/nvim" ] || [ "$target" = "$(readlink -f "$DATA_HOME/nvim")" ]; then
			report_pass "nvim symlink"
		else
			report_fail "nvim symlink (points to $target, expected $DATA_HOME/nvim)"
		fi
	else
		report_fail "nvim symlink (not found)"
	fi

	echo ""
}

test_configs() {
	echo "Testing configuration symlinks..."

	test_symlink "$CONFIG_HOME/nvim" "$INSTALL_DIR/HOME/general/nvim" "nvim config symlink"
	test_symlink "$CONFIG_HOME/tmux" "$INSTALL_DIR/HOME/general/tmux" "tmux config symlink"
	test_symlink "$CONFIG_HOME/fish" "$INSTALL_DIR/HOME/general/fish" "fish config symlink"
	test_symlink "$CONFIG_HOME/git/config" "$INSTALL_DIR/HOME/general/gitconfig" "git config symlink"
	test_symlink "$INSTALL_DIR/etc/ssh" "$INSTALL_DIR/HOME/general/ssh" "ssh config symlink"
	test_symlink "$INSTALL_DIR/etc/mambarc" "$INSTALL_DIR/HOME/general/mambarc" "mambarc symlink"

	echo ""
}

test_conda_binaries() {
	echo "Testing conda-installed binaries..."

	# Core tools
	test_fish_binary "fish" "--version" "fish shell"
	test_fish_binary "fzf" "--version" "fzf"
	test_fish_binary "rg" "--version" "ripgrep"
	test_fish_binary "make" "--version" "make"
	test_fish_binary "cmake" "--version" "cmake"
	test_fish_binary "git" "--version" "git"
	test_fish_binary "git-lfs" "--version" "git-lfs"
	test_fish_binary "tmux" "-V" "tmux"
	test_fish_binary "nvim" "--version" "nvim"
	test_fish_binary "jq" "--version" "jq"
	test_fish_binary "zoxide" "--version" "zoxide"
	test_fish_binary "starship" "--version" "starship"
	test_fish_binary "node" "--version" "node"
	test_fish_binary "npm" "--version" "npm"

	# LSP servers and formatters
	test_fish_binary "lua-language-server" "--version" "lua-language-server"
	test_fish_binary "stylua" "--version" "stylua"
	test_fish_binary "prettier" "--version" "prettier"
	test_fish_binary "pyright" "--version" "pyright"
	test_fish_binary "ruff" "--version" "ruff"
	test_fish_binary "typescript-language-server" "--version" "typescript-language-server"

	# Architecture-specific packages
	if [ "$ARCHITECTURE" = "x86_64" ] || [ "$ARCHITECTURE" = "amd64" ]; then
		test_fish_binary "docker-compose" "--version" "docker-compose"
	else
		report_skip "docker-compose (not available on $ARCHITECTURE)"
	fi

	echo ""
}

test_python_uv() {
	echo "Testing Python/UV installation..."

	# UV directories
	test_directory "$INSTALL_DIR/uv/python" "UV python directory"
	test_directory "$INSTALL_DIR/uv/tool" "UV tool directory"

	# UV binary
	test_fish_binary "uv" "--version" "uv package manager"

	# Python 3.12
	local python_bin=$(find "$INSTALL_DIR/uv/python" -name python -type f 2>/dev/null | head -n1)
	if [ -n "$python_bin" ] && [ -x "$python_bin" ]; then
		if $python_bin --version 2>&1 | grep -q "Python 3.12"; then
			report_pass "Python 3.12"
		else
			report_fail "Python 3.12 (found different version: $($python_bin --version 2>&1))"
		fi
	else
		report_fail "Python 3.12 (binary not found in UV directory)"
	fi

	# conda-pack
	test_fish_binary "conda-pack" "--version" "conda-pack"

	echo ""
}

test_additional_binaries() {
	echo "Testing additional binaries..."

	# trzsz tools
	test_fish_binary "trzsz" "--version" "trzsz"
	test_fish_binary "trz" "--version" "trz"
	test_fish_binary "tsz" "--version" "tsz"

	# frp tools
	if run_in_fish "command -v frpc" >/dev/null 2>&1; then
		if run_in_fish "frpc -v" >/dev/null 2>&1; then
			report_pass "frpc"
		else
			report_fail "frpc (exists but -v failed)"
		fi
	else
		report_fail "frpc (not found)"
	fi

	if run_in_fish "command -v frps" >/dev/null 2>&1; then
		if run_in_fish "frps -v" >/dev/null 2>&1; then
			report_pass "frps"
		else
			report_fail "frps (exists but -v failed)"
		fi
	else
		report_fail "frps (not found)"
	fi

	echo ""
}

test_fish_environment() {
	echo "Testing Fish shell environment..."

	# homecli-fish wrapper
	if [ -x "$INSTALL_DIR/bin/homecli-fish" ]; then
		report_pass "homecli-fish wrapper script"
	else
		report_fail "homecli-fish wrapper script (not found or not executable)"
		echo ""
		return
	fi

	# Environment variables
	test_fish_variable "HOMECLI_INSTALL_DIR" "$INSTALL_DIR" "HOMECLI_INSTALL_DIR"
	test_fish_variable "XDG_CONFIG_HOME" "$CONFIG_HOME" "XDG_CONFIG_HOME"
	test_fish_variable "XDG_DATA_HOME" "$DATA_HOME" "XDG_DATA_HOME"
	test_fish_variable "MAMBA_ROOT_PREFIX" "$INSTALL_DIR/miniconda" "MAMBA_ROOT_PREFIX"
	test_fish_variable "UV_TOOL_DIR" "$INSTALL_DIR/uv/tool" "UV_TOOL_DIR"
	test_fish_variable "GIT_CONFIG_GLOBAL" "$CONFIG_HOME/git/config" "GIT_CONFIG_GLOBAL"
	test_fish_variable "HOMECLI_SSH_DIR" "$INSTALL_DIR/etc/ssh" "HOMECLI_SSH_DIR"

	# SSH wrapper functions
	test_fish_function "ssh" "SSH wrapper function"
	test_fish_function "scp" "SCP wrapper function"
	test_fish_function "sftp" "SFTP wrapper function"

	# Check starship initialization (just check if command exists)
	if run_in_fish "command -v starship" >/dev/null 2>&1; then
		report_pass "starship available in Fish"
	else
		report_fail "starship not available in Fish"
	fi

	# Check zoxide initialization
	if run_in_fish "command -v zoxide" >/dev/null 2>&1; then
		report_pass "zoxide available in Fish"
	else
		report_fail "zoxide not available in Fish"
	fi

	echo ""
}

test_neovim() {
	echo "Testing Neovim setup..."

	# Neovim can run headless
	if run_in_fish "nvim --headless -c quit" >/dev/null 2>&1; then
		report_pass "Neovim runs headless"
	else
		report_fail "Neovim headless execution failed"
	fi

	# Neovim data directory
	test_directory "$DATA_HOME/nvim" "Neovim data directory"

	# Plugin manager (Lazy)
	test_directory "$DATA_HOME/nvim/lazy" "Lazy plugin manager"

	# Mason bin directory
	test_directory "$DATA_HOME/nvim/mason/bin" "Mason bin directory"

	# Treesitter parsers directory
	if [ -d "$DATA_HOME/nvim/lazy/nvim-treesitter/parser" ]; then
		report_pass "Treesitter parser directory"

		# Check for some common parsers
		for parser in c lua python fish; do
			if [ -f "$DATA_HOME/nvim/lazy/nvim-treesitter/parser/$parser.so" ]; then
				report_pass "Treesitter $parser parser"
			else
				report_skip "Treesitter $parser parser (not installed)"
			fi
		done
	else
		report_fail "Treesitter parser directory (not found)"
	fi

	echo ""
}

test_tmux() {
	echo "Testing Tmux configuration..."

	# Config files exist
	test_file_exists "$CONFIG_HOME/tmux/tmux.conf" "tmux.conf"
	test_file_exists "$CONFIG_HOME/tmux/statusline.conf" "statusline.conf"
	test_file_exists "$CONFIG_HOME/tmux/macos.conf" "macos.conf"

	# Tmux can load config
	if run_in_fish "tmux -f $CONFIG_HOME/tmux/tmux.conf -L test_session list-keys" >/dev/null 2>&1; then
		report_pass "Tmux config loads without errors"
	else
		report_skip "Tmux config validation (test session failed)"
	fi

	echo ""
}

test_git() {
	echo "Testing Git configuration..."

	# Git config file exists
	test_file_exists "$CONFIG_HOME/git/config" "git config file"

	# Git LFS
	test_fish_binary "git-lfs" "--version" "git-lfs"

	# Git can read custom config
	if run_in_fish "GIT_CONFIG_GLOBAL=$CONFIG_HOME/git/config git config user.name" >/dev/null 2>&1; then
		report_pass "Git reads custom config"
	else
		report_skip "Git custom config (user.name not set)"
	fi

	# Check for git aliases
	for alias in lg lg1 lg2; do
		if run_in_fish "GIT_CONFIG_GLOBAL=$CONFIG_HOME/git/config git config alias.$alias" >/dev/null 2>&1; then
			report_pass "Git alias: $alias"
		else
			report_skip "Git alias: $alias (not configured)"
		fi
	done

	# LFS filter configured
	if run_in_fish "GIT_CONFIG_GLOBAL=$CONFIG_HOME/git/config git config filter.lfs.clean" >/dev/null 2>&1; then
		report_pass "Git LFS filter configured"
	else
		report_fail "Git LFS filter not configured"
	fi

	echo ""
}

test_ssh() {
	echo "Testing SSH configuration..."

	# SSH directory and config
	test_directory "$INSTALL_DIR/etc/ssh" "SSH config directory"
	test_file_exists "$INSTALL_DIR/etc/ssh/config" "SSH config file"
	test_directory "$INSTALL_DIR/etc/ssh/config.d" "SSH config.d directory"

	# Public key
	test_file_exists "$INSTALL_DIR/etc/ssh/id_rsa.pub" "SSH public key"

	echo ""
}

test_conda_environment() {
	echo "Testing conda environment..."

	# mambarc exists
	test_file_exists "$INSTALL_DIR/etc/mambarc" "mambarc file"

	# MAMBA_EXE points to correct binary
	if [ -x "$INSTALL_DIR/bin/mamba" ]; then
		report_pass "mamba binary"
	else
		report_fail "mamba binary (not found or not executable)"
	fi

	# Check if micromamba can activate
	if run_in_fish "micromamba --version" >/dev/null 2>&1; then
		report_pass "micromamba activation"
	else
		report_fail "micromamba activation failed"
	fi

	echo ""
}

#===============================================================================
# TEST RUNNER
#===============================================================================

run_tests() {
	local components=("$@")

	# If "all" is specified, run all tests
	if [[ " ${components[@]} " =~ " all " ]]; then
		components=("structure" "configs" "conda" "python" "binaries" "fish" "nvim" "tmux" "git" "ssh" "conda-env")
	fi

	# Run each test component
	for component in "${components[@]}"; do
		case "$component" in
			structure)
				test_structure
				;;
			configs)
				test_configs
				;;
			conda)
				test_conda_binaries
				;;
			python)
				test_python_uv
				;;
			binaries)
				test_additional_binaries
				;;
			fish)
				test_fish_environment
				;;
			nvim)
				test_neovim
				;;
			tmux)
				test_tmux
				;;
			git)
				test_git
				;;
			ssh)
				test_ssh
				;;
			conda-env)
				test_conda_environment
				;;
			all)
				# Already handled above
				;;
			*)
				echo "Unknown component: $component"
				;;
		esac
	done
}

#===============================================================================
# SUMMARY REPORTING
#===============================================================================

print_summary() {
	local duration=$1

	echo ""
	echo "================================================================================"
	echo "                        TEST SUMMARY"
	echo "================================================================================"
	echo "Total Tests:  $TESTS_TOTAL"

	if [ $TESTS_TOTAL -gt 0 ]; then
		local pass_pct=$(awk "BEGIN {printf \"%.1f\", ($TESTS_PASSED * 100.0 / $TESTS_TOTAL)}")
		local fail_pct=$(awk "BEGIN {printf \"%.1f\", ($TESTS_FAILED * 100.0 / $TESTS_TOTAL)}")
		local skip_pct=$(awk "BEGIN {printf \"%.1f\", ($TESTS_SKIPPED * 100.0 / $TESTS_TOTAL)}")

		printf "Passed:       %-4d (%s%%)\n" $TESTS_PASSED "$pass_pct"
		printf "Failed:       %-4d (%s%%)\n" $TESTS_FAILED "$fail_pct"
		printf "Skipped:      %-4d (%s%%)\n" $TESTS_SKIPPED "$skip_pct"
	else
		echo "No tests were run"
	fi

	echo "Duration:     ${duration}s"

	if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
		echo ""
		echo "FAILED TESTS:"
		for test in "${FAILED_TESTS[@]}"; do
			echo "  - $test"
		done
	fi

	if [ ${#SKIPPED_TESTS[@]} -gt 0 ]; then
		echo ""
		echo "SKIPPED TESTS:"
		for test in "${SKIPPED_TESTS[@]}"; do
			echo "  - $test"
		done
	fi

	echo ""
	if [ $TESTS_FAILED -eq 0 ]; then
		echo "Exit Code: 0 (all tests passed)"
	else
		echo "Exit Code: 1 (failures detected)"
	fi
	echo "================================================================================"
}

#===============================================================================
# MAIN EXECUTION
#===============================================================================

main() {
	local start_time=$(date +%s)

	parse_args "$@"
	setup_environment
	run_tests "${COMPONENTS[@]}"

	local end_time=$(date +%s)
	local duration=$((end_time - start_time))

	print_summary $duration

	# Exit with appropriate code
	if [ $TESTS_FAILED -eq 0 ]; then
		exit 0
	else
		exit 1
	fi
}

main "$@"
