CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch -Werror
export CFLAGS

STAGE1=.make/stage1
STAGE2=.make/stage2
CHIBICC=$(STAGE1)/chibicc
STAGE2_CHIBICC=$(STAGE2)/chibicc
DEFAULT_SRC_DIST=.make/chibicc.tar.gz
SRC_DIST?=$(DEFAULT_SRC_DIST)
SRC_DIST_ROOT=chibicc
SRC_DIST_LIST=.make/src-dist.files
SRC_DIST_INPUTS=$(shell git ls-files -- . ':!meta' ':!.gitignore')
ROOT_SRC_INPUTS=$(foreach path,$(SRC_DIST_INPUTS),\
	$(if $(findstring /,$(path)),,$(path)))
TEST_SRC_INPUTS=$(foreach path,$(SRC_DIST_INPUTS),\
	$(if $(filter test/%,$(path)),\
		$(if $(findstring /,$(patsubst test/%,%,$(path))),,$(path))))
STAGE_SRCS=$(filter %.c,$(ROOT_SRC_INPUTS))
STAGE_TEST_SRCS=$(filter %.c,$(TEST_SRC_INPUTS))

# Stage 1

$(CHIBICC): $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		compiler

test: $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE1) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(CC) $(CFLAGS)' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		test

test-all: test test-stage2

# Stage 2

$(STAGE2_CHIBICC): $(CHIBICC) $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(abspath $(CHIBICC)) -Iinclude' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(abspath $(CHIBICC)) \
		compiler

test-stage2: $(CHIBICC) $(DEFAULT_SRC_DIST)
	$(MAKE) -f stage.mk STAGE=$(STAGE2) \
		SRC_DIST=$(abspath $(DEFAULT_SRC_DIST)) \
		SRC_DIST_ROOT=$(SRC_DIST_ROOT) \
		'STAGE_SRCS=$(STAGE_SRCS)' \
		'STAGE_TEST_SRCS=$(STAGE_TEST_SRCS)' \
		'STAGE_CC=$(abspath $(CHIBICC)) -Iinclude' \
		'STAGE_TEST_CC=./chibicc -Iinclude -Itest' \
		STAGE_OBJ_DEPS=$(abspath $(CHIBICC)) \
		test

# Misc.

src-dist: $(SRC_DIST)

$(DEFAULT_SRC_DIST): $(SRC_DIST_INPUTS)
	mkdir -p $(dir $@) .make
	git ls-files -z -- . ':!meta' ':!.gitignore' > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@

ifneq ($(SRC_DIST),$(DEFAULT_SRC_DIST))
$(SRC_DIST): $(SRC_DIST_INPUTS)
	mkdir -p $(dir $@) .make
	git ls-files -z -- . ':!meta' ':!.gitignore' > $(SRC_DIST_LIST)
	tar --null -T $(SRC_DIST_LIST) \
		--transform='s,^,$(SRC_DIST_ROOT)/,' \
		-czf $@
endif

clean:
	rm -rf chibicc .make tmp* test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: test clean test-stage2 test-all src-dist
