#!/usr/bin/env bash

source ../run_parse.sh
source ../run_config.sh

# Include any mounts in MOUNT_VOLUMES and SHARED_VOLUME here.

VERSION=$(cat ../VERSION)
BASE_CONTAINER_NAME="amd64_ubuntu${UBUNTU_VERSION}_docktop_${WINDOW_MANAGER}";
VOLUME_BASE_PATH="${MOUNT_BASE}/${BASE_CONTAINER_NAME}"

setupDocktop;
setupMounts "${VOLUME_BASE_PATH}" "$RUN_USER" "$RUN_GROUP";
startViewer "${VOLUME_BASE_PATH}";
updateOpts;

# Run gnome
if [ "$TYPE" == "all" ] || [ "$WINDOW_MANAGER" == "gnome" ]; then
    ${ECHO_CMD}docker run ${OPTS} --name amd64_ubuntu${UBUNTU_VERSION}_docktop_gnome \
        -p ${PORT}:${INTERNAL_PORT} \
        amd64/ubuntu${UBUNTU_VERSION}-docktop-gnome:${VERSION};
fi

# Run mate
if [ "$TYPE" == "all" ] || [ "$WINDOW_MANAGER" == "mate" ]; then
    ${ECHO_CMD}docker run ${OPTS} --name amd64_ubuntu${UBUNTU_VERSION}_docktop_mate \
        -p ${PORT}:${INTERNAL_PORT} \
        amd64/ubuntu${UBUNTU_VERSION}-docktop-mate:${VERSION};
fi

# Run xfce
if [ "$TYPE" == "all" ] || [ "$WINDOW_MANAGER" == "xfce" ]; then
    ${ECHO_CMD}docker run ${OPTS} --name amd64_ubuntu${UBUNTU_VERSION}_docktop_xfce \
        -p ${PORT}:${INTERNAL_PORT} \
        amd64/ubuntu${UBUNTU_VERSION}-docktop-xfce:${VERSION};
fi

if [ "$PID_TO_CLOSE1" != "" ]; then
   kill $PID_TO_CLOSE1
fi

if [ "$PID_TO_CLOSE2" != "" ]; then
   kill $PID_TO_CLOSE2
fi