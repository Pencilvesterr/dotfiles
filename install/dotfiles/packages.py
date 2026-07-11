"""Package installation: Homebrew bundles per profile, plus non-brew tools."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from dotfiles import ui
from dotfiles.profile import Profile

BREW_LOCATIONS = (
    "/opt/homebrew/bin/brew",  # Apple Silicon
    "/usr/local/bin/brew",  # Intel mac
    "/home/linuxbrew/.linuxbrew/bin/brew",
)


def find_brew() -> str:
    brew = shutil.which("brew")
    if brew:
        return brew
    for candidate in BREW_LOCATIONS:
        if Path(candidate).is_file():
            return candidate
    raise RuntimeError("Homebrew not found. On a new machine, run ./bootstrap.sh first.")


def brewfiles_for(repo: Path, prof: Profile) -> list[Path]:
    brewfiles = [repo / "homebrew/Brewfile.terminal"]
    if prof.is_mac and not prof.minimal:
        brewfiles.append(repo / "homebrew/Brewfile.mac")
        suffix = "mac_work" if prof.is_work else "mac_personal"
        brewfiles.append(repo / f"homebrew/Brewfile.{suffix}")
    return brewfiles


def install_brewfile(brew: str, brewfile: Path) -> None:
    if not brewfile.is_file():
        raise RuntimeError(f"Brewfile not found: {brewfile}")
    ui.info(f"Checking {brewfile.name} dependencies...")
    check = subprocess.run(
        [brew, "bundle", "check", f"--file={brewfile}"], capture_output=True, text=True
    )
    if check.returncode == 0:
        ui.warning(f"{brewfile.name}: dependencies already satisfied.")
        return
    ui.info("Satisfying missing dependencies with 'brew bundle install'...")
    subprocess.run([brew, "bundle", "install", f"--file={brewfile}"], check=True)
    ui.info(f"Finished installing {brewfile.name}.")


def install_claude_cli() -> None:
    if shutil.which("claude"):
        ui.warning("Claude CLI already installed")
        return
    ui.info("Installing Claude CLI...")
    subprocess.run(
        ["bash", "-c", "curl -fsSL https://claude.ai/install.sh | bash"], check=True
    )


def install_apps(repo: Path, prof: Profile) -> None:
    ui.heading("Installing Apps")
    brew = find_brew()
    for brewfile in brewfiles_for(repo, prof):
        install_brewfile(brew, brewfile)
    install_claude_cli()

    if not prof.is_mac:
        from dotfiles import platform_setup

        ui.heading("Installing Linux-specific non-brew CLI tools")
        platform_setup.install_linux_cli_tools(repo)
        if not prof.minimal:
            ui.heading("Installing Linux-specific Apps")
            platform_setup.install_linux_apps(repo)
