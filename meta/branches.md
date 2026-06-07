# Branch Manifest

Snapshot date: 2026-06-07

This is a repository snapshot; branch tips and ahead counts may change after
new commits.

- `32bit`
  - Kind: local
  - Tip: current working branch tip
  - Upstream / relation: tracks `origin/32bit`
  - Status: Active development branch for this work.
  - Local unpushed: May have local commits not present on `origin/32bit`;
    check with `git log --oneline origin/32bit..32bit`.
- `main`
  - Kind: local
  - Tip: ``90d1f7f Make struct member access to work with `=` and `?:` ``
  - Upstream / relation: tracks `origin/main`
  - Status: Matches upstream.
- `archive/32bit-local-commits`
  - Kind: local archive
  - Tip: `b0ce6b7 Document incremental add-back plan`
  - Upstream / relation: no upstream
  - Status: Preserves the pre-reset local third-party runner commits and
    add-back plan doc.
  - Local unpushed: Has no upstream and is intentionally local.
- `wip/32bit-overgrown-snapshot`
  - Kind: local WIP archive
  - Tip: `6715dd4 WIP snapshot before incremental split`
  - Upstream / relation: no upstream
  - Status: Preserves the larger overgrown WIP snapshot for reference.
  - Local unpushed: Has no upstream and is intentionally local.
- `origin/32bit`
  - Kind: remote-tracking
  - Tip: ``90d1f7f Make struct member access to work with `=` and `?:` ``
  - Upstream / relation: remote branch
  - Status: Baseline for current `32bit` work.
- `origin/main`
  - Kind: remote-tracking
  - Tip: ``90d1f7f Make struct member access to work with `=` and `?:` ``
  - Upstream / relation: remote branch
  - Status: Matches local `main`.
- `origin/HEAD`
  - Kind: remote symbolic ref
  - Tip: `origin/main`
  - Upstream / relation: points to `origin/main`
  - Status: Default remote branch pointer.
