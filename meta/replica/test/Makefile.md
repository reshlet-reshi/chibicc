# `test/Makefile`

Source: `test/Makefile`

The test Makefile owns local executable-test builds for the compiler under
test. The root Makefile delegates its public `test-compiler` targets here with
`make -C test`, setting `CC=../chibicc` after ensuring that compiler exists.

Inside this Makefile, `CC` is the compiler being tested. `LINK_CC` is
separate and names the host compiler driver used to link test executables.

It builds real `*.o` targets for each test source, links real `*.exe` targets
from those objects and `shared/common.o`, runs the executable tests, and
invokes `driver.sh` with `CC`. It also owns the test source archive component,
which is appended to the root source archive by the top-level `archive` target.
