# `Makefile`

Source: `Makefile`

This file is the top-level build and test entrypoint. Read from top to
bottom, it first describes how to build the stage 1 compiler with the host C
compiler, then describes how that compiler builds and runs the test suite, and
finally repeats the same idea for a stage 2 compiler built by stage 1.

## Global flags and file discovery

```make
CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch

SRCS=$(wildcard *.c)
OBJS=$(SRCS:.c=.o)

TEST_SRCS=$(wildcard test/*.c)
TESTS=$(TEST_SRCS:.c=.exe)
```

`CFLAGS` is the shared compile/link flag set used when the host compiler
links `chibicc` executables. It requests C11, debug information, non-common
global definitions, and most warnings while suppressing switch warnings.

`SRCS` is computed with GNU Make's `wildcard` function. It expands to every
top-level `.c` source file in the repository root. `OBJS` is then a
substitution reference over `SRCS`: every `.c` suffix becomes `.o`. For
example, `parse.c` contributes `parse.o`.

`TEST_SRCS` performs the same discovery for C tests under `test/`. `TESTS`
maps those sources to executable names by replacing `.c` with `.exe`, so
`test/arith.c` becomes `test/arith.exe`.

These variables are evaluated by Make before it decides which targets need to
be rebuilt. Adding a new top-level compiler source or a new `test/*.c` file is
therefore enough to include it in the default build graph.

## Stage 1 compiler

```make
# Stage 1

chibicc: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJS): chibicc.h
```

The first real target is `chibicc`, so plain `make` builds the stage 1
compiler. Its prerequisites are all objects in `$(OBJS)`. Make knows how to
produce each `.o` from the corresponding `.c` through its built-in C compile
rules, using `$(CC)` and the local `CFLAGS`.

The recipe links the executable. `$@` is the current target name, so here it
is `chibicc`. `$^` is the full prerequisite list, so it expands to the object
files. `$(LDFLAGS)` is left open for callers or the environment to supply
extra linker flags.

The grouped prerequisite rule `$(OBJS): chibicc.h` says every compiler object
also depends on the shared header. If `chibicc.h` changes, Make considers all
compiler objects stale and rebuilds them before relinking `chibicc`.

## Stage 1 test executables

```make
test/%.exe: chibicc test/%.c test/shared/common.c
	./chibicc -Iinclude -Itest -c -o test/$*.o test/$*.c
	$(CC) -pthread -o $@ test/$*.o test/shared/common.c
```

This pattern rule turns each `test/*.c` source into a `test/*.exe`
executable. The `%` is the stem matched between `test/` and `.exe`; Make
exposes that stem as `$*`. For `test/arith.exe`, `$*` is `arith`.

The prerequisites force three things to exist or be current before a test is
linked: the stage 1 compiler, the test source, and `test/shared/common.c`.

The first recipe line uses the freshly built `./chibicc` to compile the test
source into an object file. `-Iinclude -Itest` makes repository headers and
test headers visible. The output object is `test/$*.o`, matching the stem of
the executable being built.

The second recipe line uses the host compiler to link the executable. `$@` is
the final executable path, such as `test/arith.exe`. The test object is linked
with `test/shared/common.c`, and `-pthread` supplies the thread support needed
by tests that exercise threading behavior.

This split is important: the test source is compiled by `chibicc`, but the
final link is still performed by the host compiler.

## Stage 1 test target

```make
test: $(TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./chibicc
```

The `test` target depends on every executable in `$(TESTS)`, so Make builds
the full stage 1 test suite before running any tests.

Inside the shell loop, `$^` expands to the list of test executables. The shell
variable needs to be written as `$$i` because a single `$` belongs to Make;
doubling it passes a literal `$i` through to the shell. Each executable is
printed, run, and allowed to stop the loop with `exit 1` on failure.

After the compiled C tests pass, the target runs `test/driver.sh ./chibicc`.
That driver script exercises command-line behavior that is easier to check
from shell than from the C test binaries.

## Combined test target

```make
test-all: test test-stage2
```

`test-all` is an aggregate target. It has no recipe of its own; it succeeds
when both `test` and `test-stage2` succeed.

This is currently a cleanup opportunity: `test-all` behaves like a command
target, but it is not listed in `.PHONY` at the bottom of the file. Adding it
there would protect the target from being shadowed by a real file named
`test-all`.

## Stage 2 compiler

```make
# Stage 2

stage2/chibicc: $(OBJS:%=stage2/%)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
```

Stage 2 is a self-hosting check. Instead of linking root-level objects built
by the host compiler, `stage2/chibicc` links corresponding objects under the
`stage2/` directory.

The prerequisite expression `$(OBJS:%=stage2/%)` is another substitution
reference. It prefixes every object name in `$(OBJS)` with `stage2/`, so
`parse.o` becomes `stage2/parse.o`. Those objects are produced by the next
pattern rule.

The link command mirrors the stage 1 link. `$@` is `stage2/chibicc`, and `$^`
is the full list of `stage2/*.o` prerequisites.

## Stage 2 objects

```make
stage2/%.o: chibicc %.c
	mkdir -p stage2/test
	./chibicc -c -o $(@D)/$*.o $*.c
```

This pattern rule builds stage 2 object files by compiling top-level compiler
sources with the stage 1 `chibicc`.

The target pattern is `stage2/%.o`, so `$*` is the source stem. For
`stage2/parse.o`, `$*` is `parse`. The prerequisite `%.c` then resolves to
`parse.c`.

`mkdir -p stage2/test` creates the stage 2 output directory tree before the
object is written. `$(@D)` is the directory part of the target path; for
`stage2/parse.o`, it is `stage2`. The compile command therefore writes
`stage2/parse.o` from `parse.c`.

The directory creation includes `stage2/test` even for compiler objects
because later stage 2 test rules need that directory as well.

## Stage 2 test executables

```make
stage2/test/%.exe: stage2/chibicc test/%.c test/shared/common.c
	mkdir -p stage2/test
	./stage2/chibicc -Iinclude -Itest -c -o stage2/test/$*.o test/$*.c
	$(CC) -pthread -o $@ stage2/test/$*.o test/shared/common.c
```

This rule is the stage 2 counterpart of the stage 1 test executable rule. It
uses `stage2/chibicc` to compile each test source and writes the intermediate
object under `stage2/test/`.

The prerequisites make the rule sensitive to the stage 2 compiler, the test
source, and shared test support. `$*` is again the test stem, and `$@` is the
stage 2 executable path such as `stage2/test/arith.exe`.

The final link still uses the host compiler with `-pthread`, just like stage
1. The distinction being tested is the compiler used to produce the test
object, not the system linker.

## Stage 2 test target

```make
test-stage2: $(TESTS:test/%=stage2/test/%)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./stage2/chibicc
```

`test-stage2` maps every stage 1 test executable name to the matching stage 2
path. The substitution `$(TESTS:test/%=stage2/test/%)` rewrites
`test/arith.exe` to `stage2/test/arith.exe`.

The loop is the same shape as the stage 1 test loop: print each executable,
run it, and stop at the first failure. After the C tests pass, the shell
driver is run against `./stage2/chibicc`, which checks command-line behavior
for the self-hosted compiler.

## Cleanup

```make
# Misc.

clean:
	rm -rf chibicc tmp* $(TESTS) test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'
```

`clean` removes generated build and test outputs. The first command deletes
the stage 1 compiler, temporary root files matching `tmp*`, all discovered
test executables, test assembly/executable outputs, and the entire `stage2`
tree.

The second command finds editor backup files and object files below the
repository root and removes them. The parentheses are quoted so the shell
passes them to `find` instead of treating them as shell syntax.

## Phony targets

```make
.PHONY: test clean test-stage2
```

`.PHONY` tells Make that these names are commands, not files to check on
disk. That matters for `test`, `clean`, and `test-stage2` because the user
expects the recipes to run when requested, even if a same-named file exists.

`test-all` is also command-shaped and should be added here if the Makefile is
cleaned up. Until then, `make test-all` still works as long as no file named
`test-all` exists in the repository root.
