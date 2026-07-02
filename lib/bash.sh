#!/usr/bin/env bash
# shared-ssh-agent: bash wrapper library
# Provides bash-specific syntax for calling core functions

# Source core logic
SSA_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SSA_LIB_DIR/core.sh"

# Wrapper function for initialization
ssa_init() {
    ssa_core_start_or_connect
}

# Wrapper function for cleanup
ssa_cleanup() {
    ssa_core_decrement_ref
}
