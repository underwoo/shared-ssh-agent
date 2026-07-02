#!/usr/bin/env bash
# Phase 1 setup script - set permissions and run tests

set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

echo "=== Phase 1 Setup ==="
echo

# Set file permissions
echo "Setting file permissions..."
chmod 755 hooks/* tests/* install.sh uninstall.sh 2>/dev/null || true
chmod 644 lib/* ARCHITECTURE.md 2>/dev/null || true

echo "✓ Permissions set"
echo

# Run test suite
echo "=== Running Test Suite ==="
echo

echo "1. Testing directory structure..."
bash tests/test-structure.sh

echo
echo "2. Testing shell syntax..."
bash tests/test-syntax.sh

echo
echo "3. Testing interactive detection..."
bash tests/test-interactive.sh

echo
echo "4. Testing stub functions..."
bash tests/test-stubs.sh

echo
echo "=== All Phase 1 Tests Passed ==="
echo

# Display summary
echo "=== Phase 1 Summary ==="
echo "✓ Created 3 directories: lib/, hooks/, tests/"
echo "✓ Created 6 library files"
echo "✓ Created 10 hook files"
echo "✓ Created 2 installer stubs"
echo "✓ Created 4 test scripts"
echo "✓ Created ARCHITECTURE.md"
echo "✓ All tests passed"
echo
echo "Ready to commit and push to GitHub"
