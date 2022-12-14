#!/bin/bash

echo "Using viewer ${USE_VIEWER}"

if [ "$USE_VIEWER" == "vnc" ] || [ "$USE_VIEWER" == "xpra" ]; then
    if [ -d "/dev/dri" ] && [ "$USE_VGL" == "1" ]; then
        if [ -x "$(command -v vglserver_config)" ]; then
            printf "3\nN\nX\n" | vglserver_config
        fi
    fi
fi

if [ "$USE_AUDIO" == "" ]; then
    rm -f /etc/pulse/client.conf
fi

sudo \
    PATH=$PATH \
    DISPLAY=$DISPLAY \
    USE_DISPLAY=$USE_DISPLAY \
    SCREEN_RESOLUTION=$SCREEN_RESOLUTION \
    TVNC_WM="$TVNC_WM" \
    USE_VIEWER="$USE_VIEWER" \
    USE_VGL="$USE_VGL" \
    USE_AUDIO="$USE_AUDIO" \
    PULSE_SERVER="$PULSE_SERVER" \
    ALSA_CARD="$ALSA_CARD" \
    -u $USER \
    /etc/docktop/entrypoint.sh
