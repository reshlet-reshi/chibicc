# Manifest Ignore Rules

`docs/manifest.md` lists tracked files that require explicit audit/status.
This file defines the only allowed omissions from that manifest.

The current manifest intentionally focuses on repository meta-structure first:
build/test entrypoints, scripts, docs, and operational files. C implementation
and header files are omitted for now because they belong to a separate compiler
implementation audit.

The fenced block below is real gitignore syntax interpreted relative to the
repository root. Manifest tooling must also honor the repo-root `.gitignore`;
that delegation is part of this contract and is declared here.

```gitignore
# C implementation and test sources
*.c
*.h
```
