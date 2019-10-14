#
# Makefile for Machine Learning tools
#

# platform dependent settings
UNAME_O = $(shell uname -o)
ifeq ($(UNAME_O), Cygwin)
	EXT_EXE = .exe
else
	EXT_EXE =
endif

dist_sources = examples/find_primes.exe examples/prime_worker.exe
dist_target = $(foreach f,$(dist_sources),./dist/$(basename $(notdir $(f)$(EXT_EXE))))
dist_assets =

all: build

clean:
	dune clean

distclean: clean
	rm -rf dist

build:
	dune build

test: build
	ALCOTEST_QUICK_TESTS=1 dune runtest

demo: dist
	./dist/find_primes

alltest: build
	dune runtest

# make distribution package (folder)
assets: $(dist_assets)
	mkdir -p dist
	$(foreach a,$^,cp a dist)

dist: build assets
	mkdir -p dist
	$(foreach f,$(dist_sources),cp _build/default/$(f) ./dist/$(basename $(notdir $(f)))$(EXT_EXE);)
ifeq ($(UNAME_O), Cygwin)
	ldd $(dist_target) \
	 | awk '$$2  == "=>" && $$3 !~ /WINDOWS/ && $$3 ~/^\// && !seen[$$3]++ { print "cp", $$3, "./dist" }' | sh
endif

.PHONY: 	all clean build test dist

