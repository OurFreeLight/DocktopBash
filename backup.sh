#!/usr/bin/env bash

NAME=$1
DOCKTOP_HOME=${2:-"$HOME/.docktop"}
UBUNTU_VERSION=${3:-"20.04"}
DIR_PATH="${DOCKTOP_HOME}/amd64_ubuntu${UBUNTU_VERSION}_docktop_$NAME"

if [ "$NAME" == "" ]; then
    echo "Name not set!"

    exit;
fi

mkdir ./temp 2>/dev/null

tar -czvf ./temp/${NAME}.tar.gz $DIR_PATH/