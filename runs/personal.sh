#!/usr/bin/env bash

RUN_USER=$1
VIEWER=${2:-"weston"}

./run.sh \
    --display=":4" \
    --max_ulimit \
    --viewer="$VIEWER" \
    --docktop_home=$(pwd)/docktop_data/ \
    --user=$RUN_USER \
    --image=ourfreelight/personal:0.3.5 \
    --name=ourfreelight_personal \
    --display_name="Personal" \
    --type=custom
