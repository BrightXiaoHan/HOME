#!/bin/bash
# scripts/test.sh - Wrapper for Fish-based test script
# This wrapper ensures the test runs in the homecli-fish environment

# Check if just showing help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: test.sh [OPTIONS]

Comprehensive testing script for homecli installation.

OPTIONS:
    --help, -h              Show this help message
    --install-dir <path>    Specify installation directory

    --all                   Run all tests (default if no component specified)
    --structure             Test installation directory structure
    --configs               Test configuration symlinks
    --conda                 Test conda-installed binaries
    --python                Test Python/UV installation
    --binaries              Test additional binaries (trzsz, frp, mihomo, mihoro)
    --environment           Test Fish shell environment
    --nvim                  Test Neovim setup
    --tmux                  Test Tmux configuration
    --git                   Test Git configuration
    --ssh                   Test SSH configuration
    --conda-env             Test conda environment activation

EXAMPLES:
    test.sh                          # Run all tests
    test.sh --environment --nvim     # Run only Fish and Neovim tests
    test.sh --install-dir /custom    # Test custom installation

EXIT CODES:
    0 - All tests passed
    1 - Some tests failed
    2 - Setup error (e.g., install directory not found)
EOF
    exit 0
fi

# Detect install directory
INSTALL_DIR=${HOMECLI_INSTALL_DIR:-$HOME/.homecli}

# Check if custom install dir is specified in args
for arg in "$@"; do
    if [ "$prev_arg" = "--install-dir" ]; then
        INSTALL_DIR="$arg"
        break
    fi
    prev_arg="$arg"
done

# Verify install directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "ERROR: Installation directory not found: $INSTALL_DIR"
    echo "Please specify --install-dir or set HOMECLI_INSTALL_DIR environment variable"
    exit 2
fi

# Check if homecli-fish wrapper exists
if [ ! -x "$INSTALL_DIR/bin/homecli-fish" ]; then
    echo "ERROR: homecli-fish wrapper not found: $INSTALL_DIR/bin/homecli-fish"
    echo "Please ensure the installation is complete"
    exit 2
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Run the Fish test script in the homecli environment
exec "$INSTALL_DIR/bin/homecli-fish" "$SCRIPT_DIR/test.fish" "$@"
