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
- `lint.py`
  - Python orchestrator for ShellCheck, strict mypy, meta README validation,
    branch manifest validation, and manifest validation.
- `lint.sh`
  - Self-locating Bash bootstrap for type-checking and invoking `meta/lint.py`.
- `manifest.md`
  - Positive manifest of tracked repository files outside `meta/` and its
    omission contract.
- `manifest.py`
  - Enforces the repository manifest against its embedded omission contract.
