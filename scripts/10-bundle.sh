#!/bin/bash
###############################################################################
# 10-bundle.sh -- build the rnpletal bundle: RNPL compiler + SDF/bbhutil,
# vutil, utilio, utilmath, svs, netlib (BLAS/LAPACK/...). No X11 needed.
#
# macOS fix applied here:
#   * <sys/sysmacros.h> is Linux/glibc-only. Guard it with #ifndef __APPLE__
#     (macOS provides major()/minor()/makedev() via <sys/types.h>).
###############################################################################
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

say "rnpletal: download + extract"
fetch "$RNPLETAL_URL" "$DIST/rnpletal.tar.gz"
rm -rf "$BUILD/rnpletal"
tar xzf "$DIST/rnpletal.tar.gz" -C "$BUILD"

say "rnpletal: patch Linux-only headers for macOS"
while IFS= read -r f; do
  perl -0pi -e 's{#include <sys/sysmacros\.h>}{#ifndef __APPLE__\n#include <sys/sysmacros.h>\n#endif}g' "$f"
  echo "  guarded sysmacros in ${f#$BUILD/}"
done < <(grep -rl "sys/sysmacros.h" "$BUILD/rnpletal" 2>/dev/null)

# --- toolchain env for this bundle ------------------------------------------
export CFLAGS="-O2 $LENIENT"
export CFLAGS_NOOPT="-O0 $LENIENT"
export CXXFLAGS="-O2"
export CPPFLAGS="-I$PREFIX/include -I$HOMEBREW_PREFIX/include"
export F77FLAGS="-O2 $FNOSECOND"
export F77FLAGSNOOPT="-O0 $FNOSECOND"
export F77LFLAGS="$FNOSECOND -L$PREFIX/lib -L$GFORTLIB"
export F90FLAGS="$F77FLAGS"
export F90LFLAGS="$F77LFLAGS"
export CCF77LIBS="-L$GFORTLIB -lgfortran -lquadmath -lm"   # C links Fortran objs
export LDFLAGS="-L$PREFIX/lib -L$GFORTLIB"
export RNPL="$PREFIX/bin/rnpl"
export INCLUDE_PATHS="$PREFIX/include $HOMEBREW_PREFIX/include"
export LIB_PATHS="$PREFIX/lib $HOMEBREW_PREFIX/lib $GFORTLIB"

# Build order from the distribution's Install.gnu.darwin.
PACKAGES="cliser rnpl svs vutil utilmath visutil utilio cvtestsdf \
netlib_linpack netlib_odepack netlib_fftpack netlib_lapack3.0"

cd "$BUILD/rnpletal"
for pack in $PACKAGES; do
  say "rnpletal: building $pack"
  [ -d "$pack" ] || { echo "  (missing, skipped)"; continue; }
  ( cd "$pack" && ./configure --prefix="$PREFIX" && make install ) \
    || echo "  WARNING: $pack reported errors (often non-fatal; see output)"
done

say "rnpletal: verifying critical outputs"
[ -x "$PREFIX/bin/rnpl" ]        || die "rnpl compiler not built"
[ -f "$PREFIX/lib/libbbhutil.a" ] || die "libbbhutil.a not built"
ar t "$PREFIX/lib/libbbhutil.a" | grep -q "bbhutil.o" || die "libbbhutil.a is incomplete (sysmacros patch failed?)"
echo "  rnpl + libbbhutil.a OK"
