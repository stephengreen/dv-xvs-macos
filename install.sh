#!/bin/bash
###############################################################################
# install.sh -- one-shot build of RNPL + xforms + XVS + DV on Apple-Silicon
# macOS, into a local ./install prefix (no sudo, nothing touches /usr/local).
#
# Usage:
#   ./install.sh            # full build: deps -> bundle -> xforms -> xvs -> dv
#   ./install.sh bundle     # run a single stage (deps|bundle|xforms|xvs|dv)
#
# After it finishes:  source env.sh   then run  DV &  or  xvs &
###############################################################################
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HERE/scripts"

run() { echo; echo "######## stage: $1 ########"; bash "$S/$2"; }

case "${1:-all}" in
  deps)   run deps   00-deps.sh ;;
  bundle) run bundle 10-bundle.sh ;;
  xforms) run xforms 20-xforms.sh ;;
  xvs)    run xvs    30-xvs.sh ;;
  dv)     run dv     40-dv.sh ;;
  all)
    run deps   00-deps.sh
    run bundle 10-bundle.sh
    run xforms 20-xforms.sh
    run xvs    30-xvs.sh
    run dv     40-dv.sh
    echo
    echo "############################################################"
    echo "  DONE. Everything is in $HERE/install"
    echo
    echo "  Next:"
    echo "    source $HERE/env.sh"
    echo "    make -C $HERE/examples       # generate sample .sdf data"
    echo "    DV &                         # 2D/3D viewer"
    echo "    sdftodv examples/gauss2d.sdf # push data to it"
    echo "############################################################"
    ;;
  *) echo "usage: $0 [all|deps|bundle|xforms|xvs|dv]"; exit 1 ;;
esac
