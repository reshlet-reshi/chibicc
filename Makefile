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

LINK_CC?=$(CC)

test-compiler: chibicc
	$(MAKE) -C test "CC=../chibicc" "LINK_CC=$(LINK_CC)" \
		test-compiler

test-compiler-exes: chibicc
	$(MAKE) -C test "CC=../chibicc" "LINK_CC=$(LINK_CC)" \
		test-compiler-exes

test-compiler-driver: chibicc
	$(MAKE) -C test "CC=../chibicc" test-compiler-driver

ARCHIVE?=.make/chibicc.tar
ROOT_ARCHIVE?=.make/chibicc-src.tar
TEST_ARCHIVE?=.make/chibicc-test.tar
ARCHIVE_ROOT=chibicc
ROOT_ARCHIVE_LIST?=.make/root-archive.files

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

FILES=\
	$(DIST_ROOT_FILES) \
	$(SRCS) \
	$(DIST_INCLUDE_FILES)

$(ROOT_ARCHIVE): $(FILES)
	mkdir -p "$$(dirname "$@")" "$$(dirname "$(ROOT_ARCHIVE_LIST)")"
	printf '%s\0' $(FILES) > $(ROOT_ARCHIVE_LIST)
	tar --null -T $(ROOT_ARCHIVE_LIST) \
		--transform='s,^,$(ARCHIVE_ROOT)/,' \
		-cf $@

$(TEST_ARCHIVE):
	$(MAKE) -C test \
		"ARCHIVE=$$(pwd)/$(TEST_ARCHIVE)" \
		"ARCHIVE_LIST=$$(pwd)/.make/test-archive.files" \
		"ARCHIVE_ROOT=$(ARCHIVE_ROOT)" archive

$(ARCHIVE): $(ROOT_ARCHIVE) $(TEST_ARCHIVE)
	mkdir -p "$$(dirname "$@")"
	cp "$(ROOT_ARCHIVE)" "$@"
	tar -Af "$@" "$(TEST_ARCHIVE)"

archive: $(ARCHIVE)

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
			"LINK_CC=$(CC)" CFLAGS= test-compiler

$(STAGE1)/.src-ready $(STAGE2)/.src-ready: $(ARCHIVE)
	@case '$(@D)' in .make/*) ;; \
		*) echo 'refusing to prepare stage outside .make' >&2; exit 1;; \
	esac
	rm -rf $(@D) $(@D).unpack
	mkdir -p $(@D).unpack
	tar -xf $(ARCHIVE) -C $(@D).unpack
	mv $(@D).unpack/$(ARCHIVE_ROOT) $(@D)
	rm -rf $(@D).unpack
	touch $@

clean:
	rm -rf chibicc .make .o tmp* test/.exe test/.o test/*.s test/*.exe
	rm -rf stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: all archive clean default test test-compiler
.PHONY: test-compiler-driver test-compiler-exes
.PHONY: test-all test-stage2 $(TEST_ARCHIVE)
