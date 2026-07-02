#!/bin/bash
# Uninstallation script for shared-ssh-agent

set -e

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

# Print functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

print_success() {
    echo -e "${GREEN}✓${NC} $*"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

print_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

# Default installation directory
DEFAULT_INSTALL_DIR="$HOME/.local/share/shared-ssh-agent"
INSTALL_DIR="${SSA_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Uninstall shared-ssh-agent and remove integration from shell RC files.

OPTIONS:
    --prefix <path>       Installation directory (default: $INSTALL_DIR)
    --keep-files          Remove RC file integrations but keep installed files
    --kill-agent          Kill running agent before uninstalling
    --dry-run            Show what would be done without making changes
    -h, --help           Show this help message

EXAMPLES:
    $0                    # Remove RC integrations and installed files
    $0 --keep-files       # Remove RC integrations only
    $0 --kill-agent       # Kill agent and remove everything

EOF
    exit 0
}

# Find RC files that might have our integration
find_rc_files() {
    local files=()
    
    # Bash
    [ -f "$HOME/.bashrc" ] && files+=("$HOME/.bashrc")
    [ -f "$HOME/.bash_logout" ] && files+=("$HOME/.bash_logout")
    
    # Zsh
    [ -f "$HOME/.zshrc" ] && files+=("$HOME/.zshrc")
    [ -f "$HOME/.zlogout" ] && files+=("$HOME/.zlogout")
    
    # Fish
    [ -f "$HOME/.config/fish/config.fish" ] && files+=("$HOME/.config/fish/config.fish")
    
    # Tcsh/Csh
    [ -f "$HOME/.tcshrc" ] && files+=("$HOME/.tcshrc")
    [ -f "$HOME/.cshrc" ] && files+=("$HOME/.cshrc")
    [ -f "$HOME/.logout" ] && files+=("$HOME/.logout")
    
    # POSIX sh
    [ -f "$HOME/.profile" ] && files+=("$HOME/.profile")
    
    echo "${files[@]}"
}

# Remove integration from a single RC file
remove_from_rc_file() {
    local rc_file="$1"
    local dry_run="$2"
    
    if [ ! -f "$rc_file" ]; then
        return 0
    fi
    
    # Check if our markers exist
    if ! grep -q "# shared-ssh-agent: auto-generated" "$rc_file"; then
        return 0
    fi
    
    if [ "$dry_run" = "true" ]; then
        print_info "[DRY RUN] Would remove integration from: $rc_file"
        return 0
    fi
    
    # Create backup
    cp "$rc_file" "$rc_file.backup-$(date +%Y%m%d-%H%M%S)"
    
    # Remove lines between markers (including markers and blank line before)
    sed -i.tmp '/^$/N;/\n# shared-ssh-agent: auto-generated/,/# shared-ssh-agent: end auto-generated block/d' "$rc_file"
    rm -f "$rc_file.tmp"
    
    print_success "Removed integration from: $rc_file"
}

# Kill running agent
kill_agent() {
    local dry_run="$1"
    
    # Try to load agent env
    local agent_env_file="$HOME/.ssh/agent_envs/$(hostname -s)"
    
    if [ ! -f "$agent_env_file" ]; then
        print_info "No agent environment file found"
        return 0
    fi
    
    . "$agent_env_file" >/dev/null 2>&1
    
    if [ -z "$SSH_AGENT_PID" ]; then
        print_info "No agent PID found"
        return 0
    fi
    
    if [ "$dry_run" = "true" ]; then
        print_info "[DRY RUN] Would kill agent (PID: $SSH_AGENT_PID)"
        return 0
    fi
    
    if ps -p "$SSH_AGENT_PID" >/dev/null 2>&1; then
        ssh-agent -k >/dev/null 2>&1 || true
        print_success "Killed agent (PID: $SSH_AGENT_PID)"
    else
        print_info "Agent not running"
    fi
    
    rm -f "$agent_env_file"
    print_success "Removed agent environment file"
}

# Remove installed files
remove_files() {
    local dry_run="$1"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "Installation directory not found: $INSTALL_DIR"
        return 0
    fi
    
    if [ "$dry_run" = "true" ]; then
        print_info "[DRY RUN] Would remove: $INSTALL_DIR"
        return 0
    fi
    
    rm -rf "$INSTALL_DIR"
    print_success "Removed installation directory: $INSTALL_DIR"
}

# Main
main() {
    local dry_run="false"
    local keep_files="false"
    local kill_agent_flag="false"
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --prefix)
                shift
                INSTALL_DIR="$1"
                ;;
            --keep-files)
                keep_files="true"
                ;;
            --kill-agent)
                kill_agent_flag="true"
                ;;
            --dry-run)
                dry_run="true"
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
        shift
    done
    
    echo ""
    echo "=== shared-ssh-agent Uninstallation ==="
    echo ""
    
    if [ "$dry_run" = "true" ]; then
        print_warning "DRY RUN MODE - no changes will be made"
        echo ""
    fi
    
    # Kill agent if requested
    if [ "$kill_agent_flag" = "true" ]; then
        print_info "Killing running agent..."
        kill_agent "$dry_run"
        echo ""
    fi
    
    # Remove from RC files
    print_info "Removing shell integrations..."
    local rc_files
    rc_files=$(find_rc_files)
    
    for rc_file in $rc_files; do
        remove_from_rc_file "$rc_file" "$dry_run"
    done
    echo ""
    
    # Remove installed files
    if [ "$keep_files" = "false" ]; then
        print_info "Removing installed files..."
        remove_files "$dry_run"
        echo ""
    else
        print_info "Keeping installed files (--keep-files specified)"
        echo ""
    fi
    
    echo "=== Uninstallation Complete ==="
    echo ""
    
    if [ "$dry_run" = "false" ]; then
        print_success "shared-ssh-agent has been uninstalled"
        echo ""
        
        if [ "$keep_files" = "false" ]; then
            echo "The installation directory has been removed."
        else
            echo "The installation directory remains at: $INSTALL_DIR"
        fi
        
        echo "Backup files were created for modified RC files (*.backup-*)."
        echo ""
        echo "You may need to reload your shell or open a new terminal."
    else
        print_info "This was a dry run. Run without --dry-run to apply changes."
    fi
    echo ""
}

main "$@"
