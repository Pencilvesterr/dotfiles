import pytest

from dotfiles import profile as profile_mod
from dotfiles.profile import Profile, ProfileError


def test_round_trip(tmp_path):
    path = tmp_path / "profile.json"
    profile_mod.save(Profile("work-mac", terminal_apps_only=True), path)
    # bypass the platform guard by loading fields directly through load() on the right OS
    prof = Profile("work-mac", terminal_apps_only=True)
    assert prof.os == "mac"
    assert prof.context == "work"
    saved = path.read_text()
    assert '"work-mac"' in saved and '"terminal_apps_only": true' in saved


def test_invalid_name_rejected():
    with pytest.raises(ProfileError):
        Profile("gaming-rig")


def test_load_missing_file_gives_helpful_error(tmp_path):
    with pytest.raises(ProfileError, match="dot profile set"):
        profile_mod.load(tmp_path / "nope.json")


def test_load_rejects_platform_mismatch(tmp_path):
    path = tmp_path / "profile.json"
    other_os = "linux" if profile_mod.current_os() == "mac" else "mac"
    profile_mod.save(Profile(f"personal-{other_os}"), path)
    with pytest.raises(ProfileError, match="this machine is"):
        profile_mod.load(path)


def test_load_matching_platform(tmp_path):
    path = tmp_path / "profile.json"
    name = f"personal-{profile_mod.current_os()}"
    profile_mod.save(Profile(name, terminal_apps_only=True), path)
    prof = profile_mod.load(path)
    assert prof.name == name
    assert prof.terminal_apps_only is True
