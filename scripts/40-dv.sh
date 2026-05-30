#!/bin/bash
###############################################################################
# 40-dv.sh -- build DV (2D/3D visualization), the last and heaviest component.
#
# macOS fixes applied here:
#   * <malloc.h> is Linux-only. Guard each include with #ifndef __APPLE__
#     (macOS provides malloc via <stdlib.h>).
#   * GLUT/GLU are not in DV's auto-detected link line; supply them via XTRALIBS.
###############################################################################
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

say "DV: download + extract"
fetch "$DV_URL" "$DIST/DV.tar.gz"
rm -rf "$BUILD/DV"
tar xzf "$DIST/DV.tar.gz" -C "$BUILD"

say "DV: patch Linux-only headers for macOS"
while IFS= read -r f; do
  perl -0pi -e 's{#include <malloc\.h>}{#ifndef __APPLE__\n#include <malloc.h>\n#endif}g' "$f"
done < <(grep -rl "include <malloc.h>" "$BUILD/DV" 2>/dev/null)
echo "  guarded <malloc.h>"

export INCLUDE_PATHS="$PREFIX/include $X11/include $JPEG/include"
export LIB_PATHS="$PREFIX/lib $X11/lib $JPEG/lib $GFORTLIB"

export CFLAGS="-O2 $LENIENT -I$PREFIX/include -I$X11/include -I$JPEG/include"
export CPPFLAGS="-I$PREFIX/include -I$X11/include -I$JPEG/include"
export F77FLAGS="-O2 $FNOSECOND"
export F77LFLAGS="$FNOSECOND -L$PREFIX/lib -L$GFORTLIB"
export LDFLAGS="-L$PREFIX/lib -L$X11/lib -L$JPEG/lib -L$GFORTLIB -Wl,-rpath,$X11/lib"
export CCF77LIBS="-L$GFORTLIB -lgfortran -lquadmath -lm"
export XTRALIBS="-L$X11/lib -lglut -lGLU -lGL -lXext -lXmu -lXi -lX11"

cd "$BUILD/DV"
say "DV: configure"
./configure --prefix="$PREFIX"

say "DV: make install"
make install

say "DV: verifying"
[ -x "$PREFIX/bin/DV" ]      || die "DV binary not built"
[ -x "$PREFIX/bin/sdftodv" ] || die "sdftodv not built"
echo "  DV + sdftodv OK"
