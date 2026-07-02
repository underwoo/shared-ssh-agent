# shared-ssh-agent Architecture

## Overview

This document describes the internal architecture of shared-ssh-agent, a shell-agnostic SSH agent management system that maintains a single shared ssh-agent across multiple terminal sessions.

## Design Philosophy

- **Shell-agnostic**: Support bash, zsh, sh/dash, fish, and csh/tcsh
- **POSIX-compliant core**: Use POSIX sh for maximum portability
- **Silent by default**: No output unless errors occur or verbose mode enabled
- **Reference counting**: Track active shells and cleanup when count reaches zero
- **Interactive-only**: Skip initialization for non-interactive shells (with opt-in override)

## Architecture Layers

The system uses a three-layer architecture:

```
User Shell Init → hooks/{shell}-init.{ext} → lib/{shell}.{ext} → lib/core.sh → ssh-agent operations
User Shell Exit → hooks/{shell}-exit.{ext} → lib/{shell}.{ext} → lib/core.sh → cleanup operations
```

### Layer 1: Hooks (`hooks/`)

Shell-specific initialization and cleanup hooks that integrate with each shell's startup/shutdown mechanism.

**Responsibilities:**
- Detect interactive vs non-interactive shells
- Source the appropriate shell-specific library wrapper
- Call initialization (`ssa_init`) or cleanup (`ssa_cleanup`) functions

**Files:**
- `bash-init.sh`, `bash-exit.sh` - Bash hooks
- `zsh-init.zsh`, `zsh-exit.zsh` - Zsh hooks
- `sh-init.sh`, `sh-exit.sh` - POSIX sh hooks
- `fish-init.fish`, `fish-exit.fish` - Fish hooks
- `csh-init.csh`, `csh-exit.csh` - C-shell hooks

### Layer 2: Shell Wrappers (`lib/`)

Shell-specific wrapper libraries that provide a consistent interface to the core logic.

**Responsibilities:**
- Source the core POSIX library (`core.sh`)
- Provide shell-specific syntax wrappers for `ssa_init()` and `ssa_cleanup()`
- Handle shell-specific path resolution

**Files:**
- `bash.sh` - Bash wrapper (uses `${BASH_SOURCE[0]}`)
- `zsh.sh` - Zsh wrapper (uses `${0:a:h}`)
- `sh.sh` - POSIX sh wrapper (uses `dirname "$0"`)
- `fish.fish` - Fish wrapper (pure Fish implementation)
- `csh.csh` - C-shell wrapper (alias-based)

### Layer 3: Core Logic (`lib/core.sh`)

POSIX-compliant agent management implementation.

**Responsibilities:**
- Start new ssh-agent or connect to existing
- Maintain reference count of active shells
- Store/retrieve agent environment variables
- Cleanup agent when last shell exits

**Core Functions:**
- `ssa_core_start_or_connect()` - Initialize or connect to agent
- `ssa_core_increment_ref()` - Increment shell reference count
- `ssa_core_decrement_ref()` - Decrement count, kill agent if zero
- `ssa_core_check_agent()` - Verify agent is accessible

## Environment Variables

### Exported Variables (set by core.sh)

```bash
SSH_AUTH_SOCK           # Socket path for ssh-agent communication
SSH_AGENT_PID           # Process ID of running agent
SSH_AGENT_COUNT         # Reference count (number of active shells)
SSA_INSTALL_DIR         # Installation directory (set by installer)
```

### Internal Variables (not exported)

```bash
SSA_AGENT_ENV_DIR       # Directory for agent env files (~/.ssh/agent_envs)
SSA_AGENT_ENV_FILE      # Path to agent env file
SSA_HOSTNAME            # Cached hostname (hostname -s)
SSA_ENABLE_NONINTERACTIVE  # User opt-in for non-interactive shells
SSA_VERBOSE             # Enable verbose output (Phase 2)
SSA_DEBUG               # Enable debug logging (Phase 2)
```

## Agent Environment Files

**Location:** `~/.ssh/agent_envs/<hostname>`

**Format:** POSIX sh-compatible variable exports

```bash
SSH_AUTH_SOCK=/tmp/ssh-XXXXXXXXX/agent.12345; export SSH_AUTH_SOCK;
SSH_AGENT_PID=12345; export SSH_AGENT_PID;
SSH_AGENT_COUNT=1; export SSH_AGENT_COUNT;
```

**Lifecycle:**
1. Created when first shell starts and no agent exists
2. Sourced by each subsequent shell to connect to existing agent
3. `SSH_AGENT_COUNT` incremented on each shell init
4. `SSH_AGENT_COUNT` decremented on each shell exit
5. Deleted when count reaches zero and agent is killed

## Interactive Shell Detection

Each shell has its own mechanism for detecting interactive mode:

**Bash:**
```bash
[[ $- != *i* ]] && return    # Check for 'i' in $- (shell options)
```

**Zsh:**
```zsh
[[ ! -o interactive ]] && return    # Check interactive option
```

**POSIX sh/dash:**
```sh
case $- in
    *i*) ;;       # Interactive
    *) return ;;  # Non-interactive
esac
```

**Fish:**
```fish
if not status is-interactive
    return
end
```

**Csh/Tcsh:**
```csh
if (! $?prompt) exit    # prompt variable only set in interactive shells
```

**Opt-in override:** Set `SSA_ENABLE_NONINTERACTIVE=1` to force initialization in non-interactive shells.

## Installation Integration

**User-local installation (default):** `~/.local/share/shared-ssh-agent`

**Shell integration points:**

| Shell | Init File | Exit File |
|-------|-----------|-----------|
| Bash | `~/.bashrc` | `~/.bash_logout` |
| Zsh | `~/.zshrc` | `~/.zlogout` |
| POSIX sh | `~/.profile` | trap on EXIT |
| Fish | `~/.config/fish/conf.d/` | `--on-event fish_exit` |
| Csh/Tcsh | `~/.cshrc` | `~/.logout` |

## Error Handling

**Level 0: Silent (default)**
- No output for normal operation
- Non-interactive shells skip initialization silently

**Level 1: Warnings (opt-in via SSA_VERBOSE=1)**
- Informational messages about agent state
- Warnings for recoverable issues

**Level 2: Critical errors (always shown)**
- Only for situations requiring user intervention
- Output to stderr

**Philosophy:** Graceful degradation. If agent management fails, the shell continues to work normally.

## POSIX Compliance

**Requirements for core.sh:**
- Shebang: `#!/bin/sh` (not `/bin/bash`)
- No bash-isms: avoid `[[`, use `[` instead
- Use `$()` for command substitution (POSIX since 1992)
- No arrays (use newline-separated strings)
- No `local` keyword (use function-scoped variable naming)

**Testing:**
```bash
shellcheck -s sh lib/core.sh
dash lib/core.sh  # Test with dash (pure POSIX)
```

## Phase 1 vs Phase 2

**Phase 1 (Current):**
- Complete directory structure
- All stub files with interactive detection
- Test suite for validation
- No functional agent management yet

**Phase 2 (Future):**
- Full agent lifecycle implementation
- Reference counting logic
- File locking for race condition prevention
- Error handling and logging
- Installer/uninstaller implementation

## Testing

**Test Suite (`tests/`):**

1. `test-structure.sh` - Verify all files/directories present
2. `test-syntax.sh` - Validate shell syntax for all files
3. `test-interactive.sh` - Test interactive detection logic
4. `test-stubs.sh` - Verify stub functions execute without errors

**Running tests:**
```bash
cd /path/to/shared-ssh-agent
chmod +x tests/*.sh
./tests/test-structure.sh
./tests/test-syntax.sh
./tests/test-interactive.sh
./tests/test-stubs.sh
```

## File Permissions

- **Executable scripts:** 755 (hooks, installers, tests)
- **Library files:** 644 (lib/*.sh, lib/*.fish, lib/*.csh)
- **Documentation:** 644 (README.md, LICENSE, ARCHITECTURE.md)

## Development Workflow

1. All changes must pass the test suite
2. Shell-specific code goes in hooks/ or lib/{shell}.*
3. Portable code goes in lib/core.sh (POSIX only)
4. Document interface changes in this file
5. Update tests when adding new features

## Future Enhancements (Post-Phase 2)

- File locking for race condition prevention (flock/lockfile/mkdir)
- Optional config file support (`~/.config/shared-ssh-agent/config`)
- macOS Keychain integration
- BSD compatibility improvements
- Systemd user service integration
- Per-host vs per-user agent modes
- Agent key autoloading on startup
