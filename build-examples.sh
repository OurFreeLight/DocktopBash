#!/usr/bin/env bash

VERSION=$(cat ./VERSION)
UBUNTU_VERSION=${1:-"20.04"}

echo "Building using Ubuntu ${UBUNTU_VERSION}"

./build.sh --dockerfile="./workspaces/personal.dockerfile" --name="ourfreelight/personal" --base_image="amd64/ubuntu${UBUNTU_VERSION}-docktop-mate:${VERSION}" --ubuntu_version="$UBUNTU_VERSION"

docker tag amd64/ubuntu${UBUNTU_VERSION}-docktop-mate-steam:${VERSION} ourfreelight/steam:${VERSION}
docker tag amd64/ubuntu${UBUNTU_VERSION}-docktop-mate-steam:${VERSION} ourfreelight/wine:${VERSION}