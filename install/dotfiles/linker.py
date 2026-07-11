"""Symlink management on top of the dotbot YAML layers in install/dotbot/.

The YAML files are the single source of truth for link definitions. dotbot performs the
actual linking; this module reads the same files to classify the state of every target,
which powers `dot diff`, `dot adopt`, dry runs, and the pre-commit self-heal.
"""

from __future__ import annotations

import filecmp
import os
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from enum import Enum
from pathlib import Path

import yaml

from dotfiles import ui
from dotfiles.profile import Profile

DOTBOT_DIR = Path("install/dotbot")


class State(Enum):
    OK = "ok"  # correct symlink
    MISSING = "missing"  # target doesn't exist yet
    WRONG_LINK = "wrong link"  # symlink pointing somewhere else (incl. broken)
    EXISTS_SAME = "exists, same content"  # real file/dir, identical to repo version
    EXISTS_DIFFERS = "exists, differs"  # real file/dir, differs from repo version
    CONFLICT = "conflict"  # differs AND the repo source has uncommitted changes
    SOURCE_MISSING = "source missing"  # repo file referenced by the config doesn't exist


@dataclass(frozen=True)
class LinkEntry:
    source: Path  # absolute path in the repo
    target: Path  # absolute path on this machine
    state: State | None = None

    def with_state(self, state: State) -> "LinkEntry":
        return LinkEntry(self.source, self.target, state)


def layer_files(repo: Path, prof: Profile) -> list[Path]:
    """The dotbot config layers for a profile, in apply order (later layers win)."""
    names = [
        "base.yaml",
        "macos.yaml" if prof.is_mac else "linux.yaml",
        "work.yaml" if prof.is_work else "personal.yaml",
    ]
    return [repo / DOTBOT_DIR / name for name in names]


def _load_tasks(layer: Path) -> list[dict]:
    tasks = yaml.safe_load(layer.read_text()) or []
    if not isinstance(tasks, list):
        raise ValueError(f"{layer}: expected a top-level list of dotbot tasks")
    return tasks


def entries(repo: Path, prof: Profile) -> list[LinkEntry]:
    """All (source, target) link pairs for a profile. Later layers override earlier
    ones for the same target (matching dotbot's relink behavior)."""
    by_target: dict[Path, LinkEntry] = {}
    for layer in layer_files(repo, prof):
        for task in _load_tasks(layer):
            for target_str, spec in (task.get("link") or {}).items():
                rel_source = spec if isinstance(spec, str) else spec["path"]
                target = Path(os.path.expanduser(target_str))
                by_target[target] = LinkEntry(source=repo / rel_source, target=target)
    return list(by_target.values())


# --- classification -----------------------------------------------------------


def _same_content(a: Path, b: Path) -> bool:
    if a.is_file() and b.is_file():
        return filecmp.cmp(a, b, shallow=False)
    if a.is_dir() and b.is_dir():
        cmp = filecmp.dircmp(a, b)
        return _dircmp_equal(cmp)
    return False


def _dircmp_equal(cmp: filecmp.dircmp) -> bool:
    if cmp.left_only or cmp.right_only or cmp.diff_files or cmp.funny_files:
        return False
    return all(_dircmp_equal(sub) for sub in cmp.subdirs.values())


def _repo_source_dirty(repo: Path, source: Path) -> bool:
    """True if the repo copy of `source` has uncommitted (staged or unstaged) changes."""
    rel = os.path.relpath(source, repo)
    result = subprocess.run(
        ["git", "-C", str(repo), "diff", "--quiet", "HEAD", "--", rel],
        capture_output=True,
    )
    return result.returncode != 0


def classify(repo: Path, entry: LinkEntry) -> LinkEntry:
    source, target = entry.source, entry.target
    if not source.exists():
        return entry.with_state(State.SOURCE_MISSING)
    if target.is_symlink():
        if os.readlink(target) == str(source):
            return entry.with_state(State.OK)
        return entry.with_state(State.WRONG_LINK)
    if not target.exists():
        return entry.with_state(State.MISSING)
    if _same_content(source, target):
        return entry.with_state(State.EXISTS_SAME)
    if _repo_source_dirty(repo, source):
        return entry.with_state(State.CONFLICT)
    return entry.with_state(State.EXISTS_DIFFERS)


def classified_entries(repo: Path, prof: Profile) -> list[LinkEntry]:
    return [classify(repo, e) for e in entries(repo, prof)]


# --- commands -----------------------------------------------------------------


def diff(repo: Path, prof: Profile) -> int:
    """Report targets that aren't correct links. Exit code: 0 clean, 1 diffs, 2 conflict."""
    rc = 0
    for e in classified_entries(repo, prof):
        if e.state in (State.OK, State.MISSING):
            continue
        if e.state is State.CONFLICT:
            ui.error(
                f"Conflict: '{e.source}' has uncommitted changes in the repo and "
                f"'{e.target}' on this machine also differs. Resolve before proceeding."
            )
            rc = 2
        elif e.state is State.SOURCE_MISSING:
            ui.error(f"Source missing in repo: {e.source} (wanted by {e.target})")
            rc = max(rc, 1)
        else:
            ui.warning(f"{e.state.value}: {e.target}")
            rc = max(rc, 1)
    if rc == 0:
        ui.success("All links match the repo.")
    return rc


def sync_links(repo: Path, prof: Profile, dry_run: bool = False) -> None:
    """Create/repair all links for the profile via dotbot."""
    if dry_run:
        for e in classified_entries(repo, prof):
            if e.state is State.MISSING:
                ui.info(f"would link: {e.target} -> {e.source}")
            elif e.state is State.WRONG_LINK:
                ui.info(f"would relink: {e.target} -> {e.source}")
            elif e.state in (State.EXISTS_SAME, State.EXISTS_DIFFERS, State.CONFLICT):
                ui.warning(f"would leave alone (not a symlink): {e.target}")
            elif e.state is State.SOURCE_MISSING:
                ui.error(f"source missing in repo: {e.source}")
        return
    run_dotbot(repo, prof)


def run_dotbot(repo: Path, prof: Profile) -> None:
    """Run dotbot once over the merged task list of all applicable layers.

    Targets that exist as real files/directories are excluded (with a warning)
    rather than passed to dotbot: it refuses to clobber them, which is what we
    want, but it would also report the whole run as failed."""
    skip = {
        e.target
        for e in classified_entries(repo, prof)
        if e.state in (State.EXISTS_SAME, State.EXISTS_DIFFERS, State.CONFLICT)
    }
    for target in sorted(skip):
        ui.warning(f"File/directory already exists, leaving alone: {target}")

    merged: list[dict] = []
    for layer in layer_files(repo, prof):
        for task in _load_tasks(layer):
            if "link" in task and task["link"]:
                task = dict(task)
                task["link"] = {
                    t: s
                    for t, s in task["link"].items()
                    if Path(os.path.expanduser(t)) not in skip
                }
            merged.append(task)

    with tempfile.NamedTemporaryFile(
        "w", suffix=".yaml", prefix="dotbot-merged-", delete=False
    ) as tmp:
        yaml.safe_dump(merged, tmp)
        tmp_path = tmp.name
    try:
        _dotbot_main(["-d", str(repo), "-c", tmp_path])
    finally:
        os.unlink(tmp_path)


def _dotbot_main(argv: list[str]) -> None:
    """Invoke dotbot's CLI in-process; raises RuntimeError on failure."""
    from dotbot.cli import main as dotbot_main

    old_argv = sys.argv
    sys.argv = ["dotbot", *argv]
    try:
        dotbot_main()
    except SystemExit as exc:
        if exc.code not in (0, None):
            raise RuntimeError(f"dotbot failed: {exc.code}") from exc
    finally:
        sys.argv = old_argv


def adopt(repo: Path, prof: Profile, targets: list[str] | None = None) -> int:
    """Copy differing machine files into the repo, then replace them with symlinks.

    Without explicit targets, adopts every EXISTS_SAME/EXISTS_DIFFERS file and skips
    conflicts (repo source has uncommitted changes). Explicit targets adopt regardless.
    """
    wanted: set[Path] | None = None
    if targets:
        wanted = {Path(os.path.expanduser(t)).absolute() for t in targets}

    adopted = 0
    for e in classified_entries(repo, prof):
        if wanted is not None and e.target not in wanted:
            continue
        if e.state in (State.EXISTS_SAME, State.EXISTS_DIFFERS, State.CONFLICT):
            if e.state is State.CONFLICT and wanted is None:
                ui.warning(
                    f"Skipping conflict (repo copy has uncommitted changes): {e.target}\n"
                    f"    Adopt it explicitly with: ./dot adopt '{e.target}'"
                )
                continue
            if not e.target.is_file():
                ui.warning(f"Skipping (only plain files can be adopted): {e.target}")
                continue
            e.source.parent.mkdir(parents=True, exist_ok=True)
            e.source.write_bytes(e.target.read_bytes())
            e.target.unlink()
            e.target.symlink_to(e.source)
            ui.success(f"Adopted: {e.target} -> {e.source}")
            adopted += 1
    if adopted == 0:
        ui.info("Nothing to adopt.")
    return 0


def heal(repo: Path, prof: Profile, stage_adopted: bool = True) -> list[LinkEntry]:
    """Self-heal used by the pre-commit hook. Returns unresolved conflicts.

    - correct link            -> untouched
    - not linked, same content -> fix the symlink
    - differs, repo file clean -> adopt machine version (and stage it)
    - differs, repo file dirty -> returned as a conflict
    """
    conflicts: list[LinkEntry] = []
    for e in classified_entries(repo, prof):
        if e.state is State.EXISTS_SAME and e.target.is_file():
            e.target.unlink()
            e.target.symlink_to(e.source)
            print(f"==> Fixed symlink (same contents): {e.target}")
        elif e.state is State.EXISTS_DIFFERS and e.target.is_file():
            e.source.write_bytes(e.target.read_bytes())
            e.target.unlink()
            e.target.symlink_to(e.source)
            rel = os.path.relpath(e.source, repo)
            if stage_adopted:
                subprocess.run(["git", "-C", str(repo), "add", rel], check=True)
            print(f"==> Adopted machine version and staged: {rel}")
            print(f"    (symlink fixed: {e.target})")
        elif e.state is State.CONFLICT:
            conflicts.append(e)
    return conflicts
