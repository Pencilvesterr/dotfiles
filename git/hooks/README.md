# Git Hooks

This directory contains git hooks that are installed by `./install.sh`.

## pre-commit

Automatically checks for broken symlinks before each commit to ensure the repository and system config files stay in sync.

**What it does:**

For each target in the config files:
- Correct symlink → skip
- Broken, same contents → fix the symlink, continue
- Broken, differs, no git changes to repo file → adopt machine version, stage it, continue
- Broken, differs, repo file has staged/unstaged changes → warn and abort

**Why this is needed:**
When you edit files using certain editors or tools (including the Edit tool), they may replace the file instead of modifying it in-place. This breaks symlinks. The hook ensures that symlinks are recreated before each commit, preventing out-of-sync configurations.

## Installation

The hook is automatically installed when you run `./install.sh`. To manually install:

```bash
cp git/hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Testing

Test the hook manually:

```bash
.git/hooks/pre-commit
```
