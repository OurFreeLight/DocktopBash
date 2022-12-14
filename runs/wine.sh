#!/usr/bin/env bash

RUN_USER=$1
VIEWER=${2:-"weston"}

./run.sh --privileged \
    --display=":6" \
    --viewer="$VIEWER" \
    --max_ulimit \
    --user=$RUN_USER \
    --container_user=$RUN_USER \
    --docktop_home=$(pwd)/docktop_data/ \
    --image=ourfreelight/wine:0.3.5 \
    --name=ourfreelight_wine \
    --display_name="Wine" \
    --type=custom
