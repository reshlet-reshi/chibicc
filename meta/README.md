# Metadata Directory

| File | Status | Notes |
| --- | --- | --- |
| `AGENTS.md` | Reviewed | Agent policy requiring clean commits, passing meta lint, and keeping this README current. |
| `README.md` | Reviewed | Local manifest for metadata tooling and policy files. |
| `branches.md` | Reviewed | Branch inventory, including local unpushed archive and WIP branches. |
| `lint.py` | Reviewed | Python orchestrator for ShellCheck, strict mypy, and manifest validation. |
| `lint.sh` | Reviewed | Self-locating Bash bootstrap for type-checking and invoking `meta/lint.py`. |
| `manifest.ignore.md` | Reviewed | Defines the omission contract for files intentionally left out of the repository manifest. |
| `manifest.md` | Reviewed | Positive manifest of tracked repository files outside `meta/`. |
| `manifest.py` | Reviewed | Enforces the repository manifest against the manifest ignore contract. |
