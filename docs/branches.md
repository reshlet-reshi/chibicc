# Branch Manifest

Snapshot date: 2026-06-07

This is a repository snapshot; branch tips and ahead counts may change after new commits.

| Branch | Kind | Tip | Upstream / relation | Status |
| --- | --- | --- | --- | --- |
| `32bit` | local | current working branch tip | tracks `origin/32bit` | Active development branch for this work. |
| `main` | local | ``90d1f7f Make struct member access to work with `=` and `?:` `` | tracks `origin/main` | Matches upstream. |
| `archive/32bit-local-commits` | local archive | `b0ce6b7 Document incremental add-back plan` | no upstream | Preserves the pre-reset local third-party runner commits and add-back plan doc. |
| `wip/32bit-overgrown-snapshot` | local WIP archive | `6715dd4 WIP snapshot before incremental split` | no upstream | Preserves the larger overgrown WIP snapshot for reference. |
| `origin/32bit` | remote-tracking | ``90d1f7f Make struct member access to work with `=` and `?:` `` | remote branch | Baseline for current `32bit` work. |
| `origin/main` | remote-tracking | ``90d1f7f Make struct member access to work with `=` and `?:` `` | remote branch | Matches local `main`. |
| `origin/HEAD` | remote symbolic ref | `origin/main` | points to `origin/main` | Default remote branch pointer. |

## Local Unpushed Branches

- `32bit` may have local commits not present on `origin/32bit`; check with `git log --oneline origin/32bit..32bit`.
- `archive/32bit-local-commits` has no upstream and is intentionally local.
- `wip/32bit-overgrown-snapshot` has no upstream and is intentionally local.
