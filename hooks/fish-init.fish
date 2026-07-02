#!/usr/bin/env fish
# shared-ssh-agent: fish initialization hook
# This file is sourced by ~/.config/fish/conf.d/shared-ssh-agent.fish

# Interactive shell check - exit silently if non-interactive
if not status is-interactive
    and not set -q SSA_ENABLE_NONINTERACTIVE
    exit 0
end

# Source the fish wrapper library
if set -q SSA_INSTALL_DIR; and test -f "$SSA_INSTALL_DIR/lib/fish.fish"
    source "$SSA_INSTALL_DIR/lib/fish.fish"
    ssa_init
end
