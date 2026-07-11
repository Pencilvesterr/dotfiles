"""Machine profile: which of the four machine types this is, persisted locally."""

from __future__ import annotations

import json
import platform
from dataclasses import dataclass
from pathlib import Path

PROFILE_FILE = Path("~/.config/dotfiles/profile.json").expanduser()
VALID_PROFILES = ("personal-mac", "work-mac", "personal-linux", "work-linux")


class ProfileError(Exception):
    pass


@dataclass(frozen=True)
class Profile:
    name: str
    minimal: bool = False

    def __post_init__(self) -> None:
        if self.name not in VALID_PROFILES:
            raise ProfileError(
                f"Invalid profile '{self.name}'. Valid profiles: {', '.join(VALID_PROFILES)}"
            )

    @property
    def os(self) -> str:
        """'mac' or 'linux'"""
        return self.name.rsplit("-", 1)[1]

    @property
    def context(self) -> str:
        """'work' or 'personal'"""
        return self.name.split("-", 1)[0]

    @property
    def is_work(self) -> bool:
        return self.context == "work"

    @property
    def is_mac(self) -> bool:
        return self.os == "mac"


def current_os() -> str:
    return "mac" if platform.system() == "Darwin" else "linux"


def load(path: Path = PROFILE_FILE) -> Profile:
    """Load the saved profile, erroring helpfully if missing or mismatched with the platform."""
    if not path.exists():
        raise ProfileError(
            f"No machine profile found at {path}.\n"
            "Set one with: ./dot profile set <"
            + "|".join(VALID_PROFILES)
            + "> or run ./dot install --profile <name>"
        )
    try:
        data = json.loads(path.read_text())
        prof = Profile(name=data["profile"], minimal=bool(data.get("minimal", False)))
    except (json.JSONDecodeError, KeyError, TypeError) as exc:
        raise ProfileError(f"Could not parse profile file {path}: {exc}") from exc

    if prof.os != current_os():
        raise ProfileError(
            f"Saved profile '{prof.name}' is for {prof.os}, but this machine is "
            f"{current_os()}. Fix it with: ./dot profile set <name>"
        )
    return prof


def save(prof: Profile, path: Path = PROFILE_FILE) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"profile": prof.name, "minimal": prof.minimal}, indent=2) + "\n")
