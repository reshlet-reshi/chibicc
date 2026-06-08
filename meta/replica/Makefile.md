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
- Local test rules build `test/*.o`, `test/*.exe`, and
  `test/shared/common.o`, then run the executable tests and driver tests.
- `src-dist` creates a tracked-source archive at `.make/chibicc.tar.gz` by
  default, omitting metadata-only files.
- `test` and `test-stage2` unpack that archive under `.make/stage1/` and
  `.make/stage2/`, then run the extracted Makefile in each stage tree.
- `clean` removes local generated outputs, staged `.make/` contents, and stale
  old-layout artifacts.

Generated outputs are intentionally outside the tracked source set:

- root local build: `chibicc`, root `*.o`, `test/*.o`, `test/*.exe`, and
  `test/shared/common.o`
- stage builds and source archives: `.make/`
