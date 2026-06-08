default: test-compiler

all: test-compiler

SRCS=\
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

TESTS=$(SRCS:.c=.exe)
LINK_CC?=cc
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

alignof.o: $(CC) alignof.c $(TEST_DEPS)
	$(CC) -I. -c -o alignof.o ./alignof.c

alignof.exe: alignof.o shared/common.o
	$(LINK_CC) -pthread -o alignof.exe alignof.o shared/common.o

alloca.o: $(CC) alloca.c $(TEST_DEPS)
	$(CC) -I. -c -o alloca.o ./alloca.c

alloca.exe: alloca.o shared/common.o
	$(LINK_CC) -pthread -o alloca.exe alloca.o shared/common.o

arith.o: $(CC) arith.c $(TEST_DEPS)
	$(CC) -I. -c -o arith.o ./arith.c

arith.exe: arith.o shared/common.o
	$(LINK_CC) -pthread -o arith.exe arith.o shared/common.o

asm.o: $(CC) asm.c $(TEST_DEPS)
	$(CC) -I. -c -o asm.o ./asm.c

asm.exe: asm.o shared/common.o
	$(LINK_CC) -pthread -o asm.exe asm.o shared/common.o

atomic.o: $(CC) atomic.c $(TEST_DEPS)
	$(CC) -I. -c -o atomic.o ./atomic.c

atomic.exe: atomic.o shared/common.o
	$(LINK_CC) -pthread -o atomic.exe atomic.o shared/common.o

attribute.o: $(CC) attribute.c $(TEST_DEPS)
	$(CC) -I. -c -o attribute.o ./attribute.c

attribute.exe: attribute.o shared/common.o
	$(LINK_CC) -pthread -o attribute.exe attribute.o shared/common.o

bitfield.o: $(CC) bitfield.c $(TEST_DEPS)
	$(CC) -I. -c -o bitfield.o ./bitfield.c

bitfield.exe: bitfield.o shared/common.o
	$(LINK_CC) -pthread -o bitfield.exe bitfield.o shared/common.o

builtin.o: $(CC) builtin.c $(TEST_DEPS)
	$(CC) -I. -c -o builtin.o ./builtin.c

builtin.exe: builtin.o shared/common.o
	$(LINK_CC) -pthread -o builtin.exe builtin.o shared/common.o

cast.o: $(CC) cast.c $(TEST_DEPS)
	$(CC) -I. -c -o cast.o ./cast.c

cast.exe: cast.o shared/common.o
	$(LINK_CC) -pthread -o cast.exe cast.o shared/common.o

commonsym.o: $(CC) commonsym.c $(TEST_DEPS)
	$(CC) -I. -c -o commonsym.o ./commonsym.c

commonsym.exe: commonsym.o shared/common.o
	$(LINK_CC) -pthread -o commonsym.exe commonsym.o shared/common.o

compat.o: $(CC) compat.c $(TEST_DEPS)
	$(CC) -I. -c -o compat.o ./compat.c

compat.exe: compat.o shared/common.o
	$(LINK_CC) -pthread -o compat.exe compat.o shared/common.o

complit.o: $(CC) complit.c $(TEST_DEPS)
	$(CC) -I. -c -o complit.o ./complit.c

complit.exe: complit.o shared/common.o
	$(LINK_CC) -pthread -o complit.exe complit.o shared/common.o

const.o: $(CC) const.c $(TEST_DEPS)
	$(CC) -I. -c -o const.o ./const.c

const.exe: const.o shared/common.o
	$(LINK_CC) -pthread -o const.exe const.o shared/common.o

constexpr.o: $(CC) constexpr.c $(TEST_DEPS)
	$(CC) -I. -c -o constexpr.o ./constexpr.c

constexpr.exe: constexpr.o shared/common.o
	$(LINK_CC) -pthread -o constexpr.exe constexpr.o shared/common.o

control.o: $(CC) control.c $(TEST_DEPS)
	$(CC) -I. -c -o control.o ./control.c

control.exe: control.o shared/common.o
	$(LINK_CC) -pthread -o control.exe control.o shared/common.o

decl.o: $(CC) decl.c $(TEST_DEPS)
	$(CC) -I. -c -o decl.o ./decl.c

decl.exe: decl.o shared/common.o
	$(LINK_CC) -pthread -o decl.exe decl.o shared/common.o

enum.o: $(CC) enum.c $(TEST_DEPS)
	$(CC) -I. -c -o enum.o ./enum.c

enum.exe: enum.o shared/common.o
	$(LINK_CC) -pthread -o enum.exe enum.o shared/common.o

extern.o: $(CC) extern.c $(TEST_DEPS)
	$(CC) -I. -c -o extern.o ./extern.c

extern.exe: extern.o shared/common.o
	$(LINK_CC) -pthread -o extern.exe extern.o shared/common.o

float.o: $(CC) float.c $(TEST_DEPS)
	$(CC) -I. -c -o float.o ./float.c

float.exe: float.o shared/common.o
	$(LINK_CC) -pthread -o float.exe float.o shared/common.o

function.o: $(CC) function.c $(TEST_DEPS)
	$(CC) -I. -c -o function.o ./function.c

function.exe: function.o shared/common.o
	$(LINK_CC) -pthread -o function.exe function.o shared/common.o

generic.o: $(CC) generic.c $(TEST_DEPS)
	$(CC) -I. -c -o generic.o ./generic.c

generic.exe: generic.o shared/common.o
	$(LINK_CC) -pthread -o generic.exe generic.o shared/common.o

initializer.o: $(CC) initializer.c $(TEST_DEPS)
	$(CC) -I. -c -o initializer.o ./initializer.c

initializer.exe: initializer.o shared/common.o
	$(LINK_CC) -pthread -o initializer.exe initializer.o shared/common.o

line.o: $(CC) line.c $(TEST_DEPS)
	$(CC) -I. -c -o line.o ./line.c

line.exe: line.o shared/common.o
	$(LINK_CC) -pthread -o line.exe line.o shared/common.o

literal.o: $(CC) literal.c $(TEST_DEPS)
	$(CC) -I. -c -o literal.o ./literal.c

literal.exe: literal.o shared/common.o
	$(LINK_CC) -pthread -o literal.exe literal.o shared/common.o

macro.o: $(CC) macro.c $(TEST_DEPS)
	$(CC) -I. -c -o macro.o ./macro.c

macro.exe: macro.o shared/common.o
	$(LINK_CC) -pthread -o macro.exe macro.o shared/common.o

offsetof.o: $(CC) offsetof.c $(TEST_DEPS)
	$(CC) -I. -c -o offsetof.o ./offsetof.c

offsetof.exe: offsetof.o shared/common.o
	$(LINK_CC) -pthread -o offsetof.exe offsetof.o shared/common.o

pointer.o: $(CC) pointer.c $(TEST_DEPS)
	$(CC) -I. -c -o pointer.o ./pointer.c

pointer.exe: pointer.o shared/common.o
	$(LINK_CC) -pthread -o pointer.exe pointer.o shared/common.o

pragma-once.o: $(CC) pragma-once.c $(TEST_DEPS)
	$(CC) -I. -c -o pragma-once.o ./pragma-once.c

pragma-once.exe: pragma-once.o shared/common.o
	$(LINK_CC) -pthread -o pragma-once.exe pragma-once.o \
		shared/common.o

sizeof.o: $(CC) sizeof.c $(TEST_DEPS)
	$(CC) -I. -c -o sizeof.o ./sizeof.c

sizeof.exe: sizeof.o shared/common.o
	$(LINK_CC) -pthread -o sizeof.exe sizeof.o shared/common.o

stdhdr.o: $(CC) stdhdr.c $(TEST_DEPS)
	$(CC) -I. -c -o stdhdr.o ./stdhdr.c

stdhdr.exe: stdhdr.o shared/common.o
	$(LINK_CC) -pthread -o stdhdr.exe stdhdr.o shared/common.o

string.o: $(CC) string.c $(TEST_DEPS)
	$(CC) -I. -c -o string.o ./string.c

string.exe: string.o shared/common.o
	$(LINK_CC) -pthread -o string.exe string.o shared/common.o

struct.o: $(CC) struct.c $(TEST_DEPS)
	$(CC) -I. -c -o struct.o ./struct.c

struct.exe: struct.o shared/common.o
	$(LINK_CC) -pthread -o struct.exe struct.o shared/common.o

tls.o: $(CC) tls.c $(TEST_DEPS)
	$(CC) -I. -c -o tls.o ./tls.c

tls.exe: tls.o shared/common.o
	$(LINK_CC) -pthread -o tls.exe tls.o shared/common.o

typedef.o: $(CC) typedef.c $(TEST_DEPS)
	$(CC) -I. -c -o typedef.o ./typedef.c

typedef.exe: typedef.o shared/common.o
	$(LINK_CC) -pthread -o typedef.exe typedef.o shared/common.o

typeof.o: $(CC) typeof.c $(TEST_DEPS)
	$(CC) -I. -c -o typeof.o ./typeof.c

typeof.exe: typeof.o shared/common.o
	$(LINK_CC) -pthread -o typeof.exe typeof.o shared/common.o

unicode.o: $(CC) unicode.c $(TEST_DEPS)
	$(CC) -I. -c -o unicode.o ./unicode.c

unicode.exe: unicode.o shared/common.o
	$(LINK_CC) -pthread -o unicode.exe unicode.o shared/common.o

union.o: $(CC) union.c $(TEST_DEPS)
	$(CC) -I. -c -o union.o ./union.c

union.exe: union.o shared/common.o
	$(LINK_CC) -pthread -o union.exe union.o shared/common.o

usualconv.o: $(CC) usualconv.c $(TEST_DEPS)
	$(CC) -I. -c -o usualconv.o ./usualconv.c

usualconv.exe: usualconv.o shared/common.o
	$(LINK_CC) -pthread -o usualconv.exe usualconv.o shared/common.o

varargs.o: $(CC) varargs.c $(TEST_DEPS)
	$(CC) -I. -c -o varargs.o ./varargs.c

varargs.exe: varargs.o shared/common.o
	$(LINK_CC) -pthread -o varargs.exe varargs.o shared/common.o

variable.o: $(CC) variable.c $(TEST_DEPS)
	$(CC) -I. -c -o variable.o ./variable.c

variable.exe: variable.o shared/common.o
	$(LINK_CC) -pthread -o variable.exe variable.o shared/common.o

vla.o: $(CC) vla.c $(TEST_DEPS)
	$(CC) -I. -c -o vla.o ./vla.c

vla.exe: vla.o shared/common.o
	$(LINK_CC) -pthread -o vla.exe vla.o shared/common.o

test-compiler-driver: $(CC) driver.sh
	./driver.sh $(CC)

ARCHIVE?=../.make/chibicc-test.tar
ARCHIVE_LIST?=../.make/test-archive.files
ARCHIVE_ROOT?=chibicc

FILES=\
	$(SRCS) \
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

$(ARCHIVE): $(FILES)
	mkdir -p "$$(dirname "$@")" "$$(dirname "$(ARCHIVE_LIST)")"
	printf '%s\0' $(FILES) > $(ARCHIVE_LIST)
	tar --null -T $(ARCHIVE_LIST) \
		--transform='s,^,$(ARCHIVE_ROOT)/test/,' \
		-cf $@

archive: $(ARCHIVE)

.PHONY: all archive default test-compiler
.PHONY: test-compiler-driver test-compiler-exes
