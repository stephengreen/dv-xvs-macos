#!/bin/bash
###############################################################################
# 00-deps.sh -- check/install external dependencies.
#   - Homebrew packages: gcc (gfortran), jpeg-turbo, ffmpeg, autoconf, automake
#   - XQuartz (the macOS X11 server) -- required, installs to /opt/X11
###############################################################################
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

say "Checking command-line tools (clang, make)"
command -v clang >/dev/null || die "clang not found. Run: xcode-select --install"
command -v make  >/dev/null || die "make not found. Run: xcode-select --install"

say "Checking Homebrew"
command -v brew >/dev/null || die "Homebrew not found. Install from https://brew.sh"

say "Installing Homebrew packages (gcc, jpeg-turbo, ffmpeg, autoconf, automake)"
# gcc provides gfortran; ffmpeg satisfies xvs's MPEG-encoder configure check;
# jpeg-turbo provides libjpeg for xforms/xvs/DV screenshot export.
for pkg in gcc jpeg-turbo ffmpeg autoconf automake; do
  if brew list --versions "$pkg" >/dev/null 2>&1; then
    echo "  $pkg already installed"
  else
    echo "  installing $pkg"
    brew install "$pkg"
  fi
done

command -v gfortran >/dev/null || die "gfortran still not found after 'brew install gcc'"

say "Checking XQuartz (X11 server)"
if [ -d /opt/X11 ] && [ -f /opt/X11/lib/libX11.dylib ]; then
  echo "  XQuartz present at /opt/X11"
else
  echo "  XQuartz NOT found -- installing (requires your admin password)"
  brew install --cask xquartz || die "XQuartz install failed; install manually from https://www.xquartz.org"
  echo
  echo "  *** IMPORTANT: log out and back in once so XQuartz registers, ***"
  echo "  *** then re-run the install.                                   ***"
fi

# GLUT ships inside XQuartz; DV needs it.
[ -f /opt/X11/lib/libglut.dylib ] || echo "  (note: libglut not found in /opt/X11 -- DV needs it; update XQuartz)"

say "Dependencies OK"
echo "  gfortran : $(command -v gfortran)"
echo "  jpeg     : $JPEG"
echo "  X11      : $X11"
echo "  ffmpeg   : $(command -v ffmpeg || echo MISSING)"
