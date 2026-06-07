# Metadata Directory

`replica/` contains one Markdown file for each path listed in
`meta/manifest.md`. Those files mirror repository paths and hold per-file
documentation notes; individual replica files are intentionally not listed here.

- `AGENTS.md`
  - Agent policy requiring clean commits, passing meta lint, and keeping this
    README current.
- `README.md`
  - Local manifest for metadata tooling and policy files.
- `branches.md`
  - Branch inventory, including local unpushed archive and WIP branches.
- `lint.py`
  - Python orchestrator for ShellCheck, strict mypy, meta README validation,
    and manifest validation.
- `lint.sh`
  - Self-locating Bash bootstrap for type-checking and invoking `meta/lint.py`.
- `manifest.md`
  - Positive manifest of tracked repository files outside `meta/` and its
    omission contract.
- `manifest.py`
  - Enforces the repository manifest against its embedded omission contract.
- `README.py`
  - Enforces this local metadata manifest against tracked `meta/` files.
- `replica/`
  - Per-file documentation subtree for paths listed in `meta/manifest.md`.
