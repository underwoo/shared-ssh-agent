#!/usr/bin/env zsh
# shared-ssh-agent: zsh exit hook
# This file is sourced by ~/.zlogout

# Source the zsh wrapper library
if [ -n "$SSA_INSTALL_DIR" ] && [ -f "$SSA_INSTALL_DIR/lib/zsh.sh" ]; then
    source "$SSA_INSTALL_DIR/lib/zsh.sh"
    ssa_cleanup
fi
