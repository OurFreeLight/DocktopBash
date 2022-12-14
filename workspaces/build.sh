#!/usr/bin/env bash

TYPE=$1
WINDOW_MANAGER=$2
UBUNTU_VERSION=$3

VERSION=$(cat ../VERSION)
BASE_IMAGE_NAME="amd64/ubuntu${UBUNTU_VERSION}-docktop-${WINDOW_MANAGER}"
USE_BASEIMAGE="amd64/ubuntu${UBUNTU_VERSION}-docktop-${WINDOW_MANAGER}:${VERSION}"
TIMEZONE="America/Phoenix"

echo "Building with base image ${USE_BASEIMAGE}"

# Build developer image
if [ "$TYPE" == "all" ] || [ "$TYPE" == "developer" ]; then
    docker build --progress=plain -t ${BASE_IMAGE_NAME}-developer:$VERSION \
         --build-arg TIMEZONE=$TIMEZONE --build-arg BASEIMAGE=$USE_BASEIMAGE \
        -f ./developer.dockerfile .
    docker tag ${BASE_IMAGE_NAME}-developer:$VERSION ${BASE_IMAGE_NAME}-developer:latest;
fi

# Build steam image
if [ "$TYPE" == "all" ] || [ "$TYPE" == "steam" ]; then
    docker build --progress=plain -t ${BASE_IMAGE_NAME}-steam:$VERSION  \
         --build-arg TIMEZONE=$TIMEZONE --build-arg BASEIMAGE=$USE_BASEIMAGE \
         -f ./steam${UBUNTU_VERSION}.dockerfile .
    docker tag ${BASE_IMAGE_NAME}-steam:$VERSION ${BASE_IMAGE_NAME}-steam:latest;
fi

# Build wine image
if [ "$TYPE" == "all" ] || [ "$TYPE" == "wine" ]; then
    docker build --progress=plain -t ${BASE_IMAGE_NAME}-wine:$VERSION  \
         --build-arg TIMEZONE=$TIMEZONE --build-arg BASEIMAGE=$USE_BASEIMAGE \
         -f ./wine${UBUNTU_VERSION}.dockerfile .
    docker tag ${BASE_IMAGE_NAME}-wine:$VERSION ${BASE_IMAGE_NAME}-wine:latest;
fi