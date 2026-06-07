# Repository File Manifest

| File | Status | Notes |
| --- | --- | --- |
| `.gitignore` | OK | Ignores build/test outputs, local temporaries, and third-party checkout state. |
| `docs/branches.md` | Reviewed | Branch inventory, including local unpushed archive and WIP branches. |
| `docs/manifest.ignore.md` | Reviewed | Defines the omission contract for files intentionally left out of this manifest. |
| `docs/manifest.md` | Reviewed | Positive manifest of tracked files requiring explicit audit/status. |
| `LICENSE` | OK | MIT license text. |
| `Makefile` | Needs cleanup | Core build/test entrypoint; `test-all` should be added to `.PHONY`. |
| `README.md` | OK | Upstream project overview and design notes. |
| `reset.sh` | Reviewed | Destructive reset helper with confirmation prompt and repo-directory anchoring. |
| `test/common` | OK | Shared C test support compiled by the Makefile despite lacking a `.c` extension. |
| `test/driver.sh` | Works, noisy | Driver tests pass syntax checks; shellcheck reports legacy quoting/style noise. |
| `test/thirdparty/common` | Needs fix | Checkout helper should validate standalone Git checkouts before destructive `git reset --hard`. |
| `test/thirdparty/cpython.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/git.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/libpng.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/sqlite.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
| `test/thirdparty/tinycc.sh` | Needs cleanup | Third-party test uses SSH GitHub URL, which is unfriendly without a GitHub SSH key. |
