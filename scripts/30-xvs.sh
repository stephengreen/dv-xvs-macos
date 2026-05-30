#!/bin/bash
###############################################################################
# 30-xvs.sh -- build XVS (1D visualization).
#
# macOS fixes applied here:
#   * -DGFORTRAN43_OR_LATER : configure's gfortran-flavour autodetect fails on
#     gfortran 15 ("Unimplemented version") and does not set the GFORTRAN macro,
#     so f77_intrinsics.h falls back to f2c names (d_sin, d_abs, ...) that
#     gfortran does not provide. This macro maps them to the real
#     _gfortran_specific__*_r8 symbols.
#   * ffmpeg must be installed (00-deps) or configure aborts on the MPEG check.
#   * cb.c mouse-query guards (below) + the xforms fli_show_object_pixmap guard
#     (in 20-xforms.sh) together fix the long-standing xvs crash on data push.
###############################################################################
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

say "xvs: download + extract"
fetch "$XVS_URL" "$DIST/xvs.tar.gz"
rm -rf "$BUILD/xvs"
tar xzf "$DIST/xvs.tar.gz" -C "$BUILD"

# macOS/XQuartz fix (other half of the xvs crash fix; see also 20-xforms.sh):
# xvs's idle callback polls the mouse against canvas windows via XQueryPointer.
# On XQuartz, hiding a GL canvas during the panel repanel tears down its window,
# so the query BadWindow-crashes. Guard the 4 mouse-query helpers in cb.c to skip
# hidden / null-window canvases (a hidden canvas can't contain the mouse anyway).
say "xvs: patch cb.c mouse-query guards (macOS/XQuartz BadWindow fix)"
perl -0pi -e 's{if\( !gl \) return 0;\n\n   win = fl_get_real_object_window\(gl\);\n   fl_get_win_mouse\(win,&mouse_x,&mouse_y,&mouse_mask\);}{if( !gl || !gl->visible ) return 0;\n\n   win = fl_get_real_object_window(gl);\n   if( !win ) return 0;\n   fl_get_win_mouse(win,&mouse_x,&mouse_y,&mouse_mask);}g' \
  "$BUILD/xvs/src/cb.c"
[ "$(grep -c '!gl->visible' "$BUILD/xvs/src/cb.c")" -eq 4 ] \
  || die "cb.c mouse-query guards did not apply to all 4 sites"
echo "  patched cb.c (4 guards)"

export INCLUDE_PATHS="$PREFIX/include $X11/include $JPEG/include"
export LIB_PATHS="$PREFIX/lib $X11/lib $JPEG/lib $GFORTLIB"

GF="-DGFORTRAN43_OR_LATER"
export CFLAGS="-O2 $LENIENT $GF -I$PREFIX/include -I$X11/include -I$JPEG/include"
export CPPFLAGS="$GF -I$PREFIX/include -I$X11/include -I$JPEG/include"
export F77FLAGS="-O2 $FNOSECOND"
export F77LFLAGS="$FNOSECOND -L$PREFIX/lib -L$GFORTLIB"
export LDFLAGS="-L$PREFIX/lib -L$X11/lib -L$JPEG/lib -L$GFORTLIB -Wl,-rpath,$X11/lib"
export CCF77LIBS="-L$GFORTLIB -lgfortran -lquadmath -lm"

cd "$BUILD/xvs"
say "xvs: configure"
./configure --prefix="$PREFIX"

say "xvs: make install"
make install

say "xvs: verifying"
[ -x "$PREFIX/bin/xvs" ]      || die "xvs binary not built"
[ -x "$PREFIX/bin/sdftoxvs" ] || die "sdftoxvs not built"
echo "  xvs + sdftoxvs OK"
