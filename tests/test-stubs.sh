#!/usr/bin/env bash
# Test that core functions execute without errors (Phase 2 version)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export SSA_INSTALL_DIR="$REPO_ROOT"

echo "Testing core functions..."

# Clean up any existing agent first
AGENT_ENV_FILE="$HOME/.ssh/agent_envs/$(hostname -s)"
if [ -f "$AGENT_ENV_FILE" ]; then
    . "$AGENT_ENV_FILE" >/dev/null 2>&1
    if [ -n "$SSH_AGENT_PID" ]; then
        ssh-agent -k >/dev/null 2>&1 || true
    fi
    rm -f "$AGENT_ENV_FILE" 2>/dev/null || true
fi
unset SSH_AGENT_PID SSH_AUTH_SOCK SSH_AGENT_COUNT

# Source core
source "$REPO_ROOT/lib/core.sh"

# Test start_or_connect
ssa_core_start_or_connect || { echo "start_or_connect failed"; exit 1; }

# Should have started an agent
if [ -z "$SSH_AGENT_PID" ]; then
    echo "FAIL: No agent started"
    exit 1
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
