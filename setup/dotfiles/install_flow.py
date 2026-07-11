"""Full machine provisioning: `dot install`. The frequent, lightweight path is
`dot sync` — install is for new machines or re-provisioning."""

from __future__ import annotations

import argparse
import shutil
import sys
import time
from pathlib import Path

from dotfiles import gitrepo, linker, managed, packages, platform_setup
from dotfiles import profile as profile_mod
from dotfiles import ui
from dotfiles.linker import State
from dotfiles.profile import Profile, ProfileError

BACKUP_ROOT = Path("~/.config/dotfiles/backup").expanduser()


def run_install(repo: Path, args: argparse.Namespace) -> int:
    prof = _resolve_profile(args)
    ui.info(f"Installing dotfiles for profile '{prof.name}' (minimal={prof.minimal})...")

    ui.heading("Checking existing dotfiles")
    states = linker.classified_entries(repo, prof)
    conflicts = [e for e in states if e.state is State.CONFLICT]
    diffs = [e for e in states if e.state in (State.EXISTS_SAME, State.EXISTS_DIFFERS)]

    for e in conflicts:
        ui.error(
            f"Conflict: '{e.source}' has uncommitted changes in the repo and "
            f"'{e.target}' on this machine also differs. Resolve before proceeding."
        )
    if conflicts:
        return 2

    mode = _resolve_mode(args, diffs)
    if mode is None:
        return 1

    if args.dry_run:
        _report_plan(repo, prof, args, mode, diffs)
        return 0

    if not args.skip_apps:
        packages.install_apps(repo, prof)

    if not prof.minimal:
        platform_setup.apply_defaults(repo, prof)

    ui.heading("Symbolic Links")
    if mode == "overwrite" and diffs:
        _backup_and_remove(diffs)
    elif diffs:
        ui.info("Adopting existing files into the repo...")
        linker.adopt(repo, prof)
    linker.run_dotbot(repo, prof)

    ui.heading("Git Repo Housekeeping")
    ui.info("Registering hooks path, skip-worktree flags and work-tooling filter...")
    gitrepo.housekeeping(repo, prof)

    ui.heading("Managed Files")
    if mode != "overwrite":
        ui.info("Adopting existing managed files into repo...")
        managed.pull(repo, prof)
    managed.push(repo, prof)

    ui.success("Dotfiles set up successfully.")
    return 0


def _resolve_profile(args: argparse.Namespace) -> Profile:
    if args.profile:
        prof = Profile(args.profile, minimal=args.minimal)
        profile_mod.save(prof)
        return prof
    try:
        prof = profile_mod.load()
    except ProfileError:
        if not sys.stdin.isatty():
            raise
        prof = _prompt_profile(minimal=args.minimal)
        profile_mod.save(prof)
        return prof
    if args.minimal and not prof.minimal:
        prof = Profile(prof.name, minimal=True)
        profile_mod.save(prof)
    return prof


def _prompt_profile(minimal: bool) -> Profile:
    print("Which machine is this?")
    choices = [p for p in profile_mod.VALID_PROFILES if p.endswith(profile_mod.current_os())]
    for i, name in enumerate(choices, 1):
        print(f"  {i}) {name}")
    while True:
        answer = input(f"Enter 1-{len(choices)}: ").strip()
        if answer.isdigit() and 1 <= int(answer) <= len(choices):
            return Profile(choices[int(answer) - 1], minimal=minimal)


def _resolve_mode(args: argparse.Namespace, diffs: list) -> str | None:
    """How to handle existing real files at link targets: 'adopt' or 'overwrite'."""
    if args.adopt or not diffs:
        return "adopt"
    if args.overwrite:
        return "overwrite"
    for e in diffs:
        ui.warning(f"{e.state.value}: {e.target}")
    if args.dry_run:
        return "adopt"
    if not sys.stdin.isatty():
        ui.error(
            "Existing files differ from the repo. Re-run with --adopt (keep machine "
            "versions) or --overwrite (keep repo versions, back up machine files)."
        )
        return None
    while True:
        answer = input(
            "Existing files found. [a]dopt them into the repo, [o]verwrite them "
            "(backed up first), or a[b]ort? "
        ).strip().lower()
        if answer in ("a", "adopt"):
            return "adopt"
        if answer in ("o", "overwrite"):
            return "overwrite"
        if answer in ("b", "abort", "q"):
            return None


def _backup_and_remove(diffs: list) -> None:
    backup_dir = BACKUP_ROOT / time.strftime("%Y%m%d-%H%M%S")
    for e in diffs:
        dest = backup_dir / str(e.target).lstrip("/")
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(e.target), str(dest))
        ui.warning(f"Backed up and removed: {e.target} -> {dest}")
    ui.info(f"Backups saved under {backup_dir}")


def _report_plan(repo: Path, prof: Profile, args: argparse.Namespace, mode: str, diffs: list) -> None:
    ui.heading("Dry run — planned actions")
    if not args.skip_apps:
        for brewfile in packages.brewfiles_for(repo, prof):
            ui.info(f"would install: {brewfile.name}")
        if not prof.is_mac:
            ui.info("would install: linux CLI tools" + ("" if prof.minimal else " + apps"))
    if not prof.minimal:
        ui.info("would apply OS defaults")
    if diffs:
        ui.info(f"would {mode} {len(diffs)} existing file(s)")
    linker.sync_links(repo, prof, dry_run=True)
    ui.info("would run git housekeeping (hooks path, skip-worktree, filter)")
    managed.pull(repo, prof, dry_run=True)
    managed.push(repo, prof, dry_run=True)
