"""OS-specific setup, delegated to the platform bash scripts (pure sequences of
`defaults write` / apt calls that gain nothing from a Python port)."""

from __future__ import annotations

import subprocess
from pathlib import Path

from dotfiles import ui
from dotfiles.profile import Profile


def _run_script(repo: Path, script: str, *args: str) -> None:
    subprocess.run(["bash", str(repo / script), *args], check=True)


def apply_defaults(repo: Path, prof: Profile) -> None:
    if prof.is_mac:
        ui.heading("OSX System Defaults")
        _run_script(repo, "mac_config/osx-defaults.sh", "all")
    else:
        ui.heading("Linux Settings")
        _run_script(repo, "linux/install_debian.sh", "settings")


def install_linux_cli_tools(repo: Path) -> None:
    _run_script(repo, "linux/install_debian.sh", "cli-tools")


def install_linux_apps(repo: Path) -> None:
    _run_script(repo, "linux/install_debian.sh", "apps")
