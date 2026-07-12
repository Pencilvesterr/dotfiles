# Wire tests/ into CI (own workflow) + fast tests into pre-commit

## Context

`tests/` has 4 pytest files (test_configs.py, test_linker.py, test_profile.py,
test_managed.py) plus two Docker smoke scripts. Investigation found:

- The pytest suite already ran in CI, but bundled inside `.github/workflows/lint.yml`'s
  `python` job alongside `ruff check` — it wasn't its own workflow.
- `docker-smoke-full.sh` already has its own dedicated workflow (`linux-smoke-full.yml`).
- `docker-smoke.sh` is intentionally manual-only (comment: "Not run in CI") — superseded by
  `macos-smoke.yml` for real macOS coverage; left alone.
- The pytest suite is fast (~1.5s locally for 22 tests), so it's a good fit for pre-commit,
  but pre-commit previously only did link self-healing/managed-file pulls — it never ran the
  test suite.

Morgan confirmed: split pytest out of `lint.yml` into its own dedicated workflow, and add the
fast pytest run to the pre-commit hook.

## Changes

1. New `.github/workflows/tests.yml` — dedicated workflow running `uv run pytest` on
   push (main) and PR.
2. Trim `.github/workflows/lint.yml` — keep `ruff check` in the `python` job, drop the
   `Pytest` step (moved to `tests.yml`).
3. `config/git/hooks/pre-commit` — run `uv run pytest -q` before the existing
   `./dot hook pre-commit` self-heal step, gated on the same `uv`-availability check the
   script already used (never block commits on machines without uv).

## Status

- [x] Plan written
- [ ] tests.yml added
- [ ] lint.yml trimmed
- [ ] pre-commit hook updated
- [ ] Verified: pytest passes standalone, shellcheck passes on the hook, scratch-clone commit test
