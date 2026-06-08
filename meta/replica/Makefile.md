# `Makefile`

Source: `Makefile`

The Makefile is moving quickly, so this replica intentionally avoids a
literate copy of its rules for now. Recreating the file block by block has
been high-churn documentation, and detailed commentary can return after the
build layout settles.

It currently covers these build roles:

- `default` builds the local `chibicc` executable.
- `all` aliases the full `test-all` gate.
- Local compiler rules build root `*.o` objects and link `./chibicc`.
- Public local test targets delegate to `test/Makefile`, which builds
  `test/*.o`, `test/*.exe`, and `test/shared/common.o`.
- `src-dist` creates an uncompressed combined source archive at
  `.make/chibicc.tar` by default, omitting metadata-only files.
- Source distribution is split into root and test component archives before
  the combined archive is assembled.
- `test` and `test-stage2` unpack that archive under `.make/stage1/` and
  `.make/stage2/`, then run the extracted Makefile in each stage tree.
- `clean` removes local generated outputs, staged `.make/` contents, and stale
  old-layout artifacts.

Generated outputs are intentionally outside the tracked source set:

- root local build: `chibicc`, root `*.o`, `test/*.o`, `test/*.exe`, and
  `test/shared/common.o`
- stage builds and source archives: `.make/`
