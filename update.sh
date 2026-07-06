#!/bin/bash
# Update script for shared-ssh-agent
# Updates the installation to the latest version from GitHub

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

# Usage
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Update shared-ssh-agent to the latest version from GitHub.

OPTIONS:
    --prefix <path>       Installation directory (default: $DEFAULT_INSTALL_DIR)
    --check               Check for updates without installing
    -h, --help            Show this help message

EXAMPLES:
    $0                           # Update default installation
    $0 --prefix ~/.ssh-agent     # Update custom installation
    $0 --check                   # Check if updates are available

The update method depends on how you installed:
  - Git clone: pulls latest changes via git
  - Bootstrap (curl): re-downloads from GitHub

EOF
}

# Parse arguments
INSTALL_DIR=""
CHECK_ONLY=false

while [ $# -gt 0 ]; do
    case "$1" in
        --prefix)
            INSTALL_DIR="$2"
            shift 2
            ;;
        --check)
            CHECK_ONLY=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}" >&2
            usage
            exit 1
            ;;
    esac
done

# Determine installation directory
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
fi

# Check if installation exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}Error: Installation not found at $INSTALL_DIR${NC}" >&2
    echo "Have you installed shared-ssh-agent yet?" >&2
    echo "Run: curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash" >&2
    exit 1
fi

echo -e "${BLUE}=== Checking for updates ===${NC}"
echo "Installation directory: $INSTALL_DIR"
echo

# Detect installation method
if [ -d "$INSTALL_DIR/.git" ]; then
    INSTALL_METHOD="git"
    echo "Installation method: Git clone"
else
    INSTALL_METHOD="bootstrap"
    echo "Installation method: Bootstrap (curl)"
fi
echo

# Function to get current version
get_current_version() {
    if [ -f "$INSTALL_DIR/CHANGELOG.md" ]; then
        # Extract version from CHANGELOG.md
        grep -m 1 "^## \[" "$INSTALL_DIR/CHANGELOG.md" | sed 's/.*\[\([^]]*\)\].*/\1/' || echo "unknown"
    else
        echo "unknown"
    fi
}

# Function to get latest version from GitHub
get_latest_version() {
    # Try to get latest release tag from GitHub API
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "https://api.github.com/repos/underwoo/shared-ssh-agent/releases/latest" 2>/dev/null | 
            grep '"tag_name":' | sed -E 's/.*"v?([^"]+)".*/\1/' || echo "unknown"
    else
        echo "unknown"
    fi
}

CURRENT_VERSION=$(get_current_version)
LATEST_VERSION=$(get_latest_version)

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"
echo

# Check-only mode
if [ "$CHECK_ONLY" = true ]; then
    if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] && [ "$LATEST_VERSION" != "unknown" ]; then
        echo -e "${YELLOW}Update available: $CURRENT_VERSION → $LATEST_VERSION${NC}"
        exit 0
    else
        echo -e "${GREEN}You are running the latest version${NC}"
        exit 0
    fi
fi

# Perform update based on installation method
if [ "$INSTALL_METHOD" = "git" ]; then
    echo -e "${BLUE}=== Updating via git ===${NC}"
    cd "$INSTALL_DIR"
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}Warning: You have uncommitted changes in $INSTALL_DIR${NC}"
        echo "Stashing changes..."
        git stash push -m "shared-ssh-agent auto-update stash $(date +%Y-%m-%d_%H:%M:%S)"
    fi
    
    # Pull latest changes
    echo "Fetching updates from GitHub..."
    if git pull --ff-only origin main; then
        echo -e "${GREEN}✓ Successfully updated via git${NC}"
    else
        echo -e "${RED}Error: Failed to update via git${NC}" >&2
        echo "Try manually updating: cd $INSTALL_DIR && git pull" >&2
        exit 1
    fi
    
elif [ "$INSTALL_METHOD" = "bootstrap" ]; then
    echo -e "${BLUE}=== Updating via re-download ===${NC}"
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    trap "rm -rf '$TMP_DIR'" EXIT
    
    echo "Downloading latest version from GitHub..."
    cd "$TMP_DIR"
    
    # Download all necessary files
    GITHUB_RAW="https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main"
    
    if ! curl -fsSL "$GITHUB_RAW/install.sh" -o install.sh; then
        echo -e "${RED}Error: Failed to download update${NC}" >&2
        exit 1
    fi
    
    chmod +x install.sh
    
    # Download the repository archive
    if ! curl -fsSL "https://github.com/underwoo/shared-ssh-agent/archive/refs/heads/main.tar.gz" | tar -xz; then
        echo -e "${RED}Error: Failed to download repository${NC}" >&2
        exit 1
    fi
    
    # Backup current installation
    BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup at $BACKUP_DIR..."
    cp -r "$INSTALL_DIR" "$BACKUP_DIR"
    
    # Remove old installation files (but keep directory structure)
    rm -rf "$INSTALL_DIR"/{lib,hooks,*.sh,*.md}
    
    # Copy new files
    echo "Installing updated files..."
    cp -r shared-ssh-agent-main/* "$INSTALL_DIR/"
    
    echo -e "${GREEN}✓ Successfully downloaded latest version${NC}"
    echo -e "${BLUE}Backup saved at: $BACKUP_DIR${NC}"
fi

# Detect which shells are currently configured
echo
echo -e "${BLUE}=== Detecting configured shells ===${NC}"
CONFIGURED_SHELLS=()

check_shell_configured() {
    local shell="$1"
    local rc_file="$2"
    
    if [ -f "$HOME/$rc_file" ] && grep -q "shared-ssh-agent" "$HOME/$rc_file" 2>/dev/null; then
        CONFIGURED_SHELLS+=("$shell")
        return 0
    fi
    return 1
}

check_shell_configured "bash" ".bashrc"
check_shell_configured "zsh" ".zshrc"
check_shell_configured "fish" ".config/fish/config.fish"
check_shell_configured "csh" ".cshrc"
check_shell_configured "tcsh" ".tcshrc"
check_shell_configured "sh" ".profile"

if [ ${#CONFIGURED_SHELLS[@]} -eq 0 ]; then
    echo -e "${YELLOW}Warning: No shells appear to be configured${NC}"
    echo "The update is complete, but you may need to run install.sh again"
else
    echo "Currently configured shells: ${CONFIGURED_SHELLS[*]}"
    echo
    echo -e "${GREEN}✓ Update complete!${NC}"
    echo
    echo "Your shell integration hooks are already configured."
    echo "Restart your shells to use the updated version."
fi

# Show what's new if CHANGELOG exists
if [ -f "$INSTALL_DIR/CHANGELOG.md" ]; then
    echo
    echo -e "${BLUE}=== Recent changes ===${NC}"
    # Show unreleased changes or latest version notes
    sed -n '/^## \[/,/^## \[/p' "$INSTALL_DIR/CHANGELOG.md" | head -n -1 | head -n 20
fi

echo
echo -e "${GREEN}Update completed successfully!${NC}"
