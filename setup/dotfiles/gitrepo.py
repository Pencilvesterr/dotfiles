"""Machine-local git configuration for this repo: skip-worktree flags, the
work-tooling clean filter, and the hooks path. All idempotent — run on every sync."""

from __future__ import annotations

import subprocess
from pathlib import Path

from dotfiles import ui
from dotfiles.profile import Profile

# work.gitconfig is symlinked to ~/.gitconfig on work machines. Work tooling
# auto-appends machine-specific sections ([trace2], [githooks], etc.) below this
# marker; skip-worktree and the clean filter keep those out of commits.
WORK_GITCONFIG = "config/git/global-config/work.gitconfig"
STRIP_FILTER_CLEAN = "sed '/^# Work specific - kept here/,$d'"


def _git(repo: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)


def housekeeping(repo: Path, prof: Profile) -> None:
    set_hooks_path(repo)
    set_skip_worktree(repo, prof)
    register_strip_work_tooling_filter(repo)


def ensure_submodules(repo: Path) -> None:
    # Non-fatal: the private submodule isn't reachable by consumers of the public
    # repo who lack access to it, and provisioning must still succeed for them.
    result = _git(repo, "submodule", "update", "--init", "--recursive")
    if result.returncode != 0:
        ui.warning(f"Could not update git submodules: {result.stderr.strip()}")


def set_hooks_path(repo: Path) -> None:
    _git(repo, "config", "core.hooksPath", str(repo / "config" / "git" / "hooks"))


def set_skip_worktree(repo: Path, prof: Profile) -> None:
    paths = ["config/zsh/local.zsh"]
    if prof.is_work:
        # To commit intentional changes to work.gitconfig: temporarily disable with
        # `git update-index --no-skip-worktree config/git/global-config/work.gitconfig`,
        # stage and commit, then re-enable.
        paths.append(WORK_GITCONFIG)
    for path in paths:
        result = _git(repo, "update-index", "--skip-worktree", path)
        if result.returncode != 0:
            ui.warning(f"Could not mark {path} skip-worktree: {result.stderr.strip()}")


def register_strip_work_tooling_filter(repo: Path) -> None:
    # Safety net: if skip-worktree is ever disabled and work.gitconfig is staged,
    # this clean filter (routed via .gitattributes) strips the work-tooling sections
    # so they can never land in a commit. Lives in .git/config (machine-local).
    _git(repo, "config", "filter.strip-work-tooling.clean", STRIP_FILTER_CLEAN)
    _git(repo, "config", "filter.strip-work-tooling.smudge", "cat")
