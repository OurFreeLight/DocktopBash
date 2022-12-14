#!/bin/bash

echo "Starting as user: $USER"

if [ -f "/home/$USER/.bashrc" ]; then
    echo "Home directory for $USER exists..."
else
    docktop restore_home $USER
fi

touch ~/.Xauthority

if [ "$USE_VIEWER" == "vnc" ] || [ "$USE_VIEWER" == "xpra" ]; then
    if [ -d "/dev/dri" ] && [ "$USE_VGL" == "1" ]; then
        if [ -x "$(command -v /opt/VirtualGL/bin/eglinfo)" ]; then
            for DRM in /dev/dri/card*; do
                if /opt/VirtualGL/bin/eglinfo "$DRM"; then
                    export VGL_DISPLAY="$DRM"
                    break
                fi
            done
        fi
    fi
fi

if [ "$USE_VIEWER" == "x11_forwarding" ] || [ "$USE_VIEWER" == "weston" ]; then
    echo "Using viewer ${USE_VIEWER}"

    bash -c "$TVNC_WM --display=$DISPLAY"
else
    if [ "$USE_VIEWER" == "vnc" ]; then
        VGL_OPTION=""

        if [ "$USE_VGL" == "1" ] && [ "$VGL_DISPLAY" != "" ]; then
            VGL_OPTION="-vgl"
        fi

        echo "Starting TurboVNC on display $DISPLAY with geometry $SCREEN_RESOLUTION"
        /opt/TurboVNC/bin/vncserver $DISPLAY -SecurityTypes none $VGL_OPTION -geometry $SCREEN_RESOLUTION
    fi

    if [ "$USE_VIEWER" == "xpra" ]; then
        echo "Starting Xpra on display $DISPLAY with geometry $SCREEN_RESOLUTION"
        xpra start --bind-tcp=0.0.0.0:5901 --html=on --start-child="$TVNC_WM" --exit-with-children=no --daemon=no --pulseaudio=yes --notifications=no --bell=no $DISPLAY
    fi
fi

while :
do
    sleep 1
done