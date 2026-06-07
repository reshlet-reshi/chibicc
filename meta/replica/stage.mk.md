# `stage.mk`

Source: `stage.mk`

This file is the reusable build graph for one compiler stage. The top-level
`Makefile` invokes it recursively with the selected stage root, source
archive, and compiler commands.

## Required variables

```make
ifndef STAGE
$(error STAGE is required)
endif
ifndef SRC_DIST
$(error SRC_DIST is required)
endif
ifndef SRC_DIST_ROOT
$(error SRC_DIST_ROOT is required)
endif
ifndef STAGE_SRCS
$(error STAGE_SRCS is required)
endif
ifndef STAGE_TEST_SRCS
$(error STAGE_TEST_SRCS is required)
endif
ifndef STAGE_CC
$(error STAGE_CC is required)
endif
ifndef STAGE_TEST_CC
$(error STAGE_TEST_CC is required)
endif
```

`STAGE` is the output and extracted-source root, such as `.make/stage1`.
`SRC_DIST` is the absolute source archive path to unpack. `SRC_DIST_ROOT` is
the wrapped directory name inside the tarball. `STAGE_SRCS` and
`STAGE_TEST_SRCS` are tracked source lists supplied by the top-level
`Makefile`. `STAGE_CC` compiles compiler objects. `STAGE_TEST_CC` compiles
test objects. `STAGE_OBJ_DEPS` is optional and is used by stage 2 to depend
on the stage 1 compiler.

## Source names and stage paths

```make
SRCS=$(STAGE_SRCS)
TEST_SRCS=$(STAGE_TEST_SRCS)

SRC_READY=$(STAGE)/.src-ready
UNPACK=$(STAGE).unpack
CHIBICC=$(STAGE)/chibicc
OBJDIR=$(STAGE)/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
TEST_OBJDIR=$(STAGE)/test/.o
TEST_EXEDIR=$(STAGE)/test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)
```

`SRCS` and `TEST_SRCS` come from the tracked source archive input list rather
than from working-tree wildcards. They are used only to derive target names.
The recipes compile and link from the extracted stage source tree.

`SRC_READY` is the stamp proving that the source archive has been unpacked
and flattened into `$(STAGE)`. `UNPACK` is a temporary extraction directory.
All compiler and test output paths are derived from `$(STAGE)`.

## Stage preparation

```make
compiler: $(CHIBICC)

$(SRC_READY): $(SRC_DIST)
	@case '$(STAGE)' in .make/*) ;; \
		*) echo 'refusing to prepare stage outside .make' >&2; exit 1;; \
	esac
	rm -rf $(STAGE) $(UNPACK)
	mkdir -p $(UNPACK)
	tar -xzf $(SRC_DIST) -C $(UNPACK)
	mv $(UNPACK)/$(SRC_DIST_ROOT) $(STAGE)
	rm -rf $(UNPACK)
	touch $@
```

`compiler` is the public submake target for building the selected stage
compiler.

`$(SRC_READY)` depends on the source archive. If the archive is newer than the
stamp, the stage is rebuilt from a fresh extract. The guard rejects stage
paths outside `.make/` before running `rm -rf`.

The recipe extracts the wrapped archive into `$(UNPACK)`, moves the unpacked
`$(SRC_DIST_ROOT)` directory into `$(STAGE)`, removes the temporary unpack
directory, and touches the stamp. After this rule, `$(STAGE)` contains the
source files plus any generated outputs added by later rules.

## Compiler build

```make
$(CHIBICC): $(OBJS)
	cd $(STAGE) && $(CC) $(CFLAGS) -o chibicc \
		$(abspath $^) $(LDFLAGS)

$(OBJDIR)/%.o: $(SRC_READY) $(STAGE_OBJ_DEPS)
	mkdir -p $(@D)
	cd $(STAGE) && $(STAGE_CC) -c -o $(abspath $@) $*.c
```

The compiler binary target links all compiler objects. The link command runs
from inside `$(STAGE)` and writes the stage-local `chibicc` executable.
`$(abspath $^)` converts object prerequisites to absolute paths, which remain
valid after changing directories.

The compiler object rule depends on `$(SRC_READY)`, so objects rebuild after a
fresh source extract. It also depends on optional `$(STAGE_OBJ_DEPS)`, used by
stage 2 to rebuild objects when the stage 1 compiler changes.

The compile command also runs from inside `$(STAGE)`. `$*.c` is therefore the
stage-local source file, while `$(abspath $@)` writes the object back to the
absolute target path.

## Test build and run

```make
$(TEST_EXEDIR)/%.exe: $(CHIBICC) $(SRC_READY)
	mkdir -p $(@D) $(TEST_OBJDIR)
	cd $(STAGE) && \
		$(STAGE_TEST_CC) -c -o test/.o/$*.o test/$*.c
	cd $(STAGE) && \
		$(CC) -pthread -o test/.exe/$*.exe \
		test/.o/$*.o test/shared/common.c

test: $(TESTS)
	cd $(STAGE) && \
		for i in test/.exe/*.exe; do echo $$i; ./$$i || exit 1; echo; done
	cd $(STAGE) && test/driver.sh ./chibicc
```

Each test executable depends on the stage compiler and the source-ready stamp.
The compile step uses `$(STAGE_TEST_CC)` from inside the stage source tree and
writes the object under `test/.o/`. The link step writes the executable under
`test/.exe/` with the host compiler and `-pthread`.

The `test` target depends on all discovered test executables, then changes
into the stage directory to run them. The shell driver also runs from inside
the stage and receives `./chibicc`, the compiler binary for that same stage.

## Phony targets

```make
.PHONY: compiler test
```

`compiler` and `test` are command targets exported by `stage.mk`; they are not
files to check on disk.
