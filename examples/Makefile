# Build the sample SDF generators against the locally-installed libbbhutil.
# Usage:  make            (from this examples/ directory)
#         ./test_1d ; ./test_2d
#
# Assumes the toolchain was built into ../install (the repo default).

PREFIX  := $(abspath ..)/install
GFORTLIB := $(shell dirname $$(gfortran -print-file-name=libgfortran.dylib))

CC      := clang
CFLAGS  := -O2 -I$(PREFIX)/include
LDFLAGS := -L$(PREFIX)/lib -L$(GFORTLIB)
LIBS    := -lbbhutil -lgfortran -lquadmath -lm

PROGS := test_1d test_2d

all: $(PROGS)

test_1d: test_1d.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) $(LIBS)

test_2d: test_2d.c
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS) $(LIBS)

clean:
	rm -f $(PROGS) *.sdf

.PHONY: all clean
