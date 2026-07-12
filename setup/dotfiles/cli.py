"""Argparse CLI: ./dot <subcommand>. Subcommand implementations live in the sibling modules."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from dotfiles import profile as profile_mod
from dotfiles import ui
from dotfiles.profile import Profile, ProfileError

REPO_ROOT = Path(__file__).resolve().parents[2]


class DotfilesError(Exception):
    """Raised for expected failures that should print cleanly instead of a traceback."""


def _load_profile() -> Profile:
    return profile_mod.load()


# --- subcommands -------------------------------------------------------------


def cmd_install(args: argparse.Namespace) -> int:
    from dotfiles.install_flow import run_install

    return run_install(REPO_ROOT, args)


def cmd_sync(args: argparse.Namespace) -> int:
    from dotfiles import gitrepo, linker, managed

    prof = _load_profile()
    gitrepo.ensure_submodules(REPO_ROOT)
    linker.sync_links(REPO_ROOT, prof, dry_run=args.dry_run)
    managed.push(REPO_ROOT, prof, dry_run=args.dry_run)
    if not args.dry_run:
        gitrepo.housekeeping(REPO_ROOT, prof)
    ui.success("Sync complete.")
    return 0


def cmd_diff(args: argparse.Namespace) -> int:
    from dotfiles import linker, managed

    prof = _load_profile()
    link_rc = linker.diff(REPO_ROOT, prof)
    managed_rc = managed.diff(REPO_ROOT, prof)
    return max(link_rc, managed_rc)


def cmd_adopt(args: argparse.Namespace) -> int:
    from dotfiles import linker

    prof = _load_profile()
    return linker.adopt(REPO_ROOT, prof, targets=args.targets or None)


def cmd_pull(args: argparse.Namespace) -> int:
    from dotfiles import managed

    prof = _load_profile()
    managed.pull(REPO_ROOT, prof, dry_run=args.dry_run)
    return 0


def cmd_profile(args: argparse.Namespace) -> int:
    if args.profile_action == "set":
        prof = Profile(name=args.name, terminal_apps_only=args.terminal_apps_only)
        profile_mod.save(prof)
        ui.success(f"Profile saved: {prof.name} (terminal_apps_only={prof.terminal_apps_only})")
        return 0
    # show (default)
    prof = _load_profile()
    print(f"profile: {prof.name}")
    print(f"os:      {prof.os}")
    print(f"context: {prof.context}")
    print(f"terminal_apps_only: {prof.terminal_apps_only}")
    print(f"file:    {profile_mod.PROFILE_FILE}")
    return 0


def cmd_apps(args: argparse.Namespace) -> int:
    from dotfiles import packages

    prof = _load_profile()
    packages.install_apps(REPO_ROOT, prof)
    return 0


def cmd_defaults(args: argparse.Namespace) -> int:
    from dotfiles import platform_setup

    prof = _load_profile()
    platform_setup.apply_defaults(REPO_ROOT, prof)
    return 0


def cmd_hook(args: argparse.Namespace) -> int:
    from dotfiles import hook

    try:
        prof = _load_profile()
    except ProfileError as exc:
        # Never block commits on a machine that hasn't been set up yet.
        ui.warning(f"Skipping dotfiles pre-commit checks: {exc}")
        return 0
    if args.hook_name == "pre-commit":
        return hook.pre_commit(REPO_ROOT, prof)
    raise DotfilesError(f"Unknown hook: {args.hook_name}")


# --- parser ------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="dot", description="Install and sync these dotfiles on this machine."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("install", help="Full machine provisioning (apps, defaults, links)")
    p.add_argument("--profile", choices=profile_mod.VALID_PROFILES, help="Machine profile")
    p.add_argument("--terminal-apps-only", action="store_true", help="Server/minimal machine: skip GUI apps and OS defaults")
    group = p.add_mutually_exclusive_group()
    group.add_argument("--adopt", action="store_true", help="Adopt differing machine files into the repo (no prompt)")
    group.add_argument("--overwrite", action="store_true", help="Replace differing machine files with repo versions, backing them up (no prompt)")
    p.add_argument("--skip-brew-install", action="store_true", help="Skip package installation")
    p.add_argument("--dry-run", action="store_true", help="Show what would happen without doing it")
    p.set_defaults(func=cmd_install)

    p = sub.add_parser("sync", help="Fast non-interactive sync: links + managed files + git housekeeping")
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=cmd_sync)

    p = sub.add_parser("diff", help="Show link/managed-file targets that differ from the repo (exit 2 on conflict)")
    p.set_defaults(func=cmd_diff)

    p = sub.add_parser("adopt", help="Copy differing machine files into the repo and relink")
    p.add_argument("targets", nargs="*", help="Specific target paths (default: all that differ)")
    p.set_defaults(func=cmd_adopt)

    p = sub.add_parser("pull", help="Copy managed (app-owned) files from the system into the repo")
    p.add_argument("--dry-run", action="store_true")
    p.set_defaults(func=cmd_pull)

    p = sub.add_parser("profile", help="Show or set this machine's profile")
    psub = p.add_subparsers(dest="profile_action")
    pshow = psub.add_parser("show", help="Show the saved profile")
    pshow.set_defaults(func=cmd_profile, profile_action="show")
    pset = psub.add_parser("set", help="Save this machine's profile")
    pset.add_argument("name", choices=profile_mod.VALID_PROFILES)
    pset.add_argument("--terminal-apps-only", action=argparse.BooleanOptionalAction, default=False)
    pset.set_defaults(func=cmd_profile, profile_action="set")
    p.set_defaults(func=cmd_profile, profile_action="show")

    p = sub.add_parser("apps", help="Install packages (brew bundles + non-brew tools) for this profile")
    p.set_defaults(func=cmd_apps)

    p = sub.add_parser("defaults", help="Apply OS defaults (macOS defaults / Linux settings)")
    p.set_defaults(func=cmd_defaults)

    p = sub.add_parser("hook", help="Internal: git hook entry points")
    p.add_argument("hook_name", choices=["pre-commit"])
    p.set_defaults(func=cmd_hook)

    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return args.func(args)
    except (ProfileError, DotfilesError) as exc:
        ui.error(str(exc))
        return 1
    except KeyboardInterrupt:
        print(file=sys.stderr)
        return 130
