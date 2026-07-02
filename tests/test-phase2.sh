#!/usr/bin/env bash
# Integration tests for Phase 2 agent management

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export SSA_INSTALL_DIR="$REPO_ROOT"
export SSA_VERBOSE=1

echo "=== Phase 2 Integration Tests ==="
echo

# Clean up any existing managed agent
AGENT_ENV_FILE="$HOME/.ssh/agent_envs/$(hostname -s)"
if [ -f "$AGENT_ENV_FILE" ]; then
    . "$AGENT_ENV_FILE" >/dev/null 2>&1
    if [ -n "$SSH_AGENT_PID" ]; then
        ssh-agent -k >/dev/null 2>&1 || true
    fi
    rm -f "$AGENT_ENV_FILE" 2>/dev/null || true
fi

# Unset any environment variables from parent shell
unset SSH_AGENT_PID SSH_AUTH_SOCK SSH_AGENT_COUNT

# Test 1: Start first shell
echo "Test 1: Starting first shell..."
source "$REPO_ROOT/lib/bash.sh"
ssa_init

if [ -z "$SSH_AGENT_PID" ]; then
    echo "FAIL: No agent started"
    exit 1
fi

if [ "$SSH_AGENT_COUNT" != "1" ]; then
    echo "FAIL: Count should be 1, got: $SSH_AGENT_COUNT"
    exit 1
fi

FIRST_AGENT_PID=$SSH_AGENT_PID
echo "✓ First shell started, count=1, PID=$SSH_AGENT_PID"
echo

# Test 2: Start second shell (should increment)
echo "Test 2: Starting second shell in subshell..."
bash -c "
export SSA_INSTALL_DIR=\"$REPO_ROOT\"
export SSA_VERBOSE=1
source \"$REPO_ROOT/lib/bash.sh\"
ssa_init

if [ \"\$SSH_AGENT_COUNT\" != \"2\" ]; then
    echo \"FAIL: Count should be 2, got: \$SSH_AGENT_COUNT\"
    exit 1
fi

if [ \"\$SSH_AGENT_PID\" != \"$FIRST_AGENT_PID\" ]; then
    echo \"FAIL: Should be same agent PID\"
    exit 1
fi

echo \"✓ Second shell connected, count=2, same PID=\$SSH_AGENT_PID\"

# Cleanup from subshell
ssa_cleanup
"

if [ $? -ne 0 ]; then
    echo "FAIL: Second shell test failed"
    ssa_cleanup 2>/dev/null
    exit 1
fi
echo

# Verify count went back to 1 after subshell exited
sleep 0.5
source "$AGENT_ENV_FILE"
if [ "$SSH_AGENT_COUNT" != "1" ]; then
    echo "FAIL: Count should be back to 1 after subshell exit, got: $SSH_AGENT_COUNT"
    ssa_cleanup 2>/dev/null
    exit 1
fi
echo "✓ After subshell exit, count back to 1"
echo

# Test 3: Third shell
echo "Test 3: Starting third shell..."
bash -c "
export SSA_INSTALL_DIR=\"$REPO_ROOT\"
export SSA_VERBOSE=1
source \"$REPO_ROOT/lib/bash.sh\"
ssa_init

if [ \"\$SSH_AGENT_COUNT\" != \"2\" ]; then
    echo \"FAIL: Count should be 2, got: \$SSH_AGENT_COUNT\"
    exit 1
fi

echo \"✓ Third shell connected, count=2\"

# Cleanup
ssa_cleanup
"

if [ $? -ne 0 ]; then
    echo "FAIL: Third shell test failed"
    ssa_cleanup 2>/dev/null
    exit 1
fi
echo

# Test 4: Cleanup main shell (should kill agent since count=1)
echo "Test 4: Cleanup main shell..."
ssa_cleanup

# Wait a moment for cleanup
sleep 0.5

# Agent should be gone
if ps -p $FIRST_AGENT_PID >/dev/null 2>&1; then
    echo "FAIL: Agent should be killed but still running"
    ssh-agent -k >/dev/null 2>&1 || true
    exit 1
fi

if [ -f "$AGENT_ENV_FILE" ]; then
    echo "FAIL: Env file should be removed"
    rm -f "$AGENT_ENV_FILE"
    exit 1
fi

echo "✓ Cleanup successful, agent killed, env file removed"
echo

# Test 5: Start fresh agent to verify recovery
echo "Test 5: Starting fresh agent after cleanup..."
unset SSH_AGENT_PID SSH_AUTH_SOCK SSH_AGENT_COUNT
source "$REPO_ROOT/lib/bash.sh"
ssa_init

if [ -z "$SSH_AGENT_PID" ]; then
    echo "FAIL: No agent started"
    exit 1
fi

if [ "$SSH_AGENT_PID" = "$FIRST_AGENT_PID" ]; then
    echo "FAIL: Should be a new agent PID"
    ssa_cleanup 2>/dev/null
    exit 1
fi

echo "✓ New agent started, PID=$SSH_AGENT_PID"

# Final cleanup
ssa_cleanup
echo

echo "=== All Phase 2 Tests Passed ==="

