# `stage.mk`

Source: `stage.mk`

This file is the reusable build graph for one compiler stage. The top-level
`Makefile` invokes it recursively and passes variables that describe which
stage is being built and which compiler command should be used for that
stage.

## Required variables

```make
ifndef STAGE
$(error STAGE is required)
endif
ifndef STAGE_CC
$(error STAGE_CC is required)
endif
ifndef STAGE_TEST_CC
$(error STAGE_TEST_CC is required)
endif
ifndef STAGE_OBJ_DEPS
$(error STAGE_OBJ_DEPS is required)
endif
```

These guards make `stage.mk` fail early if it is invoked without the contract
expected by the top-level `Makefile`.

`STAGE` is the output root, such as `.make/stage1` or `.make/stage2`.
`STAGE_CC` is the command used to compile compiler objects for this stage.
`STAGE_TEST_CC` is the command used to compile test objects for this stage.
`STAGE_OBJ_DEPS` is appended to every compiler-object rule, giving the caller
a way to express extra dependencies such as `chibicc.h` or the previous stage
compiler.

## Source discovery and derived paths

```make
SRCS=$(wildcard *.c)
TEST_SRCS=$(wildcard test/*.c)

CHIBICC=$(STAGE)/chibicc
OBJDIR=$(STAGE)/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
TEST_OBJDIR=$(STAGE)/test/.o
TEST_EXEDIR=$(STAGE)/test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)
```

`SRCS` discovers top-level compiler sources. `TEST_SRCS` discovers C tests
under `test/`.

Every other variable is derived from `STAGE`. `CHIBICC` is the compiler
binary for this stage. `OBJDIR` is the compiler-object directory, and `OBJS`
maps each top-level source to an object under that directory. For example,
with `STAGE=.make/stage2`, `parse.c` becomes `.make/stage2/.o/parse.o`.

`TEST_OBJDIR` and `TEST_EXEDIR` are the corresponding test object and test
executable directories. `TESTS` maps `test/*.c` sources into executable paths
under `$(STAGE)/test/.exe/`.

## Compiler target and link rule

```make
compiler: $(CHIBICC)

$(CHIBICC): $(OBJS)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
```

`compiler` is the public submake target for building the stage compiler. It
depends on `$(CHIBICC)`, the actual compiler binary path for the selected
stage.

The `$(CHIBICC)` rule links all compiler objects. `$(@D)` is the directory
part of the target, so `mkdir -p $(@D)` creates `.make/stage1` or
`.make/stage2` before linking. `$@` is the target path. `$^` is the complete
list of object prerequisites.

The link step intentionally uses the host C compiler through `$(CC)`, even
for stage 2. Stage selection controls which compiler produces the object
files; the final executable link remains a host linker operation.

## Compiler object rule

```make
$(OBJDIR)/%.o: %.c $(STAGE_OBJ_DEPS)
	mkdir -p $(@D)
	$(STAGE_CC) -c -o $@ $<
```

This pattern rule builds one compiler object. The target pattern is
`$(OBJDIR)/%.o`, so `parse.c` maps to `.make/stage1/.o/parse.o` for stage 1
or `.make/stage2/.o/parse.o` for stage 2.

`$(@D)` is the output directory for the object file. `$@` is the object path
to write. `$<` is the first prerequisite, which is the matching source file.
The extra prerequisites from `$(STAGE_OBJ_DEPS)` are dependencies only; they
do not replace `$<`.

`$(STAGE_CC)` is supplied by the top-level `Makefile`. For stage 1 it expands
to the host compiler plus `$(CFLAGS)`. For stage 2 it expands to the stage 1
compiler plus `-Iinclude`.

## Test executable rule

```make
$(TEST_EXEDIR)/%.exe: $(CHIBICC) test/%.c test/shared/common.c
	mkdir -p $(@D) $(TEST_OBJDIR)
	$(STAGE_TEST_CC) -c -o $(TEST_OBJDIR)/$*.o test/$*.c
	$(CC) -pthread -o $@ $(TEST_OBJDIR)/$*.o test/shared/common.c
```

This rule turns one `test/*.c` source into one executable under the selected
stage's test executable directory. The `%` stem is exposed as `$*`. For
`.make/stage2/test/.exe/arith.exe`, `$*` is `arith`.

The prerequisites require the stage compiler, the matching test source, and
`test/shared/common.c`. The first recipe line creates both the executable
directory and the object directory.

`$(STAGE_TEST_CC)` compiles the test source into `$(TEST_OBJDIR)/$*.o`. Stage
1 receives the stage 1 compiler command; stage 2 receives the stage 2 compiler
command. The link step then uses the host C compiler with `-pthread` to write
`$@`, the final executable path.

## Test target

```make
test: $(TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(CHIBICC)
```

`test` depends on every discovered test executable for the selected stage, so
the submake builds the complete stage test suite before running it.

Inside the loop, `$^` expands to the list of test executables. The shell
variable is written as `$$i` because Make consumes single-dollar variables
before the shell sees the command. Each executable is printed, run, and allowed
to stop the loop with `exit 1` on failure.

After the compiled tests pass, `test/driver.sh` runs against the compiler
binary for the selected stage. That shell driver covers command-line behavior
that is easier to express outside the C test binaries.

## Phony targets

```make
.PHONY: compiler test
```

`compiler` and `test` are command targets exported by `stage.mk`; they are not
files that should be checked on disk. Marking them phony keeps recursive make
calls direct and predictable.
