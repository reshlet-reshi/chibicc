# `Makefile`

Source: `Makefile`

This file is the top-level build and test entrypoint. It is deliberately thin:
it defines the global host compiler flags, names the two build stages, and
invokes `stage.mk` recursively with stage-specific variables. The repeated
rules for compiler objects, compiler binaries, test objects, test
executables, and test loops live in `stage.mk`.

## Global flags and stage roots

```make
CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror
export CFLAGS

STAGE1=.make/stage1
STAGE2=.make/stage2
CHIBICC=$(STAGE1)/chibicc
STAGE2_CHIBICC=$(STAGE2)/chibicc
```

`CFLAGS` is the shared flag set used when the host C compiler builds or links
compiler binaries. It requests C11, debug information, non-common global
definitions, and most warnings while suppressing switch warnings. `-Werror`
then promotes the remaining host compiler warnings to build failures.
`export CFLAGS` puts that default flag set into the submake environment, so
`stage.mk` sees the same link flags that the top-level file defines.

`STAGE1` and `STAGE2` are the private scratch roots for generated build
artifacts. Stage 1 is the host-built compiler and its tests. Stage 2 is the
self-hosted compiler and its tests. Both roots are under `.make/`, which is
ignored and removed by `make clean`.

`CHIBICC` and `STAGE2_CHIBICC` name the compiler binary in each stage. They
are path variables used by both the top-level proxy targets and the recursive
`stage.mk` invocations.

## Stage 1 compiler proxy

```make
# Stage 1

$(CHIBICC): FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./$(CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=chibicc.h \
		compiler
```

This is the first real target in the file, so plain `make` builds the stage 1
compiler at `.make/stage1/chibicc`.

The target depends on `FORCE`, which is an empty phony-style target near the
bottom of the file. That makes top-level Make enter the recursive make every
time this target is requested. The submake then decides whether the real
stage 1 files are stale.

`$(MAKE)` is the recursive-make command. GNU Make gives it special handling,
so command-line flags and jobserver settings are passed through correctly.
`-f stage.mk` tells the submake to use the reusable stage build graph instead
of the top-level orchestration file.

The variable assignments after `-f stage.mk` configure one stage:

- `STAGE=$(STAGE1)` tells `stage.mk` to place all outputs under
  `.make/stage1`.
- `STAGE_CC=$(CC) $(CFLAGS)` says compiler objects for this stage are built
  by the host C compiler.
- `STAGE_TEST_CC=./$(CHIBICC) -Iinclude -Itest` says test objects for this
  stage are compiled by the just-built stage 1 compiler.
- `STAGE_OBJ_DEPS=chibicc.h` makes every compiler object depend on the shared
  compiler header.

The `STAGE_CC` and `STAGE_TEST_CC` assignments are shell-quoted because their
values contain spaces. After the shell removes those quotes, the submake sees
single variable assignments with multi-word compiler commands.

The final word, `compiler`, is the target requested from `stage.mk`.

## Stage 1 test proxy

```make
test: FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./$(CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=chibicc.h \
		test
```

`test` uses the same stage 1 variable set as the compiler proxy but asks
`stage.mk` for its `test` target. The submake builds
`.make/stage1/chibicc`, compiles the stage 1 test objects under
`.make/stage1/test/.o/`, links test executables under
`.make/stage1/test/.exe/`, runs those executables, and then runs
`test/driver.sh ./.make/stage1/chibicc`.

The top-level target is phony because it is a command, not a file artifact.

## Combined test target

```make
test-all: test test-stage2
```

`test-all` is an aggregate target. It has no recipe of its own; it succeeds
when both `test` and `test-stage2` succeed. Unlike the old layout, this target
is now listed in `.PHONY`, so it cannot be shadowed by a real file named
`test-all`.

## Stage 2 compiler proxy

```make
# Stage 2

$(STAGE2_CHIBICC): $(CHIBICC) FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		'STAGE_CC=./$(CHIBICC) -Iinclude' \
		'STAGE_TEST_CC=./$(STAGE2_CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(CHIBICC) \
		compiler
```

This proxy builds the self-hosted compiler at `.make/stage2/chibicc`. It has
an explicit top-level prerequisite on `$(CHIBICC)`, so stage 1 is available
before stage 2 starts.

The recursive call again uses `stage.mk`, but with a different stage root and
different compiler commands:

- `STAGE=$(STAGE2)` routes all outputs under `.make/stage2`.
- `STAGE_CC=./$(CHIBICC) -Iinclude` builds compiler objects with the stage 1
  compiler.
- `STAGE_TEST_CC=./$(STAGE2_CHIBICC) -Iinclude -Itest` prepares the stage 2
  compiler to build stage 2 test objects.
- `STAGE_OBJ_DEPS=$(CHIBICC)` makes compiler objects depend on the stage 1
  compiler binary, so they rebuild when the compiler used to produce them is
  rebuilt.

The stage 2 compiler binary is still linked by the host C compiler inside
`stage.mk`; the self-hosting check is about which compiler produces the object
files.

## Stage 2 test proxy

```make
test-stage2: $(CHIBICC) FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		'STAGE_CC=./$(CHIBICC) -Iinclude' \
		'STAGE_TEST_CC=./$(STAGE2_CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(CHIBICC) \
		test
```

`test-stage2` asks `stage.mk` to run the full test target for stage 2. The
stage 2 submake builds `.make/stage2/chibicc`, compiles stage 2 test objects
under `.make/stage2/test/.o/`, links test executables under
`.make/stage2/test/.exe/`, runs those executables, and then runs
`test/driver.sh ./.make/stage2/chibicc`.

The top-level prerequisite on `$(CHIBICC)` keeps the stage 1 compiler build
ordered before the stage 2 submake. The stage 2 submake still owns the exact
file-level dependency graph for stage 2 artifacts.

## Cleanup

```make
# Misc.

clean:
	rm -rf chibicc .make tmp* test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'
```

`clean` removes generated build and test outputs. The first command deletes
any stale root `chibicc`, the `.make` build scratch directory, temporary root
files matching `tmp*`, stale root-adjacent `test/*.exe` outputs, test
assembly outputs, and the stale root `stage2` tree from older layouts.
Removing `.make` clears the current stage 1 and stage 2 compiler binaries,
compiler objects, test objects, and test executables.

The second command finds editor backup files and object files below the
repository root and removes them. That cleanup catches stale object files left
behind by older layouts. The parentheses are quoted so the shell passes them
to `find` instead of treating them as shell syntax.

## Forced and phony targets

```make
FORCE:

.PHONY: test clean test-stage2 test-all FORCE
```

`FORCE` has no prerequisites and no recipe. Because the file named `FORCE`
does not exist, any target that depends on it is considered out of date, which
forces the proxy recipe to enter the submake.

`.PHONY` marks command targets as commands instead of files. It also marks
`FORCE` as phony so the forcing behavior remains explicit even if a file named
`FORCE` appears in the repository root.
