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

DIST_ROOT_FILES=\
	LICENSE \
	Makefile \
	README.md \
	chibicc.h

COMPILER_SRCS=\
	codegen.c \
	hashmap.c \
	main.c \
	parse.c \
	preprocess.c \
	strings.c \
	tokenize.c \
	type.c \
	unicode.c

DIST_INCLUDE_FILES=\
	include/float.h \
	include/stdalign.h \
	include/stdarg.h \
	include/stdatomic.h \
	include/stdbool.h \
	include/stddef.h \
	include/stdnoreturn.h

TEST_FILES=\
	test/alignof.c \
	test/alloca.c \
	test/arith.c \
	test/asm.c \
	test/atomic.c \
	test/attribute.c \
	test/bitfield.c \
	test/builtin.c \
	test/cast.c \
	test/commonsym.c \
	test/compat.c \
	test/complit.c \
	test/const.c \
	test/constexpr.c \
	test/control.c \
	test/decl.c \
	test/driver.sh \
	test/enum.c \
	test/extern.c \
	test/float.c \
	test/function.c \
	test/generic.c \
	test/include1.h \
	test/include2.h \
	test/include3.h \
	test/include4.h \
	test/initializer.c \
	test/line.c \
	test/literal.c \
	test/macro.c \
	test/offsetof.c \
	test/pointer.c \
	test/pragma-once.c \
	test/shared/common.c \
	test/sizeof.c \
	test/stdhdr.c \
	test/string.c \
	test/struct.c \
	test/test.h \
	test/thirdparty/common.sh.inc \
	test/thirdparty/cpython.sh \
	test/thirdparty/git.sh \
	test/thirdparty/libpng.sh \
	test/thirdparty/sqlite.sh \
	test/thirdparty/tinycc.sh \
	test/tls.c \
	test/typedef.c \
	test/typeof.c \
	test/unicode.c \
	test/union.c \
	test/usualconv.c \
	test/varargs.c \
	test/variable.c \
	test/vla.c

DIST_FILES=$(DIST_ROOT_FILES) $(COMPILER_SRCS) $(DIST_INCLUDE_FILES) \
	$(TEST_FILES)

TEST_SRCS=$(foreach path,$(filter test/%.c,$(TEST_FILES)),\
	$(if $(findstring /,$(patsubst test/%,%,$(path))),,$(path)))

LOCAL_CHIBICC=chibicc
OBJDIR=.o
OBJS=$(COMPILER_SRCS:%.c=$(OBJDIR)/%.o)
TEST_OBJDIR=test/.o
TEST_EXEDIR=test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)
TEST_LINK_CC?=$(CC)

# Stage 1

$(STAGE1_CHIBICC): $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) stage-compiler

test: $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) stage-test

test-all: test test-stage2

# Stage 2

$(STAGE2_CHIBICC): $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	$(MAKE) -C $(STAGE2) 'CC=$(abspath $(STAGE1_CHIBICC)) -Iinclude' \
		CFLAGS= stage-compiler

test-stage2: $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	$(MAKE) -C $(STAGE2) 'CC=$(abspath $(STAGE1_CHIBICC)) -Iinclude' \
		'TEST_LINK_CC=$(CC)' CFLAGS= stage-test

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

# Local stage build

stage-compiler: $(LOCAL_CHIBICC)

$(LOCAL_CHIBICC): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: %.c chibicc.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

stage-test: $(TESTS)
	for i in $(TEST_EXEDIR)/*.exe; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(LOCAL_CHIBICC)

$(TEST_EXEDIR)/%.exe: $(LOCAL_CHIBICC) test/%.c test/shared/common.c
	mkdir -p $(@D) $(TEST_OBJDIR)
	./$(LOCAL_CHIBICC) -Iinclude -Itest -c -o $(TEST_OBJDIR)/$*.o test/$*.c
	$(TEST_LINK_CC) -pthread -o $@ $(TEST_OBJDIR)/$*.o test/shared/common.c

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

clean:
	rm -rf chibicc .make .o tmp* test/.exe test/.o test/*.s test/*.exe
	rm -rf stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: clean src-dist stage-compiler stage-test test test-all test-stage2
