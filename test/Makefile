default: test-compiler

all: test-compiler

CHIBICC?=../chibicc
CHIBICC_FROM_ROOT?=./chibicc

TEST_SRCS=\
	alignof.c \
	alloca.c \
	arith.c \
	asm.c \
	atomic.c \
	attribute.c \
	bitfield.c \
	builtin.c \
	cast.c \
	commonsym.c \
	compat.c \
	complit.c \
	const.c \
	constexpr.c \
	control.c \
	decl.c \
	enum.c \
	extern.c \
	float.c \
	function.c \
	generic.c \
	initializer.c \
	line.c \
	literal.c \
	macro.c \
	offsetof.c \
	pointer.c \
	pragma-once.c \
	sizeof.c \
	stdhdr.c \
	string.c \
	struct.c \
	tls.c \
	typedef.c \
	typeof.c \
	unicode.c \
	union.c \
	usualconv.c \
	varargs.c \
	variable.c \
	vla.c

TESTS=$(TEST_SRCS:.c=.exe)
TEST_LINK_CC?=$(CC)
TEST_DEPS=\
	test.h \
	include1.h \
	include2.h \
	include3.h \
	include4.h \
	../include/float.h \
	../include/stdalign.h \
	../include/stdarg.h \
	../include/stdatomic.h \
	../include/stdbool.h \
	../include/stddef.h \
	../include/stdnoreturn.h

shared/common.o: $(CHIBICC) shared/common.c
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c \
		-o test/shared/common.o test/shared/common.c

test-compiler: test-compiler-exes test-compiler-driver

test-compiler-exes: $(TESTS)
	for i in $(TESTS); do echo $$i; ./$$i || exit 1; echo; done

alignof.exe: $(CHIBICC) alignof.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/alignof.o test/alignof.c
	$(TEST_LINK_CC) -pthread -o alignof.exe alignof.o shared/common.o

alloca.exe: $(CHIBICC) alloca.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/alloca.o test/alloca.c
	$(TEST_LINK_CC) -pthread -o alloca.exe alloca.o shared/common.o

arith.exe: $(CHIBICC) arith.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/arith.o test/arith.c
	$(TEST_LINK_CC) -pthread -o arith.exe arith.o shared/common.o

asm.exe: $(CHIBICC) asm.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/asm.o test/asm.c
	$(TEST_LINK_CC) -pthread -o asm.exe asm.o shared/common.o

atomic.exe: $(CHIBICC) atomic.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/atomic.o test/atomic.c
	$(TEST_LINK_CC) -pthread -o atomic.exe atomic.o shared/common.o

attribute.exe: $(CHIBICC) attribute.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/attribute.o test/attribute.c
	$(TEST_LINK_CC) -pthread -o attribute.exe attribute.o shared/common.o

bitfield.exe: $(CHIBICC) bitfield.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/bitfield.o test/bitfield.c
	$(TEST_LINK_CC) -pthread -o bitfield.exe bitfield.o shared/common.o

builtin.exe: $(CHIBICC) builtin.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/builtin.o test/builtin.c
	$(TEST_LINK_CC) -pthread -o builtin.exe builtin.o shared/common.o

cast.exe: $(CHIBICC) cast.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/cast.o test/cast.c
	$(TEST_LINK_CC) -pthread -o cast.exe cast.o shared/common.o

commonsym.exe: $(CHIBICC) commonsym.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/commonsym.o test/commonsym.c
	$(TEST_LINK_CC) -pthread -o commonsym.exe commonsym.o shared/common.o

compat.exe: $(CHIBICC) compat.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/compat.o test/compat.c
	$(TEST_LINK_CC) -pthread -o compat.exe compat.o shared/common.o

complit.exe: $(CHIBICC) complit.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/complit.o test/complit.c
	$(TEST_LINK_CC) -pthread -o complit.exe complit.o shared/common.o

const.exe: $(CHIBICC) const.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/const.o test/const.c
	$(TEST_LINK_CC) -pthread -o const.exe const.o shared/common.o

constexpr.exe: $(CHIBICC) constexpr.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/constexpr.o test/constexpr.c
	$(TEST_LINK_CC) -pthread -o constexpr.exe constexpr.o shared/common.o

control.exe: $(CHIBICC) control.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/control.o test/control.c
	$(TEST_LINK_CC) -pthread -o control.exe control.o shared/common.o

decl.exe: $(CHIBICC) decl.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/decl.o test/decl.c
	$(TEST_LINK_CC) -pthread -o decl.exe decl.o shared/common.o

enum.exe: $(CHIBICC) enum.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/enum.o test/enum.c
	$(TEST_LINK_CC) -pthread -o enum.exe enum.o shared/common.o

extern.exe: $(CHIBICC) extern.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/extern.o test/extern.c
	$(TEST_LINK_CC) -pthread -o extern.exe extern.o shared/common.o

float.exe: $(CHIBICC) float.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/float.o test/float.c
	$(TEST_LINK_CC) -pthread -o float.exe float.o shared/common.o

function.exe: $(CHIBICC) function.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/function.o test/function.c
	$(TEST_LINK_CC) -pthread -o function.exe function.o shared/common.o

generic.exe: $(CHIBICC) generic.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/generic.o test/generic.c
	$(TEST_LINK_CC) -pthread -o generic.exe generic.o shared/common.o

initializer.exe: $(CHIBICC) initializer.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c \
		-o test/initializer.o test/initializer.c
	$(TEST_LINK_CC) -pthread -o initializer.exe initializer.o shared/common.o

line.exe: $(CHIBICC) line.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/line.o test/line.c
	$(TEST_LINK_CC) -pthread -o line.exe line.o shared/common.o

literal.exe: $(CHIBICC) literal.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/literal.o test/literal.c
	$(TEST_LINK_CC) -pthread -o literal.exe literal.o shared/common.o

macro.exe: $(CHIBICC) macro.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/macro.o test/macro.c
	$(TEST_LINK_CC) -pthread -o macro.exe macro.o shared/common.o

offsetof.exe: $(CHIBICC) offsetof.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/offsetof.o test/offsetof.c
	$(TEST_LINK_CC) -pthread -o offsetof.exe offsetof.o shared/common.o

pointer.exe: $(CHIBICC) pointer.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/pointer.o test/pointer.c
	$(TEST_LINK_CC) -pthread -o pointer.exe pointer.o shared/common.o

pragma-once.exe: $(CHIBICC) pragma-once.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c \
		-o test/pragma-once.o test/pragma-once.c
	$(TEST_LINK_CC) -pthread -o pragma-once.exe pragma-once.o \
		shared/common.o

sizeof.exe: $(CHIBICC) sizeof.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/sizeof.o test/sizeof.c
	$(TEST_LINK_CC) -pthread -o sizeof.exe sizeof.o shared/common.o

stdhdr.exe: $(CHIBICC) stdhdr.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/stdhdr.o test/stdhdr.c
	$(TEST_LINK_CC) -pthread -o stdhdr.exe stdhdr.o shared/common.o

string.exe: $(CHIBICC) string.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/string.o test/string.c
	$(TEST_LINK_CC) -pthread -o string.exe string.o shared/common.o

struct.exe: $(CHIBICC) struct.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/struct.o test/struct.c
	$(TEST_LINK_CC) -pthread -o struct.exe struct.o shared/common.o

tls.exe: $(CHIBICC) tls.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/tls.o test/tls.c
	$(TEST_LINK_CC) -pthread -o tls.exe tls.o shared/common.o

typedef.exe: $(CHIBICC) typedef.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/typedef.o test/typedef.c
	$(TEST_LINK_CC) -pthread -o typedef.exe typedef.o shared/common.o

typeof.exe: $(CHIBICC) typeof.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/typeof.o test/typeof.c
	$(TEST_LINK_CC) -pthread -o typeof.exe typeof.o shared/common.o

unicode.exe: $(CHIBICC) unicode.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/unicode.o test/unicode.c
	$(TEST_LINK_CC) -pthread -o unicode.exe unicode.o shared/common.o

union.exe: $(CHIBICC) union.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/union.o test/union.c
	$(TEST_LINK_CC) -pthread -o union.exe union.o shared/common.o

usualconv.exe: $(CHIBICC) usualconv.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/usualconv.o test/usualconv.c
	$(TEST_LINK_CC) -pthread -o usualconv.exe usualconv.o shared/common.o

varargs.exe: $(CHIBICC) varargs.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/varargs.o test/varargs.c
	$(TEST_LINK_CC) -pthread -o varargs.exe varargs.o shared/common.o

variable.exe: $(CHIBICC) variable.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/variable.o test/variable.c
	$(TEST_LINK_CC) -pthread -o variable.exe variable.o shared/common.o

vla.exe: $(CHIBICC) vla.c shared/common.o $(TEST_DEPS)
	cd .. && $(CHIBICC_FROM_ROOT) -Itest -c -o test/vla.o test/vla.c
	$(TEST_LINK_CC) -pthread -o vla.exe vla.o shared/common.o

test-compiler-driver: $(CHIBICC) driver.sh
	./driver.sh $(CHIBICC)

TEST_SRC_DIST?=../.make/chibicc-test.tar
TEST_SRC_DIST_LIST?=../.make/test-src-dist.files
SRC_DIST_ROOT?=chibicc

TEST_FILES=\
	$(TEST_SRCS) \
	Makefile \
	driver.sh \
	include1.h \
	include2.h \
	include3.h \
	include4.h \
	shared/common.c \
	test.h \
	thirdparty/common.sh.inc \
	thirdparty/cpython.sh \
	thirdparty/git.sh \
	thirdparty/libpng.sh \
	thirdparty/sqlite.sh \
	thirdparty/tinycc.sh

$(TEST_SRC_DIST): $(TEST_FILES)
	mkdir -p "$$(dirname "$@")" "$$(dirname "$(TEST_SRC_DIST_LIST)")"
	printf '%s\0' $(TEST_FILES) > $(TEST_SRC_DIST_LIST)
	tar --null -T $(TEST_SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/test/,' \
		-cf $@

src-dist: $(TEST_SRC_DIST)

.PHONY: all default src-dist test-compiler
.PHONY: test-compiler-driver test-compiler-exes
