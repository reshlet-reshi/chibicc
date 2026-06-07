# `Makefile`

Source: `Makefile`

This file is the top-level build and test entrypoint. Read from top to
bottom, it first describes how to build the stage 1 compiler with the host C
compiler, then describes how that compiler builds and runs the test suite, and
finally repeats the same idea for a stage 2 compiler built by stage 1.

## Global flags and file discovery

```make
CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror

CHIBICC=.make/stage1/chibicc

SRCS=$(wildcard *.c)
OBJDIR=.make/stage1/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
STAGE2_OBJDIR=stage2/.o
STAGE2_OBJS=$(SRCS:%.c=$(STAGE2_OBJDIR)/%.o)

TEST_SRCS=$(wildcard test/*.c)
TEST_OBJDIR=.make/stage1/test/.o
TEST_EXEDIR=.make/stage1/test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)
STAGE2_TEST_OBJDIR=stage2/test/.o
STAGE2_TEST_EXEDIR=stage2/test/.exe
STAGE2_TESTS=$(TEST_SRCS:test/%.c=$(STAGE2_TEST_EXEDIR)/%.exe)
```

`CFLAGS` is the shared compile/link flag set used when the host compiler
links compiler executables. It requests C11, debug information, non-common
global definitions, and most warnings while suppressing switch warnings.
`-Werror` then promotes any remaining host compiler warning to a build
failure.

`CHIBICC` names the private stage 1 compiler output path. The compiler built
by the host C compiler lives at `.make/stage1/chibicc` instead of in the
repository root.

`SRCS` is computed with GNU Make's `wildcard` function. It expands to every
top-level `.c` source file in the repository root.

`OBJDIR` names the private build directory for host-built compiler objects.
`OBJS` is then a substitution reference over `SRCS`: every source becomes an
object under `.make/stage1/.o/`. For example, `parse.c` contributes
`.make/stage1/.o/parse.o`. `STAGE2_OBJDIR` names the corresponding private
object directory for the self-hosted compiler build. `STAGE2_OBJS` performs a
separate substitution for that build, so `parse.c` contributes
`stage2/.o/parse.o` there.

`TEST_SRCS` performs the same discovery for C tests under `test/`.
`TEST_OBJDIR` names the private build directory for stage 1 test objects.
`TEST_EXEDIR` names the private build directory for stage 1 test executables.
`TESTS` maps test sources into the executable directory, so `test/arith.c`
becomes `.make/stage1/test/.exe/arith.exe`. `STAGE2_TEST_OBJDIR` names the
private build directory for stage 2 test objects. `STAGE2_TEST_EXEDIR` names
the private build directory for stage 2 test executables. `STAGE2_TESTS` maps
the same sources to `stage2/test/.exe/*.exe` paths for the self-hosted test
run.

These variables are evaluated by Make before it decides which targets need to
be rebuilt. Adding a new top-level compiler source or a new `test/*.c` file is
therefore enough to include it in the appropriate build graph.

## Stage 1 compiler

```make
# Stage 1

$(CHIBICC): $(OBJS)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: %.c chibicc.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<
```

The first real target is `$(CHIBICC)`, so plain `make` builds the stage 1
compiler at `.make/stage1/chibicc`. Its prerequisites are all objects in
`$(OBJS)`, which now live under `.make/stage1/.o/`.

The recipe links the executable. `$(@D)` is the directory part of the target,
so the first recipe line creates `.make/stage1` before linking. `$@` is the
current target name, so here it is `.make/stage1/chibicc`. `$^` is the full
prerequisite list, so it expands to the object files. `$(LDFLAGS)` is left
open for callers or the environment to supply extra linker flags.

The pattern rule builds each host compiler object. For `parse.c`, the target
is `.make/stage1/.o/parse.o`; `$(@D)` is `.make/stage1/.o`, so the first
recipe line creates the object directory before compiling. `$<` is the first
prerequisite, the matching source file, and `$@` is the object path to write.

The rule also lists `chibicc.h` as a prerequisite. If the shared header
changes, Make considers all compiler objects stale and rebuilds them before
relinking `.make/stage1/chibicc`.

## Stage 1 test executables

```make
$(TEST_EXEDIR)/%.exe: $(CHIBICC) test/%.c test/shared/common.c
	mkdir -p $(@D) $(TEST_OBJDIR)
	./$(CHIBICC) -Iinclude -Itest -c -o $(TEST_OBJDIR)/$*.o test/$*.c
	$(CC) -pthread -o $@ $(TEST_OBJDIR)/$*.o test/shared/common.c
```

This pattern rule turns each `test/*.c` source into a stage 1 executable under
`.make/stage1/test/.exe/`. The `%` is the stem matched between `test/` and
`.c` for the source and between `$(TEST_EXEDIR)/` and `.exe` for the target.
Make exposes that stem as `$*`. For `.make/stage1/test/.exe/arith.exe`, `$*`
is `arith`.

The prerequisites force three things to exist or be current before a test is
linked: the stage 1 compiler, the test source, and `test/shared/common.c`.

The first recipe line creates both stage 1 test output directories. `$(@D)`
is `.make/stage1/test/.exe` for these targets, and `$(TEST_OBJDIR)` is
`.make/stage1/test/.o`. The next line uses the freshly built `./$(CHIBICC)`
to compile the test source into an object file. `-Iinclude -Itest` makes
repository headers and test headers visible. The output object is
`$(TEST_OBJDIR)/$*.o`, matching the stem of the executable being built.

The second recipe line uses the host compiler to link the executable. `$@` is
the final executable path, such as `.make/stage1/test/.exe/arith.exe`. The
test object, such as `.make/stage1/test/.o/arith.o`, is linked with
`test/shared/common.c`, and `-pthread` supplies the thread support needed by
tests that exercise threading behavior.

This split is important: the test source is compiled by the stage 1 compiler,
but the final link is still performed by the host compiler.

## Stage 1 test target

```make
test: $(TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(CHIBICC)
```

The `test` target depends on every executable in `$(TESTS)`, so Make builds
the full stage 1 test suite before running any tests.

Inside the shell loop, `$^` expands to the list of test executables. The shell
variable needs to be written as `$$i` because a single `$` belongs to Make;
doubling it passes a literal `$i` through to the shell. Each executable is
printed, run, and allowed to stop the loop with `exit 1` on failure.

After the compiled C tests pass, the target runs
`test/driver.sh ./$(CHIBICC)`. That driver script exercises command-line
behavior that is easier to check from shell than from the C test binaries.

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

stage2/chibicc: $(STAGE2_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
```

Stage 2 is a self-hosting check. Instead of linking root-level objects built
by the host compiler, `stage2/chibicc` links corresponding objects under
`stage2/.o/`.

`$(STAGE2_OBJS)` is kept separate from `$(OBJS)` so the stage 2 build remains
under `stage2/` even though stage 1 compiler objects moved under
`.make/stage1/.o/`. Those objects are produced by the next pattern rule.

The link command mirrors the stage 1 link. `$@` is `stage2/chibicc`, and `$^`
is the full list of `stage2/.o/*.o` prerequisites.

## Stage 2 objects

```make
$(STAGE2_OBJDIR)/%.o: $(CHIBICC) %.c
	mkdir -p $(@D)
	./$(CHIBICC) -Iinclude -c -o $@ $*.c
```

This pattern rule builds stage 2 object files by compiling top-level compiler
sources with the stage 1 compiler at `$(CHIBICC)`.

The target pattern is `$(STAGE2_OBJDIR)/%.o`, so `$*` is the source stem. For
`stage2/.o/parse.o`, `$*` is `parse`. The prerequisite `%.c` then resolves to
`parse.c`.

`mkdir -p $(@D)` creates the stage 2 object directory before the object is
written. `$(@D)` is the directory part of the target path; for
`stage2/.o/parse.o`, it is `stage2/.o`. The compile command writes `$@`,
which is the full target path, from `parse.c` using `./$(CHIBICC)`. The
explicit `-Iinclude` keeps the repository's compiler-private headers visible
now that the stage 1 compiler executable lives under `.make/stage1/`.

Stage 2 test outputs are deliberately handled by their own rule, so this rule
only creates the compiler object directory.

## Stage 2 test executables

```make
$(STAGE2_TEST_EXEDIR)/%.exe: stage2/chibicc test/%.c test/shared/common.c
	mkdir -p $(@D) $(STAGE2_TEST_OBJDIR)
	./stage2/chibicc -Iinclude -Itest -c -o $(STAGE2_TEST_OBJDIR)/$*.o test/$*.c
	$(CC) -pthread -o $@ $(STAGE2_TEST_OBJDIR)/$*.o test/shared/common.c
```

This rule is the stage 2 counterpart of the stage 1 test executable rule. It
uses `stage2/chibicc` to compile each test source and writes the intermediate
object under `stage2/test/.o/`.

The prerequisites make the rule sensitive to the stage 2 compiler, the test
source, and shared test support. `$*` is again the test stem, and `$@` is the
stage 2 executable path such as `stage2/test/.exe/arith.exe`.

The first recipe line creates both stage 2 test output directories. `$(@D)`
is `stage2/test/.exe` for these targets, and `$(STAGE2_TEST_OBJDIR)` is
`stage2/test/.o`. The final link writes `$@`, the executable path under
`stage2/test/.exe/`, and still uses the host compiler with `-pthread`, just
like stage 1. The distinction being tested is the compiler used to produce
the test object, not the system linker.

## Stage 2 test target

```make
test-stage2: $(STAGE2_TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./stage2/chibicc
```

`test-stage2` depends on `$(STAGE2_TESTS)`, the explicit list of stage 2 test
executables derived from `TEST_SRCS`. That keeps stage 2 test executables
under `stage2/test/.exe/` even though stage 1 test executables moved under
`.make/stage1/test/.exe/`.

The loop is the same shape as the stage 1 test loop: print each executable,
run it, and stop at the first failure. After the C tests pass, the shell
driver is run against `./stage2/chibicc`, which checks command-line behavior
for the self-hosted compiler.

## Cleanup

```make
# Misc.

clean:
	rm -rf chibicc .make tmp* $(TESTS) test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'
```

`clean` removes generated build and test outputs. The first command deletes
any stale root `chibicc`, the `.make` build scratch directory, temporary root
files matching `tmp*`, all discovered stage 1 test executables, stale
root-adjacent `test/*.exe` outputs, test assembly outputs, and the entire
`stage2` tree. Removing `.make` clears the current stage 1 compiler, host
compiler objects, stage 1 test objects, and stage 1 test executables. Removing
`stage2` clears the stage 2 compiler, `stage2/.o/` compiler objects,
`stage2/test/.o/` test objects, and `stage2/test/.exe/` executables.

The second command finds editor backup files and object files below the
repository root and removes them. That cleanup also catches stale `test/*.o`
files left behind by older builds. The parentheses are quoted so the shell
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
