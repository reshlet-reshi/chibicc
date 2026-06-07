# Repository File Manifest

| File | Status | Notes |
| --- | --- | --- |
| `.gitignore` | OK | Ignores build/test outputs, Python bytecode caches, local temporaries, and third-party checkout state. |
| `AGENTS.md` | Reviewed | Root policy pointer to the detailed meta agent instructions. |
| `meta/branches.md` | Reviewed | Branch inventory, including local unpushed archive and WIP branches. |
| `meta/AGENTS.md` | Reviewed | Agent policy requiring clean commits and passing meta lint. |
| `meta/lint.py` | Reviewed | Python orchestrator for ShellCheck, strict mypy, and manifest validation. |
| `meta/lint.sh` | Reviewed | Self-locating Bash bootstrap for type-checking and invoking `meta/lint.py`. |
| `meta/manifest.ignore.md` | Reviewed | Defines the omission contract for files intentionally left out of this manifest. |
| `meta/manifest.md` | Reviewed | Positive manifest of tracked files requiring explicit audit/status. |
| `meta/manifest.py` | Reviewed | Enforces this manifest against the manifest ignore contract. |
| `LICENSE` | OK | MIT license text. |
| `Makefile` | Needs cleanup | Core build/test entrypoint; `test-all` should be added to `.PHONY`. |
| `mypy.ini` | Reviewed | Very strict explicit mypy configuration for repository Python lint. |
| `README.md` | OK | Upstream project overview and design notes. |
| `reset.sh` | Reviewed | Destructive reset helper with confirmation prompt and repo-directory anchoring. |
| `test/driver.sh` | Reviewed | Driver tests are covered by ShellCheck and regression test targets. |
| `test/thirdparty/common.sh.inc` | Needs fix | Checkout helper should validate standalone Git checkouts before destructive `git reset --hard`. |
| `test/thirdparty/cpython.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/git.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/libpng.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/sqlite.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/tinycc.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
