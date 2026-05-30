#!/bin/bash
# Source this to use the locally-built RNPL / xvs / DV toolchain:
#     source env.sh
# Nothing here requires sudo; everything lives under this repo's ./install.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

export PATH="$REPO/install/bin:$PATH"

GFORTLIB="$(dirname "$(gfortran -print-file-name=libgfortran.dylib 2>/dev/null)" 2>/dev/null)"
export DYLD_FALLBACK_LIBRARY_PATH="$REPO/install/lib:/opt/X11/lib:$GFORTLIB:${DYLD_FALLBACK_LIBRARY_PATH:-/usr/local/lib:/usr/lib}"

# X display (XQuartz must be running: `open -a XQuartz`).
# Auto-detect the live display instead of hardcoding one: a stale launchd
# DISPLAY (e.g. a leftover ".../org.macports:0" path) or XQuartz coming up on
# :1 instead of :0 would otherwise send the GUIs to a server that isn't there.
# Probe each candidate X display and keep the first that actually answers.
_pick_display() {
  local d
  for d in "$(launchctl getenv DISPLAY 2>/dev/null)" :0 :1 :2; do
    [ -n "$d" ] || continue
    if DISPLAY="$d" /opt/X11/bin/xdpyinfo >/dev/null 2>&1; then echo "$d"; return; fi
  done
  echo ":0"   # fallback; start XQuartz with: open -a XQuartz
}
export DISPLAY="$(_pick_display)"
unset -f _pick_display

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
