#!/usr/bin/env fish
# shared-ssh-agent: fish exit hook
# This function runs on fish_exit event

function __ssa_fish_exit --on-event fish_exit
    # Source the fish wrapper library
    if set -q SSA_INSTALL_DIR; and test -f "$SSA_INSTALL_DIR/lib/fish.fish"
        source "$SSA_INSTALL_DIR/lib/fish.fish"
        ssa_cleanup
    end
end
