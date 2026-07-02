#!/usr/bin/env bash
# shared-ssh-agent: bash initialization hook
# This file is sourced by ~/.bashrc for interactive shells

# Interactive shell check - exit silently if non-interactive
[[ $- != *i* ]] && [ -z "$SSA_ENABLE_NONINTERACTIVE" ] && return

# Source the bash wrapper library
if [ -n "$SSA_INSTALL_DIR" ] && [ -f "$SSA_INSTALL_DIR/lib/bash.sh" ]; then
    source "$SSA_INSTALL_DIR/lib/bash.sh"
    ssa_init
fi
