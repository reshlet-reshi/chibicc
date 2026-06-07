# Repository File Manifest

This file lists tracked files outside `meta/` that require explicit
audit/status. It also defines the only allowed omissions from that manifest.

The `meta/` directory is omitted because it maintains its own local manifest in
`meta/README.md`. The repository manifest intentionally focuses on tracked
files outside that metadata directory: build/test entrypoints, scripts, docs,
and operational files. C implementation and header files are omitted for now
because they belong to a separate compiler implementation audit.

The fenced block below is real gitignore syntax interpreted relative to the
repository root. Manifest tooling must also honor the repo-root `.gitignore`;
that delegation is part of this contract and is declared here.

```gitignore
# Repository metadata maintains its own local manifest in meta/README.md
meta/

# C implementation and test sources
*.c
*.h
```

| File | Status | Notes |
| --- | --- | --- |
| `.gitignore` | OK | Ignores build/test outputs, Python bytecode caches, local temporaries, and third-party checkout state. |
| `AGENTS.md` | Reviewed | Root policy pointer to the detailed meta agent instructions. |
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
