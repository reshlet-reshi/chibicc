# Metadata Lint

`lint.sh` bootstraps type-checking for `meta/lint.py`, then hands off to
`lint.py`. The Python lint runner checks visible shell and Python files before
running these extra metadata validators.

- `meta/README.py`
- `meta/branches.py`
- `meta/manifest.py`
