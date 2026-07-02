#!/usr/bin/env zsh
# shared-ssh-agent: zsh wrapper library
# Provides zsh-specific syntax for calling core functions

# Source core logic
SSA_LIB_DIR="${0:a:h}"
source "$SSA_LIB_DIR/core.sh"

# Wrapper function for initialization
ssa_init() {
    ssa_core_start_or_connect
}

# Wrapper function for cleanup
ssa_cleanup() {
    ssa_core_decrement_ref
}
