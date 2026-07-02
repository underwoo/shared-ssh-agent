#!/bin/bash
# Installation script for shared-ssh-agent
# Universal SSH agent sharing across shells and sessions
#
# Can be run directly from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash -s -- --all-shells
#
# Or from a local clone:
#   ./install.sh

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

# Default installation directory
DEFAULT_INSTALL_DIR="$HOME/.local/share/shared-ssh-agent"
INSTALL_DIR=""

# Detected shells
DETECTED_SHELLS=()
SHELLS_TO_INSTALL=()

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# GitHub repository
GITHUB_REPO="https://github.com/underwoo/shared-ssh-agent.git"
GITHUB_RAW="https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main"

# Bootstrap mode detection
BOOTSTRAP_MODE=false

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Install shared-ssh-agent for universal SSH agent sharing across shells.

OPTIONS:
    --shell <shell>       Install for specific shell (bash, zsh, fish, csh, tcsh, sh)
                         Can be specified multiple times. Default: auto-detect
    --prefix <path>       Installation directory (default: $DEFAULT_INSTALL_DIR)
    --all-shells         Install for all detected shells
    --dry-run            Show what would be done without making changes
    -h, --help           Show this help message

EXAMPLES:
    $0                          # Auto-detect and install for current shell
    $0 --shell bash --shell zsh # Install for bash and zsh only
    $0 --all-shells             # Install for all available shells
    $0 --prefix ~/.ssh-agent    # Custom installation directory

EOF
    exit 0
}

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

# Detect available shells
detect_shells() {
    print_info "Detecting available shells..."
    
    for shell in bash zsh fish tcsh csh sh dash; do
        if command -v "$shell" >/dev/null 2>&1; then
            DETECTED_SHELLS+=("$shell")
            print_success "Found: $shell"
        fi
    done
    
    if [ ${#DETECTED_SHELLS[@]} -eq 0 ]; then
        print_error "No supported shells detected"
        exit 1
    fi
}

# Get current shell
get_current_shell() {
    if [ -n "$SHELL" ]; then
        basename "$SHELL"
    else
        echo "bash"  # fallback
    fi
}

# Check if a value is in an array
array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

# Get shell RC files
get_shell_rc_files() {
    local shell="$1"
    case "$shell" in
        bash)
            echo "$HOME/.bashrc"
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        csh)
            echo "$HOME/.cshrc"
            ;;
        tcsh)
            # Check both .tcshrc and .cshrc
            if [ -f "$HOME/.tcshrc" ]; then
                echo "$HOME/.tcshrc"
            fi
            if [ -f "$HOME/.cshrc" ]; then
                echo "$HOME/.cshrc"
            fi
            # If neither exists, prefer .tcshrc
            if [ ! -f "$HOME/.tcshrc" ] && [ ! -f "$HOME/.cshrc" ]; then
                echo "$HOME/.tcshrc"
            fi
            ;;
        sh|dash)
            echo "$HOME/.profile"
            ;;
    esac
}

# Get shell logout files
get_shell_logout_files() {
    local shell="$1"
    case "$shell" in
        bash)
            echo "$HOME/.bash_logout"
            ;;
        zsh)
            echo "$HOME/.zlogout"
            ;;
        fish)
            # Fish uses event handlers, handled in the hook itself
            echo ""
            ;;
        csh|tcsh)
            echo "$HOME/.logout"
            ;;
        sh|dash)
            # POSIX sh uses trap in the init file, no separate logout file
            echo ""
            ;;
    esac
}

# Get hook file extension
get_hook_extension() {
    local shell="$1"
    case "$shell" in
        bash|sh|dash)
            echo "sh"
            ;;
        zsh)
            echo "zsh"
            ;;
        fish)
            echo "fish"
            ;;
        csh|tcsh)
            echo "csh"
            ;;
    esac
}

# Check if already installed in RC file
is_already_installed() {
    local rc_file="$1"
    [ -f "$rc_file" ] && grep -q "# shared-ssh-agent: auto-generated" "$rc_file"
}

# Add to RC file with markers
add_to_rc_file() {
    local rc_file="$1"
    local content="$2"
    local dry_run="$3"
    
    if is_already_installed "$rc_file"; then
        print_warning "Already installed in $rc_file, skipping"
        return 0
    fi
    
    if [ "$dry_run" = "true" ]; then
        print_info "[DRY RUN] Would add to: $rc_file"
        return 0
    fi
    
    # Create directory if needed
    local rc_dir
    rc_dir="$(dirname "$rc_file")"
    if [ ! -d "$rc_dir" ]; then
        mkdir -p "$rc_dir"
    fi
    
    # Create file if it doesn't exist
    if [ ! -f "$rc_file" ]; then
        touch "$rc_file"
    fi
    
    # Add content with markers
    {
        echo ""
        echo "# shared-ssh-agent: auto-generated - do not edit this block"
        echo "$content"
        echo "# shared-ssh-agent: end auto-generated block"
    } >> "$rc_file"
    
    print_success "Added to: $rc_file"
}

# Install for a specific shell
install_for_shell() {
    local shell="$1"
    local dry_run="$2"
    
    print_info "Installing for: $shell"
    
    local ext
    ext="$(get_hook_extension "$shell")"
    
    # Get RC file(s)
    local rc_files
    rc_files="$(get_shell_rc_files "$shell")"
    
    if [ -z "$rc_files" ]; then
        print_warning "No RC file defined for $shell"
        return 1
    fi
    
    # Init hook content
    local init_content
    init_content="export SSA_INSTALL_DIR=\"${INSTALL_DIR}\"
source \"${INSTALL_DIR}/hooks/${shell}-init.${ext}\""
    
    # Add to each RC file
    for rc_file in $rc_files; do
        add_to_rc_file "$rc_file" "$init_content" "$dry_run"
    done
    
    # Logout hook (if applicable)
    local logout_files
    logout_files="$(get_shell_logout_files "$shell")"
    
    if [ -n "$logout_files" ]; then
        for logout_file in $logout_files; do
            if is_already_installed "$logout_file"; then
                print_warning "Already installed in $logout_file, skipping"
                continue
            fi
            
            local exit_content
            exit_content="source \"${INSTALL_DIR}/hooks/${shell}-exit.${ext}\""
            
            add_to_rc_file "$logout_file" "$exit_content" "$dry_run"
        done
    fi
}

# Bootstrap: download repo if needed
bootstrap_download() {
    local temp_dir="/tmp/shared-ssh-agent-bootstrap-$$"
    
    print_info "Downloading shared-ssh-agent from GitHub..." >&2
    
    mkdir -p "$temp_dir" || {
        print_error "Failed to create temp directory" >&2
        return 1
    }
    
    # Try git first, then curl + tar, then wget + tar
    if command -v git >/dev/null 2>&1; then
        print_info "Using git to clone repository..." >&2
        if git clone --depth 1 "$GITHUB_REPO" "$temp_dir" >&2 2>&1; then
            print_success "Downloaded successfully" >&2
        else
            print_error "Failed to clone repository" >&2
            rm -rf "$temp_dir"
            return 1
        fi
    elif command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
        print_info "Using curl to download tarball..." >&2
        if curl -fsSL "${GITHUB_REPO%.git}/archive/refs/heads/main.tar.gz" 2>&2 | \
            tar -xz -C "$temp_dir" --strip-components=1 2>&2; then
            print_success "Downloaded successfully" >&2
        else
            print_error "Failed to download tarball" >&2
            rm -rf "$temp_dir"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
        print_info "Using wget to download tarball..." >&2
        if wget -qO- "${GITHUB_REPO%.git}/archive/refs/heads/main.tar.gz" 2>&2 | \
            tar -xz -C "$temp_dir" --strip-components=1 2>&2; then
            print_success "Downloaded successfully" >&2
        else
            print_error "Failed to download tarball" >&2
            rm -rf "$temp_dir"
            return 1
        fi
    else
        print_error "No suitable download tool available (need git, or curl+tar, or wget+tar)" >&2
        print_info "Please install one of:" >&2
        print_info "  - git" >&2
        print_info "  - curl + tar" >&2
        print_info "  - wget + tar" >&2
        print_info "" >&2
        print_info "Or clone manually:" >&2
        print_info "  git clone $GITHUB_REPO" >&2
        print_info "  cd shared-ssh-agent" >&2
        print_info "  ./install.sh" >&2
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify download
    if [ ! -d "$temp_dir/lib" ] || [ ! -d "$temp_dir/hooks" ]; then
        print_error "Downloaded files are incomplete (missing lib/ or hooks/)" >&2
        print_info "Contents of $temp_dir:" >&2
        ls -la "$temp_dir" >&2
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Return the temp dir path (stdout only)
    echo "$temp_dir"
    return 0
}

# Check if we're being piped from curl (bootstrap mode)
detect_bootstrap_mode() {
    # Check if stdin is a pipe or if SCRIPT_DIR doesn't have the required files
    if [ ! -t 0 ] || [ ! -d "$SCRIPT_DIR/lib" ] || [ ! -d "$SCRIPT_DIR/hooks" ]; then
        # Additional check: if $0 is bash or contains 'bash', we're likely piped
        if [[ "$0" == *bash* ]] || [ "$0" = "-bash" ] || [ ! -d "$SCRIPT_DIR/lib" ]; then
            BOOTSTRAP_MODE=true
            return 0
        fi
    fi
    return 1
}

# Copy files to installation directory
copy_files() {
    local dry_run="$1"
    
    if [ "$dry_run" = "true" ]; then
        print_info "[DRY RUN] Would copy files to: $INSTALL_DIR"
        return 0
    fi
    
    print_info "Installing files to: $INSTALL_DIR"
    
    # Debug: show what we're working with
    if [ "$BOOTSTRAP_MODE" = "true" ]; then
        print_info "Source directory: $SCRIPT_DIR"
        print_info "Checking source directories..."
        if [ -d "$SCRIPT_DIR/lib" ]; then
            print_info "  ✓ lib/ exists"
        else
            print_error "  ✗ lib/ missing at $SCRIPT_DIR/lib"
        fi
        if [ -d "$SCRIPT_DIR/hooks" ]; then
            print_info "  ✓ hooks/ exists"
        else
            print_error "  ✗ hooks/ missing at $SCRIPT_DIR/hooks"
        fi
    fi
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Copy directories
    for dir in lib hooks; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            cp -r "$SCRIPT_DIR/$dir" "$INSTALL_DIR/"
            print_success "Copied: $dir/"
        else
            print_error "Missing directory: $dir/"
            print_error "SCRIPT_DIR is: $SCRIPT_DIR"
            print_error "Contents of SCRIPT_DIR:"
            ls -la "$SCRIPT_DIR" || echo "Cannot list $SCRIPT_DIR"
            exit 1
        fi
    done
    
    # Copy documentation
    for file in README.md LICENSE ARCHITECTURE.md; do
        if [ -f "$SCRIPT_DIR/$file" ]; then
            cp "$SCRIPT_DIR/$file" "$INSTALL_DIR/"
        fi
    done
    
    # Set permissions
    chmod 644 "$INSTALL_DIR"/lib/*
    chmod 755 "$INSTALL_DIR"/hooks/*
    
    print_success "Files installed successfully"
}

# Main installation
main() {
    local dry_run="false"
    local auto_detect="true"
    local all_shells="false"
    local requested_shells=()
    local temp_dir=""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --shell)
                shift
                requested_shells+=("$1")
                auto_detect="false"
                ;;
            --prefix)
                shift
                INSTALL_DIR="$1"
                ;;
            --all-shells)
                all_shells="true"
                auto_detect="false"
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
    
    # Detect bootstrap mode and download if needed
    if detect_bootstrap_mode; then
        print_info "Bootstrap mode detected (installing from GitHub)"
        if [ "$dry_run" != "true" ]; then
            temp_dir=$(bootstrap_download)
            if [ $? -ne 0 ] || [ -z "$temp_dir" ]; then
                print_error "Bootstrap download failed"
                exit 1
            fi
            SCRIPT_DIR="$temp_dir"
            print_info "Using downloaded files from: $SCRIPT_DIR"
        else
            print_info "[DRY RUN] Would download repository from GitHub"
        fi
        echo ""
    fi
    
    # Set installation directory
    if [ -z "$INSTALL_DIR" ]; then
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    fi
    
    echo ""
    echo "=== shared-ssh-agent Installation ==="
    echo ""
    
    # Detect shells
    detect_shells
    echo ""
    
    # Determine which shells to install for
    if [ "$all_shells" = "true" ]; then
        SHELLS_TO_INSTALL=("${DETECTED_SHELLS[@]}")
        print_info "Installing for all detected shells"
    elif [ "$auto_detect" = "true" ]; then
        current_shell="$(get_current_shell)"
        if array_contains "$current_shell" "${DETECTED_SHELLS[@]}"; then
            SHELLS_TO_INSTALL=("$current_shell")
            print_info "Auto-detected current shell: $current_shell"
        else
            print_warning "Current shell ($current_shell) not detected, falling back to bash"
            SHELLS_TO_INSTALL=("bash")
        fi
    else
        # Validate requested shells
        for shell in "${requested_shells[@]}"; do
            if array_contains "$shell" "${DETECTED_SHELLS[@]}"; then
                SHELLS_TO_INSTALL+=("$shell")
            else
                print_warning "Requested shell not available: $shell"
            fi
        done
        
        if [ ${#SHELLS_TO_INSTALL[@]} -eq 0 ]; then
            print_error "No valid shells selected"
            exit 1
        fi
    fi
    
    echo ""
    print_info "Will install for: ${SHELLS_TO_INSTALL[*]}"
    print_info "Installation directory: $INSTALL_DIR"
    
    if [ "$dry_run" = "true" ]; then
        print_warning "DRY RUN MODE - no changes will be made"
    fi
    
    echo ""
    
    # Copy files
    copy_files "$dry_run"
    echo ""
    
    # Install for each shell
    for shell in "${SHELLS_TO_INSTALL[@]}"; do
        install_for_shell "$shell" "$dry_run"
        echo ""
    done
    
    # Cleanup temp directory if bootstrap mode
    if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "$temp_dir"
    fi
    
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    
    if [ "$dry_run" = "false" ]; then
        print_success "shared-ssh-agent has been installed!"
        echo ""
        echo "Next steps:"
        echo "  1. Open a new terminal or reload your shell configuration"
        echo "  2. The agent will start automatically on your next interactive shell"
        echo ""
        echo "Configuration options (set in your shell RC before sourcing):"
        echo "  export SSA_VERBOSE=1              # Enable verbose output"
        echo "  export SSA_DEBUG=1                # Enable debug logging (~/.shared-ssh-agent.log)"
        echo "  export SSA_ENABLE_NONINTERACTIVE=1  # Enable for non-interactive shells (not recommended)"
        echo ""
        if [ "$BOOTSTRAP_MODE" = "true" ]; then
            echo "To uninstall, run:"
            echo "  curl -fsSL $GITHUB_RAW/uninstall.sh | bash"
        else
            echo "To uninstall, run: $SCRIPT_DIR/uninstall.sh"
        fi
    else
        print_info "This was a dry run. Run without --dry-run to apply changes."
    fi
    echo ""
}

main "$@"
