# `Makefile`

Source: `Makefile`

This file is both the repository-level build orchestrator and the local build
file used inside each extracted stage source tree. The outer targets create a
source distribution, unpack it into `.make/stage1` or `.make/stage2`, and then
run local stage targets in that extracted tree. The local targets build a
compiler named `chibicc`, build test executables, and run the driver tests.

The Makefile intentionally keeps variable definitions close to the first rule
that needs them. Variables used in target names or prerequisite lists still
appear before those rules, because Make expands that syntax while reading the
file. Recipe-only variables can sit beside the recipe that consumes them.

## Entry points

```make
default: chibicc

all: test-all
```

The first target is `default`, so plain `make` builds the local compiler
through that named target. `default` depends on `chibicc`, the real local
compiler file target that writes root `./chibicc` from root `*.o` objects.

The conventional `all` target is an alias for `test-all`, so `make all` runs
the full stage 1 and stage 2 test gate without changing the default target's
lighter behavior.

## Local compiler build

```make
CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror

COMPILER_SRCS=\
	codegen.c \
	hashmap.c \
	...
	unicode.c

OBJS=$(COMPILER_SRCS:.c=.o)

chibicc: $(OBJS)
	$(CC) $(CFLAGS) -o chibicc $(OBJS) $(LDFLAGS)

codegen.o: codegen.c chibicc.h
	$(CC) $(CFLAGS) -c -o codegen.o codegen.c

...

unicode.o: unicode.c chibicc.h
	$(CC) $(CFLAGS) -c -o unicode.o unicode.c
```

`CFLAGS` is the host compiler warning and debug policy. It requests C11,
debug information, non-common globals, most warnings, and then treats enabled
warnings as errors. `-Wno-switch` stays before `-Werror`, so switch warnings
remain explicitly disabled. Recursive Make calls read this default from the
extracted Makefile, while command-line `CFLAGS=...` overrides still propagate
through Make's normal `MAKEFLAGS` handling.

`COMPILER_SRCS` is the semantic list of root compiler implementation sources.
Those files become root `*.o` objects and then link into `chibicc`.

`OBJS` maps every root compiler source into a root object file while
preserving the stem, so `parse.c` becomes `parse.o`.

`chibicc` is a real file target. It depends on the full object list, and its
recipe links the literal `chibicc` executable from `$(OBJS)`. `$(LDFLAGS)`
remains available for callers that need additional link flags.

Each compiler object is also a real file target. The Makefile writes these
rules explicitly instead of using GNU Make pattern target syntax, keeping the
local stage build usable with pdpmake. Every object depends on its matching
source file and on `chibicc.h`, so touching the shared header rebuilds all
compiler objects.

The object recipes use literal source filenames such as `codegen.c` instead
of `$<`, because pdpmake's `$<` extension can mean the first out-of-date
prerequisite rather than simply the first prerequisite. The real target graph
lets Make skip up-to-date objects and avoid relinking `chibicc` when nothing
relevant changed.

## Local compiler test build

```make
TEST_SRCS=\
	test/alignof.c \
	test/alloca.c \
	test/arith.c \
	...
	test/vla.c

TESTS=$(TEST_SRCS:.c=.exe)
TEST_LINK_CC?=$(CC)

test-compiler: chibicc
	for src in $(TEST_SRCS); do \
		stem=$${src#test/}; \
		stem=$${stem%.c}; \
		obj=test/$$stem.o; \
		exe=test/$$stem.exe; \
		./chibicc -Iinclude -Itest -c -o $$obj $$src || exit 1; \
		$(TEST_LINK_CC) -pthread -o $$exe $$obj test/shared/common.c \
			|| exit 1; \
	done
	for i in $(TESTS); do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./chibicc
```

`TEST_SRCS` is the semantic list of direct `test/*.c` programs. `TESTS` maps
each test source to its direct executable path with the same stem, so
`test/arith.c` becomes `test/arith.exe`.

`TEST_LINK_CC` defaults to `$(CC)` but can be overridden by the outer
orchestrator when compiler-building and test-linking need different drivers.

`test-compiler` depends on `chibicc`, so the local compiler file is rebuilt
before test objects are compiled. The recipe loops over `$(TEST_SRCS)`.

For each source, `$${src#test/}` removes the leading `test/`, and
`$${stem%.c}` removes the `.c` suffix. `test/arith.c` therefore becomes the
stem `arith`, the object path `test/arith.o`, and the executable path
`test/arith.exe`.

The compile step always uses the local stage compiler with the stage-local
`include/` and `test/` directories. The link step combines the test object
with `test/shared/common.c` and writes the executable next to the test source.
Each command exits the loop immediately on failure.

After the loop, the target runs each executable in `$(TESTS)`, printing the
path before running it, and then runs `test/driver.sh` against the local
`./chibicc`.

The link step uses `$(TEST_LINK_CC)` without `$(CFLAGS)`, so stage 1 test
helper warnings do not become `-Werror` failures. Stage 2 overrides
`TEST_LINK_CC` to the host compiler because chibicc does not accept every
linker option used here, such as `-pthread`.

## Source distribution

```make
SRC_DIST?=.make/chibicc.tar.gz
SRC_DIST_ROOT=chibicc
SRC_DIST_LIST=.make/src-dist.files

DIST_ROOT_FILES=\
	LICENSE \
	Makefile \
	README.md \
	chibicc.h

DIST_INCLUDE_FILES=\
	include/float.h \
	include/stdalign.h \
	...
	include/stdnoreturn.h

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

$(SRC_DIST): $(DIST_FILES)
	mkdir -p "$$(dirname "$@")" "$$(dirname "$(SRC_DIST_LIST)")"
	printf '%s\0' $(DIST_FILES) > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@

src-dist: $(SRC_DIST)
```

`SRC_DIST` is the source archive that `src-dist` writes and stage builds
consume. Callers can override it to choose a different archive path.
`SRC_DIST_ROOT` is the top-level directory name stored inside the tarball.
`SRC_DIST_LIST` is a temporary nul-delimited list consumed by tar. It lives
under `.make/`, including when `make src-dist` runs from an extracted tree.

The source distribution no longer asks Git for a file list at build time.
`DIST_ROOT_FILES`, `COMPILER_SRCS`, `DIST_INCLUDE_FILES`, and `TEST_FILES`
are the explicit contract for files that enter the tarball. They contain
tracked project files outside `meta/` and intentionally omit `.gitignore` and
`.gitmodules`. Because these lists are ordinary Make data, the same archive
rule works from the repository root and from an extracted source tree that has
no `.git/` directory.

`TEST_FILES` starts with `$(TEST_SRCS)` and then adds every current
distributed non-program file under `test/`, including headers, shell scripts,
third-party test harnesses, and nested helpers. This keeps the test program
list explicit while still deriving the source distribution's test subtree from
one place.

`DIST_FILES` is derived from the smaller lists, so compiler and test files are
not repeated in one giant manifest. Nested helper sources such as
`test/shared/common.c` stay in the source distribution but are not standalone
test executables.

The archive target depends on every `DIST_FILES` entry. The recipe creates
the output directory and the temporary list directory with shell `dirname`,
writes the explicit file list as nul-delimited records, and gives that list
to GNU tar with `--null -T`.

`--transform` prefixes every archive member with `$(SRC_DIST_ROOT)/`, so the
tarball expands to a wrapping `chibicc/` directory. Stage extraction flattens
that wrapper by moving `chibicc/` to the requested stage path. `src-dist` is
the public command target for building the archive directly.

## Stage 1 orchestration

```make
STAGE1=.make/stage1
STAGE1_CHIBICC=$(STAGE1)/chibicc

$(STAGE1_CHIBICC): $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) chibicc

test: $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) test-compiler

test-all: test test-stage2
```

`STAGE1` is the extracted source root under `.make/`, and `STAGE1_CHIBICC`
is the compiler binary produced in that extracted root. These variables sit
directly before the stage 1 rules because they are used in target names and
prerequisites.

`$(STAGE1_CHIBICC)` depends on `$(STAGE1)/.src-ready`, a stamp that means the
source archive has been extracted into `.make/stage1`.

The recipe enters the extracted tree with `$(MAKE) -C $(STAGE1) chibicc`.
`$(MAKE)` preserves recursive Make behavior such as jobserver flags. Stage 1
uses the extracted Makefile's normal `$(CC)` and `$(CFLAGS)` values, so
compiler sources are still built with the host warning policy.

The public `test` target follows the same extraction path but asks the
extracted Makefile to run `test-compiler`. `test-all` is just an aggregate
over the stage 1 and stage 2 test commands.

## Stage 2 orchestration

```make
STAGE2=.make/stage2
STAGE2_CHIBICC=$(STAGE2)/chibicc

$(STAGE2_CHIBICC): $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	STAGE1_CHIBICC=$$(pwd)/$(STAGE1_CHIBICC); \
		$(MAKE) -C $(STAGE2) "CC=$$STAGE1_CHIBICC -Iinclude" \
			CFLAGS= chibicc

test-stage2: $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	STAGE1_CHIBICC=$$(pwd)/$(STAGE1_CHIBICC); \
		$(MAKE) -C $(STAGE2) "CC=$$STAGE1_CHIBICC -Iinclude" \
			"TEST_LINK_CC=$(CC)" CFLAGS= test-compiler
```

`STAGE2` is the second extracted source root, and `STAGE2_CHIBICC` is the
compiler binary produced there. Stage 2 has two prerequisites: the stage 1
compiler and an extracted stage 2 source tree.

Once both prerequisites exist, the recipe captures the absolute stage 1
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

.PHONY: all clean default src-dist test test-compiler
.PHONY: test-all test-stage2
```

`clean` removes local direct-stage outputs, extracted stage trees, source
archives, temporary test outputs, and stale directories from previous output
layouts such as `.o`, `test/.o`, `test/.exe`, and root `stage2`. The final
`find` removes backup files and any leftover object files outside the current
directory layout.

Command targets are phony. Real file targets such as `chibicc`,
`$(SRC_DIST)`, `$(STAGE1_CHIBICC)`, and `$(STAGE2_CHIBICC)` are left as
normal targets so Make can use timestamps to decide what is stale.
