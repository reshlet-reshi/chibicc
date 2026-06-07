# `Makefile`

Source: `Makefile`

This file is both the repository-level build orchestrator and the local build
file used inside each extracted stage source tree. The outer targets create a
source distribution, unpack it into `.make/stage1` or `.make/stage2`, and then
run local stage targets in that extracted tree. The local targets build a
compiler named `chibicc`, build test executables, and run the driver tests.

## Flags and stage paths

```make
CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror

STAGE1=.make/stage1
STAGE2=.make/stage2
STAGE1_CHIBICC=$(STAGE1)/chibicc
STAGE2_CHIBICC=$(STAGE2)/chibicc
SRC_DIST?=.make/chibicc.tar.gz
SRC_DIST_ROOT=chibicc
SRC_DIST_LIST=.make/src-dist.files
```

`CFLAGS` is the host compiler warning and debug policy. It requests C11,
debug information, non-common globals, most warnings, and then treats enabled
warnings as errors. `-Wno-switch` stays before `-Werror`, so switch warnings
remain explicitly disabled. Recursive Make calls read this default from the
extracted Makefile, while command-line `CFLAGS=...` overrides still propagate
through GNU Make's normal `MAKEFLAGS` handling.

`STAGE1` and `STAGE2` are extracted source roots under `.make/`.
`STAGE1_CHIBICC` and `STAGE2_CHIBICC` are the compiler binaries produced in
those extracted roots. `SRC_DIST` is the source archive that `src-dist`
writes and stage builds consume; callers can override it to choose a different
archive path. `SRC_DIST_ROOT` is the top-level directory name stored inside
the tarball.

`SRC_DIST_LIST` is a temporary nul-delimited list consumed by tar. It lives
under `.make/`, including when `make src-dist` is run from an extracted tree.

## Fixed source lists

```make
DIST_ROOT_FILES=\
	LICENSE \
	Makefile \
	README.md \
	chibicc.h

COMPILER_SRCS=\
	codegen.c \
	hashmap.c \
	...
	unicode.c

DIST_INCLUDE_FILES=\
	include/float.h \
	include/stdalign.h \
	...
	include/stdnoreturn.h

TEST_SRCS=\
	test/alignof.c \
	test/alloca.c \
	test/arith.c \
	...
	test/vla.c

TEST_FILES=\
	$(TEST_SRCS) \
	test/driver.sh \
	test/include1.h \
	test/shared/common.c \
	test/thirdparty/common.sh.inc \
	...
	test/thirdparty/tinycc.sh

DIST_FILES=\
	$(DIST_ROOT_FILES) \
	$(COMPILER_SRCS) \
	$(DIST_INCLUDE_FILES) \
	$(TEST_FILES)
```

The source distribution no longer asks Git for a file list at build time.
`DIST_ROOT_FILES`, `COMPILER_SRCS`, `DIST_INCLUDE_FILES`, and `TEST_FILES`
are the explicit contract for files that enter the tarball. They contain
tracked project files outside `meta/` and intentionally omit `.gitignore` and
`.gitmodules`. Because these lists are ordinary Make data, the same archive
rule works from the repository root and from an extracted source tree that has
no `.git/` directory.

`COMPILER_SRCS` is the semantic list of root compiler implementation sources.
Those files become `$(OBJDIR)/*.o` and then link into `chibicc`.

`TEST_SRCS` is the semantic list of direct `test/*.c` programs. Those files
become local test objects and executables.

`TEST_FILES` starts with `$(TEST_SRCS)` and then adds every current
distributed non-program file under `test/`, including headers, shell scripts,
third-party test harnesses, and nested helpers. This keeps the test program
list explicit while still deriving the source distribution's test subtree from
one place.

`DIST_FILES` is derived from the smaller lists, so compiler and test files are
not repeated in one giant manifest. Nested helper sources such as
`test/shared/common.c` stay in the source distribution but are not standalone
test executables.

## Local stage outputs

```make
LOCAL_CHIBICC=chibicc
OBJDIR=.o
OBJS=$(COMPILER_SRCS:%.c=$(OBJDIR)/%.o)
TEST_OBJDIR=test/.o
TEST_EXEDIR=test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)
TEST_LINK_CC?=$(CC)
```

These variables describe one local stage tree. In the repository root they
allow direct commands such as `make compiler` and `make test-compiler`.
Inside `.make/stage1` or `.make/stage2`, the same variables point at the
outputs for that extracted stage.

`LOCAL_CHIBICC` is the local compiler binary. `OBJDIR` receives compiler
objects such as `.o/parse.o`. `TEST_OBJDIR` receives test objects such as
`test/.o/arith.o`, and `TEST_EXEDIR` receives test executables such as
`test/.exe/arith.exe`.

The substitutions preserve each stem. For example, `parse.c` maps to
`.o/parse.o`, and `test/arith.c` maps to `test/.exe/arith.exe`.
`TEST_LINK_CC` defaults to `$(CC)` but can be overridden by the outer
orchestrator when compiler-building and test-linking need different drivers.

## Entry points and local stage targets

```make
default: compiler

all: test-all

compiler:
	mkdir -p $(OBJDIR)
	for src in $(COMPILER_SRCS); do \
		obj=$(OBJDIR)/$${src%.c}.o; \
		$(CC) $(CFLAGS) -c -o $$obj $$src || exit 1; \
	done
	$(CC) $(CFLAGS) -o $(LOCAL_CHIBICC) $(OBJS) $(LDFLAGS)

test-compiler: compiler
	mkdir -p $(TEST_EXEDIR) $(TEST_OBJDIR)
	for src in $(TEST_SRCS); do \
		stem=$${src#test/}; \
		stem=$${stem%.c}; \
		obj=$(TEST_OBJDIR)/$$stem.o; \
		exe=$(TEST_EXEDIR)/$$stem.exe; \
		./$(LOCAL_CHIBICC) -Iinclude -Itest -c -o $$obj $$src || exit 1; \
		$(TEST_LINK_CC) -pthread -o $$exe $$obj test/shared/common.c \
			|| exit 1; \
	done
	for i in $(TEST_EXEDIR)/*.exe; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(LOCAL_CHIBICC)
```

The first target is `default`, so plain `make` builds the local compiler
through that named target. `default` depends on `compiler`, the phony
local-stage command target that writes root `./chibicc` and `.o/*.o` outputs.
This keeps the default build lightweight while leaving `test-all` as the
full "does everything work right now?" gate.

The conventional `all` target is an alias for `test-all`, so `make all` runs
the full stage 1 and stage 2 test gate without changing the default target's
lighter behavior.

`compiler` is the local command target. It builds `chibicc` in whatever tree
Make is currently running in.

The target first creates `$(OBJDIR)`, then loops over `$(COMPILER_SRCS)`.
`$$src` is a shell variable; the doubled dollar signs pass a literal `$`
through Make to the shell. `$${src%.c}` strips the `.c` suffix, so `parse.c`
maps to `.o/parse.o`.

Each loop iteration compiles one root compiler source with `$(CC)
$(CFLAGS)`. The `|| exit 1` guard stops the loop at the first failed compile
instead of continuing to link with a missing or stale object.

The final command links `$(LOCAL_CHIBICC)` from the explicit `$(OBJS)` list.
`$(LDFLAGS)` remains available for callers that need additional link flags.
The recipe intentionally avoids GNU Make pattern rules and automatic
variables such as `$@`, `$<`, and `$^`, keeping the local stage build usable
with pdpmake.

The compiler build uses `$(CC) $(CFLAGS)`. In stage 1, that is the host
compiler with the repository warning policy. In stage 2, the outer Makefile
sets `CC` to the stage 1 compiler and clears `CFLAGS`, so chibicc receives
only the stage-local include path.

`test-compiler` depends on `compiler`, so the local `./chibicc` is rebuilt
before test objects are compiled. The recipe creates the test object and
executable directories, then loops over `$(TEST_SRCS)`.

For each source, `$${src#test/}` removes the leading `test/`, and
`$${stem%.c}` removes the `.c` suffix. `test/arith.c` therefore becomes the
stem `arith`, the object path `test/.o/arith.o`, and the executable path
`test/.exe/arith.exe`.

The compile step always uses the local stage compiler with the stage-local
`include/` and `test/` directories. The link step combines the test object
with `test/shared/common.c` and writes the executable to `$(TEST_EXEDIR)`.
Each command exits the loop immediately on failure.

After the loop, the target runs each `test/.exe/*.exe` program, printing the
executable path before running it, and then runs `test/driver.sh` against the
local `./chibicc`.

The link step uses `$(TEST_LINK_CC)` without `$(CFLAGS)`, so stage 1 test
helper warnings do not become `-Werror` failures. Stage 2 overrides
`TEST_LINK_CC` to the host compiler because chibicc does not accept every
linker option used here, such as `-pthread`.

## Source distribution

```make
$(SRC_DIST): $(DIST_FILES)
	mkdir -p "$$(dirname "$@")" "$$(dirname "$(SRC_DIST_LIST)")"
	printf '%s\0' $(DIST_FILES) > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@

src-dist: $(SRC_DIST)
```

The next real file target is `$(SRC_DIST)`, the source archive file target.
By default it creates `.make/chibicc.tar.gz`; callers can override `SRC_DIST`
to write somewhere else. Stage extraction also depends on `$(SRC_DIST)`, so
the same override chooses the archive path used by stage builds.

The archive target depends on every `DIST_FILES` entry. The recipe creates
the output directory and the temporary list directory with shell `dirname`
rather than GNU make's `$(dir ...)`, writes the explicit file list as
nul-delimited records, and gives that list to GNU tar with `--null -T`.

`--transform` prefixes every archive member with `$(SRC_DIST_ROOT)/`, so the
tarball expands to a wrapping `chibicc/` directory. Stage extraction flattens
that wrapper by moving `chibicc/` to the requested stage path.

`src-dist` is the public command target for building the archive directly.

## Stage 1 orchestration

```make
$(STAGE1_CHIBICC): $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) compiler

test: $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) test-compiler

test-all: test test-stage2
```

`$(STAGE1_CHIBICC)` depends on `$(STAGE1)/.src-ready`, a stamp that means the
source archive has been extracted into `.make/stage1`.

The recipe then enters the extracted tree with `$(MAKE) -C $(STAGE1)`.
`$(MAKE)` preserves recursive Make behavior such as jobserver flags. Stage 1
uses the extracted Makefile's normal `$(CC)` and `$(CFLAGS)` values, so
compiler sources are still built with the host warning policy.

The public `test` target follows the same extraction path but asks the
extracted Makefile to run `test-compiler`. `test-all` is just an aggregate
over the stage 1 and stage 2 test commands.

## Stage 2 orchestration

```make
$(STAGE2_CHIBICC): $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	STAGE1_CHIBICC=$$(pwd)/$(STAGE1_CHIBICC); \
		$(MAKE) -C $(STAGE2) "CC=$$STAGE1_CHIBICC -Iinclude" \
			CFLAGS= compiler

test-stage2: $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	STAGE1_CHIBICC=$$(pwd)/$(STAGE1_CHIBICC); \
		$(MAKE) -C $(STAGE2) "CC=$$STAGE1_CHIBICC -Iinclude" \
			"TEST_LINK_CC=$(CC)" CFLAGS= test-compiler
```

Stage 2 has two prerequisites: the stage 1 compiler and an extracted stage 2
source tree. Once both exist, the recipe captures the absolute stage 1
compiler path with shell `pwd`, enters `.make/stage2`, and sets `CC` to that
compiler plus `-Iinclude`.

That `CC` value is the local stage's compiler-build driver. It compiles stage
2 compiler objects and links `.make/stage2/chibicc`. `CFLAGS=` keeps host-only
warning flags from being passed to chibicc while it is compiling stage 2. The
include path remains stage-local because the recursive call runs from inside
`.make/stage2`.

`test-stage2` asks the stage 2 extracted Makefile to run `test-compiler`, so
the tests are compiled by `.make/stage2/chibicc` after that compiler has
been built. It also passes `TEST_LINK_CC=$(CC)` so the final test executable
link continues to use the host compiler, which accepts link options such as
`-pthread`.

## Stage extraction

```make
$(STAGE1)/.src-ready $(STAGE2)/.src-ready: $(SRC_DIST)
	@case '$(@D)' in .make/*) ;; \
		*) echo 'refusing to prepare stage outside .make' >&2; exit 1;; \
	esac
	rm -rf $(@D) $(@D).unpack
	mkdir -p $(@D).unpack
	tar -xzf $(SRC_DIST) -C $(@D).unpack
	mv $(@D).unpack/$(SRC_DIST_ROOT) $(@D)
	rm -rf $(@D).unpack
	touch $@
```

Both stage stamps share the same recipe. `$@` is the stamp path, and `$(@D)`
is its directory, either `.make/stage1` or `.make/stage2`.

The guard refuses to prepare a stage outside `.make/`. The recipe removes the
old stage tree and temporary unpack directory, creates a fresh temporary
directory, extracts the source distribution into it, moves the tarball's
`$(SRC_DIST_ROOT)` directory into the final stage directory, removes the
temporary directory, and touches the stamp.

Because extraction replaces the whole stage directory, rebuilding a stale
source distribution gives the next stage build a clean source tree.

## Cleanup and phony targets

```make
clean:
	rm -rf chibicc .make .o tmp* test/.exe test/.o test/*.s test/*.exe
	rm -rf stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: all clean compiler default src-dist test test-compiler
.PHONY: test-all test-stage2
```

`clean` removes local direct-stage outputs, extracted stage trees, source
archives, temporary test outputs, and stale root `stage2` output from the old
layout. The final `find` removes backup files and any leftover object files
outside the current directory layout.

Command targets are phony. Real file targets such as `$(SRC_DIST)`,
`$(STAGE1_CHIBICC)`, and `$(STAGE2_CHIBICC)` are left as normal targets so
Make can use timestamps to decide what is stale.
