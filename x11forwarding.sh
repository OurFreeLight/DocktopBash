#!/usr/bin/env bash

USE_DISPLAY=$1

/usr/bin/Xorg ${USE_DISPLAY} vt8  \
  -retro \
  +extension RANDR \
  +extension RENDER \
  +extension GLX \
  +extension XVideo \
  +extension DOUBLE-BUFFER \
  +extension SECURITY \
  +extension DAMAGE \
  +extension X-Resource \
  -extension XINERAMA -xinerama \
  -extension MIT-SHM \
  +extension Composite +extension COMPOSITE \
  -extension XTEST -tst \
  -dpms \
  -s off \
  -nolisten tcp \
  -dpi 96 \
  -verbose && \
./runs/steam.sh