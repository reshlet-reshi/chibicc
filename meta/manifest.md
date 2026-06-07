# Repository File Manifest

This file indexes tracked files outside `meta/` that require explicit
audit/status documentation. It also defines the only allowed omissions from
that manifest.

The `meta/` directory is omitted because it maintains its own local manifest in
`meta/README.md`. The repository manifest intentionally focuses on tracked
files outside that metadata directory: build/test entrypoints, scripts, docs,
and operational files. C implementation and header files are omitted for now
because they belong to a separate compiler implementation audit.

The fenced block below is real gitignore syntax interpreted relative to the
repository root. Manifest tooling must also honor the repo-root `.gitignore`;
that delegation is part of this contract and is declared here.

Each listed file links to matching per-file documentation under
`meta/replica/`, preserving its repository-relative path and adding `.md`.
Status and notes live in those replica docs. For example, `.gitignore` is
documented at `meta/replica/.gitignore.md`.

```gitignore
# Repository metadata maintains its own local manifest in meta/README.md
meta/

# C implementation and test sources
*.c
*.h
```

- [`.gitignore`](replica/.gitignore.md)
- [`AGENTS.md`](replica/AGENTS.md.md)
- [`LICENSE`](replica/LICENSE.md)
- [`Makefile`](replica/Makefile.md)
- [`mypy.ini`](replica/mypy.ini.md)
- [`README.md`](replica/README.md.md)
- [`reset.sh`](replica/reset.sh.md)
- [`test/driver.sh`](replica/test/driver.sh.md)
- [`test/thirdparty/common.sh.inc`](replica/test/thirdparty/common.sh.inc.md)
- [`test/thirdparty/cpython.sh`](replica/test/thirdparty/cpython.sh.md)
- [`test/thirdparty/git.sh`](replica/test/thirdparty/git.sh.md)
- [`test/thirdparty/libpng.sh`](replica/test/thirdparty/libpng.sh.md)
- [`test/thirdparty/sqlite.sh`](replica/test/thirdparty/sqlite.sh.md)
- [`test/thirdparty/tinycc.sh`](replica/test/thirdparty/tinycc.sh.md)
