# Manifest Ignore Rules

`meta/manifest.md` lists tracked files outside `meta/` that require explicit
audit/status.
This file defines the only allowed omissions from that manifest.

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
