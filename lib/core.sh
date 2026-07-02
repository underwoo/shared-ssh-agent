#!/bin/sh
# shared-ssh-agent: POSIX-compliant core agent management
# All shell-specific wrappers source this file

# Configuration
SSA_AGENT_ENV_DIR="${HOME}/.ssh/agent_envs"
SSA_HOSTNAME="$(hostname -s 2>/dev/null || hostname 2>/dev/null || uname -n)"
SSA_AGENT_ENV_FILE="${SSA_AGENT_ENV_DIR}/${SSA_HOSTNAME}"

# Debug logging helper
_ssa_log() {
    if [ "$SSA_DEBUG" = "1" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] shared-ssh-agent: $*" >>"$HOME/.shared-ssh-agent.log"
    fi
}

# File locking using portable mkdir-based approach
_ssa_lock() {
    _ssa_lockdir="$SSA_AGENT_ENV_DIR/.lock"
    _ssa_tries=0
    
    while [ $_ssa_tries -lt 10 ]; do
        if mkdir "$_ssa_lockdir" 2>/dev/null; then
            _ssa_log "Lock acquired"
            return 0
        fi
        _ssa_tries=$(expr $_ssa_tries + 1)
        sleep 0.1
    done
    
    _ssa_log "Failed to acquire lock after 10 tries"
    return 1
}

_ssa_unlock() {
    rmdir "$SSA_AGENT_ENV_DIR/.lock" 2>/dev/null
    _ssa_log "Lock released"
}

# Portable sed for updating count (handles GNU vs BSD sed)
_ssa_update_count() {
    _ssa_old="$1"
    _ssa_new="$2"
    
    # Detect OS for sed syntax
    case "$(uname -s)" in
        Darwin|*BSD*)
            # BSD sed requires -i with extension
            sed -i '' "s/^SSH_AGENT_COUNT=$_ssa_old/SSH_AGENT_COUNT=$_ssa_new/" \
                "$SSA_AGENT_ENV_FILE" 2>/dev/null
            ;;
        *)
            # GNU sed
            sed -i "s/^SSH_AGENT_COUNT=$_ssa_old/SSH_AGENT_COUNT=$_ssa_new/" \
                "$SSA_AGENT_ENV_FILE" 2>/dev/null
            ;;
    esac
    
    _ssa_log "Updated count from $_ssa_old to $_ssa_new"
}

# Internal: Start a new agent
_ssa_start_new_agent() {
    _ssa_log "Starting new agent"
    
    # Ensure agent_envs directory exists
    if [ ! -e "$SSA_AGENT_ENV_DIR" ]; then
        mkdir -p "$SSA_AGENT_ENV_DIR" 2>/dev/null || {
            _ssa_log "Failed to create $SSA_AGENT_ENV_DIR"
            return 1
        }
    fi
    
    if [ ! -d "$SSA_AGENT_ENV_DIR" ]; then
        # Path exists but is not a directory
        if [ "$SSA_VERBOSE" = "1" ]; then
            echo "shared-ssh-agent: Warning: $SSA_AGENT_ENV_DIR is not a directory" >&2
        fi
        _ssa_log "Error: $SSA_AGENT_ENV_DIR is not a directory"
        return 1
    fi
    
    # Remove stale env file
    rm -f "$SSA_AGENT_ENV_FILE" 2>/dev/null
    
    # Start new agent
    (umask 066; ssh-agent >"$SSA_AGENT_ENV_FILE" 2>/dev/null) || {
        _ssa_log "Failed to start ssh-agent"
        return 1
    }
    
    # Add reference count
    echo "SSH_AGENT_COUNT=1; export SSH_AGENT_COUNT;" >>"$SSA_AGENT_ENV_FILE"
    
    # Source the new env
    . "$SSA_AGENT_ENV_FILE" >/dev/null 2>&1
    
    if [ "$SSA_VERBOSE" = "1" ]; then
        echo "shared-ssh-agent: Started new agent (PID: $SSH_AGENT_PID)" >&2
    fi
    _ssa_log "Started new agent (PID: $SSH_AGENT_PID)"
    
    return 0
}

# Core function: Check if agent is accessible
# Exit codes: 0=has keys, 1=no keys but running, 2=not running
ssa_core_check_agent() {
    ssh-add -l >/dev/null 2>&1
    return $?
}

# Core function: Start agent or connect to existing
ssa_core_start_or_connect() {
    _ssa_log "start_or_connect called"
    
    # Check for required commands
    for _ssa_cmd in ssh-agent ssh-add sed hostname; do
        if ! command -v "$_ssa_cmd" >/dev/null 2>&1; then
            if [ "$SSA_VERBOSE" = "1" ]; then
                echo "shared-ssh-agent: Error: $_ssa_cmd not found" >&2
            fi
            _ssa_log "Error: $_ssa_cmd not found"
            return 1
        fi
    done
    
    # Check if agent already accessible (from current env)
    ssa_core_check_agent
    _ssa_status=$?
    _ssa_log "Initial agent check status: $_ssa_status"
    
    # If no agent currently accessible, try to load/start one
    if [ $_ssa_status -eq 2 ]; then
        # No agent running, try to load env file
        if [ -r "$SSA_AGENT_ENV_FILE" ]; then
            _ssa_log "Loading existing env file"
            . "$SSA_AGENT_ENV_FILE" >/dev/null 2>&1
        fi
        
        # Check again after loading env
        ssa_core_check_agent
        _ssa_status=$?
        _ssa_log "Agent check after loading env: $_ssa_status"
        
        if [ $_ssa_status -eq 2 ]; then
            # Still no agent, need to start one (with locking)
            _ssa_lock || return 1
            
            # Double-check after acquiring lock (another shell may have started it)
            if [ -r "$SSA_AGENT_ENV_FILE" ]; then
                . "$SSA_AGENT_ENV_FILE" >/dev/null 2>&1
                ssa_core_check_agent
                _ssa_status=$?
            fi
            
            if [ $_ssa_status -eq 2 ]; then
                _ssa_start_new_agent
                _ssa_result=$?
                _ssa_unlock
                return $_ssa_result
            else
                _ssa_unlock
            fi
        fi
    fi
    
    # At this point, an agent is accessible
    # Check if we have the env variables loaded (PID and COUNT)
    if [ -z "$SSH_AGENT_PID" ] || [ -z "$SSH_AGENT_COUNT" ]; then
        # Try loading from env file
        if [ -r "$SSA_AGENT_ENV_FILE" ]; then
            _ssa_log "Loading env variables from file"
            . "$SSA_AGENT_ENV_FILE" >/dev/null 2>&1
        fi
        
        # If still no PID/COUNT, this is an external agent (SSH forwarding, etc)
        # Skip reference counting for external agents
        if [ -z "$SSH_AGENT_PID" ] || [ -z "$SSH_AGENT_COUNT" ]; then
            _ssa_log "External agent detected (forwarded or pre-existing), skipping reference counting"
            return 0
        fi
    fi
    
    # We have our managed agent, increment reference count
    ssa_core_increment_ref
    return 0
}

# Core function: Increment reference count
ssa_core_increment_ref() {
    _ssa_log "increment_ref called"
    
    # Check that we have agent variables set
    if [ -z "$SSH_AGENT_PID" ] || [ -z "$SSH_AGENT_COUNT" ]; then
        _ssa_log "Missing SSH_AGENT_PID or SSH_AGENT_COUNT"
        return 1
    fi
    
    # Check that env file exists
    if [ ! -f "$SSA_AGENT_ENV_FILE" ]; then
        _ssa_log "Env file does not exist"
        return 1
    fi
    
    # Calculate new count
    _ssa_new_count=$(expr $SSH_AGENT_COUNT + 1)
    
    # Update env file (portable sed)
    _ssa_update_count "$SSH_AGENT_COUNT" "$_ssa_new_count"
    
    # Update environment variable
    SSH_AGENT_COUNT=$_ssa_new_count
    export SSH_AGENT_COUNT
    
    if [ "$SSA_VERBOSE" = "1" ]; then
        echo "shared-ssh-agent: Incremented count to $SSH_AGENT_COUNT" >&2
    fi
    _ssa_log "Incremented count to $SSH_AGENT_COUNT"
    
    return 0
}

# Core function: Decrement reference count and cleanup if needed
ssa_core_decrement_ref() {
    _ssa_log "decrement_ref called"
    
    # Check if we have agent variables
    if [ -z "$SSH_AGENT_PID" ]; then
        _ssa_log "No SSH_AGENT_PID set, nothing to do"
        return 0
    fi
    
    # Check if we're counting
    if [ -z "$SSH_AGENT_COUNT" ]; then
        _ssa_log "No SSH_AGENT_COUNT set, nothing to do"
        return 0
    fi
    
    # Load current count from file (in case it changed)
    if [ -f "$SSA_AGENT_ENV_FILE" ]; then
        . "$SSA_AGENT_ENV_FILE" >/dev/null 2>&1
    fi
    
    if [ "$SSH_AGENT_COUNT" -gt 1 ]; then
        # Decrement count
        _ssa_new_count=$(expr $SSH_AGENT_COUNT - 1)
        _ssa_update_count "$SSH_AGENT_COUNT" "$_ssa_new_count"
        
        if [ "$SSA_VERBOSE" = "1" ]; then
            echo "shared-ssh-agent: Decremented count to $_ssa_new_count" >&2
        fi
        _ssa_log "Decremented count to $_ssa_new_count"
    else
        # Last shell, kill agent
        _ssa_log "Last shell, killing agent (PID: $SSH_AGENT_PID)"
        ssh-agent -k >/dev/null 2>&1
        rm -f "$SSA_AGENT_ENV_FILE" 2>/dev/null
        
        if [ "$SSA_VERBOSE" = "1" ]; then
            echo "shared-ssh-agent: Killed agent (PID: $SSH_AGENT_PID)" >&2
        fi
    fi
    
    return 0
}
