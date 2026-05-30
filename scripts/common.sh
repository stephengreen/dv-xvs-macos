#!/bin/bash
###############################################################################
# common.sh -- shared configuration for the DV/XVS macOS build scripts.
# Sourced by every stage script. Defines paths, the toolchain, and the
# clang/gfortran flag sets that make the 2000s-era sources build on a modern
# Apple-Silicon toolchain.
###############################################################################

# --- repo layout ------------------------------------------------------------
# REPO is the directory containing this repo (one level up from scripts/).
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO="$(cd "$SCRIPTS_DIR/.." && pwd)"

PREFIX="${DVXVS_PREFIX:-$REPO/install}"   # local install tree (no sudo)
BUILD="$REPO/build"                        # extracted sources
DIST="$REPO/dist"                          # downloaded tarballs
mkdir -p "$PREFIX/bin" "$PREFIX/lib" "$PREFIX/include" "$BUILD" "$DIST"

# --- upstream (UBC Numerical Relativity FTP) --------------------------------
FTP="ftp://laplace.physics.ubc.ca/pub"
RNPLETAL_URL="$FTP/rnpletal/rnpletal.tar.gz"
XFORMS_URL="$FTP/xforms-1.2.4/xforms-1.2.4.tar.gz"
XVS_URL="$FTP/xvs/xvs.tar.gz"
DV_URL="$FTP/DV/DV.tar.gz"

# --- external dependencies (Homebrew + XQuartz) -----------------------------
X11="/opt/X11"
: "${HOMEBREW_PREFIX:=$(brew --prefix 2>/dev/null || echo /opt/homebrew)}"
JPEG="$(brew --prefix jpeg-turbo 2>/dev/null || brew --prefix jpeg 2>/dev/null || echo "$HOMEBREW_PREFIX/opt/jpeg-turbo")"
GFORTLIB="$(dirname "$(gfortran -print-file-name=libgfortran.dylib 2>/dev/null)" 2>/dev/null)"

# --- toolchain --------------------------------------------------------------
export CC="clang"
export CXX="clang++"
export F77="gfortran"
export F90="gfortran"
export PATH="$PREFIX/bin:$PATH"   # so configure finds the freshly-built rnpl

# clang 17+ promotes several legacy-C patterns to hard errors; relax them so the
# old sources compile. (-fcommon restores pre-clang-11 tentative-definition
# merging that this code relies on.)
LENIENT="-fcommon -Wno-implicit-function-declaration -Wno-implicit-int \
-Wno-error=implicit-function-declaration -Wno-error=implicit-int \
-Wno-error=int-conversion -Wno-error=incompatible-function-pointer-types \
-Wno-error=return-type -Wno-error=deprecated-non-prototype"

# Fortran-only flag: gfortran adds a trailing underscore by default; the C glue
# in these packages expects single-underscore names. Keep this OFF the C/clang
# link line (it is not a valid clang flag).
FNOSECOND="-fno-second-underscore"

# Helpers ---------------------------------------------------------------------
say()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# fetch URL DEST -- download once, verify it is a valid gzip.
fetch() {
  local url="$1" dest="$2"
  if gzip -t "$dest" 2>/dev/null; then echo "  have $(basename "$dest")"; return; fi
  echo "  downloading $(basename "$dest")"
  curl -fSL --retry 3 -m 600 "$url" -o "$dest" || die "download failed: $url"
  gzip -t "$dest" 2>/dev/null || die "downloaded file is not valid gzip: $dest"
}
