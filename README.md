# DV & XVS on Apple-Silicon macOS

Build **DV**, **XVS**, and **RNPL** — Matthew Choptuik's numerical-relativity
visualization/analysis tools — natively on a modern Apple-Silicon Mac.

- **RNPL** — *Rapid Numerical Prototyping Language*; compiles high-level PDE
  descriptions into finite-difference Fortran/C. Also provides the **SDF**
  (Simple Data Format) I/O library `libbbhutil`.
- **XVS** — Xforms/OpenGL viewer for **1D** time-dependent data.
- **DV** ("Data Vault") — Xforms/OpenGL viewer for **2D/3D** (and AMR) data.

The upstream instructions ([UBC Numerical Relativity](https://laplace.physics.ubc.ca/Doc/rnpletal/),
linked from Frans Pretorius's [Intro to RNPL](https://fpretori.scholar.princeton.edu/introduction-rnpl))
target Linux. The sources are from the early 2000s and **do not build as-is**
on a current macOS toolchain (clang 17, gfortran 15, Apple Silicon). This repo
carries the small set of patches and the exact build/runtime configuration that
make them work — installing entirely into a local prefix, **no `sudo`**.

> Verified on macOS 15.7 (Sequoia), Apple Silicon (arm64), Xcode clang 17,
> Homebrew gcc/gfortran 15, XQuartz 2.8.

---

## Quick start

```bash
git clone <this-repo> dv-xvs-macos
cd dv-xvs-macos

./install.sh                 # deps → rnpletal → xforms → xvs → DV  (~10–15 min)

source env.sh                # sets PATH, DISPLAY, HOSTNAME=localhost, …
make -C examples             # build the sample data generators
( cd examples && ./test_2d ) # writes examples/gauss2d.sdf

open -a XQuartz              # start the X server (once)
DV &                         # the Data Vault window appears
sdftodv examples/gauss2d.sdf # push the animated 2D surface into DV
```

In DV: double-click the `gauss2d` register in the browser → **Send to local
view** → the OpenGL surface opens; the time slider animates the 20 frames.

For 1D: `( cd examples && ./test_1d )` then `xvs &` and `sdftoxvs examples/wave.sdf`.

---

## Prerequisites

`./install.sh deps` installs/checks all of these for you:

| Need | Provides | Install |
|------|----------|---------|
| Xcode CLT | clang, make | `xcode-select --install` |
| Homebrew | package manager | <https://brew.sh> |
| `gcc` | **gfortran** | `brew install gcc` |
| `jpeg-turbo` | libjpeg (screenshots) | `brew install jpeg-turbo` |
| `ffmpeg` | MPEG export (xvs configure **requires** an encoder) | `brew install ffmpeg` |
| `autoconf`, `automake` | regenerating configures (rarely) | `brew install autoconf automake` |
| **XQuartz** | the macOS X11 server + GLUT/GL at `/opt/X11` | `brew install --cask xquartz` |

After installing XQuartz the **first** time, log out and back in once so it
registers, then run `open -a XQuartz`.

---

## What the build does

`install.sh` runs five stages (each is a standalone script in `scripts/`):

1. **deps** — Homebrew packages + XQuartz.
2. **bundle** (`rnpletal.tar.gz`) — RNPL compiler, `libbbhutil` (SDF), `vutil`,
   `utilio`, `utilmath`, `svs`, and netlib BLAS/LAPACK. No X11.
3. **xforms** (`xforms-1.2.4.tar.gz`) — GUI toolkit, built against XQuartz.
4. **xvs** (`xvs.tar.gz`) — the 1D viewer.
5. **DV** (`DV.tar.gz`) — the 2D/3D viewer.

Sources are downloaded from the UBC FTP server into `dist/`, extracted into
`build/`, and installed into `install/` (`bin/`, `lib/`, `include/`). Re-running
any stage re-extracts and re-patches from the cached tarball, so it's idempotent.

---

## The macOS-specific fixes (why this repo exists)

Each is applied automatically by the scripts; documented here so you know what
changed and why.

### 1. `<sys/sysmacros.h>` — Linux-only header *(bundle)*
`bbhutil.h` includes it for `major()/minor()/makedev()`. That header is
glibc-only; macOS supplies those macros via `<sys/types.h>`. We guard it:
```c
#ifndef __APPLE__
#include <sys/sysmacros.h>
#endif
```
Without this, `bbhutil.o`/`sdf.o` silently fail to compile and `libbbhutil.a`
is archived **incomplete** — every later link against SDF then fails.

### 2. `<malloc.h>` — Linux-only header *(DV)*
~20 DV sources include `<malloc.h>`; on macOS `malloc` comes from `<stdlib.h>`.
Same `#ifndef __APPLE__` guard.
(`<values.h>` also appears but is already `#ifdef HAVE_VALUES_H`-guarded and
configure correctly finds it absent — no patch needed.)

### 3. `-DGFORTRAN43_OR_LATER` — Fortran intrinsic names *(xvs)*
xvs's `configure` tries to detect the gfortran "flavour" and on gfortran 15
prints *"Unimplemented version of gfortran encountered"* and **fails to define
the GFORTRAN macro**. `f77_intrinsics.h` then falls back to f2c names
(`d_sin`, `d_abs`, `d_sqrt`, …) that gfortran does **not** provide → a wall of
`Undefined symbols for architecture arm64`. Forcing this macro maps them to the
real `_gfortran_specific__*_r8` symbols that live in `libgfortran`.

### 4. ffmpeg + the MPEG-encoder check *(xvs)*
xvs `configure` **aborts** if it finds no MPEG encoder. Installing `ffmpeg`
(done in `deps`) satisfies it natively. (Alternatively `export MPEG_ENCODER=none`
to disable movie export.)

### 5. GLUT/GLU on the link line *(DV)*
DV's auto-detected `LIBS` omits GLUT/GLU; we pass them explicitly via
`XTRALIBS="-lglut -lGLU -lGL -lXext -lXmu -lXi -lX11"` (all shipped inside
XQuartz).

Plus modern-clang hygiene applied throughout: `-fcommon` and
`-Wno-error=implicit-function-declaration,implicit-int,int-conversion,…` so the
legacy C compiles; and Fortran's `-fno-second-underscore` is kept **off** the
C/clang link line (it isn't a clang flag) while the gfortran runtime
(`-lgfortran -lquadmath`) is added wherever clang links Fortran objects.

---

## Runtime configuration (`env.sh`)

`source env.sh` sets four things that matter on macOS:

- **`PATH`** / **`DYLD_FALLBACK_LIBRARY_PATH`** → the local `install/` tree.
- **`DISPLAY=:0`** → XQuartz. Forced to `:0` because a stale launchd `DISPLAY`
  (e.g. an `org.macports:0` path) makes the GUIs connect to the wrong server and
  **no window appears**.
- **`HOSTNAME=localhost`, `XVSHOST=localhost`, `DVHOST=localhost`** → the crucial
  one. xvs/DV use a **client/server socket model**: the GUI is a server that
  binds to the address of its hostname, and the `sdfto*` tools are clients that
  connect to `*HOST`. A Mac's own short hostname usually isn't resolvable (not in
  `/etc/hosts`), so the server's `gethostbyname()` fails with **"Unknown host"**
  and clients can't connect. These tools honor a `HOSTNAME` override, and
  `localhost` always resolves to `127.0.0.1` — **no `sudo`, no `/etc/hosts` edit.**

---

## Usage

```
DV &                     # start the 2D/3D viewer (server)
sdftodv  file.sdf …      # send SDF data to DV
xvs &                    # start the 1D viewer (server)
sdftoxvs file.sdf …      # send SDF data to xvs
```

SDF inspection/manipulation tools (also installed): `sdfinfo`, `sdfdump`,
`sdftodv`, `sdftoxvs`, `sdfslice`, `sdftranspose`, `sdfrank`, `sdffilter`, …

Writing SDF from your own C — link against `libbbhutil` (see `examples/`):
```c
#include <bbhutil.h>
int    shape[2] = {nx, ny};
double bbox[4]  = {x0, x1, y0, y1};
gft_out_bbox("myfield", time, shape, 2, bbox, data);   /* -> myfield.sdf */
```
```
clang myprog.c -I install/include -L install/lib -lbbhutil \
      -L "$(dirname $(gfortran -print-file-name=libgfortran.dylib))" \
      -lgfortran -lquadmath -lm -o myprog
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `ser0_start: ... Unknown host` / client `Connect failed` | `source env.sh` (sets `HOSTNAME=localhost`). |
| GUI launches but **no window** | XQuartz not running (`open -a XQuartz`) or wrong `DISPLAY`; `env.sh` forces `:0`. |
| `configure: error` after "Can't find an MPEG encoder" | `brew install ffmpeg` (or `export MPEG_ENCODER=none`). |
| `Undefined symbols: _d_sin, _d_abs, …` (xvs) | the `-DGFORTRAN43_OR_LATER` fix — rerun `./install.sh xvs`. |
| `'sys/sysmacros.h' file not found` | the bundle patch — rerun `./install.sh bundle`. |
| `ld: library 'gfortran' not found` | `brew install gcc`; `env.sh`/scripts locate it via `gfortran -print-file-name`. |
| DV: `copying /usr/local/lib/DV/default_opts.dvo … No such file` | harmless; `env.sh` seeds `~/.DV/` to silence it. |

---

## Known issues

- **xvs exits on a `BadDrawable` (X_CopyArea) error when data is sent.** The xvs
  GUI launches and renders, but the *first plot redraw* (triggered by
  `sdftoxvs`) issues a BadDrawable on XQuartz and Xlib's default handler turns
  it into `exit()`. In testing this was **deterministic on the data push** (8/8
  trials), not random — a sit-idle xvs stays up; pushing data kills it.
  Toggling XQuartz indirect GLX (`enable_iglx` on **and** off, with restarts)
  made **no difference** — so it is not a GLX-mode issue. **DV is unaffected**
  and handles 1D data too, so the practical workaround is to use DV for 1D.
  (A proper fix would require patching xvs's redraw path; not yet found.)

- **A stale `org.macports.startx` launchd agent can hijack `DISPLAY`.** If
  `launchctl getenv DISPLAY` shows a `.../org.macports:0` path (a leftover that
  can exist even on brew-only systems) or XQuartz comes up on `:1` instead of
  `:0`, hardcoding `DISPLAY=:0` sends the GUIs to a dead server and no window
  appears. `env.sh` handles this by **probing each candidate display and using
  the first that answers**, so it works regardless. If things still seem stuck,
  **log out and back in** — XQuartz's first run after install needs a fresh
  login to register its launchd agent cleanly.

---

## Credits & license

RNPL, xvs, and DV are by **Matthew W. Choptuik** (UBC) and collaborators;
the patched **xforms 1.2.4** is also redistributed by UBC. This repo contains
**only** build scripts and documentation — it downloads the upstream sources at
build time and does not redistribute them. All rights to those packages remain
with their authors. Report tool bugs to UBC; report build-script issues here.
