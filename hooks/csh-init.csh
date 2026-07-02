#!/bin/csh
# shared-ssh-agent: csh initialization hook
# This file is sourced by ~/.cshrc for interactive shells

# Interactive shell check - exit silently if non-interactive
if (! $?prompt) then
    if (! $?SSA_ENABLE_NONINTERACTIVE) then
        exit 0
    endif
endif

# Source the csh wrapper library
if ($?SSA_INSTALL_DIR) then
    if (-f "$SSA_INSTALL_DIR/lib/csh.csh") then
        source "$SSA_INSTALL_DIR/lib/csh.csh"
        ssa_init
    endif
endif
