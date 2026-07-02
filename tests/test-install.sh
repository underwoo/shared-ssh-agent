#!/usr/bin/env bash
# Test installation script functionality

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Testing install.sh ==="
echo

# Test 1: Dry run for current shell
echo "Test 1: Dry run installation for current shell..."
"$REPO_ROOT/install.sh" --dry-run >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Dry run for current shell succeeded"
else
    echo "✗ Dry run for current shell failed"
    exit 1
fi
echo

# Test 2: Dry run for all shells
echo "Test 2: Dry run installation for all shells..."
"$REPO_ROOT/install.sh" --all-shells --dry-run >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Dry run for all shells succeeded"
else
    echo "✗ Dry run for all shells failed"
    exit 1
fi
echo

# Test 3: Dry run with custom prefix
echo "Test 3: Dry run with custom prefix..."
"$REPO_ROOT/install.sh" --prefix /tmp/test-ssa --dry-run >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Dry run with custom prefix succeeded"
else
    echo "✗ Dry run with custom prefix failed"
    exit 1
fi
echo

# Test 4: Dry run for specific shells
echo "Test 4: Dry run for specific shells (bash, zsh)..."
"$REPO_ROOT/install.sh" --shell bash --shell zsh --dry-run >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Dry run for specific shells succeeded"
else
    echo "✗ Dry run for specific shells failed"
    exit 1
fi
echo

# Test 5: Help output
echo "Test 5: Help output..."
"$REPO_ROOT/install.sh" --help >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Help output succeeded"
else
    echo "✗ Help output failed"
    exit 1
fi
echo

# Test 6: Actual installation to temp directory
echo "Test 6: Actual installation to temporary directory..."
TEST_PREFIX="/tmp/shared-ssh-agent-test-$$"
TEST_HOME="/tmp/test-home-$$"
mkdir -p "$TEST_HOME"

# Create fake RC files
touch "$TEST_HOME/.bashrc"
touch "$TEST_HOME/.bash_logout"

# Install with temp home
(
    export HOME="$TEST_HOME"
    "$REPO_ROOT/install.sh" --prefix "$TEST_PREFIX" --shell bash >/dev/null 2>&1
)

if [ $? -eq 0 ]; then
    echo "✓ Actual installation succeeded"
    
    # Verify files were copied
    if [ -d "$TEST_PREFIX/lib" ] && [ -d "$TEST_PREFIX/hooks" ]; then
        echo "✓ Files copied to installation directory"
    else
        echo "✗ Files not copied correctly"
        exit 1
    fi
    
    # Verify RC file was modified
    if grep -q "shared-ssh-agent: auto-generated" "$TEST_HOME/.bashrc"; then
        echo "✓ RC file modified correctly"
    else
        echo "✗ RC file not modified"
        exit 1
    fi
    
    # Test uninstall
    echo
    echo "Test 7: Uninstall from temporary directory..."
    (
        export HOME="$TEST_HOME"
        export SSA_INSTALL_DIR="$TEST_PREFIX"
        "$REPO_ROOT/uninstall.sh" --prefix "$TEST_PREFIX" >/dev/null 2>&1
    )
    
    if [ $? -eq 0 ]; then
        echo "✓ Uninstall succeeded"
        
        # Verify files were removed
        if [ ! -d "$TEST_PREFIX" ]; then
            echo "✓ Installation directory removed"
        else
            echo "✗ Installation directory still exists"
            exit 1
        fi
        
        # Verify RC file was cleaned
        if ! grep -q "shared-ssh-agent: auto-generated" "$TEST_HOME/.bashrc"; then
            echo "✓ RC file cleaned correctly"
        else
            echo "✗ RC file still has integration"
            exit 1
        fi
    else
        echo "✗ Uninstall failed"
        exit 1
    fi
else
    echo "✗ Actual installation failed"
    exit 1
fi

# Cleanup
rm -rf "$TEST_PREFIX" "$TEST_HOME"

echo
echo "=== All Installation Tests Passed ==="
