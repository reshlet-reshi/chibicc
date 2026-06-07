# Metadata Directory

`replica/` contains one Markdown file for each path listed in
`meta/manifest.md`. Those files mirror repository paths and hold per-file
documentation notes; individual replica files are intentionally not listed here.

- `replica/`
  - Per-file documentation subtree for paths listed in `meta/manifest.md`.
- `AGENTS.md`
  - Agent policy requiring clean commits, passing meta lint, and keeping this
    README current.
- `README.md`
  - Local manifest for metadata tooling and policy files.
- `README.py`
  - Enforces this local metadata manifest against Git-visible `meta/` files.
- `branches.md`
  - Branch inventory, including local unpushed archive and WIP branches.
- `branches.py`
  - Enforces branch manifest entries against local and remote Git refs.
- `lint.md`
  - Configures extra executable metadata validators for `meta/lint.py`.
- `lint.py`
  - Walks Git-visible files, dispatches extension-based lints, and runs
    configured metadata validators.
- `lint.sh`
  - Self-locating Bash bootstrap for type-checking and invoking `meta/lint.py`.
- `manifest.md`
  - Positive manifest of tracked repository files outside `meta/` and its
    omission contract.
- `manifest.py`
  - Enforces the repository manifest, omission contract, and exact replica docs.
- `mypy.ini`
  - Strict mypy configuration used by metadata lint tooling.
- `reset.sh`
  - Repo-root reset helper for discarding local tracked, untracked, and ignored
    changes after confirmation.
