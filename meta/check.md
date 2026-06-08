# Metadata Check

`check.sh` runs the fast metadata lint first, then runs the heavier build and
compatibility checks listed below. This is the full pre-push confidence gate.

The system-make check runs `test-all` with parallel jobs. The pdpmake check
keeps the distributed Makefile honest against the repository-local pdpmake
submodule, which is intentionally serial.

- `meta/test-system-make.sh`
- `meta/test-pdpmake.sh`
