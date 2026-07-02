#!/usr/bin/env bash
# Test that core functions execute without errors (Phase 2 version)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export SSA_INSTALL_DIR="$REPO_ROOT"

echo "Testing core functions..."

# Kill any existing agents (including GitHub runner agents)
if [ -n "$SSH_AGENT_PID" ]; then
    kill "$SSH_AGENT_PID" 2>/dev/null || true
fi
if [ -n "$SSH_AUTH_SOCK" ]; then
    rm -f "$SSH_AUTH_SOCK" 2>/dev/null || true
fi

# Clean up any existing agent files
AGENT_ENV_FILE="$HOME/.ssh/agent_envs/$(hostname -s)"
rm -rf "$HOME/.ssh/agent_envs" 2>/dev/null || true
mkdir -p "$HOME/.ssh/agent_envs"

# Clear all environment variables
unset SSH_AGENT_PID SSH_AUTH_SOCK SSH_AGENT_COUNT

# Source core
source "$REPO_ROOT/lib/core.sh"

# Test start_or_connect
ssa_core_start_or_connect || { echo "start_or_connect failed with exit code $?"; exit 1; }

# Should have started an agent OR detected external agent
# External agents won't have SSH_AGENT_PID set by us
if [ -z "$SSH_AGENT_PID" ]; then
    # External agent case - that's OK, skip the rest
    echo "✓ External agent detected, skipping reference counting tests"
    exit 0
fi

# Test check_agent
ssa_core_check_agent
if [ $? -eq 2 ]; then
    echo "FAIL: Agent should be accessible"
    exit 1
fi

# Test increment (already at 1, should go to 2)
ssa_core_increment_ref || { echo "increment_ref failed"; exit 1; }
if [ "$SSH_AGENT_COUNT" != "2" ]; then
    echo "FAIL: Count should be 2, got: $SSH_AGENT_COUNT"
    exit 1
fi

# Test decrement (should go back to 1)
ssa_core_decrement_ref || { echo "decrement_ref failed"; exit 1; }

# Reload env to check count
. "$AGENT_ENV_FILE" >/dev/null 2>&1
if [ "$SSH_AGENT_COUNT" != "1" ]; then
    echo "FAIL: Count should be 1 after decrement, got: $SSH_AGENT_COUNT"
    exit 1
fi

# Final cleanup
ssa_core_decrement_ref || { echo "Final decrement failed"; exit 1; }

# Agent should be gone
if [ -f "$AGENT_ENV_FILE" ]; then
    echo "FAIL: Env file should be removed"
    rm -f "$AGENT_ENV_FILE"
    exit 1
fi

echo "✓ All core functions working correctly"

