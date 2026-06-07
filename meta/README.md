# Metadata Directory

| File | Status | Notes |
| --- | --- | --- |
| `AGENTS.md` | Reviewed | Agent policy requiring clean commits, passing meta lint, and keeping this README current. |
| `README.md` | Reviewed | Local manifest for metadata tooling and policy files. |
| `branches.md` | Reviewed | Branch inventory, including local unpushed archive and WIP branches. |
| `lint.py` | Reviewed | Python orchestrator for ShellCheck, strict mypy, meta README validation, and manifest validation. |
| `lint.sh` | Reviewed | Self-locating Bash bootstrap for type-checking and invoking `meta/lint.py`. |
| `manifest.md` | Reviewed | Positive manifest of tracked repository files outside `meta/` and its omission contract. |
| `manifest.py` | Reviewed | Enforces the repository manifest against its embedded omission contract. |
| `readme.py` | Reviewed | Enforces this local metadata manifest against tracked `meta/` files. |
