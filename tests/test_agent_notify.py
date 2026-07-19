import os
import subprocess
from pathlib import Path

import pytest


REPO = Path(__file__).parents[1]
NOTIFY = REPO / "config/agent-notify/notify.sh"
DISPLAY = REPO / "config/agent-notify/ntfy-display.sh"


def fake_command(bin_dir: Path, name: str, body: str) -> None:
    command = bin_dir / name
    command.write_text(f"#!/bin/bash\n{body}\n")
    command.chmod(0o755)


def run_script(script: Path, *args: str, env: dict[str, str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(script), *args],
        capture_output=True,
        env=env,
        text=True,
        check=False,
    )


def test_macos_notifications_identify_agent_and_event(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    trace = tmp_path / "osascript.args"
    fake_command(bin_dir, "uname", 'echo Darwin')
    fake_command(bin_dir, "osascript", 'printf "%s\\n" "$@" > "$TRACE"')
    env = {
        "HOME": str(tmp_path),
        "PATH": f"{bin_dir}:{os.environ['PATH']}",
        "TERM_PROGRAM": "WezTerm",
        "TRACE": str(trace),
    }

    result = run_script(NOTIFY, "claude", "complete", env=env)
    assert result.returncode == 0
    args = trace.read_text()
    assert "Done in WezTerm — ready for your next message" in args
    assert "Claude Code" in args

    result = run_script(NOTIFY, "codex", "approval", env=env)
    assert result.returncode == 0
    args = trace.read_text()
    assert "Codex needs your approval to continue." in args
    assert "Codex" in args

    result = run_script(NOTIFY, "codex", "complete", env=env)
    assert result.returncode == 0
    assert "Codex has finished a turn and is ready for your input." in trace.read_text()


@pytest.mark.parametrize(
    ("agent", "event", "title", "message"),
    [
        ("claude", "complete", "Claude Code", "Claude Code finished on buildbox"),
        ("codex", "complete", "Codex", "Codex finished on buildbox"),
        ("codex", "approval", "Codex", "Codex on buildbox needs your approval"),
    ],
)
def test_remote_notifications_publish_through_ntfy(
    tmp_path, agent, event, title, message
):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    trace = tmp_path / "curl.args"
    env_file = tmp_path / ".env"
    env_file.write_text(
        "NTFY_SERVER=ntfy.example.com\nNTFY_TOPIC=agents\nNTFY_TOKEN=secret-token\n"
    )
    fake_command(bin_dir, "uname", 'echo Linux')
    fake_command(bin_dir, "hostname", 'echo buildbox')
    fake_command(bin_dir, "curl", 'printf "%s\\n" "$@" > "$TRACE"')
    env = {
        "AGENT_NOTIFY_ENV_FILE": str(env_file),
        "HOME": str(tmp_path),
        "PATH": f"{bin_dir}:{os.environ['PATH']}",
        "TRACE": str(trace),
    }

    result = run_script(NOTIFY, agent, event, env=env)

    assert result.returncode == 0
    args = trace.read_text()
    assert "Authorization: Bearer secret-token" in args
    assert f"X-Title: {title}" in args
    assert message in args
    assert "https://ntfy.example.com/agents" in args


def test_remote_notification_requires_ntfy_credentials(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    fake_command(bin_dir, "uname", 'echo Linux')
    env = {"HOME": str(tmp_path), "PATH": f"{bin_dir}:{os.environ['PATH']}"}

    result = run_script(NOTIFY, "codex", "complete", env=env)

    assert result.returncode == 1
    assert "NTFY_SERVER, NTFY_TOPIC must be set" in result.stderr


@pytest.mark.parametrize("args", [("unknown", "complete"), ("claude", "approval")])
def test_notification_rejects_unsupported_agent_or_event(tmp_path, args):
    result = run_script(
        NOTIFY,
        *args,
        env={"HOME": str(tmp_path), "PATH": os.environ["PATH"]},
    )

    assert result.returncode == 2


def test_remote_display_uses_ntfy_title_and_message(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    trace = tmp_path / "osascript.args"
    fake_command(bin_dir, "osascript", 'printf "%s\\n" "$@" > "$TRACE"')
    env = {
        "NTFY_MESSAGE": "Codex finished on buildbox",
        "NTFY_TITLE": "Codex",
        "PATH": f"{bin_dir}:{os.environ['PATH']}",
        "TRACE": str(trace),
    }

    result = run_script(DISPLAY, env=env)

    assert result.returncode == 0
    args = trace.read_text()
    assert "Codex finished on buildbox" in args
    assert "Codex (remote)" in args
