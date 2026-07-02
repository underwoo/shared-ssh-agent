#!/usr/bin/env bash
# Validate shell syntax for all script files

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Testing shell syntax..."

# Test POSIX sh files
for file in lib/core.sh lib/sh.sh hooks/sh-init.sh hooks/sh-exit.sh; do
    if command -v dash >/dev/null 2>&1; then
        dash -n "$REPO_ROOT/$file" || { echo "Syntax error: $file"; exit 1; }
    elif command -v shellcheck >/dev/null 2>&1; then
        shellcheck -s sh "$REPO_ROOT/$file" || { echo "Syntax error: $file"; exit 1; }
    else
        sh -n "$REPO_ROOT/$file" || { echo "Syntax error: $file"; exit 1; }
    fi
done

# Test bash files
for file in lib/bash.sh hooks/bash-init.sh hooks/bash-exit.sh install.sh uninstall.sh; do
    bash -n "$REPO_ROOT/$file" 2>/dev/null || { echo "Syntax error: $file"; exit 1; }
done

# Test zsh files
if command -v zsh >/dev/null 2>&1; then
    for file in lib/zsh.sh hooks/zsh-init.zsh hooks/zsh-exit.zsh; do
        zsh -n "$REPO_ROOT/$file" 2>/dev/null || { echo "Syntax error: $file"; exit 1; }
    done
else
    echo "⚠ Zsh not available, skipping zsh syntax checks"
fi

# Test fish files
if command -v fish >/dev/null 2>&1; then
    for file in lib/fish.fish hooks/fish-init.fish hooks/fish-exit.fish; do
        fish -n "$REPO_ROOT/$file" 2>/dev/null || { echo "Syntax error: $file"; exit 1; }
    done
else
    echo "⚠ Fish not available, skipping fish syntax checks"
fi

# Test csh files
if command -v tcsh >/dev/null 2>&1; then
    for file in lib/csh.csh hooks/csh-init.csh hooks/csh-exit.csh; do
        tcsh -n "$REPO_ROOT/$file" 2>/dev/null || { echo "Syntax error: $file"; exit 1; }
    done
else
    echo "⚠ Tcsh not available, skipping csh syntax checks"
fi

echo "✓ All syntax checks passed"
