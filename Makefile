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
TEST_DEPS=\
	test/test.h \
	test/include1.h \
	test/include2.h \
	test/include3.h \
	test/include4.h \
	include/float.h \
	include/stdalign.h \
	include/stdarg.h \
	include/stdatomic.h \
	include/stdbool.h \
	include/stddef.h \
	include/stdnoreturn.h

test/shared/common.o: chibicc test/shared/common.c
	./chibicc -Itest -c -o test/shared/common.o test/shared/common.c

test-compiler: test-compiler-exes test-compiler-driver

test-compiler-exes: $(TESTS)
	for i in $(TESTS); do echo $$i; ./$$i || exit 1; echo; done

test/alignof.exe: chibicc test/alignof.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/alignof.o test/alignof.c
	$(TEST_LINK_CC) -pthread -o test/alignof.exe test/alignof.o \
		test/shared/common.o

test/alloca.exe: chibicc test/alloca.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/alloca.o test/alloca.c
	$(TEST_LINK_CC) -pthread -o test/alloca.exe test/alloca.o \
		test/shared/common.o

test/arith.exe: chibicc test/arith.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/arith.o test/arith.c
	$(TEST_LINK_CC) -pthread -o test/arith.exe test/arith.o \
		test/shared/common.o

test/asm.exe: chibicc test/asm.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/asm.o test/asm.c
	$(TEST_LINK_CC) -pthread -o test/asm.exe test/asm.o \
		test/shared/common.o

test/atomic.exe: chibicc test/atomic.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/atomic.o test/atomic.c
	$(TEST_LINK_CC) -pthread -o test/atomic.exe test/atomic.o \
		test/shared/common.o

test/attribute.exe: chibicc test/attribute.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/attribute.o test/attribute.c
	$(TEST_LINK_CC) -pthread -o test/attribute.exe test/attribute.o \
		test/shared/common.o

test/bitfield.exe: chibicc test/bitfield.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/bitfield.o test/bitfield.c
	$(TEST_LINK_CC) -pthread -o test/bitfield.exe test/bitfield.o \
		test/shared/common.o

test/builtin.exe: chibicc test/builtin.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/builtin.o test/builtin.c
	$(TEST_LINK_CC) -pthread -o test/builtin.exe test/builtin.o \
		test/shared/common.o

test/cast.exe: chibicc test/cast.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/cast.o test/cast.c
	$(TEST_LINK_CC) -pthread -o test/cast.exe test/cast.o \
		test/shared/common.o

test/commonsym.exe: chibicc test/commonsym.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/commonsym.o test/commonsym.c
	$(TEST_LINK_CC) -pthread -o test/commonsym.exe test/commonsym.o \
		test/shared/common.o

test/compat.exe: chibicc test/compat.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/compat.o test/compat.c
	$(TEST_LINK_CC) -pthread -o test/compat.exe test/compat.o \
		test/shared/common.o

test/complit.exe: chibicc test/complit.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/complit.o test/complit.c
	$(TEST_LINK_CC) -pthread -o test/complit.exe test/complit.o \
		test/shared/common.o

test/const.exe: chibicc test/const.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/const.o test/const.c
	$(TEST_LINK_CC) -pthread -o test/const.exe test/const.o \
		test/shared/common.o

test/constexpr.exe: chibicc test/constexpr.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/constexpr.o test/constexpr.c
	$(TEST_LINK_CC) -pthread -o test/constexpr.exe test/constexpr.o \
		test/shared/common.o

test/control.exe: chibicc test/control.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/control.o test/control.c
	$(TEST_LINK_CC) -pthread -o test/control.exe test/control.o \
		test/shared/common.o

test/decl.exe: chibicc test/decl.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/decl.o test/decl.c
	$(TEST_LINK_CC) -pthread -o test/decl.exe test/decl.o \
		test/shared/common.o

test/enum.exe: chibicc test/enum.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/enum.o test/enum.c
	$(TEST_LINK_CC) -pthread -o test/enum.exe test/enum.o \
		test/shared/common.o

test/extern.exe: chibicc test/extern.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/extern.o test/extern.c
	$(TEST_LINK_CC) -pthread -o test/extern.exe test/extern.o \
		test/shared/common.o

test/float.exe: chibicc test/float.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/float.o test/float.c
	$(TEST_LINK_CC) -pthread -o test/float.exe test/float.o \
		test/shared/common.o

test/function.exe: chibicc test/function.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/function.o test/function.c
	$(TEST_LINK_CC) -pthread -o test/function.exe test/function.o \
		test/shared/common.o

test/generic.exe: chibicc test/generic.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/generic.o test/generic.c
	$(TEST_LINK_CC) -pthread -o test/generic.exe test/generic.o \
		test/shared/common.o

test/initializer.exe: chibicc test/initializer.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/initializer.o test/initializer.c
	$(TEST_LINK_CC) -pthread -o test/initializer.exe test/initializer.o \
		test/shared/common.o

test/line.exe: chibicc test/line.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/line.o test/line.c
	$(TEST_LINK_CC) -pthread -o test/line.exe test/line.o \
		test/shared/common.o

test/literal.exe: chibicc test/literal.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/literal.o test/literal.c
	$(TEST_LINK_CC) -pthread -o test/literal.exe test/literal.o \
		test/shared/common.o

test/macro.exe: chibicc test/macro.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/macro.o test/macro.c
	$(TEST_LINK_CC) -pthread -o test/macro.exe test/macro.o \
		test/shared/common.o

test/offsetof.exe: chibicc test/offsetof.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/offsetof.o test/offsetof.c
	$(TEST_LINK_CC) -pthread -o test/offsetof.exe test/offsetof.o \
		test/shared/common.o

test/pointer.exe: chibicc test/pointer.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/pointer.o test/pointer.c
	$(TEST_LINK_CC) -pthread -o test/pointer.exe test/pointer.o \
		test/shared/common.o

test/pragma-once.exe: chibicc test/pragma-once.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/pragma-once.o test/pragma-once.c
	$(TEST_LINK_CC) -pthread -o test/pragma-once.exe test/pragma-once.o \
		test/shared/common.o

test/sizeof.exe: chibicc test/sizeof.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/sizeof.o test/sizeof.c
	$(TEST_LINK_CC) -pthread -o test/sizeof.exe test/sizeof.o \
		test/shared/common.o

test/stdhdr.exe: chibicc test/stdhdr.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/stdhdr.o test/stdhdr.c
	$(TEST_LINK_CC) -pthread -o test/stdhdr.exe test/stdhdr.o \
		test/shared/common.o

test/string.exe: chibicc test/string.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/string.o test/string.c
	$(TEST_LINK_CC) -pthread -o test/string.exe test/string.o \
		test/shared/common.o

test/struct.exe: chibicc test/struct.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/struct.o test/struct.c
	$(TEST_LINK_CC) -pthread -o test/struct.exe test/struct.o \
		test/shared/common.o

test/tls.exe: chibicc test/tls.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/tls.o test/tls.c
	$(TEST_LINK_CC) -pthread -o test/tls.exe test/tls.o \
		test/shared/common.o

test/typedef.exe: chibicc test/typedef.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/typedef.o test/typedef.c
	$(TEST_LINK_CC) -pthread -o test/typedef.exe test/typedef.o \
		test/shared/common.o

test/typeof.exe: chibicc test/typeof.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/typeof.o test/typeof.c
	$(TEST_LINK_CC) -pthread -o test/typeof.exe test/typeof.o \
		test/shared/common.o

test/unicode.exe: chibicc test/unicode.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/unicode.o test/unicode.c
	$(TEST_LINK_CC) -pthread -o test/unicode.exe test/unicode.o \
		test/shared/common.o

test/union.exe: chibicc test/union.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/union.o test/union.c
	$(TEST_LINK_CC) -pthread -o test/union.exe test/union.o \
		test/shared/common.o

test/usualconv.exe: chibicc test/usualconv.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/usualconv.o test/usualconv.c
	$(TEST_LINK_CC) -pthread -o test/usualconv.exe test/usualconv.o \
		test/shared/common.o

test/varargs.exe: chibicc test/varargs.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/varargs.o test/varargs.c
	$(TEST_LINK_CC) -pthread -o test/varargs.exe test/varargs.o \
		test/shared/common.o

test/variable.exe: chibicc test/variable.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/variable.o test/variable.c
	$(TEST_LINK_CC) -pthread -o test/variable.exe test/variable.o \
		test/shared/common.o

test/vla.exe: chibicc test/vla.c test/shared/common.o \
	$(TEST_DEPS)
	./chibicc -Itest -c -o test/vla.o test/vla.c
	$(TEST_LINK_CC) -pthread -o test/vla.exe test/vla.o \
		test/shared/common.o

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

test: $(STAGE1_CHIBICC)
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
