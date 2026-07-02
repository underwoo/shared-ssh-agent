# shared-ssh-agent

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

## Quick Start

```bash
# Clone the repository
git clone https://github.com/underwoo/shared-ssh-agent.git
cd shared-ssh-agent

# Install for your current shell
./install.sh

# Reload your shell or open a new terminal
```

## Status

🚧 **Work in Progress** - Initial development phase

## License

MIT License - See LICENSE file for details

## Author

Seth Underwood (@underwoo)
