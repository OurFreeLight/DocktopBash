#!/usr/bin/env bash

UBUNTU_VERSION=20.04

NAME=$1
DOCKTOP_HOME=${2:-"$HOME/.docktop"}
PATH="${DOCKTOP_HOME}/amd64_ubuntu${UBUNTU_VERSION}_docktop_$NAME"

tar -czvf ./${NAME}.tar.gz $PATH/