#!/usr/bin/env bash
# Test that stub functions execute without errors

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Testing stub functions..."

# Source core and test stubs
source "$REPO_ROOT/lib/core.sh"

ssa_core_start_or_connect || { echo "start_or_connect failed"; exit 1; }
ssa_core_increment_ref || { echo "increment_ref failed"; exit 1; }
ssa_core_decrement_ref || { echo "decrement_ref failed"; exit 1; }
ssa_core_check_agent  # May fail (no agent), but should not crash

echo "✓ All stub functions executable"
