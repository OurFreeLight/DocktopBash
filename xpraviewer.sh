#!/usr/bin/env bash

XPRA_PATH=""
XPRA_VIEWER="xpra"
XPRA_OPTS=""
XPRA_PORT=${1:-"5900"}

${XPRA_PATH}${XPRA_VIEWER} start-desktop tcp:127.0.0.1:${XPRA_PORT} ${XPRA_OPTS}