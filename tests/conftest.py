import subprocess
import textwrap
from pathlib import Path

import pytest

REAL_REPO = Path(__file__).resolve().parents[1]


def git(repo: Path, *args: str) -> None:
    subprocess.run(
        ["git", "-C", str(repo), "-c", "user.email=test@test", "-c", "user.name=test", *args],
        check=True,
        capture_output=True,
    )


@pytest.fixture
def home(tmp_path, monkeypatch) -> Path:
    """An isolated $HOME so nothing ever touches the real one."""
    home = tmp_path / "home"
    home.mkdir()
    monkeypatch.setenv("HOME", str(home))
    return home


@pytest.fixture
def repo(tmp_path) -> Path:
    """A scratch dotfiles repo with two linkable files, committed."""
    repo = tmp_path / "repo"
    (repo / "install/dotbot").mkdir(parents=True)
    (repo / "zsh").mkdir()
    (repo / "zsh/aliases.zsh").write_text("alias ll='ls -l'\n")
    (repo / "zsh/custom.zsh").write_text("export FOO=bar\n")
    (repo / "install/dotbot/base.yaml").write_text(
        textwrap.dedent("""\
        - defaults:
            link:
              create: true
              relink: true
        - link:
            ~/.config/zsh/aliases.zsh: zsh/aliases.zsh
            ~/.config/zsh/custom.zsh: zsh/custom.zsh
        """)
    )
    (repo / "install/dotbot/linux.yaml").write_text("- link: {}\n")
    (repo / "install/dotbot/macos.yaml").write_text("- link: {}\n")
    (repo / "install/dotbot/work.yaml").write_text("- link:\n    ~/.gitconfig: gitconfig.work\n")
    (repo / "install/dotbot/personal.yaml").write_text(
        "- link:\n    ~/.gitconfig: gitconfig.personal\n"
    )
    (repo / "gitconfig.work").write_text("[user]\n  name = work\n")
    (repo / "gitconfig.personal").write_text("[user]\n  name = personal\n")
    (repo / "install/managed.toml").write_text(
        textwrap.dedent("""\
        [[files]]
        repo = "htoprc"
        system = "~/.config/htop/htoprc"

        [[files]]
        repo = "workfile"
        system = "~/.workfile"
        context = "work"
        os = "mac"
        """)
    )
    (repo / "htoprc").write_text("fields=0\n")
    (repo / "workfile").write_text("work\n")
    git(repo, "init")
    git(repo, "add", "-A")
    git(repo, "commit", "-m", "init")
    return repo
