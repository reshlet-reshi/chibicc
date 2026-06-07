CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror

CHIBICC=.make/stage1/chibicc

SRCS=$(wildcard *.c)
OBJDIR=.make/stage1/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
STAGE2=.make/stage2
STAGE2_OBJDIR=$(STAGE2)/.o
STAGE2_OBJS=$(SRCS:%.c=$(STAGE2_OBJDIR)/%.o)

TEST_SRCS=$(wildcard test/*.c)
TEST_OBJDIR=.make/stage1/test/.o
TEST_EXEDIR=.make/stage1/test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)
STAGE2_TEST_OBJDIR=$(STAGE2)/test/.o
STAGE2_TEST_EXEDIR=$(STAGE2)/test/.exe
STAGE2_TESTS=$(TEST_SRCS:test/%.c=$(STAGE2_TEST_EXEDIR)/%.exe)

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

$(STAGE2)/chibicc: $(STAGE2_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(STAGE2_OBJDIR)/%.o: $(CHIBICC) %.c
	mkdir -p $(@D)
	./$(CHIBICC) -Iinclude -c -o $@ $*.c

$(STAGE2_TEST_EXEDIR)/%.exe: $(STAGE2)/chibicc test/%.c test/shared/common.c
	mkdir -p $(@D) $(STAGE2_TEST_OBJDIR)
	./$(STAGE2)/chibicc -Iinclude -Itest -c \
		-o $(STAGE2_TEST_OBJDIR)/$*.o test/$*.c
	$(CC) -pthread -o $@ $(STAGE2_TEST_OBJDIR)/$*.o test/shared/common.c

test-stage2: $(STAGE2_TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(STAGE2)/chibicc

# Misc.

clean:
	rm -rf chibicc .make tmp* $(TESTS) test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: test clean test-stage2
