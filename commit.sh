#!/usr/bin/env bash

CONTAINER_ID=$1
IMAGE_NAME=$2

if [ "$1" == "" ]; then
    echo "A container id is required!"

    exit 1
fi

if [ "$2" == "" ]; then
    echo "An image name is required!"

    exit 1
fi

docker exec "${CONTAINER_ID}" bash -c "sudo -u someone13 /opt/TurboVNC/bin/vncserver -kill \$DISPLAY" &

sleep 2

docker commit "${CONTAINER_ID}" "${IMAGE_NAME}"