#!/bin/sh
# shared-ssh-agent: POSIX sh initialization hook
# This file is sourced by ~/.profile for interactive shells

# Interactive shell check - exit silently if non-interactive
case $- in
    *i*) ;;
    *) [ -z "$SSA_ENABLE_NONINTERACTIVE" ] && return ;;
esac

# Source the sh wrapper library
if [ -n "$SSA_INSTALL_DIR" ] && [ -f "$SSA_INSTALL_DIR/lib/sh.sh" ]; then
    . "$SSA_INSTALL_DIR/lib/sh.sh"
    ssa_init
fi
