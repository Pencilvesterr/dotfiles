from types import SimpleNamespace

import pytest

from dotfiles import managed
from dotfiles.profile import Profile

from conftest import git


def test_entries_filtered_by_context_and_os(repo):
    base_only = managed.entries(repo, Profile("personal-linux"))
    assert [e.repo_path.name for e in base_only] == ["htoprc"]
    work_mac = managed.entries(repo, Profile("work-mac"))
    assert [e.repo_path.name for e in work_mac] == ["htoprc", "workfile"]
    work_linux = managed.entries(repo, Profile("work-linux"))
    assert [e.repo_path.name for e in work_linux] == ["htoprc"]


def test_push_then_pull_round_trip(repo, home):
    prof = Profile("personal-linux")
    system = home / ".config/htop/htoprc"

    managed.push(repo, prof)
    assert system.read_text() == "fields=0\n"

    system.write_text("fields=1 2\n")  # app rewrote its config
    managed.pull(repo, prof)
    assert (repo / "htoprc").read_text() == "fields=1 2\n"


def test_push_replaces_dangling_destination_symlink(repo, home):
    prof = Profile("personal-linux")
    system = home / ".config/htop/htoprc"
    system.parent.mkdir(parents=True)
    system.symlink_to(home / "missing/htoprc")

    managed.push(repo, prof)

    assert not system.is_symlink()
    assert system.read_text() == "fields=0\n"


def test_dry_run_changes_nothing(repo, home):
    prof = Profile("personal-linux")
    system = home / ".config/htop/htoprc"
    managed.push(repo, prof, dry_run=True)
    assert not system.exists()


def test_diff_reports_difference(repo, home):
    prof = Profile("personal-linux")
    managed.push(repo, prof)
    assert managed.diff(repo, prof) == 0
    (home / ".config/htop/htoprc").write_text("changed\n")
    assert managed.diff(repo, prof) == 1


def test_sync_pulls_machine_change_into_repo(repo, home):
    prof = Profile("personal-linux")
    system = home / ".config/htop/htoprc"
    system.parent.mkdir(parents=True)
    system.write_text("machine version\n")

    assert managed.sync(repo, prof) == 0

    assert system.read_text() == "machine version\n"
    assert (repo / "htoprc").read_text() == "machine version\n"


def test_sync_pushes_repo_version_when_machine_file_is_missing(repo, home):
    system = home / ".config/htop/htoprc"

    assert managed.sync(repo, Profile("personal-linux")) == 0

    assert system.read_text() == "fields=0\n"


@pytest.mark.parametrize("repo_change", ["unstaged", "staged"])
def test_sync_aborts_when_both_versions_changed(repo, home, repo_change):
    prof = Profile("personal-linux")
    system = home / ".config/htop/htoprc"
    system.parent.mkdir(parents=True)
    system.write_text("machine version\n")
    repo_file = repo / "htoprc"
    repo_file.write_text("repo version\n")
    if repo_change == "staged":
        git(repo, "add", "htoprc")

    assert managed.sync(repo, prof) == 2

    assert system.read_text() == "machine version\n"
    assert repo_file.read_text() == "repo version\n"


def test_repo_dirty_detects_untracked_file(repo):
    untracked = repo / "new-managed-file"
    untracked.write_text("new\n")

    assert managed._repo_path_dirty(repo, untracked)


def test_conflict_preflight_prevents_other_managed_copies(repo, home):
    (repo / "setup/managed.toml").write_text(
        (repo / "setup/managed.toml").read_text()
        + '\n[[files]]\nrepo = "second"\nsystem = "~/.second"\n'
    )
    (repo / "second").write_text("repo second\n")
    git(repo, "add", "setup/managed.toml", "second")
    git(repo, "commit", "-m", "add second managed file")
    system = home / ".config/htop/htoprc"
    system.parent.mkdir(parents=True)
    system.write_text("machine version\n")
    (repo / "htoprc").write_text("repo version\n")

    assert managed.sync(repo, Profile("personal-linux")) == 2

    assert not (home / ".second").exists()


def test_sync_overwrite_flag_makes_repo_version_win(repo, home):
    system = home / ".config/htop/htoprc"
    system.parent.mkdir(parents=True)
    system.write_text("machine version\n")
    (repo / "htoprc").write_text("intentional repo edit\n")

    assert managed.sync(
        repo, Profile("personal-linux"), overwrite_with_repo=True
    ) == 0

    assert system.read_text() == "intentional repo edit\n"


def test_sync_dry_run_reports_pull_without_changes(repo, home):
    system = home / ".config/htop/htoprc"
    system.parent.mkdir(parents=True)
    system.write_text("machine version\n")

    assert managed.sync(repo, Profile("personal-linux"), dry_run=True) == 0

    assert system.read_text() == "machine version\n"
    assert (repo / "htoprc").read_text() == "fields=0\n"


def test_sync_parser_accepts_overwrite_from_repo_flag():
    from dotfiles.cli import build_parser

    args = build_parser().parse_args(["sync", "--overwrite-from-repo"])
    assert args.overwrite_from_repo is True


def test_sync_parser_accepts_link_overwrite_flag():
    from dotfiles.cli import build_parser

    args = build_parser().parse_args(["sync", "--overwrite"])
    assert args.overwrite is True


def test_cli_sync_conflict_stops_before_links_and_housekeeping(monkeypatch):
    from dotfiles import cli, gitrepo, linker

    calls = []
    monkeypatch.setattr(cli, "_load_profile", lambda: Profile("personal-linux"))
    monkeypatch.setattr(managed, "sync", lambda *args, **kwargs: 2)
    monkeypatch.setattr(linker, "sync_links", lambda *args, **kwargs: calls.append("links"))
    monkeypatch.setattr(gitrepo, "housekeeping", lambda *args, **kwargs: calls.append("housekeeping"))

    rc = cli.cmd_sync(
        SimpleNamespace(dry_run=False, overwrite=False, overwrite_from_repo=False)
    )

    assert rc == 2
    assert calls == []
