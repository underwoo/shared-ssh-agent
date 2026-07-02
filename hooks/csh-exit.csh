#!/bin/csh
# shared-ssh-agent: csh exit hook
# This file is sourced by ~/.logout

# Source the csh wrapper library
if ($?SSA_INSTALL_DIR) then
    if (-f "$SSA_INSTALL_DIR/lib/csh.csh") then
        source "$SSA_INSTALL_DIR/lib/csh.csh"
        ssa_cleanup
    endif
endif
