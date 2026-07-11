"""Git hook entry points (invoked via `dot hook <name>` from git/hooks/ shims)."""

from __future__ import annotations

from pathlib import Path

from dotfiles import linker, managed
from dotfiles.profile import Profile


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
    return 0
