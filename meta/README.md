# Metadata Directory

`replica/` contains one Markdown file for each path listed in
`meta/manifest.md`. Those files mirror repository paths and hold per-file
documentation notes; individual replica files are intentionally not listed
here. Git submodules under `meta/` are listed as directory entries.

- `pdpmake/`
  - Git submodule containing pdpmake for Makefile compatibility checks.
- `replica/`
  - Per-file documentation subtree for paths listed in `meta/manifest.md`.
- `stage0-posix/`
  - Git submodule containing the pinned stage0-posix bootstrap experiment.
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
- `check.md`
  - Configures heavy executable checks for `meta/check.py`.
- `check.py`
  - Runs fast metadata lint plus configured full-check executables.
- `check.sh`
  - Self-locating Bash bootstrap for type-checking and invoking
    `meta/check.py`.
- `lint.md`
  - Configures extra executable metadata validators for `meta/lint.py`.
- `lint.py`
  - Walks Git-visible files, dispatches extension-based lints, checks the
    source archive file lists, and runs configured metadata validators.
- `lint.sh`
  - Self-locating Bash bootstrap for type-checking and invoking `meta/lint.py`.
- `manifest.md`
  - Positive manifest of tracked repository files outside `meta/` and its
    omission contract.
- `manifest.py`
  - Enforces the repository manifest, omission contract, and exact replica docs.
- `mypy.ini`
  - Strict mypy configuration used by metadata lint tooling.
- `pdpmake.sh`
  - Self-locating wrapper that builds and execs the local pdpmake submodule.
- `reset.sh`
  - Repo-root reset helper for discarding local tracked, untracked, and ignored
    changes after confirmation.
- `stage0-init.sh`
  - Guest init script copied into the experimental stage0 QEMU initramfs.
- `stage0-qemu.sh`
  - Manual preseeded QEMU harness for booting the pinned stage0-posix
    experiment, with opt-out flags for headless and slow-path runs.
- `test-pdpmake.sh`
  - Serial pdpmake compatibility wrapper that runs `test-all` and cleans up.
- `test-system-make.sh`
  - System-make wrapper that runs parallel `test-all` and cleans up.
