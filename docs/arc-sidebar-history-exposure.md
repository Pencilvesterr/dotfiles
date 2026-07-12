# StorableSidebar.json: pre-existing public history exposure

## Status

Not yet remediated. Documented here per the decision in
[private-secrets-submodule-plan.md](private-secrets-submodule-plan.md) to stop future tracking
now and defer a history rewrite until the sensitivity is properly assessed.

## What happened

`config/arc/StorableSidebar.json` (Arc browser sidebar/sync data — tab titles, URLs, session
state) was tracked in this repo and pushed to the public GitHub remote
(`github.com/Pencilvesterr/dotfiles`, confirmed public) from before the July 2026 `config/`+
`setup/` reorg (commit `bf7abc1` carried it forward from its pre-reorg path) up through the
commit that removed it from tracking as part of moving it into the `private/` submodule.

There is no credential inside this file — nothing to rotate. The exposure is the *content itself*
(real synced browsing data), which is why it's a judgment call rather than an automatic "rotate
and move on."

## Remediating (not yet done)

If the historical exposure needs to be fully removed (not just stopped going forward):

1. Confirm every historical path the file lived at (it moved during the `config/`+`setup/`
   reorg — check with `git log --all --full-history --follow -- config/arc/StorableSidebar.json`
   and look for its pre-reorg path too).
2. Purge it from all commits:
   ```bash
   git filter-repo --path config/arc/StorableSidebar.json --path <pre-reorg-path> --invert-paths
   ```
3. Force-push the rewritten history to `origin`.
4. Anyone with an existing clone or fork must re-clone — a rewritten history can't be pulled into
   an existing local copy without conflicts.

This is destructive and disruptive (rewrites shared history, requires a force-push), so it should
only be done after deciding the file's past contents are sensitive enough to warrant it.
