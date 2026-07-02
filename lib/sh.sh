#!/bin/sh
# shared-ssh-agent: POSIX sh wrapper library
# Provides POSIX sh-specific syntax for calling core functions

# Source core logic
SSA_LIB_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SSA_LIB_DIR/core.sh"

# Wrapper function for initialization
ssa_init() {
    ssa_core_start_or_connect
}

# Wrapper function for cleanup
ssa_cleanup() {
    ssa_core_decrement_ref
}
