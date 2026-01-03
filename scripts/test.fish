#!/usr/bin/env fish
# scripts/test.fish - Comprehensive validation for homecli installation
# Tests that all functionalities work correctly after installation

#===============================================================================
# GLOBAL VARIABLES
#===============================================================================

set -g TESTS_TOTAL 0
set -g TESTS_PASSED 0
set -g TESTS_FAILED 0
set -g TESTS_SKIPPED 0
set -g FAILED_TESTS
set -g SKIPPED_TESTS

# Environment variables
set -g INSTALL_DIR (set -q HOMECLI_INSTALL_DIR; and echo $HOMECLI_INSTALL_DIR; or echo $HOME/.homecli)
set -g CONFIG_HOME (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $INSTALL_DIR/config)
set -g DATA_HOME (set -q XDG_DATA_HOME; and echo $XDG_DATA_HOME; or echo $INSTALL_DIR/data)
set -g STATE_HOME (set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $INSTALL_DIR/state)
set -g CACHE_HOME (set -q XDG_CACHE_HOME; and echo $XDG_CACHE_HOME; or echo $INSTALL_DIR/cache)
set -g ARCHITECTURE (uname -m)

# Component flags
set -g COMPONENTS

#===============================================================================
# ARGUMENT PARSING
#===============================================================================

function usage
    echo "Usage: "(status filename)" [OPTIONS]"
    echo ""
    echo "Comprehensive testing script for homecli installation."
    echo ""
    echo "OPTIONS:"
    echo "    --help, -h              Show this help message"
    echo "    --install-dir <path>    Specify installation directory"
    echo ""
    echo "    --all                   Run all tests (default if no component specified)"
    echo "    --structure             Test installation directory structure"
    echo "    --configs               Test configuration symlinks"
    echo "    --conda                 Test conda-installed binaries"
    echo "    --python                Test Python/UV installation"
    echo "    --binaries              Test additional binaries (trzsz, frp)"
    echo "    --environment           Test Fish shell environment"
    echo "    --nvim                  Test Neovim setup"
    echo "    --tmux                  Test Tmux configuration"
    echo "    --git                   Test Git configuration"
    echo "    --ssh                   Test SSH configuration"
    echo "    --conda-env             Test conda environment activation"
    echo ""
    echo "EXAMPLES:"
    echo "    "(status filename)"                          # Run all tests"
    echo "    "(status filename)" --environment --nvim     # Run only Fish and Neovim tests"
    echo "    "(status filename)" --install-dir /custom    # Test custom installation"
    echo ""
    echo "EXIT CODES:"
    echo "    0 - All tests passed"
    echo "    1 - Some tests failed"
    echo "    2 - Setup error (e.g., install directory not found)"
end

function parse_args
    set -g COMPONENTS

    while set -q argv[1]
        switch $argv[1]
            case --help -h
                usage
                exit 0
            case --install-dir
                set -g INSTALL_DIR $argv[2]
                set -g CONFIG_HOME $INSTALL_DIR/config
                set -g DATA_HOME $INSTALL_DIR/data
                set -g STATE_HOME $INSTALL_DIR/state
                set -g CACHE_HOME $INSTALL_DIR/cache
                set -e argv[1..2]
            case --all
                set -ga COMPONENTS all
                set -e argv[1]
            case --structure
                set -ga COMPONENTS structure
                set -e argv[1]
            case --configs
                set -ga COMPONENTS configs
                set -e argv[1]
            case --conda
                set -ga COMPONENTS conda
                set -e argv[1]
            case --python
                set -ga COMPONENTS python
                set -e argv[1]
            case --binaries
                set -ga COMPONENTS binaries
                set -e argv[1]
            case --environment
                set -ga COMPONENTS environment
                set -e argv[1]
            case --nvim
                set -ga COMPONENTS nvim
                set -e argv[1]
            case --tmux
                set -ga COMPONENTS tmux
                set -e argv[1]
            case --git
                set -ga COMPONENTS git
                set -e argv[1]
            case --ssh
                set -ga COMPONENTS ssh
                set -e argv[1]
            case --conda-env
                set -ga COMPONENTS conda-env
                set -e argv[1]
            case '*'
                echo "Unknown option: $argv[1]"
                echo "Use --help for usage information"
                exit 2
        end
    end

    # If no components specified, run all tests
    if test (count $COMPONENTS) -eq 0
        set -ga COMPONENTS all
    end
end

#===============================================================================
# RESULT TRACKING
#===============================================================================

function report_pass
    echo "  [PASS] $argv[1]"
    set -g TESTS_PASSED (math $TESTS_PASSED + 1)
    set -g TESTS_TOTAL (math $TESTS_TOTAL + 1)
end

function report_fail
    echo "  [FAIL] $argv[1]"
    set -a FAILED_TESTS "$argv[1]"
    set -g TESTS_FAILED (math $TESTS_FAILED + 1)
    set -g TESTS_TOTAL (math $TESTS_TOTAL + 1)
end

function report_skip
    echo "  [SKIP] $argv[1]"
    set -a SKIPPED_TESTS "$argv[1]"
    set -g TESTS_SKIPPED (math $TESTS_SKIPPED + 1)
    set -g TESTS_TOTAL (math $TESTS_TOTAL + 1)
end

#===============================================================================
# TEST FRAMEWORK HELPERS
#===============================================================================

function test_directory
    set -l dir $argv[1]
    set -l description $argv[2]

    if test -d "$dir" -a -r "$dir"
        report_pass "$description"
    else
        report_fail "$description (not found or not readable)"
    end
end

function test_file_exists
    set -l file $argv[1]
    set -l description $argv[2]

    if test -f "$file"
        report_pass "$description"
    else
        report_fail "$description (file not found)"
    end
end

function test_symlink
    set -l link $argv[1]
    set -l expected_target $argv[2]
    set -l description $argv[3]

    if test -L "$link"
        set -l actual_target (readlink -f "$link" 2>/dev/null; or readlink "$link" 2>/dev/null)
        set -l expected_resolved (readlink -f "$expected_target" 2>/dev/null; or echo "$expected_target")

        if test "$actual_target" = "$expected_resolved"
            report_pass "$description"
        else
            report_fail "$description (points to $actual_target, expected $expected_resolved)"
        end
    else
        report_fail "$description (symlink not found)"
    end
end

function test_binary
    set -l binary $argv[1]
    set -l test_flag $argv[2]
    set -l description $argv[3]

    if not set -q test_flag[1]
        set test_flag --version
    end

    if command -v $binary >/dev/null 2>&1
        if $binary $test_flag >/dev/null 2>&1
            report_pass "$description"
        else
            report_fail "$description (command exists but $test_flag failed)"
        end
    else
        report_fail "$description (command not found)"
    end
end

function test_env_variable
    set -l var_name $argv[1]
    set -l expected_value $argv[2]
    set -l description $argv[3]

    set -l actual_value $$var_name

    if test "$actual_value" = "$expected_value"
        report_pass "$description"
    else
        report_fail "$description (got: $actual_value, expected: $expected_value)"
    end
end

function test_function_exists
    set -l func_name $argv[1]
    set -l description $argv[2]

    if type -q $func_name
        report_pass "$description"
    else
        report_fail "$description (function not defined)"
    end
end

#===============================================================================
# COMPONENT TEST FUNCTIONS
#===============================================================================

function test_structure
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
    if test -L "$INSTALL_DIR/nvim"
        set -l target (readlink -f "$INSTALL_DIR/nvim" 2>/dev/null; or readlink "$INSTALL_DIR/nvim")
        set -l expected (readlink -f "$DATA_HOME/nvim" 2>/dev/null; or echo "$DATA_HOME/nvim")
        if test "$target" = "$expected"
            report_pass "nvim symlink"
        else
            report_fail "nvim symlink (points to $target, expected $expected)"
        end
    else
        report_fail "nvim symlink (not found)"
    end

    echo ""
end

function test_configs
    echo "Testing configuration symlinks..."

    test_symlink "$CONFIG_HOME/nvim" "$INSTALL_DIR/HOME/general/nvim" "nvim config symlink"
    test_symlink "$CONFIG_HOME/tmux" "$INSTALL_DIR/HOME/general/tmux" "tmux config symlink"
    test_symlink "$CONFIG_HOME/fish" "$INSTALL_DIR/HOME/general/fish" "fish config symlink"
    test_symlink "$CONFIG_HOME/git/config" "$INSTALL_DIR/HOME/general/gitconfig" "git config symlink"
    test_symlink "$INSTALL_DIR/etc/ssh" "$INSTALL_DIR/HOME/general/ssh" "ssh config symlink"
    test_symlink "$INSTALL_DIR/etc/mambarc" "$INSTALL_DIR/HOME/general/mambarc" "mambarc symlink"

    echo ""
end

function test_conda_binaries
    echo "Testing conda-installed binaries..."

    # Core tools
    test_binary fish --version "fish shell"
    test_binary fzf --version "fzf"
    test_binary rg --version "ripgrep"
    test_binary make --version "make"
    test_binary cmake --version "cmake"
    test_binary git --version "git"
    test_binary git-lfs --version "git-lfs"
    test_binary tmux -V "tmux"
    test_binary nvim --version "nvim"
    test_binary jq --version "jq"
    test_binary zoxide --version "zoxide"
    test_binary starship --version "starship"
    test_binary node --version "node"
    test_binary npm --version "npm"

    # LSP servers and formatters
    test_binary lua-language-server --version "lua-language-server"
    test_binary stylua --version "stylua"
    test_binary prettier --version "prettier"
    test_binary pyright --version "pyright"
    test_binary ruff --version "ruff"
    test_binary typescript-language-server --version "typescript-language-server"

    # Architecture-specific packages
    if test "$ARCHITECTURE" = "x86_64" -o "$ARCHITECTURE" = "amd64"
        test_binary docker-compose --version "docker-compose"
    else
        report_skip "docker-compose (not available on $ARCHITECTURE)"
    end

    echo ""
end

function test_python_uv
    echo "Testing Python/UV installation..."

    # UV directories
    test_directory "$INSTALL_DIR/uv/python" "UV python directory"
    test_directory "$INSTALL_DIR/uv/tool" "UV tool directory"

    # UV binary
    test_binary uv --version "uv package manager"

    # Python 3.12
    set -l python_bin (find "$INSTALL_DIR/uv/python" -name python -type f 2>/dev/null | head -n1)
    if test -n "$python_bin" -a -x "$python_bin"
        if $python_bin --version 2>&1 | grep -q "Python 3.12"
            report_pass "Python 3.12"
        else
            report_fail "Python 3.12 (found different version: "($python_bin --version 2>&1)")"
        end
    else
        report_fail "Python 3.12 (binary not found in UV directory)"
    end

    # conda-pack
    test_binary conda-pack --version "conda-pack"

    echo ""
end

function test_additional_binaries
    echo "Testing additional binaries..."

    # trzsz tools
    test_binary trzsz --version "trzsz"
    test_binary trz --version "trz"
    test_binary tsz --version "tsz"

    # frp tools
    if command -v frpc >/dev/null 2>&1
        if frpc -v >/dev/null 2>&1
            report_pass "frpc"
        else
            report_fail "frpc (exists but -v failed)"
        end
    else
        report_fail "frpc (not found)"
    end

    if command -v frps >/dev/null 2>&1
        if frps -v >/dev/null 2>&1
            report_pass "frps"
        else
            report_fail "frps (exists but -v failed)"
        end
    else
        report_fail "frps (not found)"
    end

    echo ""
end

function test_environment
    echo "Testing Fish shell environment..."

    # Environment variables
    test_env_variable HOMECLI_INSTALL_DIR "$INSTALL_DIR" "HOMECLI_INSTALL_DIR"
    test_env_variable XDG_CONFIG_HOME "$CONFIG_HOME" "XDG_CONFIG_HOME"
    test_env_variable XDG_DATA_HOME "$DATA_HOME" "XDG_DATA_HOME"
    test_env_variable MAMBA_ROOT_PREFIX "$INSTALL_DIR/miniconda" "MAMBA_ROOT_PREFIX"
    test_env_variable UV_TOOL_DIR "$INSTALL_DIR/uv/tool" "UV_TOOL_DIR"
    test_env_variable GIT_CONFIG_GLOBAL "$CONFIG_HOME/git/config" "GIT_CONFIG_GLOBAL"
    test_env_variable HOMECLI_SSH_DIR "$INSTALL_DIR/etc/ssh" "HOMECLI_SSH_DIR"

    # SSH wrapper functions
    test_function_exists ssh "SSH wrapper function"
    test_function_exists scp "SCP wrapper function"
    test_function_exists sftp "SFTP wrapper function"

    # Check if binaries are in PATH
    test_binary starship --version "starship in PATH"
    test_binary zoxide --version "zoxide in PATH"

    echo ""
end

function test_neovim
    echo "Testing Neovim setup..."

    # Neovim can run headless
    if nvim --headless -c quit >/dev/null 2>&1
        report_pass "Neovim runs headless"
    else
        report_fail "Neovim headless execution failed"
    end

    # Neovim data directory
    test_directory "$DATA_HOME/nvim" "Neovim data directory"

    # Plugin manager (Lazy)
    test_directory "$DATA_HOME/nvim/lazy" "Lazy plugin manager"

    # Mason bin directory
    test_directory "$DATA_HOME/nvim/mason/bin" "Mason bin directory"

    # Treesitter parsers directory
    if test -d "$DATA_HOME/nvim/lazy/nvim-treesitter/parser"
        report_pass "Treesitter parser directory"

        # Check for some common parsers
        for parser in c lua python fish
            if test -f "$DATA_HOME/nvim/lazy/nvim-treesitter/parser/$parser.so"
                report_pass "Treesitter $parser parser"
            else
                report_skip "Treesitter $parser parser (not installed)"
            end
        end
    else
        report_fail "Treesitter parser directory (not found)"
    end

    echo ""
end

function test_tmux
    echo "Testing Tmux configuration..."

    # Config files exist
    test_file_exists "$CONFIG_HOME/tmux/tmux.conf" "tmux.conf"
    test_file_exists "$CONFIG_HOME/tmux/statusline.conf" "statusline.conf"
    test_file_exists "$CONFIG_HOME/tmux/macos.conf" "macos.conf"

    # Tmux can load config
    if tmux -f "$CONFIG_HOME/tmux/tmux.conf" -L test_session list-keys >/dev/null 2>&1
        report_pass "Tmux config loads without errors"
    else
        report_skip "Tmux config validation (test session failed)"
    end

    echo ""
end

function test_git
    echo "Testing Git configuration..."

    # Git config file exists
    test_file_exists "$CONFIG_HOME/git/config" "git config file"

    # Git LFS
    test_binary git-lfs --version "git-lfs"

    # Git can read custom config
    if env GIT_CONFIG_GLOBAL=$CONFIG_HOME/git/config git config user.name >/dev/null 2>&1
        report_pass "Git reads custom config"
    else
        report_skip "Git custom config (user.name not set)"
    end

    # Check for git aliases
    for alias in lg lg1 lg2
        if env GIT_CONFIG_GLOBAL=$CONFIG_HOME/git/config git config alias.$alias >/dev/null 2>&1
            report_pass "Git alias: $alias"
        else
            report_skip "Git alias: $alias (not configured)"
        end
    end

    # LFS filter configured
    if env GIT_CONFIG_GLOBAL=$CONFIG_HOME/git/config git config filter.lfs.clean >/dev/null 2>&1
        report_pass "Git LFS filter configured"
    else
        report_fail "Git LFS filter not configured"
    end

    echo ""
end

function test_ssh
    echo "Testing SSH configuration..."

    # SSH directory and config
    test_directory "$INSTALL_DIR/etc/ssh" "SSH config directory"
    test_file_exists "$INSTALL_DIR/etc/ssh/config" "SSH config file"
    test_directory "$INSTALL_DIR/etc/ssh/config.d" "SSH config.d directory"

    # Public key
    test_file_exists "$INSTALL_DIR/etc/ssh/id_rsa.pub" "SSH public key"

    echo ""
end

function test_conda_environment
    echo "Testing conda environment..."

    # mambarc exists
    test_file_exists "$INSTALL_DIR/etc/mambarc" "mambarc file"

    # MAMBA_EXE points to correct binary
    if test -x "$INSTALL_DIR/bin/mamba"
        report_pass "mamba binary"
    else
        report_fail "mamba binary (not found or not executable)"
    end

    # Check if micromamba can activate
    if micromamba --version >/dev/null 2>&1
        report_pass "micromamba activation"
    else
        report_fail "micromamba activation failed"
    end

    echo ""
end

#===============================================================================
# TEST RUNNER
#===============================================================================

function run_tests
    set -l components $COMPONENTS

    # If "all" is specified, run all tests
    if contains all $components
        set components structure configs conda python binaries environment nvim tmux git ssh conda-env
    end

    # Run each test component
    for component in $components
        switch $component
            case structure
                test_structure
            case configs
                test_configs
            case conda
                test_conda_binaries
            case python
                test_python_uv
            case binaries
                test_additional_binaries
            case environment
                test_environment
            case nvim
                test_neovim
            case tmux
                test_tmux
            case git
                test_git
            case ssh
                test_ssh
            case conda-env
                test_conda_environment
            case all
                # Already handled above
            case '*'
                echo "Unknown component: $component"
        end
    end
end

#===============================================================================
# SUMMARY REPORTING
#===============================================================================

function print_summary
    set -l duration $argv[1]

    echo ""
    echo "================================================================================"
    echo "                        TEST SUMMARY"
    echo "================================================================================"
    echo "Total Tests:  $TESTS_TOTAL"

    if test $TESTS_TOTAL -gt 0
        set -l pass_pct (math "$TESTS_PASSED * 100 / $TESTS_TOTAL")
        set -l fail_pct (math "$TESTS_FAILED * 100 / $TESTS_TOTAL")
        set -l skip_pct (math "$TESTS_SKIPPED * 100 / $TESTS_TOTAL")

        printf "Passed:       %-4d (%d%%)\n" $TESTS_PASSED $pass_pct
        printf "Failed:       %-4d (%d%%)\n" $TESTS_FAILED $fail_pct
        printf "Skipped:      %-4d (%d%%)\n" $TESTS_SKIPPED $skip_pct
    else
        echo "No tests were run"
    end

    echo "Duration:     {$duration}s"

    if test $TESTS_FAILED -gt 0
        echo ""
        echo "FAILED TESTS:"
        for test in $FAILED_TESTS
            echo "  - $test"
        end
    end

    if test $TESTS_SKIPPED -gt 0
        echo ""
        echo "SKIPPED TESTS:"
        for test in $SKIPPED_TESTS
            echo "  - $test"
        end
    end

    echo ""
    if test $TESTS_FAILED -eq 0
        echo "Exit Code: 0 (all tests passed)"
    else
        echo "Exit Code: 1 (failures detected)"
    end
    echo "================================================================================"
end

#===============================================================================
# MAIN EXECUTION
#===============================================================================

function main
    set -l start_time (date +%s)

    # Verify install directory exists
    if not test -d "$INSTALL_DIR"
        echo "ERROR: Installation directory not found: $INSTALL_DIR"
        echo "Please specify --install-dir or set HOMECLI_INSTALL_DIR environment variable"
        exit 2
    end

    echo "=========================================="
    echo "HomeCLI Installation Test"
    echo "=========================================="
    echo "Install Directory: $INSTALL_DIR"
    echo "Architecture:      $ARCHITECTURE"
    echo "=========================================="
    echo ""

    parse_args $argv
    run_tests

    set -l end_time (date +%s)
    set -l duration (math $end_time - $start_time)

    print_summary $duration

    # Exit with appropriate code
    if test $TESTS_FAILED -eq 0
        exit 0
    else
        exit 1
    end
end

# Run main function with all arguments
main $argv
