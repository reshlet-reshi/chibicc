CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror

CHIBICC=.make/stage1/chibicc

SRCS=$(wildcard *.c)
OBJDIR=.make/stage1/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
STAGE2_OBJS=$(SRCS:%.c=stage2/%.o)

TEST_SRCS=$(wildcard test/*.c)
TEST_OBJDIR=.make/stage1/test/.o
TEST_EXEDIR=.make/stage1/test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)
STAGE2_TESTS=$(TEST_SRCS:test/%.c=stage2/test/%.exe)

# Stage 1

$(CHIBICC): $(OBJS)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: %.c chibicc.h
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(TEST_EXEDIR)/%.exe: $(CHIBICC) test/%.c test/shared/common.c
	mkdir -p $(@D) $(TEST_OBJDIR)
	./$(CHIBICC) -Iinclude -Itest -c -o $(TEST_OBJDIR)/$*.o test/$*.c
	$(CC) -pthread -o $@ $(TEST_OBJDIR)/$*.o test/shared/common.c

test: $(TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(CHIBICC)

test-all: test test-stage2

# Stage 2

stage2/chibicc: $(STAGE2_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

stage2/%.o: $(CHIBICC) %.c
	mkdir -p stage2/test
	./$(CHIBICC) -Iinclude -c -o $(@D)/$*.o $*.c

stage2/test/%.exe: stage2/chibicc test/%.c test/shared/common.c
	mkdir -p stage2/test
	./stage2/chibicc -Iinclude -Itest -c -o stage2/test/$*.o test/$*.c
	$(CC) -pthread -o $@ stage2/test/$*.o test/shared/common.c

test-stage2: $(STAGE2_TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./stage2/chibicc

# Misc.

clean:
	rm -rf chibicc .make tmp* $(TESTS) test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: test clean test-stage2
