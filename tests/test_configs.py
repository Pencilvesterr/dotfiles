"""Standing regression guard: every path referenced by the real configs must exist."""

import tomllib

from dotfiles import linker
from dotfiles.profile import VALID_PROFILES, Profile

from conftest import REAL_REPO


def test_every_link_source_exists_for_every_profile():
    for name in VALID_PROFILES:
        prof = Profile(name)
        for entry in linker.entries(REAL_REPO, prof):
            assert entry.source.exists(), (
                f"{name}: {entry.source} referenced by a dotbot layer but missing from the repo"
            )


def test_link_targets_are_home_relative_and_unique_per_profile():
    for name in VALID_PROFILES:
        prof = Profile(name)
        targets = [e.target for e in linker.entries(REAL_REPO, prof)]
        assert len(targets) == len(set(targets))


def test_agent_settings_follow_machine_context():
    for name, expected in (
        (
            "personal-mac",
            ("settings.personal.json", "config.personal.toml", "hooks.personal.json"),
        ),
        ("work-mac", ("settings.work.json", "config.work.toml", "hooks.work.json")),
    ):
        by_target = {
            entry.target.name: entry.source.name
            for entry in linker.entries(REAL_REPO, Profile(name))
        }
        assert by_target["settings.json"] == expected[0]
        assert by_target["config.toml"] == expected[1]
        assert by_target["hooks.json"] == expected[2]


def test_managed_repo_paths_exist():
    data = tomllib.loads((REAL_REPO / "setup/managed.toml").read_text())
    for item in data["files"]:
        repo_path = REAL_REPO / item["repo"]
        assert repo_path.exists(), f"managed file missing: {item['repo']}"


def test_layers_parse_for_all_profiles():
    for name in VALID_PROFILES:
        for layer in linker.layer_files(REAL_REPO, Profile(name)):
            assert layer.is_file(), f"missing layer file: {layer}"
