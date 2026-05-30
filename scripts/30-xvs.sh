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
###############################################################################
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

say "xvs: download + extract"
fetch "$XVS_URL" "$DIST/xvs.tar.gz"
rm -rf "$BUILD/xvs"
tar xzf "$DIST/xvs.tar.gz" -C "$BUILD"

# NOTE: xvs's GUI launches and renders fine, but on XQuartz it can hit an
# intermittent "BadDrawable / X_CopyArea" error and exit (a documented quirk of
# these xforms apps on modern X11). DV is unaffected. No reliable in-tree fix
# was found; left as a known issue. See README "Known issues".

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
