ifndef STAGE
$(error STAGE is required)
endif
ifndef STAGE_CC
$(error STAGE_CC is required)
endif
ifndef STAGE_TEST_CC
$(error STAGE_TEST_CC is required)
endif
ifndef STAGE_OBJ_DEPS
$(error STAGE_OBJ_DEPS is required)
endif

SRCS=$(wildcard *.c)
TEST_SRCS=$(wildcard test/*.c)

CHIBICC=$(STAGE)/chibicc
OBJDIR=$(STAGE)/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
TEST_OBJDIR=$(STAGE)/test/.o
TEST_EXEDIR=$(STAGE)/test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)

compiler: $(CHIBICC)

$(CHIBICC): $(OBJS)
	mkdir -p $(@D)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)/%.o: %.c $(STAGE_OBJ_DEPS)
	mkdir -p $(@D)
	$(STAGE_CC) -c -o $@ $<

$(TEST_EXEDIR)/%.exe: $(CHIBICC) test/%.c test/shared/common.c
	mkdir -p $(@D) $(TEST_OBJDIR)
	$(STAGE_TEST_CC) -c -o $(TEST_OBJDIR)/$*.o test/$*.c
	$(CC) -pthread -o $@ $(TEST_OBJDIR)/$*.o test/shared/common.c

test: $(TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./$(CHIBICC)

.PHONY: compiler test
