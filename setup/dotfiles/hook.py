"""Git hook entry points (invoked via `dot hook <name>` from config/git/hooks/ shims)."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from dotfiles import linker, managed, ui
from dotfiles.profile import Profile

PRIVATE_REPO = Path("dotfiles-private")
ARC_SIDEBAR = Path("Library/Application Support/Arc/StorableSidebar.json")
PRIVATE_ARC_SIDEBAR = Path("arc/StorableSidebar.json")


def _private_git(private_repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(private_repo), *args],
        capture_output=True,
        text=True,
    )


def _warn_private_sync(message: str, result: subprocess.CompletedProcess[str] | None = None) -> None:
    detail = ""
    if result is not None:
        detail = (result.stderr or result.stdout).strip().splitlines()[-1:]
        detail = f": {detail[0]}" if detail else ""
    ui.warning(f"Private Arc sync skipped: {message}{detail}")


def sync_private_arc(repo: Path, prof: Profile) -> None:
    """Back up Arc's sidebar to the nested private repo on a work Mac.

    This is intentionally best-effort: private-repo failures must not block a commit
    to the public dotfiles repository.
    """
    if not (prof.is_work and prof.is_mac):
        return

    private_repo = repo / PRIVATE_REPO
    source = Path.home() / ARC_SIDEBAR
    destination = private_repo / PRIVATE_ARC_SIDEBAR

    if not source.is_file():
        _warn_private_sync(f"Arc sidebar not found at {source}")
        return
    if not private_repo.is_dir():
        _warn_private_sync(f"private repository not found at {private_repo}")
        return

    root = _private_git(private_repo, "rev-parse", "--show-toplevel")
    if root.returncode != 0 or Path(root.stdout.strip()).resolve() != private_repo.resolve():
        _warn_private_sync(f"{private_repo} is not a Git worktree", root)
        return

    try:
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
    except OSError as exc:
        _warn_private_sync(f"could not copy the Arc sidebar: {exc}")
        return

    changed = _private_git(
        private_repo, "status", "--porcelain=v1", "--", str(PRIVATE_ARC_SIDEBAR)
    )
    if changed.returncode != 0:
        _warn_private_sync("could not inspect the private repository", changed)
        return
    if not changed.stdout.strip():
        return

    commit = _private_git(
        private_repo,
        "commit",
        "--only",
        "--no-verify",
        "-m",
        "Update latest Arc sidebar",
        "--",
        str(PRIVATE_ARC_SIDEBAR),
    )
    if commit.returncode != 0:
        _warn_private_sync("could not commit the Arc sidebar", commit)
        return

    push = _private_git(private_repo, "push")
    if push.returncode != 0:
        _warn_private_sync("the Arc commit was created but could not be pushed", push)
        return

    ui.success("Updated and pushed the private Arc sidebar")


def pre_commit(repo: Path, prof: Profile) -> int:
    """Self-heal dotfile links before committing.

    - correct link                                   -> ok
    - broken/unlinked, same contents                 -> fix the symlink
    - differs, repo file has no uncommitted changes  -> adopt machine version, stage it
    - differs, repo file also changed                -> abort the commit
    Managed (app-owned) files are always pulled system -> repo, never staged.
    """
    conflicts = linker.heal(repo, prof, stage_adopted=True)

    for e in managed.entries(repo, prof):
        if not e.system_path.exists() or not e.repo_path.is_file():
            continue
        if managed.same_content(e.repo_path, e.system_path):
            continue
        e.repo_path.write_bytes(e.system_path.read_bytes())
        rel = e.repo_path.relative_to(repo)
        print(f"==> Pulled system version (not staged): {rel}")
        print(f"    (from: {e.system_path})")

    if conflicts:
        for e in conflicts:
            rel = e.source.relative_to(repo)
            print()
            print(f"  CONFLICT: {e.target}")
            print("  The file on your machine differs from the repo version,")
            print("  and the repo file also has staged or unstaged changes.")
            print()
            print("  Options:")
            print(f"    Keep machine version:  cp '{e.target}' '{e.source}' && git add '{rel}'")
            print(f"    Keep repo version:     rm '{e.target}' && ln -s '{e.source}' '{e.target}'")
            print()
        print("Commit aborted. Resolve the conflicts above and try again.")
        return 1
    sync_private_arc(repo, prof)
    return 0
