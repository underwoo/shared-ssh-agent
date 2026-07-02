# Architecture Decisions

## Core Design Decisions

### Three-Layer Architecture
**Decision**: Hooks → Shell Wrappers → POSIX Core
**Rationale**: Maximum portability while supporting shell-specific features
**Date**: Phase 1

### POSIX-Compliant Core
**Decision**: lib/core.sh must be pure POSIX sh
**Rationale**: Works everywhere (dash, ash, sh, bash, etc.)
**Trade-off**: No arrays, no `[[`, more verbose
**Date**: Phase 1

### Interactive-Only by Default
**Decision**: Skip initialization for non-interactive shells by default
**Rationale**: No overhead for scripts, cron, SSH commands
**Override**: SSA_ENABLE_NONINTERACTIVE=1 for opt-in
**Date**: Phase 1

### Reference Counting
**Decision**: Track active shells, cleanup when count reaches 0
**Rationale**: Single agent survives across sessions, cleaned up automatically
**Implementation**: SSH_AGENT_COUNT in environment file
**Date**: Phase 2

### Agent Environment Files
**Decision**: Store at ~/.ssh/agent_envs/<hostname>
**Format**: POSIX sh-compatible export statements
**Rationale**: Simple, portable, no dependencies
**Date**: Phase 2

### Installation Location
**Decision**: Default to ~/.local/share/shared-ssh-agent
**Rationale**: XDG Base Directory spec compliance
**Override**: --prefix flag for custom location
**Date**: Phase 3

### Idempotent Installation
**Decision**: Use marker blocks in RC files for safe re-runs
**Format**: `# shared-ssh-agent: auto-generated [begin|end]`
**Rationale**: Safe to run installer multiple times, add shells incrementally
**Date**: Phase 3

### Bootstrap Installation
**Decision**: Support curl | bash pattern
**Implementation**: install.sh detects when piped, downloads to temp, self-executes
**Rationale**: One-line installation from GitHub
**Date**: Phase 3

## Shell-Specific Decisions

### Bash
- RC: ~/.bashrc (init), ~/.bash_logout (exit)
- Interactive check: `[[ $- != *i* ]]`

### Zsh
- RC: ~/.zshrc (init), ~/.zlogout (exit)
- Interactive check: `[[ ! -o interactive ]]`

### Fish
- RC: ~/.config/fish/config.fish (init with on-event fish_exit for cleanup)
- Interactive check: `status is-interactive`
- Pure Fish implementation (no sourcing of POSIX core)

### Csh/Tcsh
- RC: ~/.cshrc or ~/.tcshrc (init), ~/.logout (exit)
- Interactive check: `$?prompt`
- Alias-based function emulation

### POSIX sh
- RC: ~/.profile (init with trap on EXIT for cleanup)
- Interactive check: `case $- in *i*)`

## Testing Decisions

### CI/CD Strategy
**Decision**: GitHub Actions with matrix testing
**Coverage**: Ubuntu + macOS × bash + zsh
**Additional**: tcsh, sh, bootstrap tests
**Date**: Phase 4

### Test Organization
**Decision**: Separate test scripts per concern
**Files**: test-structure, test-syntax, test-interactive, test-phase2, test-install
**Rationale**: Parallel execution, clear failure isolation
**Date**: Phase 1-4

## Documentation Decisions

### File Structure
- README.md: User-facing quick start and complete guide
- ARCHITECTURE.md: Developer-facing internal design
- MIGRATION.md: oh-my-bash plugin migration guide
- CHANGELOG.md: Version history (Keep a Changelog format)

### Versioning
**Decision**: Semantic Versioning (semver.org)
**First Release**: v1.0.0 (2026-07-02)
**Rationale**: Feature complete, tested, production-ready

## Future Considerations (Not Yet Decided)

### File Locking
- **Question**: flock vs lockfile vs mkdir atomic locking?
- **Context**: Race conditions when multiple shells start simultaneously
- **Status**: Deferred post-v1.0.0

### Config File
- **Question**: Support ~/.config/shared-ssh-agent/config?
- **Current**: Environment variables only
- **Status**: YAGNI - will add if users request

### Keychain Integration
- **Question**: Integrate with macOS Keychain for key persistence?
- **Context**: macOS-specific feature
- **Status**: Research needed

### Systemd Service
- **Question**: Optional systemd user service mode?
- **Context**: Linux-specific feature
- **Status**: User feedback needed
