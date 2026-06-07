# Metadata Lint

`lint.sh` bootstraps type-checking for `meta/lint.py`, then hands off to
`lint.py`. The Python lint runner walks the repository root, prunes `.git`,
filters to Git-visible files, and dispatches each file by its full basename
extension. Unrecognized extensions are lint findings; extensionless files are
allowed only when named `LICENSE` or `Makefile`. Extension dispatch skips
`meta/replica/`, whose exact file set is validated by `meta/manifest.py`.
The only allowed `.ini` file is root `mypy.ini`, which is validated by mypy
itself. Python files are checked by Ruff and mypy.

After per-file dispatch succeeds, `lint.py` runs these extra metadata
validators.

- `meta/README.py`
- `meta/branches.py`
- `meta/manifest.py`
