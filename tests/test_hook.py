import subprocess
from pathlib import Path

import pytest

from dotfiles import hook
from dotfiles.profile import Profile

from conftest import git


def git_output(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", "-C", str(repo), *args],
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def init_private_repo(repo: Path, tmp_path: Path, *, with_remote: bool = True) -> tuple[Path, Path]:
    private_repo = repo / "dotfiles-private"
    (private_repo / "arc").mkdir(parents=True)
    (private_repo / "arc/StorableSidebar.json").write_text("old sidebar\n")
    (private_repo / "notes.txt").write_text("original notes\n")
    git(private_repo, "init", "-b", "main")
    git(private_repo, "config", "user.email", "test@test")
    git(private_repo, "config", "user.name", "test")
    git(private_repo, "add", "-A")
    git(private_repo, "commit", "-m", "initial private files")

    remote = tmp_path / "private-remote.git"
    if with_remote:
        remote.mkdir()
        git(remote, "init", "--bare")
        git(private_repo, "remote", "add", "origin", str(remote))
        git(private_repo, "push", "-u", "origin", "main")
    return private_repo, remote


def write_arc_sidebar(home: Path, contents: str = "latest sidebar\n") -> Path:
    sidebar = home / "Library/Application Support/Arc/StorableSidebar.json"
    sidebar.parent.mkdir(parents=True)
    sidebar.write_text(contents)
    return sidebar


@pytest.mark.parametrize(
    "profile",
    [Profile("personal-mac"), Profile("work-linux"), Profile("personal-linux")],
)
def test_private_arc_sync_only_runs_for_work_mac(repo, home, profile, capsys):
    write_arc_sidebar(home)

    hook.sync_private_arc(repo, profile)

    assert not (repo / "dotfiles-private").exists()
    assert capsys.readouterr().out == ""


def test_private_arc_sync_commits_only_sidebar_and_pushes(repo, home, tmp_path):
    private_repo, remote = init_private_repo(repo, tmp_path)
    source = write_arc_sidebar(home)
    (private_repo / "notes.txt").write_text("staged private notes\n")
    git(private_repo, "add", "notes.txt")
    (private_repo / "untracked.txt").write_text("leave me alone\n")

    hook.sync_private_arc(repo, Profile("work-mac"))

    assert (private_repo / "arc/StorableSidebar.json").read_bytes() == source.read_bytes()
    assert git_output(private_repo, "log", "-1", "--pretty=%s").strip() == (
        "Update latest Arc sidebar"
    )
    assert git_output(private_repo, "show", "--pretty=", "--name-only", "HEAD").splitlines() == [
        "arc/StorableSidebar.json"
    ]
    assert git_output(private_repo, "status", "--short").splitlines() == [
        "M  notes.txt",
        "?? untracked.txt",
    ]
    remote_sidebar = subprocess.run(
        ["git", "--git-dir", str(remote), "show", "main:arc/StorableSidebar.json"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    assert remote_sidebar == "latest sidebar\n"


def test_private_arc_sync_does_nothing_when_sidebar_is_unchanged(repo, home, tmp_path):
    private_repo, _ = init_private_repo(repo, tmp_path)
    write_arc_sidebar(home, "old sidebar\n")
    before = git_output(private_repo, "rev-parse", "HEAD")

    hook.sync_private_arc(repo, Profile("work-mac"))

    assert git_output(private_repo, "rev-parse", "HEAD") == before


@pytest.mark.parametrize("missing", ["source", "private_repo"])
def test_private_arc_sync_warns_when_required_path_is_missing(
    repo, home, tmp_path, missing, capsys
):
    if missing == "source":
        init_private_repo(repo, tmp_path)
    else:
        write_arc_sidebar(home)

    hook.sync_private_arc(repo, Profile("work-mac"))

    assert "Private Arc sync skipped" in capsys.readouterr().out


def test_private_arc_push_failure_warns_without_raising(repo, home, tmp_path, capsys):
    private_repo, _ = init_private_repo(repo, tmp_path, with_remote=False)
    write_arc_sidebar(home)

    hook.sync_private_arc(repo, Profile("work-mac"))

    assert git_output(private_repo, "log", "-1", "--pretty=%s").strip() == (
        "Update latest Arc sidebar"
    )
    assert "created but could not be pushed" in capsys.readouterr().out
