#!/usr/bin/env bash

RUN_USER=$1
VIEWER=${2:-"x11_forwarding"}

# Running containers as privileged is not secure.
# Unfortunately a lot of games will not run unless running inside a privileged container with 
# /dev/fuse mounted.

./run.sh --privileged \
    --device="/dev/fuse" \
    --cap_add="SYS_ADMIN" \
    --env="ALSA_CARD=1" \
    --env="ALSA_PCM_CARD=0" \
    --env="PULSE_SERVER=''" \
    --device="/dev/input/js0" \
    --no_audio \
    --display=":5" \
    --max_ulimit \
    --viewer="$VIEWER" \
    --user=$RUN_USER \
    --container_user=$RUN_USER \
    --docktop_home=$(pwd)/docktop_data/ \
    --image=ourfreelight/steam:0.3.5 \
    --name=ourfreelight_steam \
    --display_name="Steam" \
    --type=custom
