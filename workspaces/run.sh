#!/usr/bin/env bash

source ../run_parse.sh
source ../run_config.sh

echo "Running with screen resolution $SCREEN_RESOLUTION"

VERSION=$(cat ../VERSION)
BASE_CONTAINER_NAME="amd64_ubuntu${UBUNTU_VERSION}_docktop_${WINDOW_MANAGER}"
BASE_IMAGE_NAME="amd64/ubuntu${UBUNTU_VERSION}-docktop-${WINDOW_MANAGER}"

if [ "$TYPE" == "developer" ]; then
   NAME="developer"
fi

if [ "$TYPE" == "steam" ]; then
   NAME="steam"
fi

if [ "$TYPE" == "custom" ]; then
   if [ "$NAME" == "" ]; then
      echo "You must set the name of the container using --name."

      exit 1
   fi
fi

BASE_CONTAINER_NAME="amd64_ubuntu${UBUNTU_VERSION}_docktop_$NAME";
VOLUME_BASE_PATH="${MOUNT_BASE}/${BASE_CONTAINER_NAME}"

if [ "$VIEW_ONLY" == "" ]; then
   setupDocktop;
   setupMounts "${VOLUME_BASE_PATH}" "$RUN_USER" "$RUN_GROUP";
fi

startViewer "${VOLUME_BASE_PATH}";

if [ "$VIEW_ONLY" == "1" ]; then
   while :
   do
      sleep 1
   done;
fi

if [ "$VIEW_ONLY" == "" ]; then
   updateOpts;

   # Run developer
   if [ "$TYPE" == "developer" ]; then
      ${ECHO_CMD}docker run ${OPTS} --name ${BASE_CONTAINER_NAME}_developer \
         -p ${PORT}:${INTERNAL_PORT} \
         ${BASE_IMAGE_NAME}-developer:${VERSION};
   fi

   # Run steam
   if [ "$TYPE" == "steam" ]; then
      ${ECHO_CMD}docker run ${OPTS} --name ${BASE_CONTAINER_NAME}_steam \
         -p ${PORT}:${INTERNAL_PORT} \
         ${BASE_IMAGE_NAME}-steam:${VERSION};
   fi

   # Run custom image
   if [ "$TYPE" == "custom" ]; then
      ${ECHO_CMD}docker run ${OPTS} --name ${BASE_CONTAINER_NAME} \
         -p ${PORT}:${INTERNAL_PORT} \
         ${IMAGE};
   fi
fi

if [ "$PID_TO_CLOSE1" != "" ]; then
   kill $PID_TO_CLOSE1
fi

if [ "$PID_TO_CLOSE2" != "" ]; then
   kill $PID_TO_CLOSE2
fi
