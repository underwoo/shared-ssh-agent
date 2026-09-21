# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.2] - 2026-09-21

### Fixed
- `update.sh` no longer exits with status 1 after a successful update when some shells are not configured (`check_shell_configured` returning non-zero aborted the script under `set -e`)

## [1.1.1] - 2026-09-21

### Fixed
- `install.sh` now installs `update.sh` and `CHANGELOG.md` into the installation directory, so `update.sh` can run and report the installed version

### Documentation
- Added upgrade instructions for installations made with v1.0.0

## [1.1.0] - 2026-09-21

### Added
- Self-update script (`update.sh`) for updating to latest version
- Support for both git-based and bootstrap installations
- Update version checking via `--check` flag
- Documentation for update workflow and optional shell aliases

### Fixed
- Silence `mkdir` output when it is aliased with `-v` (or similar) by calling `command mkdir` and discarding stdout as well as stderr

## [1.0.0] - 2026-07-02

### Added
- Universal SSH agent sharing across multiple shells (bash, zsh, fish, csh/tcsh, POSIX sh)
- Automatic agent lifecycle management with reference counting
- One-line installation via curl pipe to bash
- Idempotent installation supporting multiple shells simultaneously
- Comprehensive uninstaller with cleanup options
- Interactive-only mode by default (opt-in for non-interactive via SSA_ENABLE_NONINTERACTIVE)
- Configuration via environment variables (SSA_VERBOSE, SSA_DEBUG, SSA_AGENT_ENV_DIR)
- GitHub Actions CI/CD pipeline with 6 parallel test jobs
- Cross-platform support (Linux, macOS, BSD)
- Multi-shell test coverage (bash, zsh, sh, tcsh)
- Comprehensive documentation (README, ARCHITECTURE, MIGRATION)
- Migration guide from oh-my-bash plugin
- Bootstrap installation mode for direct GitHub installs
- Dry-run mode for installation
- Custom installation prefix support
- Shell auto-detection

### Architecture
- Three-layer design: hooks → shell wrappers → POSIX core
- POSIX-compliant core library for maximum portability
- Shell-specific hooks for each supported shell
- Agent environment files at ~/.ssh/agent_envs/<hostname>
- Reference counting to track active shell sessions
- Automatic cleanup when last shell exits

### Testing
- Structure validation tests
- Shell syntax validation (shellcheck)
- Interactive detection tests
- Agent functionality tests
- Cross-shell compatibility tests
- Idempotent installation tests
- Bootstrap installation tests
- CI/CD on Ubuntu and macOS

## Project History

### Development Phases

**Phase 1**: Project structure and stubs
- Created directory layout (hooks/, lib/, tests/)
- Implemented shell-specific stub files
- Added interactive detection logic
- Basic test suite

**Phase 2**: Core agent functionality
- Implemented POSIX-compliant agent lifecycle management
- Added reference counting logic
- Agent startup and connection logic
- Cleanup and shutdown logic
- Agent environment file management

**Phase 3**: Installation and uninstallation
- Full-featured install.sh with shell auto-detection
- Multi-shell support in single run
- Idempotent installation
- RC file modification with marker blocks
- Comprehensive uninstall.sh with cleanup options
- Bootstrap mode for one-line installs

**Phase 4**: CI/CD and comprehensive testing
- GitHub Actions workflow with 6 parallel jobs
- Multi-OS testing (Ubuntu, macOS)
- Multi-shell testing (bash, zsh, sh, tcsh)
- Bootstrap installation tests
- Idempotent installation verification
- Cross-shell compatibility validation

**Phase 5**: Documentation and release preparation
- Expanded README with complete usage guide
- Architecture documentation
- Migration guide from oh-my-bash plugin
- CHANGELOG following Keep a Changelog format
- Prepared for v1.0.0 release

[Unreleased]: https://github.com/underwoo/shared-ssh-agent/compare/v1.1.2...HEAD
[1.1.2]: https://github.com/underwoo/shared-ssh-agent/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/underwoo/shared-ssh-agent/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/underwoo/shared-ssh-agent/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/underwoo/shared-ssh-agent/releases/tag/v1.0.0
