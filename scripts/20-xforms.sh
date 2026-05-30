#!/bin/bash
###############################################################################
# 20-xforms.sh -- build Matt Choptuik's patched xforms 1.2.4, the GUI toolkit
# both xvs and DV link against. Builds against XQuartz (/opt/X11) + libjpeg.
#
# We use v1.2.4 specifically: the rnpletal Ubuntu notes warn that a 2021 X11
# security patch made older xforms (1.0) crash DV randomly; 1.2.4 is the fix.
###############################################################################
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

say "xforms 1.2.4: download + extract"
fetch "$XFORMS_URL" "$DIST/xforms-1.2.4.tar.gz"
rm -rf "$BUILD/xforms-1.2.4"
tar xzf "$DIST/xforms-1.2.4.tar.gz" -C "$BUILD"

export CFLAGS="-O2 $LENIENT -I$X11/include -I$JPEG/include"
export CXXFLAGS="-O2 -I$X11/include -I$JPEG/include"
export CPPFLAGS="-I$X11/include -I$JPEG/include"
export LDFLAGS="-L$X11/lib -L$JPEG/lib -Wl,-rpath,$X11/lib"

cd "$BUILD/xforms-1.2.4"
say "xforms 1.2.4: configure"
./configure --prefix="$PREFIX" \
  --x-includes="$X11/include" --x-libraries="$X11/lib" \
  --disable-docs --disable-demos

say "xforms 1.2.4: make install"
make
make install

say "xforms 1.2.4: verifying"
[ -f "$PREFIX/lib/libforms.dylib" ] || die "libforms not built"
[ -f "$PREFIX/include/forms.h" ]    || die "forms.h not installed"
echo "  libforms + libformsGL + forms.h OK"
