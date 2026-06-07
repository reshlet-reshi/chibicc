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
export CFLAGS

STAGE1=.make/stage1
STAGE2=.make/stage2
STAGE1_CHIBICC=$(STAGE1)/chibicc
STAGE2_CHIBICC=$(STAGE2)/chibicc
DEFAULT_SRC_DIST=.make/chibicc.tar.gz
SRC_DIST?=$(DEFAULT_SRC_DIST)
SRC_DIST_ROOT=chibicc
SRC_DIST_LIST=.make/src-dist.files
```

`CFLAGS` is the host compiler warning and debug policy. It requests C11,
debug information, non-common globals, most warnings, and then treats enabled
warnings as errors. `-Wno-switch` stays before `-Werror`, so switch warnings
remain explicitly disabled. The variable is exported so recursive Make calls
inherit the same flag policy when it is folded into a compiler command.

`STAGE1` and `STAGE2` are extracted source roots under `.make/`.
`STAGE1_CHIBICC` and `STAGE2_CHIBICC` are the compiler binaries produced in
those extracted roots. `DEFAULT_SRC_DIST` is the archive that stage builds
consume. `SRC_DIST` is overridable for `make src-dist`, and `SRC_DIST_ROOT`
is the top-level directory name stored inside the tarball.

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

TEST_FILES=\
	test/alignof.c \
	test/alloca.c \
	test/arith.c \
	test/driver.sh \
	test/include1.h \
	test/shared/common.c \
	test/thirdparty/common.sh.inc \
	...
	test/vla.c

DIST_FILES=$(DIST_ROOT_FILES) $(COMPILER_SRCS) $(DIST_INCLUDE_FILES) \
	$(TEST_FILES)

TEST_SRCS=$(foreach path,$(filter test/%.c,$(TEST_FILES)),\
	$(if $(findstring /,$(patsubst test/%,%,$(path))),,$(path)))
```

The source distribution no longer asks Git for a file list at build time.
`DIST_ROOT_FILES`, `COMPILER_SRCS`, `DIST_INCLUDE_FILES`, and `TEST_FILES`
are the explicit contract for files that enter the tarball. They contain
tracked project files outside `meta/` and intentionally omit `.gitignore`.
Because these lists are ordinary Make data, the same archive rule works from
the repository root and from an extracted source tree that has no `.git/`
directory.

`COMPILER_SRCS` is the semantic list of root compiler implementation sources.
Those files become `$(OBJDIR)/*.o` and then link into `chibicc`.

`TEST_FILES` lists every current distributed file under `test/`, including
headers, shell scripts, third-party test harnesses, and nested helpers.
`DIST_FILES` is derived from the smaller lists, so compiler and test files are
not repeated in one giant manifest.

`TEST_SRCS` is derived from `TEST_FILES` by first taking `test/%.c` entries.
For each candidate, Make removes the `test/` prefix and checks whether the
rest still contains `/`. Direct files such as `test/arith.c` become test
programs. Nested helper sources such as `test/shared/common.c` stay in the
source distribution but are not standalone test executables.

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
allow direct commands such as `make stage-compiler` and `make stage-test`.
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

## Stage 1 orchestration

```make
# Stage 1

$(STAGE1_CHIBICC): $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) stage-compiler

test: $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) stage-test

test-all: test test-stage2
```

The first real target is `$(STAGE1_CHIBICC)`, so plain `make` builds the
stage 1 compiler. Its prerequisite, `$(STAGE1)/.src-ready`, is a stamp that
means the source archive has been extracted into `.make/stage1`.

The recipe then enters the extracted tree with `$(MAKE) -C $(STAGE1)`.
`$(MAKE)` preserves recursive Make behavior such as jobserver flags. Stage 1
uses the extracted Makefile's normal `$(CC)` and `$(CFLAGS)` values, so
compiler sources are still built with the host warning policy.

The public `test` target follows the same extraction path but asks the
extracted Makefile to run `stage-test`. `test-all` is just an aggregate over
the stage 1 and stage 2 test commands.

## Stage 2 orchestration

```make
# Stage 2

$(STAGE2_CHIBICC): $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	$(MAKE) -C $(STAGE2) 'CC=$(abspath $(STAGE1_CHIBICC)) -Iinclude' \
		CFLAGS= stage-compiler

test-stage2: $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	$(MAKE) -C $(STAGE2) 'CC=$(abspath $(STAGE1_CHIBICC)) -Iinclude' \
		'TEST_LINK_CC=$(CC)' CFLAGS= stage-test
```

Stage 2 has two prerequisites: the stage 1 compiler and an extracted stage 2
source tree. Once both exist, the recursive Make call enters `.make/stage2`
and sets `CC` to the absolute stage 1 compiler path plus `-Iinclude`.

That `CC` value is the local stage's compiler-build driver. It compiles stage
2 compiler objects and links `.make/stage2/chibicc`. `CFLAGS=` keeps host-only
warning flags from being passed to chibicc while it is compiling stage 2. The
include path remains stage-local because the recursive call runs from inside
`.make/stage2`.

`test-stage2` asks the stage 2 extracted Makefile to run `stage-test`, so the
tests are compiled by `.make/stage2/chibicc` after that compiler has been
built. It also passes `TEST_LINK_CC=$(CC)` so the final test executable link
continues to use the host compiler, which accepts link options such as
`-pthread`.

## Stage extraction

```make
# Stage extraction

$(STAGE1)/.src-ready $(STAGE2)/.src-ready: $(DEFAULT_SRC_DIST)
	@case '$(@D)' in .make/*) ;; \
		*) echo 'refusing to prepare stage outside .make' >&2; exit 1;; \
	esac
	rm -rf $(@D) $(@D).unpack
	mkdir -p $(@D).unpack
	tar -xzf $(DEFAULT_SRC_DIST) -C $(@D).unpack
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

## Local compiler build

```make
# Local stage build

stage-compiler: $(LOCAL_CHIBICC)

$(LOCAL_CHIBICC): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: %.c chibicc.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<
```

`stage-compiler` is the local command target. It builds `chibicc` in whatever
tree Make is currently running in.

`$(LOCAL_CHIBICC)` links all compiler objects. `$@` is the output file
`chibicc`, and `$^` expands to all object prerequisites. `$(LDFLAGS)` remains
available for callers that need additional link flags.

The object rule maps each root `%.c` compiler source to `.o/%.o`. `$(@D)` is
`.o`, so the recipe creates the object directory before compiling. `$<` is
the first prerequisite, the matching source file. `chibicc.h` is also a
prerequisite so compiler objects rebuild when the shared header changes.

The compiler build uses `$(CC) $(CFLAGS)`. In stage 1, that is the host
compiler with the repository warning policy. In stage 2, the outer Makefile
sets `CC` to the stage 1 compiler and clears `CFLAGS`, so chibicc receives
only the stage-local include path.

## Local test build

```make
stage-test: $(TESTS)
	for i in $(TEST_EXEDIR)/*.exe; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(LOCAL_CHIBICC)

$(TEST_EXEDIR)/%.exe: $(LOCAL_CHIBICC) test/%.c test/shared/common.c
	mkdir -p $(@D) $(TEST_OBJDIR)
	./$(LOCAL_CHIBICC) -Iinclude -Itest -c -o $(TEST_OBJDIR)/$*.o test/$*.c
	$(TEST_LINK_CC) -pthread -o $@ $(TEST_OBJDIR)/$*.o test/shared/common.c
```

`stage-test` depends on every local test executable. Once they exist, it runs
each `test/.exe/*.exe` program, printing the executable path before running
it, and then runs `test/driver.sh` against the local `./chibicc`.

The executable rule depends on the local compiler, the test source, and the
shared C helper. `$*` is the pattern stem, such as `arith`, so the compile
step turns `test/arith.c` into `test/.o/arith.o`. The link step writes the
matching executable to `$@`, such as `test/.exe/arith.exe`.

The compile step always uses the local stage compiler. The link step uses
`$(TEST_LINK_CC)` without `$(CFLAGS)`, so stage 1 test helper warnings do not
become `-Werror` failures. Stage 2 overrides `TEST_LINK_CC` to the host
compiler because chibicc does not accept every linker option used here, such
as `-pthread`.

## Source distribution

```make
# Misc.

src-dist: $(SRC_DIST)

$(DEFAULT_SRC_DIST): $(DIST_FILES)
	mkdir -p $(dir $@) $(dir $(SRC_DIST_LIST))
	printf '%s\0' $(DIST_FILES) > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@

ifneq ($(SRC_DIST),$(DEFAULT_SRC_DIST))
$(SRC_DIST): $(DIST_FILES)
	mkdir -p $(dir $@) $(dir $(SRC_DIST_LIST))
	printf '%s\0' $(DIST_FILES) > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@
endif
```

`src-dist` is the public command target. By default it creates
`.make/chibicc.tar.gz`; callers can override `SRC_DIST` to write somewhere
else.

The archive target depends on every `DIST_FILES` entry. The recipe creates
the output directory and the temporary list directory, writes the explicit
file list as nul-delimited records, and gives that list to GNU tar with
`--null -T`.

`--transform` prefixes every archive member with `$(SRC_DIST_ROOT)/`, so the
tarball expands to a wrapping `chibicc/` directory. Stage extraction flattens
that wrapper by moving `chibicc/` to the requested stage path.

The conditional rule exists so `make src-dist SRC_DIST=/tmp/chibicc.tar.gz`
has a real file target separate from the default archive.

## Cleanup and phony targets

```make
clean:
	rm -rf chibicc .make .o tmp* test/.exe test/.o test/*.s test/*.exe
	rm -rf stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: clean src-dist stage-compiler stage-test test test-all test-stage2
```

`clean` removes local direct-stage outputs, extracted stage trees, source
archives, temporary test outputs, and stale root `stage2` output from the old
layout. The final `find` removes backup files and any leftover object files
outside the current directory layout.

Command targets are phony. Real file targets such as `$(DEFAULT_SRC_DIST)`,
`$(STAGE1_CHIBICC)`, `$(STAGE2_CHIBICC)`, local objects, and local test
executables are left as normal targets so Make can use timestamps to decide
what is stale.
