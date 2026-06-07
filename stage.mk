ifndef STAGE
$(error STAGE is required)
endif
ifndef SRC_DIST
$(error SRC_DIST is required)
endif
ifndef SRC_DIST_ROOT
$(error SRC_DIST_ROOT is required)
endif
ifndef STAGE_SRCS
$(error STAGE_SRCS is required)
endif
ifndef STAGE_TEST_SRCS
$(error STAGE_TEST_SRCS is required)
endif
ifndef STAGE_CC
$(error STAGE_CC is required)
endif
ifndef STAGE_TEST_CC
$(error STAGE_TEST_CC is required)
endif

SRCS=$(STAGE_SRCS)
TEST_SRCS=$(STAGE_TEST_SRCS)

SRC_READY=$(STAGE)/.src-ready
UNPACK=$(STAGE).unpack
CHIBICC=$(STAGE)/chibicc
OBJDIR=$(STAGE)/.o
OBJS=$(SRCS:%.c=$(OBJDIR)/%.o)
TEST_OBJDIR=$(STAGE)/test/.o
TEST_EXEDIR=$(STAGE)/test/.exe
TESTS=$(TEST_SRCS:test/%.c=$(TEST_EXEDIR)/%.exe)

compiler: $(CHIBICC)

$(SRC_READY): $(SRC_DIST)
	@case '$(STAGE)' in .make/*) ;; \
		*) echo 'refusing to prepare stage outside .make' >&2; exit 1;; \
	esac
	rm -rf $(STAGE) $(UNPACK)
	mkdir -p $(UNPACK)
	tar -xzf $(SRC_DIST) -C $(UNPACK)
	mv $(UNPACK)/$(SRC_DIST_ROOT) $(STAGE)
	rm -rf $(UNPACK)
	touch $@

$(CHIBICC): $(OBJS)
	cd $(STAGE) && $(CC) $(CFLAGS) -o chibicc \
		$(abspath $^) $(LDFLAGS)

$(OBJDIR)/%.o: $(SRC_READY) $(STAGE_OBJ_DEPS)
	mkdir -p $(@D)
	cd $(STAGE) && $(STAGE_CC) -c -o $(abspath $@) $*.c

$(TEST_EXEDIR)/%.exe: $(CHIBICC) $(SRC_READY)
	mkdir -p $(@D) $(TEST_OBJDIR)
	cd $(STAGE) && \
		$(STAGE_TEST_CC) -c -o test/.o/$*.o test/$*.c
	cd $(STAGE) && \
		$(CC) -pthread -o test/.exe/$*.exe \
		test/.o/$*.o test/shared/common.c

test: $(TESTS)
	cd $(STAGE) && \
		for i in test/.exe/*.exe; do echo $$i; ./$$i || exit 1; echo; done
	cd $(STAGE) && test/driver.sh ./chibicc

.PHONY: compiler test
