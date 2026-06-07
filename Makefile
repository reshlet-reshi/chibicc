CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror

SRCS=$(wildcard *.c)
OBJDIR=.make/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
STAGE2_OBJS=$(SRCS:%.c=stage2/%.o)

TEST_SRCS=$(wildcard test/*.c)
TESTS=$(TEST_SRCS:.c=.exe)

# Stage 1

chibicc: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: %.c chibicc.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

test/%.exe: chibicc test/%.c test/shared/common.c
	./chibicc -Iinclude -Itest -c -o test/$*.o test/$*.c
	$(CC) -pthread -o $@ test/$*.o test/shared/common.c

test: $(TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./chibicc

test-all: test test-stage2

# Stage 2

stage2/chibicc: $(STAGE2_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

stage2/%.o: chibicc %.c
	mkdir -p stage2/test
	./chibicc -c -o $(@D)/$*.o $*.c

stage2/test/%.exe: stage2/chibicc test/%.c test/shared/common.c
	mkdir -p stage2/test
	./stage2/chibicc -Iinclude -Itest -c -o stage2/test/$*.o test/$*.c
	$(CC) -pthread -o $@ stage2/test/$*.o test/shared/common.c

test-stage2: $(TESTS:test/%=stage2/test/%)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./stage2/chibicc

# Misc.

clean:
	rm -rf chibicc .make tmp* $(TESTS) test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: test clean test-stage2
