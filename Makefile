default: chibicc

all: test-all

CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror

SRCS=\
	codegen.c \
	hashmap.c \
	main.c \
	parse.c \
	preprocess.c \
	strings.c \
	tokenize.c \
	type.c \
	unicode.c

OBJS=$(SRCS:.c=.o)

chibicc: $(OBJS)
	$(CC) $(CFLAGS) -o chibicc $(OBJS)

codegen.o: codegen.c chibicc.h
	$(CC) $(CFLAGS) -c -o codegen.o codegen.c

hashmap.o: hashmap.c chibicc.h
	$(CC) $(CFLAGS) -c -o hashmap.o hashmap.c

main.o: main.c chibicc.h
	$(CC) $(CFLAGS) -c -o main.o main.c

parse.o: parse.c chibicc.h
	$(CC) $(CFLAGS) -c -o parse.o parse.c

preprocess.o: preprocess.c chibicc.h
	$(CC) $(CFLAGS) -c -o preprocess.o preprocess.c

strings.o: strings.c chibicc.h
	$(CC) $(CFLAGS) -c -o strings.o strings.c

tokenize.o: tokenize.c chibicc.h
	$(CC) $(CFLAGS) -c -o tokenize.o tokenize.c

type.o: type.c chibicc.h
	$(CC) $(CFLAGS) -c -o type.o type.c

unicode.o: unicode.c chibicc.h
	$(CC) $(CFLAGS) -c -o unicode.o unicode.c

TEST_SRCS=\
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
	test/enum.c \
	test/extern.c \
	test/float.c \
	test/function.c \
	test/generic.c \
	test/initializer.c \
	test/line.c \
	test/literal.c \
	test/macro.c \
	test/offsetof.c \
	test/pointer.c \
	test/pragma-once.c \
	test/sizeof.c \
	test/stdhdr.c \
	test/string.c \
	test/struct.c \
	test/tls.c \
	test/typedef.c \
	test/typeof.c \
	test/unicode.c \
	test/union.c \
	test/usualconv.c \
	test/varargs.c \
	test/variable.c \
	test/vla.c

TESTS=$(TEST_SRCS:.c=.exe)
TEST_LINK_CC?=$(CC)

test/shared/common.o: chibicc test/shared/common.c
	./chibicc -Itest -c -o test/shared/common.o test/shared/common.c

test-compiler: test-compiler-exes test-compiler-driver

test-compiler-exes: chibicc test/shared/common.o
	for src in $(TEST_SRCS); do \
		stem=$${src#test/}; \
		stem=$${stem%.c}; \
		obj=test/$$stem.o; \
		exe=test/$$stem.exe; \
		./chibicc -Itest -c -o $$obj $$src || exit 1; \
		$(TEST_LINK_CC) -pthread -o $$exe $$obj test/shared/common.o \
			|| exit 1; \
	done
	for i in $(TESTS); do echo $$i; ./$$i || exit 1; echo; done

test-compiler-driver: chibicc test/driver.sh
	test/driver.sh ./chibicc

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
	include/stdarg.h \
	include/stdatomic.h \
	include/stdbool.h \
	include/stddef.h \
	include/stdnoreturn.h

TEST_FILES=\
	$(TEST_SRCS) \
	test/driver.sh \
	test/include1.h \
	test/include2.h \
	test/include3.h \
	test/include4.h \
	test/shared/common.c \
	test/test.h \
	test/thirdparty/common.sh.inc \
	test/thirdparty/cpython.sh \
	test/thirdparty/git.sh \
	test/thirdparty/libpng.sh \
	test/thirdparty/sqlite.sh \
	test/thirdparty/tinycc.sh

DIST_FILES=\
	$(DIST_ROOT_FILES) \
	$(SRCS) \
	$(DIST_INCLUDE_FILES) \
	$(TEST_FILES)

$(SRC_DIST): $(DIST_FILES)
	mkdir -p "$$(dirname "$@")" "$$(dirname "$(SRC_DIST_LIST)")"
	printf '%s\0' $(DIST_FILES) > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@

src-dist: $(SRC_DIST)

STAGE1=.make/stage1
STAGE1_CHIBICC=$(STAGE1)/chibicc

$(STAGE1_CHIBICC): $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) chibicc

test: $(STAGE1)/.src-ready
	$(MAKE) -C $(STAGE1) test-compiler

test-all: test test-stage2

STAGE2=.make/stage2
STAGE2_CHIBICC=$(STAGE2)/chibicc

$(STAGE2_CHIBICC): $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	STAGE1_CHIBICC=$$(pwd)/$(STAGE1_CHIBICC); \
		$(MAKE) -C $(STAGE2) "CC=$$STAGE1_CHIBICC" \
			CFLAGS= chibicc

test-stage2: $(STAGE1_CHIBICC) $(STAGE2)/.src-ready
	STAGE1_CHIBICC=$$(pwd)/$(STAGE1_CHIBICC); \
		$(MAKE) -C $(STAGE2) "CC=$$STAGE1_CHIBICC" \
			"TEST_LINK_CC=$(CC)" CFLAGS= test-compiler

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

clean:
	rm -rf chibicc .make .o tmp* test/.exe test/.o test/*.s test/*.exe
	rm -rf stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: all clean default src-dist test test-compiler
.PHONY: test-compiler-driver test-compiler-exes
.PHONY: test-all test-stage2
