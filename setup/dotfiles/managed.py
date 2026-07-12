"""Managed files: configs owned by third-party apps that overwrite symlinks, so they
are copied between the repo and the system instead of linked. Defined in
setup/managed.toml."""

from __future__ import annotations

import filecmp
import os
import shutil
import tomllib
from dataclasses import dataclass
from pathlib import Path

from dotfiles import ui
from dotfiles.profile import Profile

MANAGED_FILE = Path("setup/managed.toml")


@dataclass(frozen=True)
class ManagedEntry:
    repo_path: Path  # absolute path in the repo
    system_path: Path  # absolute path on this machine


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
