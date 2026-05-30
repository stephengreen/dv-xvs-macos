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

# macOS/XQuartz fix (half of the xvs crash fix; see also 30-xvs.sh): the object
# back-pixmap blit fli_show_object_pixmap() lacks the `w/h <= 0` guard that its
# sibling fli_show_form_pixmap() has. During xvs's panel repanel a widget can go
# momentarily zero-height; the unguarded version then issues a degenerate
# X_CopyArea that XQuartz rejects with BadDrawable, and Xlib's default handler
# exit()s the GUI. Add the missing guard (parity with the form-pixmap version).
say "xforms 1.2.4: patch fli_show_object_pixmap (macOS/XQuartz BadDrawable fix)"
perl -0pi -e 's{(\|\| ! p->win\n)(\s*)(\|\| NON_SQB\( obj \) \))}{$1$2|| p->w <= 0\n$2|| p->h <= 0\n$2$3}' \
  "$BUILD/xforms-1.2.4/lib/xsupport.c"
[ "$(grep -c 'p->w <= 0' "$BUILD/xforms-1.2.4/lib/xsupport.c")" -eq 2 ] \
  || die "xsupport.c fli_show_object_pixmap guard did not apply"
echo "  patched xsupport.c"

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
