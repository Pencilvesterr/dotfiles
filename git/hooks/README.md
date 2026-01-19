# Git Hooks

This directory contains git hooks that are installed by `./install.sh`.

## pre-commit

Automatically synchronizes hardlinks before each commit to ensure the repository and system config files stay in sync.

**What it does:**
1. Runs `./scripts/hardlinks.sh --delete --include-files` for both regular and work configs
2. Runs `./scripts/hardlinks.sh --create` for both regular and work configs
3. Stages any files that were modified during the sync
4. Proceeds with the commit

**Why this is needed:**
When you edit files using certain editors or tools (including the Edit tool), they may replace the file instead of modifying it in-place. This breaks hardlinks by giving the file a new inode. This hook ensures that hardlinks are recreated before each commit, preventing out-of-sync configurations.

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
