"""Full machine provisioning: `dot install`. The frequent, lightweight path is
`dot sync` — install is for new machines or re-provisioning."""

from __future__ import annotations

import argparse
import subprocess
import sys
import threading
from pathlib import Path

from dotfiles import gitrepo, linker, managed, packages, platform_setup
from dotfiles import profile as profile_mod
from dotfiles import ui
from dotfiles.linker import State
from dotfiles.profile import Profile, ProfileError

SUDO_KEEPALIVE_INTERVAL = 60


def _ensure_sudo() -> threading.Event | None:
    """Prompt for the sudo password once, upfront, instead of letting it surface
    unpredictably mid-run (Homebrew casks like docker-desktop, and the Linux
    platform scripts, both shell out to sudo). Keeps the credential cache alive
    in the background for the rest of install so those later calls never block
    on a terminal that isn't there."""
    if not sys.stdin.isatty():
        return None
    ui.info("Some steps need sudo (Homebrew casks, Linux platform scripts) — requesting it upfront.")
    subprocess.run(["sudo", "-v"], check=True)
    stop = threading.Event()

    def keepalive() -> None:
        while not stop.wait(SUDO_KEEPALIVE_INTERVAL):
            subprocess.run(
                ["sudo", "-n", "-v"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )

    threading.Thread(target=keepalive, daemon=True).start()
    return stop


def run_install(repo: Path, args: argparse.Namespace) -> int:
    prof = _resolve_profile(args)
    ui.info(f"Installing dotfiles for profile '{prof.name}' (terminal_apps_only={prof.terminal_apps_only})...")

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

    sudo_stop = _ensure_sudo()
    try:
        if not args.skip_brew_install:
            packages.install_apps(repo, prof)

        if not prof.terminal_apps_only:
            platform_setup.apply_defaults(repo, prof)
    finally:
        if sudo_stop:
            sudo_stop.set()

    ui.heading("Symbolic Links")
    if mode == "overwrite" and diffs:
        linker.backup_and_remove(diffs)
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
        prof = Profile(args.profile, terminal_apps_only=args.terminal_apps_only)
        profile_mod.save(prof)
        return prof
    try:
        prof = profile_mod.load()
    except ProfileError:
        if not sys.stdin.isatty():
            raise
        prof = _prompt_profile(terminal_apps_only=args.terminal_apps_only)
        profile_mod.save(prof)
        return prof
    if args.terminal_apps_only and not prof.terminal_apps_only:
        prof = Profile(prof.name, terminal_apps_only=True)
        profile_mod.save(prof)
    return prof


def _prompt_profile(terminal_apps_only: bool) -> Profile:
    print("Which machine is this?")
    choices = [p for p in profile_mod.VALID_PROFILES if p.endswith(profile_mod.current_os())]
    for i, name in enumerate(choices, 1):
        print(f"  {i}) {name}")
    while True:
        answer = input(f"Enter 1-{len(choices)}: ").strip()
        if answer.isdigit() and 1 <= int(answer) <= len(choices):
            return Profile(choices[int(answer) - 1], terminal_apps_only=terminal_apps_only)


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


def _report_plan(repo: Path, prof: Profile, args: argparse.Namespace, mode: str, diffs: list) -> None:
    ui.heading("Dry run — planned actions")
    if not args.skip_brew_install:
        for brewfile in packages.brewfiles_for(repo, prof):
            ui.info(f"would install: {brewfile.name}")
        if not prof.is_mac:
            ui.info("would install: linux CLI tools" + ("" if prof.terminal_apps_only else " + apps"))
    if not prof.terminal_apps_only:
        ui.info("would apply OS defaults")
    if diffs:
        ui.info(f"would {mode} {len(diffs)} existing file(s)")
    linker.sync_links(repo, prof, dry_run=True)
    ui.info("would run git housekeeping (hooks path, skip-worktree, filter)")
    managed.pull(repo, prof, dry_run=True)
    managed.push(repo, prof, dry_run=True)
