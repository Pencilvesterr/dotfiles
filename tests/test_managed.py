from dotfiles import managed
from dotfiles.profile import Profile


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
