CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror
export CFLAGS

STAGE1=.make/stage1
STAGE2=.make/stage2
CHIBICC=$(STAGE1)/chibicc
STAGE2_CHIBICC=$(STAGE2)/chibicc

# Stage 1

$(CHIBICC): FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./$(CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=chibicc.h \
		compiler

test: FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./$(CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=chibicc.h \
		test

test-all: test test-stage2

# Stage 2

$(STAGE2_CHIBICC): $(CHIBICC) FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		'STAGE_CC=./$(CHIBICC) -Iinclude' \
		'STAGE_TEST_CC=./$(STAGE2_CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(CHIBICC) \
		compiler

test-stage2: $(CHIBICC) FORCE
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		'STAGE_CC=./$(CHIBICC) -Iinclude' \
		'STAGE_TEST_CC=./$(STAGE2_CHIBICC) -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(CHIBICC) \
		test

# Misc.

clean:
	rm -rf chibicc .make tmp* test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

FORCE:

.PHONY: test clean test-stage2 test-all FORCE
