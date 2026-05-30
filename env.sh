#!/bin/bash
# Source this to use the locally-built RNPL / xvs / DV toolchain:
#     source env.sh
# Nothing here requires sudo; everything lives under this repo's ./install.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

export PATH="$REPO/install/bin:$PATH"

GFORTLIB="$(dirname "$(gfortran -print-file-name=libgfortran.dylib 2>/dev/null)" 2>/dev/null)"
export DYLD_FALLBACK_LIBRARY_PATH="$REPO/install/lib:/opt/X11/lib:$GFORTLIB:${DYLD_FALLBACK_LIBRARY_PATH:-/usr/local/lib:/usr/lib}"

# X display (XQuartz must be running: `open -a XQuartz`).
# Force :0 -- a stale launchd DISPLAY (e.g. an "org.macports:0" path) makes
# DV/xvs connect to the wrong X server and their windows never appear.
export DISPLAY=:0

# CRITICAL on macOS: xvs/DV use a client/server socket model. The server binds
# to the address of its hostname; the client connects to *HOST. A Mac's own
# short hostname is usually NOT resolvable (not in /etc/hosts), so the server's
# gethostbyname() fails with "Unknown host". These tools honor a HOSTNAME
# override, and "localhost" always resolves to 127.0.0.1 -- no sudo needed.
export HOSTNAME=localhost
export XVSHOST=localhost
export DVHOST=localhost

# DV copies default options from a hardcoded prefix on first run; seed ~/.DV so
# that path is never needed (otherwise a harmless "No such file" warning prints).
if [ ! -f "$HOME/.DV/default_opts.dvo" ] && [ -f "$REPO/install/lib/DV/default_opts.dvo" ]; then
  mkdir -p "$HOME/.DV" && cp "$REPO/install/lib/DV/default_opts.dvo" "$HOME/.DV/" 2>/dev/null
fi

echo "RNPL/xvs/DV ready.  DISPLAY=$DISPLAY  HOSTNAME=$HOSTNAME"
echo "  DV &   ; sdftodv  file.sdf      (2D/3D)"
echo "  xvs &  ; sdftoxvs file.sdf      (1D)"
