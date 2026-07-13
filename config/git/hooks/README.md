# Git Hooks

This directory is registered as the repo's hooks path (`git config core.hooksPath`)
by `./dot install` / `./dot sync`.

## pre-commit

A thin shim that runs `./dot hook pre-commit` (see `setup/dotfiles/hook.py`).
It checks every symlink target defined in `setup/dotbot/*.yaml` before each
commit to keep the repository and system config files in sync:

- Correct symlink → skip
- Broken, same contents → fix the symlink, continue
- Broken, differs, no git changes to repo file → adopt machine version, stage it, continue
- Broken, differs, repo file has staged/unstaged changes → warn and abort

Managed (app-owned) files from `setup/managed.toml` are always pulled
system → repo, never staged.

On a machine with the `work-mac` profile, the hook also copies Arc's current
`StorableSidebar.json` into the ignored `dotfiles-private/` checkout. When the
file changed, it commits only that file to the private repository and pushes the
current branch. Private sync failures warn but do not block the public commit.

**Why this is needed:**
When you edit files using certain editors or tools (including the Edit tool), they may replace the file instead of modifying it in-place. This breaks symlinks. The hook ensures that symlinks are recreated before each commit, preventing out-of-sync configurations.

On machines without a saved profile (`./dot profile set <name>`) or without uv,
the hook skips its checks rather than blocking commits.

## Testing

Test the hook manually:

```bash
./dot hook pre-commit
```
