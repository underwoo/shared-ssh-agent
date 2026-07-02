#!/usr/bin/env bash
# shared-ssh-agent: bash exit hook
# This file is sourced by ~/.bash_logout

# Source the bash wrapper library
if [ -n "$SSA_INSTALL_DIR" ] && [ -f "$SSA_INSTALL_DIR/lib/bash.sh" ]; then
    source "$SSA_INSTALL_DIR/lib/bash.sh"
    ssa_cleanup
fi
