#!/bin/sh
# shared-ssh-agent: POSIX sh exit hook
# This file can be called via trap on EXIT

# Source the sh wrapper library
if [ -n "$SSA_INSTALL_DIR" ] && [ -f "$SSA_INSTALL_DIR/lib/sh.sh" ]; then
    . "$SSA_INSTALL_DIR/lib/sh.sh"
    ssa_cleanup
fi
