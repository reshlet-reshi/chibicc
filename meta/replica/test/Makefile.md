# `test/Makefile`

Source: `test/Makefile`

The test Makefile owns local executable-test builds for the compiler under
test. The root Makefile delegates its public `test-compiler` targets here with
`make -C test` after ensuring `../chibicc` exists.

It builds `*.o`, `*.exe`, and `shared/common.o` under `test/`, runs the
executable tests, and invokes `driver.sh` with the compiler path. It also owns
the test source archive component, which is appended to the root source
archive by the top-level `src-dist` target.
