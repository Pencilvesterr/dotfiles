# Repository Guidelines

## Project Structure & Module Organization

User configuration lives under `config/` (for example, `config/nvim/` and `config/zsh/`). Provisioning code lives in `setup/`: the Python CLI is in `setup/dotfiles/`, link definitions in `setup/dotbot/`, platform scripts in `setup/mac/` and `setup/linux/`, and package lists in `setup/homebrew/`. Tests are under `tests/`; documentation and screenshots belong in `docs/` and `img/`. The top-level `dot` shim invokes the Python package through `uv`.

## Build, Test, and Development Commands

- `uv sync --locked`: install the exact development dependencies from `uv.lock`.
- `uv run pytest`: run the Python test suite.
- `uv run ruff check`: lint Python code (Python 3.11, 100-character lines).
- `./tests/docker-smoke.sh`: exercise the Linux installation flow in Docker.
- `./tests/docker-smoke-full.sh`: run the slower, full Linux provisioning smoke test.
- `./dot sync --dry-run`: preview link and managed-file synchronization safely.
- `./dot diff`: report machine targets that differ from repository sources.

Never test `./dot` against your real home directory. Follow the pytest fixtures and smoke scripts, which isolate operations with a temporary `HOME`.

## Coding Style & Naming Conventions

Use four spaces for Python and keep modules and functions in `snake_case`. Ruff is the source of truth for Python linting. Shell scripts should quote expansions and pass ShellCheck at warning severity. Preserve each file's existing YAML and TOML conventions. Put new configuration in the matching application directory and register links in the appropriate base, OS, or context Dotbot layer.

## Testing Guidelines

Pytest discovers `tests/test_*.py`; name tests `test_<behavior>`. Add focused unit tests for CLI, profile, linker, config, or managed-file behavior. Run `uv run pytest` and `uv run ruff check` before submitting. Changes to shell or platform setup should also run the relevant smoke script. No numeric coverage threshold is enforced; cover new branches and failure modes.

## Commit & Pull Request Guidelines

Recent commits use short, imperative subjects such as `Quote workspace names...` and `Setup a full smoke test on linux`. Keep each commit focused and explain non-obvious behavior in the body. Pull requests should describe the affected profile or platform, list validation performed, link relevant issues or plans, and include screenshots only for visible UI/configuration changes. Ensure all applicable CI checks pass.

## Security & Configuration Tips

Do not commit tokens, machine-local values, or private Arc data. Sensitive files belong in the private submodule or documented local-only locations. Avoid changing skip-worktree files such as `config/zsh/local.zsh` unintentionally.
