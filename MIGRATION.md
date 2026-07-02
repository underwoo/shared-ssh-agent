# Migration Guide: From oh-my-bash Plugin to Universal Installation

This guide helps you migrate from the oh-my-bash `shared-ssh-agent` plugin to the universal standalone version.

## Why Migrate?

The universal version offers:
- **Multi-shell support**: Use the same agent across bash, zsh, fish, csh, etc.
- **No framework dependency**: Works without oh-my-bash
- **Better testing**: Comprehensive CI/CD test suite
- **Simpler updates**: Git clone and pull, no framework coupling
- **One-line install**: Easy installation from GitHub

## Compatibility

**Good news**: The agent environment files are 100% compatible! Both versions use:
- Same location: `~/.ssh/agent_envs/<hostname>`
- Same file format
- Same reference counting mechanism

You can switch between versions without losing your running agent.

## Migration Steps

### Step 1: Backup (Optional but Recommended)

```bash
# Backup your current setup
cp ~/.bashrc ~/.bashrc.backup
cp -r ~/.ssh/agent_envs ~/.ssh/agent_envs.backup
```

### Step 2: Note Your Current Agent

If you have an active agent, note its PID:
```bash
echo "Current agent PID: $SSH_AGENT_PID"
echo "Current count: $SSH_AGENT_COUNT"
```

The agent will continue running during migration.

### Step 3: Remove oh-my-bash Plugin

Edit `~/.bashrc` and remove `shared-ssh-agent` from the plugins array:

**Before:**
```bash
plugins=(
  git
  bashmarks
  shared-ssh-agent  # ← Remove this
  docker
)
```

**After:**
```bash
plugins=(
  git
  bashmarks
  docker
)
```

### Step 4: Reload Your Shell

```bash
source ~/.bashrc
```

Your existing agent should still be running. Verify:
```bash
ssh-add -l
```

### Step 5: Install Universal Version

**Option A: One-line install**
```bash
curl -fsSL https://raw.githubusercontent.com/underwoo/shared-ssh-agent/main/install.sh | bash
```

**Option B: From clone**
```bash
git clone https://github.com/underwoo/shared-ssh-agent.git
cd shared-ssh-agent
./install.sh --shell bash
```

### Step 6: Verify Installation

Open a new terminal and check:
```bash
# Should show the same agent
echo $SSH_AGENT_PID
ssh-add -l

# Check the integration
grep shared-ssh-agent ~/.bashrc
```

### Step 7: Test Multi-Shell (Optional)

If you use multiple shells, install for them too:
```bash
cd shared-ssh-agent
./install.sh --shell zsh
./install.sh --shell fish
# etc.
```

Or install for all detected shells at once:
```bash
./install.sh --all-shells
```

## Rollback

If you need to roll back to the oh-my-bash plugin:

1. **Uninstall universal version:**
   ```bash
   cd shared-ssh-agent
   ./uninstall.sh
   ```

2. **Restore oh-my-bash plugin:**
   ```bash
   # Edit ~/.bashrc and add shared-ssh-agent back to plugins=()
   vim ~/.bashrc
   source ~/.bashrc
   ```

Your agent environment files remain intact through the entire process.

## Differences

| Feature | oh-my-bash Plugin | Universal Version |
|---------|------------------|-------------------|
| Shell support | bash only | bash, zsh, fish, csh/tcsh, sh |
| Dependencies | oh-my-bash | None |
| Installation | Copy to OMB custom dir | Standalone installer |
| Updates | Manual copy | git pull + reinstall |
| Testing | Manual | Automated CI/CD |
| Bootstrap install | No | Yes (curl \| bash) |

## Functionality Changes

### What's the Same
- Agent lifecycle management
- Reference counting
- Environment file location and format
- Interactive-only default behavior
- Configuration variables (SSA_VERBOSE, SSA_DEBUG, etc.)

### What's New
- Multi-shell support
- One-line installation
- Idempotent installation (safe to run multiple times)
- Better error messages and debugging
- Comprehensive test suite
- Portable POSIX-compliant core

### What's Different
- RC file markers: Now uses `# shared-ssh-agent: auto-generated` blocks
- Installation location: Now `~/.local/share/shared-ssh-agent` (configurable)
- Uninstall script: Now removes integration cleanly using markers

## Troubleshooting

### "Agent not starting after migration"

Check that oh-my-bash isn't still loading the old plugin:
```bash
grep -r shared-ssh-agent ~/.oh-my-bash/custom/
```

### "Multiple agents running"

Kill all agents and start fresh:
```bash
pkill -u $USER ssh-agent
rm -rf ~/.ssh/agent_envs/*
# Open new shell - universal version will start fresh agent
```

### "Installation says already installed"

The universal version detected the oh-my-bash plugin's integration. Remove it:
```bash
# Edit ~/.bashrc and remove the shared-ssh-agent plugin from OMB
# Then reinstall universal version
```

### "Agent count seems wrong"

Reset the count:
```bash
# Kill current agent
ssh-agent -k
rm ~/.ssh/agent_envs/$(hostname -s)
# Open new shell
```

## Getting Help

- **Issues**: https://github.com/underwoo/shared-ssh-agent/issues
- **Discussions**: https://github.com/underwoo/shared-ssh-agent/discussions
- **Documentation**: https://github.com/underwoo/shared-ssh-agent

## Next Steps

After successful migration:

1. Consider installing for other shells you use
2. Set up configuration variables if needed (SSA_VERBOSE, etc.)
3. Star the repository if you find it useful!
4. Report any issues or improvements

Welcome to universal SSH agent management! 🎉
