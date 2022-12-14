#!/usr/bin/env bash

TYPE=$1
WINDOW_MANAGER=$2
BASEIMAGE=$3
UBUNTU_VERSION=$4

VERSION=$(cat ../VERSION)
FIND_GROUP_NAME="docker"
TIMEZONE="America/Phoenix"

if [ "$BASEIMAGE" == "nvidia-opengl" ]; then
    BASEIMAGE="nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04"
fi

if [ "$(uname -a | grep Darwin)" ]; then
    FIND_GROUP_NAME="daemon"
fi

HOST_DOCKER_GID=$(cut -d: -f3 < <(cat /etc/group | grep $FIND_GROUP_NAME))
HOST_DOCKER_GROUP=$FIND_GROUP_NAME

echo "Found docker group (id: $HOST_DOCKER_GID) $HOST_DOCKER_GROUP"
echo "Building with base image ${BASEIMAGE}"
echo "Base Image Building using Ubuntu $UBUNTU_VERSION"

# Build gnome
if [ "$WINDOW_MANAGER" == "all" ] || [ "$WINDOW_MANAGER" == "gnome" ]; then
    docker build --progress=plain -t amd64/ubuntu${UBUNTU_VERSION}-docktop-gnome:$VERSION \
        --build-arg HOST_DOCKER_GROUP=$HOST_DOCKER_GROUP --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID \
        --build-arg TIMEZONE=$TIMEZONE --build-arg BASEIMAGE=$BASEIMAGE \
        -f ./ubuntu${UBUNTU_VERSION}-gnome.amd64.dockerfile .
    docker tag amd64/ubuntu${UBUNTU_VERSION}-docktop-gnome:$VERSION \
        amd64/ubuntu${UBUNTU_VERSION}-docktop-gnome:latest;
fi

# Build mate
if [ "$WINDOW_MANAGER" == "all" ] || [ "$WINDOW_MANAGER" == "mate" ]; then
    docker build --progress=plain -t amd64/ubuntu${UBUNTU_VERSION}-docktop-mate:$VERSION \
        --build-arg HOST_DOCKER_GROUP=$HOST_DOCKER_GROUP --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID \
        --build-arg TIMEZONE=$TIMEZONE --build-arg BASEIMAGE=$BASEIMAGE \
        -f ./ubuntu${UBUNTU_VERSION}-mate.amd64.dockerfile .
    docker tag amd64/ubuntu${UBUNTU_VERSION}-docktop-mate:$VERSION \
        amd64/ubuntu${UBUNTU_VERSION}-docktop-mate:latest;
fi

# Build XFCE
if [ "$WINDOW_MANAGER" == "all" ] || [ "$WINDOW_MANAGER" == "xfce" ]; then
    docker build --progress=plain -t amd64/ubuntu${UBUNTU_VERSION}-docktop-xfce:$VERSION \
        --build-arg HOST_DOCKER_GROUP=$HOST_DOCKER_GROUP --build-arg HOST_DOCKER_GID=$HOST_DOCKER_GID \
        --build-arg TIMEZONE=$TIMEZONE --build-arg BASEIMAGE=$BASEIMAGE \
        -f ./ubuntu${UBUNTU_VERSION}-xfce.amd64.dockerfile .
    docker tag amd64/ubuntu${UBUNTU_VERSION}-docktop-xfce:$VERSION \
        amd64/ubuntu${UBUNTU_VERSION}-docktop-xfce:latest;
fi