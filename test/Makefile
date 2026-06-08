default: test-compiler

all: test-compiler

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
TEST_LINK_CC?=cc
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

shared/common.o: $(CC) shared/common.c
	$(CC) -I. -c -o shared/common.o ./shared/common.c

test-compiler: test-compiler-exes test-compiler-driver

test-compiler-exes: $(TESTS)
	for i in $(TESTS); do echo $$i; ./$$i || exit 1; echo; done

alignof.exe: $(CC) alignof.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o alignof.o ./alignof.c
	$(TEST_LINK_CC) -pthread -o alignof.exe alignof.o shared/common.o

alloca.exe: $(CC) alloca.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o alloca.o ./alloca.c
	$(TEST_LINK_CC) -pthread -o alloca.exe alloca.o shared/common.o

arith.exe: $(CC) arith.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o arith.o ./arith.c
	$(TEST_LINK_CC) -pthread -o arith.exe arith.o shared/common.o

asm.exe: $(CC) asm.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o asm.o ./asm.c
	$(TEST_LINK_CC) -pthread -o asm.exe asm.o shared/common.o

atomic.exe: $(CC) atomic.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o atomic.o ./atomic.c
	$(TEST_LINK_CC) -pthread -o atomic.exe atomic.o shared/common.o

attribute.exe: $(CC) attribute.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o attribute.o ./attribute.c
	$(TEST_LINK_CC) -pthread -o attribute.exe attribute.o shared/common.o

bitfield.exe: $(CC) bitfield.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o bitfield.o ./bitfield.c
	$(TEST_LINK_CC) -pthread -o bitfield.exe bitfield.o shared/common.o

builtin.exe: $(CC) builtin.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o builtin.o ./builtin.c
	$(TEST_LINK_CC) -pthread -o builtin.exe builtin.o shared/common.o

cast.exe: $(CC) cast.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o cast.o ./cast.c
	$(TEST_LINK_CC) -pthread -o cast.exe cast.o shared/common.o

commonsym.exe: $(CC) commonsym.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o commonsym.o ./commonsym.c
	$(TEST_LINK_CC) -pthread -o commonsym.exe commonsym.o shared/common.o

compat.exe: $(CC) compat.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o compat.o ./compat.c
	$(TEST_LINK_CC) -pthread -o compat.exe compat.o shared/common.o

complit.exe: $(CC) complit.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o complit.o ./complit.c
	$(TEST_LINK_CC) -pthread -o complit.exe complit.o shared/common.o

const.exe: $(CC) const.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o const.o ./const.c
	$(TEST_LINK_CC) -pthread -o const.exe const.o shared/common.o

constexpr.exe: $(CC) constexpr.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o constexpr.o ./constexpr.c
	$(TEST_LINK_CC) -pthread -o constexpr.exe constexpr.o shared/common.o

control.exe: $(CC) control.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o control.o ./control.c
	$(TEST_LINK_CC) -pthread -o control.exe control.o shared/common.o

decl.exe: $(CC) decl.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o decl.o ./decl.c
	$(TEST_LINK_CC) -pthread -o decl.exe decl.o shared/common.o

enum.exe: $(CC) enum.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o enum.o ./enum.c
	$(TEST_LINK_CC) -pthread -o enum.exe enum.o shared/common.o

extern.exe: $(CC) extern.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o extern.o ./extern.c
	$(TEST_LINK_CC) -pthread -o extern.exe extern.o shared/common.o

float.exe: $(CC) float.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o float.o ./float.c
	$(TEST_LINK_CC) -pthread -o float.exe float.o shared/common.o

function.exe: $(CC) function.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o function.o ./function.c
	$(TEST_LINK_CC) -pthread -o function.exe function.o shared/common.o

generic.exe: $(CC) generic.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o generic.o ./generic.c
	$(TEST_LINK_CC) -pthread -o generic.exe generic.o shared/common.o

initializer.exe: $(CC) initializer.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o initializer.o ./initializer.c
	$(TEST_LINK_CC) -pthread -o initializer.exe initializer.o shared/common.o

line.exe: $(CC) line.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o line.o ./line.c
	$(TEST_LINK_CC) -pthread -o line.exe line.o shared/common.o

literal.exe: $(CC) literal.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o literal.o ./literal.c
	$(TEST_LINK_CC) -pthread -o literal.exe literal.o shared/common.o

macro.exe: $(CC) macro.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o macro.o ./macro.c
	$(TEST_LINK_CC) -pthread -o macro.exe macro.o shared/common.o

offsetof.exe: $(CC) offsetof.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o offsetof.o ./offsetof.c
	$(TEST_LINK_CC) -pthread -o offsetof.exe offsetof.o shared/common.o

pointer.exe: $(CC) pointer.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o pointer.o ./pointer.c
	$(TEST_LINK_CC) -pthread -o pointer.exe pointer.o shared/common.o

pragma-once.exe: $(CC) pragma-once.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o pragma-once.o ./pragma-once.c
	$(TEST_LINK_CC) -pthread -o pragma-once.exe pragma-once.o \
		shared/common.o

sizeof.exe: $(CC) sizeof.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o sizeof.o ./sizeof.c
	$(TEST_LINK_CC) -pthread -o sizeof.exe sizeof.o shared/common.o

stdhdr.exe: $(CC) stdhdr.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o stdhdr.o ./stdhdr.c
	$(TEST_LINK_CC) -pthread -o stdhdr.exe stdhdr.o shared/common.o

string.exe: $(CC) string.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o string.o ./string.c
	$(TEST_LINK_CC) -pthread -o string.exe string.o shared/common.o

struct.exe: $(CC) struct.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o struct.o ./struct.c
	$(TEST_LINK_CC) -pthread -o struct.exe struct.o shared/common.o

tls.exe: $(CC) tls.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o tls.o ./tls.c
	$(TEST_LINK_CC) -pthread -o tls.exe tls.o shared/common.o

typedef.exe: $(CC) typedef.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o typedef.o ./typedef.c
	$(TEST_LINK_CC) -pthread -o typedef.exe typedef.o shared/common.o

typeof.exe: $(CC) typeof.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o typeof.o ./typeof.c
	$(TEST_LINK_CC) -pthread -o typeof.exe typeof.o shared/common.o

unicode.exe: $(CC) unicode.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o unicode.o ./unicode.c
	$(TEST_LINK_CC) -pthread -o unicode.exe unicode.o shared/common.o

union.exe: $(CC) union.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o union.o ./union.c
	$(TEST_LINK_CC) -pthread -o union.exe union.o shared/common.o

usualconv.exe: $(CC) usualconv.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o usualconv.o ./usualconv.c
	$(TEST_LINK_CC) -pthread -o usualconv.exe usualconv.o shared/common.o

varargs.exe: $(CC) varargs.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o varargs.o ./varargs.c
	$(TEST_LINK_CC) -pthread -o varargs.exe varargs.o shared/common.o

variable.exe: $(CC) variable.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o variable.o ./variable.c
	$(TEST_LINK_CC) -pthread -o variable.exe variable.o shared/common.o

vla.exe: $(CC) vla.c shared/common.o $(TEST_DEPS)
	$(CC) -I. -c -o vla.o ./vla.c
	$(TEST_LINK_CC) -pthread -o vla.exe vla.o shared/common.o

test-compiler-driver: $(CC) driver.sh
	./driver.sh $(CC)

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
