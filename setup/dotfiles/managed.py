"""Managed files: configs owned by third-party apps that overwrite symlinks, so they
are copied between the repo and the system instead of linked. Defined in
setup/managed.toml."""

from __future__ import annotations

import filecmp
import os
import shutil
import subprocess
import tomllib
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

from dotfiles import ui
from dotfiles.profile import Profile

MANAGED_FILE = Path("setup/managed.toml")


@dataclass(frozen=True)
class ManagedEntry:
    repo_path: Path  # absolute path in the repo
    system_path: Path  # absolute path on this machine


class State(Enum):
    SAME = "same"
    MACHINE_MISSING = "machine missing"
    REPO_MISSING = "repo missing"
    MACHINE_CHANGED = "machine changed"
    CONFLICT = "conflict"
    BOTH_MISSING = "both missing"


def entries(repo: Path, prof: Profile) -> list[ManagedEntry]:
    data = tomllib.loads((repo / MANAGED_FILE).read_text())
    out = []
    for item in data.get("files", []):
        if item.get("context", prof.context) != prof.context:
            continue
        if item.get("os", prof.os) != prof.os:
            continue
        out.append(
            ManagedEntry(
                repo_path=repo / item["repo"],
                system_path=Path(os.path.expanduser(item["system"])),
            )
        )
    return out


def _copy(src: Path, dest: Path, dry_run: bool, label: str) -> None:
    if not src.exists():
        ui.warning(f"Not found, skipping: {src}")
        return
    if dest.exists():
        try:
            if src.resolve() == dest.resolve():
                ui.info(f"Skipping (same file): {src}")
                return
        except OSError:
            pass
        if same_content(src, dest):
            return  # already in sync, stay quiet
    if dry_run:
        ui.info(f"would {label}: {src} -> {dest}")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.is_symlink() and not dest.exists():
        dest.unlink()
    if src.is_dir():
        shutil.copytree(src, dest, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dest)
    ui.success(f"{label}: {src} -> {dest}")


def same_content(a: Path, b: Path) -> bool:
    if a.is_file() and b.is_file():
        return filecmp.cmp(a, b, shallow=False)
    return False


def _repo_path_dirty(repo: Path, path: Path) -> bool:
    """Return whether path has staged, unstaged, deleted, or untracked changes.

    Resolve the containing Git worktree independently because managed files may
    live in a submodule rather than the top-level dotfiles repository.
    """
    cwd = path.parent
    while not cwd.exists() and cwd != repo:
        cwd = cwd.parent
    root = subprocess.run(
        ["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
    )
    if root.returncode != 0:
        return True  # fail safe: never overwrite either side without Git history
    git_root = Path(root.stdout.strip())
    try:
        rel = path.relative_to(git_root)
    except ValueError:
        return True
    status = subprocess.run(
        ["git", "-C", str(git_root), "status", "--porcelain=v1", "--", str(rel)],
        capture_output=True,
        text=True,
    )
    return status.returncode != 0 or bool(status.stdout.strip())


def classify(repo: Path, entry: ManagedEntry) -> State:
    repo_exists = entry.repo_path.is_file()
    system_exists = entry.system_path.is_file()
    if not repo_exists and not system_exists:
        return State.BOTH_MISSING
    if not system_exists:
        return State.MACHINE_MISSING
    if not repo_exists:
        return State.REPO_MISSING
    if same_content(entry.repo_path, entry.system_path):
        return State.SAME
    if _repo_path_dirty(repo, entry.repo_path):
        return State.CONFLICT
    return State.MACHINE_CHANGED


def sync(
    repo: Path,
    prof: Profile,
    dry_run: bool = False,
    overwrite_with_repo: bool = False,
) -> int:
    """Synchronize managed files, preferring machine changes unless explicitly overridden."""
    classified = [(entry, classify(repo, entry)) for entry in entries(repo, prof)]

    if not overwrite_with_repo:
        conflicts = [entry for entry, state in classified if state is State.CONFLICT]
        if conflicts:
            for entry in conflicts:
                ui.error(
                    f"Conflict: '{entry.repo_path}' has uncommitted changes and "
                    f"'{entry.system_path}' on this machine also differs."
                )
                ui.info("Keep the machine version: ./dot pull")
                ui.info("Keep the repo version: ./dot sync --overwrite-managed-with-repo-version")
            return 2

    for entry, state in classified:
        if overwrite_with_repo:
            _copy(entry.repo_path, entry.system_path, dry_run, "push")
        elif state is State.MACHINE_CHANGED or state is State.REPO_MISSING:
            _copy(entry.system_path, entry.repo_path, dry_run, "pull")
        elif state is State.MACHINE_MISSING:
            _copy(entry.repo_path, entry.system_path, dry_run, "push")
        elif state is State.BOTH_MISSING:
            ui.warning(f"Not found on machine or in repo, skipping: {entry.system_path}")
    return 0


def pull(repo: Path, prof: Profile, dry_run: bool = False) -> None:
    """Copy managed files from their system locations into the repo."""
    for e in entries(repo, prof):
        _copy(e.system_path, e.repo_path, dry_run, "pull")


def push(repo: Path, prof: Profile, dry_run: bool = False) -> None:
    """Copy managed files from the repo to their system locations."""
    for e in entries(repo, prof):
        _copy(e.repo_path, e.system_path, dry_run, "push")


def diff(repo: Path, prof: Profile) -> int:
    """Report managed files whose system copy differs from the repo copy."""
    rc = 0
    for e in entries(repo, prof):
        if not e.system_path.exists() or not e.repo_path.exists():
            continue
        if not same_content(e.repo_path, e.system_path):
            ui.warning(f"managed file differs from repo: {e.system_path}")
            rc = 1
    return rc
