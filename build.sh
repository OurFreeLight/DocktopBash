#!/usr/bin/env bash

set -e

help() {
    echo "Build script
Copyright (C) 2022, Freelight, Inc
Version: $(cat ./VERSION)

Usage: ./build.sh [options]

Options:
  --name(=string)                 Specify a custom name to use when building.
  --type(=string)                 The type of image to build.
  --window_manager(=string)       The window manager to use when building.
  --ubuntu_version(=string)       The ubuntu version to use.
  --base_image(=string)           The base image to use when building.
  --dockerfile(=string)           Specify a dockerfile to use to build.
  --build_dir(=string)            Specify a directory to build in.
  --version(=string)              Set the image version.
  --skip_latest                   Do not set this image tag as the latest.
  --timezone(=string)             Set the default timezone.

Types:
  all              Build all docker images.
  base             Build the base docker images.
  developer        Build the developer docker image.
  steam            Build the steam docker image.

Window Manager:
  all              Build all window manager docker images.
  gnome            Build only gnome type docker images.
  mate             Build only mate type docker images.
  xfce             Build only xfce type docker images.

Base images you can specify any base image you'd like to use, or select from:
Base Images:
  nvidia-opengl    Use the base nvidia glx image. This will only work on 
                   headless servers that do NOT have a GPU connected to X11.
"

    exit 1
}

NAME=""
DOCKERFILE=""
BUILD_DIR="."
IS_LATEST="1"
VERSION=$(cat ./VERSION)
TYPE="all"
WINDOW_MANAGER="mate"
BASEIMAGE="ubuntu:20.04"
UBUNTU_VERSION="20.04"
TIMEZONE="America/Phoenix"

while :; do
  case $1 in
    -h|-\?|--help)
      help

      exit 0
      ;;
    --name=?*)
      NAME="${1#*=}"
      ;;
    --dockerfile=?*)
      DOCKERFILE="${1#*=}"
      ;;
    --type=?*)
      TYPE="${1#*=}"
      ;;
    --window_manager=?*)
      WINDOW_MANAGER="${1#*=}"
      ;;
    --base_image=?*)
      BASEIMAGE="${1#*=}"
      ;;
    --ubuntu_version=?*)
      UBUNTU_VERSION="${1#*=}"
      ;;
    --build_dir=?*)
      BUILD_DIR="${1#*=}"
      ;;
    --version=?*)
      VERSION="${1#*=}"
      ;;
    --timezone=?*)
      TIMEZONE="${1#*=}"
      ;;
    --skip_latest)
      IS_LATEST="0"
      ;;
    *)
      break
  esac

  shift
done

if [ "$TYPE" == "all" ] || [ "$TYPE" == "base" ]; then
  cd ./images/
  ./build.sh $TYPE $WINDOW_MANAGER $BASEIMAGE $UBUNTU_VERSION
  cd ..;
fi

if [ "$TYPE" == "all" ] || [ "$TYPE" == "developer" ] || [ "$TYPE" == "steam" ]; then
  cd ./workspaces/
  ./build.sh $TYPE $WINDOW_MANAGER $UBUNTU_VERSION
  cd ..;
fi

if [ "$DOCKERFILE" != "" ]; then
  if [ "$NAME" == "" ]; then
    echo "You must set an image name using --name"

    exit 1
  fi

  docker build --progress=plain -t ${NAME}:${VERSION} \
        --build-arg TIMEZONE=$TIMEZONE --build-arg BASEIMAGE="$BASEIMAGE" \
        -f ${DOCKERFILE} ${BUILD_DIR}

  if [ "$IS_LATEST" == "1" ]; then
    docker tag ${NAME}:${VERSION} ${NAME}:latest;
  fi
fi