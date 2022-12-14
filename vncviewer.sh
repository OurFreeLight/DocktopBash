#!/usr/bin/env bash

VNC_PATH="/opt/TurboVNC/bin/"
VNC_VIEWER="vncviewer"
VNC_OPTS=""
VNC_PORT=${1:-"5900"}

${VNC_PATH}${VNC_VIEWER} ${VNC_OPTS} 127.0.0.1:${VNC_PORT}
