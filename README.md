# shared-ssh-agent

[![CI](https://github.com/underwoo/shared-ssh-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/underwoo/shared-ssh-agent/actions/workflows/ci.yml)

**Universal SSH agent sharing across shells and sessions**

*One SSH agent, all your shells - bash, zsh, fish, csh, and more*

## Overview

`shared-ssh-agent` manages a single, persistent SSH agent shared across all your shell sessions. Instead of starting a new agent for every terminal window, all your shells connect to one agent with reference counting to ensure proper cleanup.

## Features

- **Universal shell support**: bash, zsh, fish, csh/tcsh, POSIX sh/dash
- **Automatic lifecycle management**: Agent starts on first shell, stops when last shell exits
- **Reference counting**: Tracks active sessions to prevent premature shutdown
- **Interactive-only by default**: No overhead for scripts, cron jobs, or non-interactive processes
- **Simple installation**: One command to set up for your shell(s)
- **Idempotent**: Safe to run installer multiple times
- **Cross-platform**: Works on Linux, macOS, and BSD systems

## Quick Start

### One-Line Install (from GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash
```

With options:
```bash
# Install for all shells
curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash -s -- --all-shells

# Install for specific shells
curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash -s -- --shell bash --shell zsh

# Custom installation directory
curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash -s -- --prefix ~/.ssh-agent

# Dry run (see what would be done)
curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash -s -- --dry-run
```

### Manual Install (from clone)

```bash
# Clone the repository
git clone https://github.com/underwoo/shared-ssh-agent.git
cd shared-ssh-agent

# Install for your current shell
./install.sh

# Or install for all detected shells
./install.sh --all-shells

# Or install for specific shells
./install.sh --shell bash --shell zsh

# Reload your shell or open a new terminal
```

## How It Works

When you open a new shell:
1. The init hook checks if an SSH agent is already running
2. If not, it starts a new agent and sets `SSH_AGENT_COUNT=1`
3. If yes, it connects to the existing agent and increments the count

When you close a shell:
1. The exit hook decrements `SSH_AGENT_COUNT`
2. If count reaches 0, the agent is killed
3. Otherwise, the agent stays running for other shells

## Installation Options

```bash
./install.sh [OPTIONS]

OPTIONS:
    --shell <shell>       Install for specific shell (bash, zsh, fish, csh, tcsh, sh)
                         Can be specified multiple times. Default: auto-detect
    --prefix <path>       Installation directory (default: ~/.local/share/shared-ssh-agent)
    --all-shells         Install for all detected shells
    --dry-run            Show what would be done without making changes
    -h, --help           Show help message

EXAMPLES:
    ./install.sh                          # Auto-detect and install for current shell
    ./install.sh --shell bash --shell zsh # Install for bash and zsh only
    ./install.sh --all-shells             # Install for all available shells
    ./install.sh --prefix ~/.ssh-agent    # Custom installation directory
```

## Updating

### Update to Latest Version

```bash
# Update from default installation location
~/.local/share/shared-ssh-agent/update.sh

# Or check if updates are available
~/.local/share/shared-ssh-agent/update.sh --check

# Update custom installation
~/.local/share/shared-ssh-agent/update.sh --prefix ~/.ssh-agent
```

The update method depends on how you installed:
- **Git clone**: Pulls latest changes via `git pull`
- **Bootstrap (curl)**: Re-downloads from GitHub

### Optional: Add Convenient Alias

Add to your shell RC file for easy updates:

```bash
# bash/zsh
alias ssa-update='~/.local/share/shared-ssh-agent/update.sh'

# fish
alias ssa-update='~/.local/share/shared-ssh-agent/update.sh'

# csh/tcsh
alias ssa-update ~/.local/share/shared-ssh-agent/update.sh
```

Then simply run `ssa-update` to update.

## Configuration

Set these environment variables in your shell RC file **before** the shared-ssh-agent block:

```bash
# Enable verbose output (shows agent startup/shutdown messages)
export SSA_VERBOSE=1

# Enable debug logging (writes to ~/.shared-ssh-agent.log)
export SSA_DEBUG=1

# Enable for non-interactive shells (not recommended)
export SSA_ENABLE_NONINTERACTIVE=1

# Custom agent environment directory (default: ~/.ssh/agent_envs)
export SSA_AGENT_ENV_DIR="$HOME/.ssh/agent_envs"
```

## Shell Support

| Shell | Status | RC Files Modified |
|-------|--------|-------------------|
| bash  | ✅ Full | `~/.bashrc`, `~/.bash_logout` |
| zsh   | ✅ Full | `~/.zshrc`, `~/.zlogout` |
| fish  | ✅ Full | `~/.config/fish/config.fish` |
| csh   | ✅ Full | `~/.cshrc`, `~/.logout` |
| tcsh  | ✅ Full | `~/.tcshrc` and/or `~/.cshrc`, `~/.logout` |
| POSIX sh/dash | ✅ Full | `~/.profile` |

## Uninstallation

```bash
# Remove integration and files
./uninstall.sh

# Or via one-line (if installed via curl)
curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/uninstall.sh | bash

# Keep files but remove shell integration
./uninstall.sh --keep-files

# Kill running agent before uninstalling
./uninstall.sh --kill-agent
```

## Troubleshooting

### Agent not starting

Check if SSH agent utilities are available:
```bash
command -v ssh-agent ssh-add
```

Enable verbose mode to see what's happening:
```bash
export SSA_VERBOSE=1
source ~/.bashrc  # or your shell's RC file
```

### Multiple agents running

Make sure you're using the installed version:
```bash
grep shared-ssh-agent ~/.bashrc  # or your shell's RC file
```

Check agent environment:
```bash
ls -la ~/.ssh/agent_envs/
cat ~/.ssh/agent_envs/$(hostname -s)
```

### Agent persists after closing all shells

This usually means a background process is holding a reference. Check:
```bash
ps aux | grep ssh-agent
```

Manually clean up:
```bash
ssh-agent -k  # using the existing agent
rm -f ~/.ssh/agent_envs/$(hostname -s)
```

### Conflicts with existing SSH agent

If you have an existing SSH agent (e.g., from SSH forwarding, keychain, or gnome-keyring), shared-ssh-agent will detect it and skip starting a new agent. This is by design.

To force a new agent, unset the environment variables first:
```bash
unset SSH_AGENT_PID SSH_AUTH_SOCK
```

## Architecture

The project follows a three-layer architecture:

1. **Hooks** (`hooks/`) - Shell-specific RC file integration
2. **Wrappers** (`lib/*.sh/*.zsh/*.fish/*.csh`) - Shell-specific syntax wrappers
3. **Core** (`lib/core.sh`) - POSIX-compliant agent lifecycle management

See [ARCHITECTURE.md](ARCHITECTURE.md) for details.

## Development

### Running Tests

```bash
# Run all tests
./tests/test-structure.sh
./tests/test-syntax.sh
./tests/test-interactive.sh
./tests/test-stubs.sh
./tests/test-phase2.sh
./tests/test-install.sh

# Or use the setup script
./setup-phase1.sh
```

### Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## Migrating from oh-my-bash Plugin

If you're currently using the oh-my-bash `shared-ssh-agent` plugin:

1. The agent environment files (`~/.ssh/agent_envs/`) are compatible - no migration needed
2. Uninstall the plugin from oh-my-bash (remove from `plugins=()` in `~/.bashrc`)
3. Install this universal version: `./install.sh --shell bash`
4. The functionality is identical but now works across all shells

See [MIGRATION.md](MIGRATION.md) for detailed instructions.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Author

Seth Underwood ([@underwoo](https://github.com/underwoo))

## Links

- [GitHub Repository](https://github.com/underwoo/shared-ssh-agent)
- [Issue Tracker](https://github.com/underwoo/shared-ssh-agent/issues)
- [CI/CD Status](https://github.com/underwoo/shared-ssh-agent/actions)
