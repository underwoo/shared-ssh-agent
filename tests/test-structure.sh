#!/usr/bin/env bash
# Verify all required files and directories exist

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Testing directory structure..."

# Required directories
for dir in lib hooks tests; do
    [ -d "$REPO_ROOT/$dir" ] || { echo "Missing: $dir/"; exit 1; }
done

# Required root files
for file in README.md LICENSE install.sh uninstall.sh; do
    [ -f "$REPO_ROOT/$file" ] || { echo "Missing: $file"; exit 1; }
done

# Required lib files
for file in core.sh bash.sh zsh.sh sh.sh fish.fish csh.csh; do
    [ -f "$REPO_ROOT/lib/$file" ] || { echo "Missing: lib/$file"; exit 1; }
done

# Required hook files
for shell in bash zsh sh fish csh; do
    for hook in init exit; do
        ext="sh"
        [ "$shell" = "fish" ] && ext="fish"
        [ "$shell" = "zsh" ] && ext="zsh"
        [ "$shell" = "csh" ] && ext="csh"
        file="hooks/${shell}-${hook}.${ext}"
        [ -f "$REPO_ROOT/$file" ] || { echo "Missing: $file"; exit 1; }
    done
done

echo "✓ All files present"
