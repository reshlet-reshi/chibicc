# `Makefile`

Source: `Makefile`

This file is the top-level build, test, and source-distribution entrypoint. It
keeps repository-level policy in one place, then delegates the repeated
per-stage build graph to `stage.mk`.

## Global flags, stage paths, and source archive

```make
CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror
export CFLAGS

STAGE1=.make/stage1
STAGE2=.make/stage2
CHIBICC=$(STAGE1)/chibicc
STAGE2_CHIBICC=$(STAGE2)/chibicc
DEFAULT_SRC_DIST=.make/chibicc.tar.gz
SRC_DIST?=$(DEFAULT_SRC_DIST)
SRC_DIST_ROOT=chibicc
SRC_DIST_LIST=.make/src-dist.files
SRC_DIST_INPUTS=$(shell git ls-files -- . ':!meta' ':!.gitignore')
ROOT_SRC_INPUTS=$(foreach path,$(SRC_DIST_INPUTS),\
	$(if $(findstring /,$(path)),,$(path)))
TEST_SRC_INPUTS=$(foreach path,$(SRC_DIST_INPUTS),\
	$(if $(filter test/%,$(path)),\
		$(if $(findstring /,$(patsubst test/%,%,$(path))),,$(path))))
STAGE_SRCS=$(filter %.c,$(ROOT_SRC_INPUTS))
STAGE_TEST_SRCS=$(filter %.c,$(TEST_SRC_INPUTS))
```

`CFLAGS` is the shared host compiler flag set. It requests C11, debug
information, non-common global definitions, and most warnings while
suppressing switch warnings. `-Werror` promotes the remaining host compiler
warnings to build failures. `export CFLAGS` makes that default visible to
recursive `stage.mk` invocations.

`STAGE1` and `STAGE2` are the private stage roots under `.make/`. Each stage
now contains both an extracted source tree and generated outputs. `CHIBICC`
and `STAGE2_CHIBICC` name the compiler binary in each stage.

`DEFAULT_SRC_DIST` is the archive path used by stage builds. `SRC_DIST` is the
public archive path for `make src-dist`; `?=` keeps it overridable for that
command while defaulting to `DEFAULT_SRC_DIST`. `SRC_DIST_ROOT` is the
directory prefix used inside the tarball. `SRC_DIST_LIST` is the private,
nul-delimited file list used while building the archive.

`SRC_DIST_INPUTS` is a Make-time snapshot of tracked source paths outside
`meta/` and excluding `.gitignore`. The archive target depends on those paths,
so normal Make timestamp checks decide when `.make/chibicc.tar.gz` is stale.

`ROOT_SRC_INPUTS` keeps tracked root-level paths by discarding anything with a
slash. `TEST_SRC_INPUTS` keeps tracked direct `test/` children by discarding
anything with another slash after `test/`.

`STAGE_SRCS` and `STAGE_TEST_SRCS` then narrow those lists to C files.
Root-level C files become compiler sources. Direct `test/*.c` files become
test programs, while nested helpers such as `test/shared/common.c` stay in
the archive but are not treated as standalone tests.

## Stage 1 proxies

```make
# Stage 1

$(CHIBICC): $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		compiler

test: $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		test
```

The first real target is `$(CHIBICC)`, so plain `make` builds the stage 1
compiler. It depends on `$(DEFAULT_SRC_DIST)`, the real source archive used by
stage builds. When the archive is missing or older than a tracked source
input, Make rebuilds the archive before entering the stage submake.

Both recipes call `$(MAKE) -f stage.mk`. `$(MAKE)` preserves Make flags and
jobserver settings across recursion. The submake receives the stage root, the
absolute archive path, the tarball root name, the tracked source lists, and
the compiler commands for that stage.

`STAGE_CC=$(CC) $(CFLAGS)` means stage 1 compiler objects are built with the
host C compiler. `STAGE_TEST_CC=./chibicc -Iinclude -Itest` is stage-local
because `stage.mk` runs the recipe from inside `.make/stage1`.

The top-level `test` target is phony, so asking for `make test` always enters
the submake. The submake still decides which stage files are stale.

## Combined test target

```make
test-all: test test-stage2
```

`test-all` is an aggregate command target. It succeeds when both stage 1 and
stage 2 tests succeed.

## Stage 2 proxies

```make
# Stage 2

$(STAGE2_CHIBICC): $(CHIBICC) $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(abspath $(CHIBICC)) -Iinclude' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(abspath $(CHIBICC)) \
		compiler

test-stage2: $(CHIBICC) $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(abspath $(CHIBICC)) -Iinclude' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(abspath $(CHIBICC)) \
		test
```

Stage 2 depends on both the source archive and the stage 1 compiler. The
archive supplies the source tree that will be unpacked into `.make/stage2`.
The stage 1 compiler supplies the compiler used to produce stage 2 compiler
objects.

`STAGE_CC` is absolute because stage 2 recipes run from inside
`.make/stage2`, not the repository root. `-Iinclude` is intentionally
stage-local, so the stage 1 compiler reads headers from the extracted stage 2
source tree. `STAGE_OBJ_DEPS` makes stage 2 compiler objects stale when the
stage 1 compiler changes.

`STAGE_TEST_CC=./chibicc -Iinclude -Itest` uses the stage 2 compiler from
inside `.make/stage2` to compile the stage 2 test objects.

## Source distribution and cleanup

```make
# Misc.

src-dist: $(SRC_DIST)

$(DEFAULT_SRC_DIST): $(SRC_DIST_INPUTS)
	mkdir -p $(dir $@) .make
	git ls-files -z -- . ':!meta' ':!.gitignore' > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@

ifneq ($(SRC_DIST),$(DEFAULT_SRC_DIST))
$(SRC_DIST): $(SRC_DIST_INPUTS)
	mkdir -p $(dir $@) .make
	git ls-files -z -- . ':!meta' ':!.gitignore' > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@
endif

clean:
	rm -rf chibicc .make tmp* test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'
```

`src-dist` is the public command target. It depends on `$(SRC_DIST)`, so
callers can override the archive path for that command. Stage builds still use
`$(DEFAULT_SRC_DIST)`.

The archive recipe creates the output directory and `.make/`, writes the
tracked source list to `$(SRC_DIST_LIST)`, and feeds that nul-delimited list
to GNU tar. `--transform` prefixes every archive member with
`$(SRC_DIST_ROOT)/`, so extracting the tarball creates a wrapping `chibicc/`
directory.

`clean` removes generated build and test outputs, including the source
archive and extracted stage trees under `.make/`. It also removes stale root
outputs from older layouts.

## Phony targets

```make
.PHONY: test clean test-stage2 test-all src-dist
```

Only command targets are phony. File targets such as `$(SRC_DIST)`,
`$(CHIBICC)`, and `$(STAGE2_CHIBICC)` are left as real targets so normal Make
timestamp checks can decide whether they are stale.
