import os
import subprocess

from dotfiles import linker
from dotfiles.linker import State
from dotfiles.profile import Profile

from conftest import git

PROF = Profile("personal-linux")


def state_of(repo, target_name):
    for e in linker.classified_entries(repo, PROF):
        if e.target.name == target_name:
            return e.state
    raise AssertionError(f"no entry for {target_name}")


def test_entries_later_layer_wins(repo, home):
    work = {e.target.name: e for e in linker.entries(repo, Profile("work-mac"))}
    personal = {e.target.name: e for e in linker.entries(repo, Profile("personal-mac"))}
    assert work[".gitconfig"].source.name == "gitconfig.work"
    assert personal[".gitconfig"].source.name == "gitconfig.personal"


def test_classify_missing_then_ok(repo, home):
    assert state_of(repo, "aliases.zsh") is State.MISSING
    linker.run_dotbot(repo, PROF)
    assert state_of(repo, "aliases.zsh") is State.OK
    assert os.readlink(home / ".config/zsh/aliases.zsh") == str(repo / "zsh/aliases.zsh")


def test_classify_wrong_link(repo, home):
    target = home / ".config/zsh/aliases.zsh"
    target.parent.mkdir(parents=True)
    target.symlink_to(home / "elsewhere")
    assert state_of(repo, "aliases.zsh") is State.WRONG_LINK
    linker.run_dotbot(repo, PROF)  # relink: true repairs it
    assert state_of(repo, "aliases.zsh") is State.OK


def test_classify_real_files(repo, home):
    same = home / ".config/zsh/aliases.zsh"
    differs = home / ".config/zsh/custom.zsh"
    same.parent.mkdir(parents=True)
    same.write_text((repo / "zsh/aliases.zsh").read_text())
    differs.write_text("export FOO=machine\n")
    assert state_of(repo, "aliases.zsh") is State.EXISTS_SAME
    assert state_of(repo, "custom.zsh") is State.EXISTS_DIFFERS
    # dotbot must not clobber real files (force is off)
    linker.run_dotbot(repo, PROF)
    assert not differs.is_symlink()
    assert differs.read_text() == "export FOO=machine\n"


def test_classify_conflict_when_repo_dirty(repo, home):
    target = home / ".config/zsh/custom.zsh"
    target.parent.mkdir(parents=True)
    target.write_text("export FOO=machine\n")
    (repo / "zsh/custom.zsh").write_text("export FOO=repo-edit\n")  # uncommitted repo change
    assert state_of(repo, "custom.zsh") is State.CONFLICT
    assert linker.diff(repo, PROF) == 2


def test_diff_ignores_source_in_uninitialized_submodule(repo, home):
    submodule = repo.parent / "private"
    submodule.mkdir()
    git(submodule, "init")
    (submodule / "secret").write_text("shh\n")
    git(submodule, "add", "secret")
    git(submodule, "commit", "-m", "init")
    submodule_commit = subprocess.run(
        ["git", "-C", str(submodule), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()

    (repo / "setup/dotbot/base.yaml").write_text(
        "- link:\n    ~/.config/private/secret: private/secret\n"
    )
    git(repo, "add", "setup/dotbot/base.yaml")
    git(repo, "update-index", "--add", "--cacheinfo", f"160000,{submodule_commit},private")
    git(repo, "commit", "-m", "add private submodule")

    assert not (repo / "private").exists()
    assert linker.diff(repo, PROF) == 0


def test_adopt_takes_machine_version(repo, home):
    target = home / ".config/zsh/custom.zsh"
    target.parent.mkdir(parents=True)
    target.write_text("export FOO=machine\n")
    linker.adopt(repo, PROF)
    assert target.is_symlink()
    assert (repo / "zsh/custom.zsh").read_text() == "export FOO=machine\n"


def test_adopt_skips_conflicts_unless_explicit(repo, home):
    target = home / ".config/zsh/custom.zsh"
    target.parent.mkdir(parents=True)
    target.write_text("export FOO=machine\n")
    (repo / "zsh/custom.zsh").write_text("export FOO=repo-edit\n")
    linker.adopt(repo, PROF)  # default: skip the conflict
    assert not target.is_symlink()
    linker.adopt(repo, PROF, targets=[str(target)])  # explicit: adopt it
    assert target.is_symlink()
    assert (repo / "zsh/custom.zsh").read_text() == "export FOO=machine\n"


def test_heal_fixes_same_adopts_differs_reports_conflicts(repo, home):
    zdir = home / ".config/zsh"
    zdir.mkdir(parents=True)
    (zdir / "aliases.zsh").write_text((repo / "zsh/aliases.zsh").read_text())  # same
    (zdir / "custom.zsh").write_text("export FOO=machine\n")  # differs, repo clean

    conflicts = linker.heal(repo, PROF)
    assert conflicts == []
    assert (zdir / "aliases.zsh").is_symlink()
    assert (zdir / "custom.zsh").is_symlink()
    assert (repo / "zsh/custom.zsh").read_text() == "export FOO=machine\n"
    # adopted file must be staged
    import subprocess

    staged = subprocess.run(
        ["git", "-C", str(repo), "diff", "--cached", "--name-only"],
        capture_output=True,
        text=True,
    ).stdout
    assert "zsh/custom.zsh" in staged


def test_heal_reports_conflict(repo, home):
    target = home / ".config/zsh/custom.zsh"
    target.parent.mkdir(parents=True)
    target.write_text("export FOO=machine\n")
    (repo / "zsh/custom.zsh").write_text("export FOO=repo-edit\n")
    git(repo, "add", "zsh/custom.zsh")  # staged repo change -> conflict

    conflicts = linker.heal(repo, PROF)
    assert len(conflicts) == 1
    assert conflicts[0].target == target
    assert not target.is_symlink()
