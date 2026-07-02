#!/usr/bin/env zsh
# shared-ssh-agent: zsh initialization hook
# This file is sourced by ~/.zshrc for interactive shells

# Interactive shell check - exit silently if non-interactive
[[ ! -o interactive ]] && [ -z "$SSA_ENABLE_NONINTERACTIVE" ] && return

# Source the zsh wrapper library
if [ -n "$SSA_INSTALL_DIR" ] && [ -f "$SSA_INSTALL_DIR/lib/zsh.sh" ]; then
    source "$SSA_INSTALL_DIR/lib/zsh.sh"
    ssa_init
fi
