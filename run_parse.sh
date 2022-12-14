#!/usr/bin/env bash

help() {
  echo "DockTop run script
Copyright (C) 2022, Freelight, Inc
Version: $(cat ./VERSION)

Usage: ./run.sh [options]

Options:
  --image(=string)                The image to use when running a custom image.
  --name(=string)                 The name of the container to run.
  --view_only                     If set, the container will not run, and will instead connect to an existing container.
  --display_name(=string)         The display name to use when running a container in a window (such as Weston).
  --type(=string)                 The type of container to run.
  --entrypoint(=string)           Set an entrypoint. Set to \"empty\" if you want to have an 
                                  empty entrypoint.
  --echo_cmd                      Echo out the final docker command to be executed.
  --no_audio                      Do not use pulse audio.
  --no_gpu                        Do not use the gpu.
  --use_vgl                       Use VirtualGL, works well with VNC, has visual issues however.
  --device(=string)               Attach a usb device.
  --display(=string)              Set the display to use.
  --env(=string)                  Set custom environmental variables to use.
  --list_usb_devices              List usb devices.
  --privileged                    Run the container in with privileged rights. SECURITY WARNING. 
                                  ONLY USE FOR TESTING OR WHEN USING SECURE CONTAINERS.
  --seccomp_unconfined            Use the unconfined seccomp profile.
  --screen_resolution(=string)    Set to the desired screen resolution in the format: 1024x768.
                                  Or if you'd like it to be detected enter: detect. Default: detect
  --screen_resolution_t(=string)  Set to the desired screen resolution for the second monitor in 
                                  the format: 1024x768. Or if you'd like it to be detected enter: 
                                  detect. Default: detect
  --window_manager(=string)       Set the window manager to use. See available window managers 
                                  below. Default: mate
  --user(=string)                 Run using the specified host user.
  --group(=string)                Run using the specified group user.
  --container_user(=string)       Run using the specified container user.
  --dont_mount_home_dir           Do not mount the user's home directory.
  --mount(=string)                Create a new directory to mount to the container.
  --network(=string)              Use a network, uses --network see docker documentation for details.
  --cap_add(=string)              Add a privilege, uses --cap-add see docker documentation for details.
  --port(=string)                 Expose a port, uses -p see docker documentation for details.
  --container_port(=string)       Set the port to use inside the container.
  --add_host(=string)             Add a host, uses --add-host see docker documentation for details.
  --dns(=string)                  Add DNS servers.
  --shared_memory_size(=string)   Set the shared memory size. Default: 16G
  --max_ulimit                    Set ulimit to the max.
  --viewer(=string)               Set the viewer to use. Can be: none,vnc,xpra,x11_forwarding,weston
                                  WARNING, IF x11_forwarding OR weston IS USED THIS SEVERELY LESSENS
                                  the benefits of containerization and can increase the vulnerability
                                  of the host system! Use with caution! The weston option will use 
                                  Xwayland and use the host's running X11 server.
  --daemon                        Run as a daemon.
  --custom_mount(=string)         Set a custom mount. If you specify \"/home/user/shared:/mnt/shared\",
                                  it will be mounted by docker like: -v \"/home/user/shared:/mnt/shared\"
  --docktop_home(=string)         Set the location for the Docktop home. This is where all container
                                  data will be placed. Default: $HOME/.docktop/

Types:
  all                             Run all docker images.
  base                            Run the base docker images.
  developer                       Run the developer docker image.
  steam                           Run the steam docker image.
  custom                          Run a custom image using this command, use 
                                  window_manager to specify the image name and 
                                  value1 to set the container name of the image.

Window Manager:
  gnome                           Run only gnome type docker images.
  mate                            Run only mate type docker images.
  xfce                            Run only xfce type docker images.
"

  exit 1
}

# Check if the user is root.
checkIfRoot() {
  local errorMsg=${1:-"This must be ran as root."}

  if [ $EUID -ne 0 ]; then
    echo "$errorMsg"

    exit 1
  fi
}

TYPE="all"
USE_DISPLAY=":1"
SCREEN_RESOLUTION="detect"
SCREEN_RESOLUTION2=""
WINDOW_MANAGER="mate"
IMAGE=""
NAME=""
VIEW_ONLY=""
DISPLAY_NAME=""
MOUNT_VOLUMES=""
USE_PRIVILEGED=""
USE_SECCOMP_UNCONFINED_PROFILE=""
ECHO_CMD=""
USE_AUDIO="1"
NO_GPU=""
USE_VGL=""
ENTRYPOINT=""
DOCKTOP_HOME="$HOME/.docktop/"
USE_NETWORK=""
SHARED_MEMORY_SIZE="16G"
MAX_ULIMIT=""
RUN_AS_DAEMON=""
USE_INTERNAL_PORT="5901"
RUN_USER="$(id -un)"
RUN_GROUP="$(id -gn)"
CONTAINER_USER="$(id -un)"
MOUNT_HOME_DIR="1"
USE_VIEWER="vnc"

VOLUMES_TO_MOUNT=()
CUSTOM_MOUNTS=()
ATTACH_USBS=()
EXPOSE_PORTS=()
ADD_HOSTS=()
ADD_DNS=()
ADD_ENVS=()
ADD_CAPS=()

while :; do
  case $1 in
    -h|-\?|--help)
      help

      exit 0
      ;;
    --display=?*)
      USE_DISPLAY="${1#*=}"
      ;;
    --env=?*)
      ADD_ENVS+=("${1#*=}")
      ;;
    --cap_add=?*)
      ADD_CAPS+=("${1#*=}")
      ;;
    --screen_resolution=?*)
      SCREEN_RESOLUTION="${1#*=}"
      ;;
    --screen_resolution_t=?*)
      SCREEN_RESOLUTION2="${1#*=}"
      ;;
    --window_manager=?*)
      WINDOW_MANAGER="${1#*=}"
      ;;
    --image=?*)
      IMAGE="${1#*=}"
      ;;
    --user=?*)
      RUN_USER="${1#*=}"
      ;;
    --dont_mount_home_dir)
      MOUNT_HOME_DIR=""
      ;;
    --container_user=?*)
      CONTAINER_USER="${1#*=}"
      ;;
    --group=?*)
      RUN_GROUP="${1#*=}"
      ;;
    --name=?*)
      NAME="${1#*=}"
      ;;
    --view_only)
      VIEW_ONLY="1"
      ;;
    --display_name=?*)
      DISPLAY_NAME="${1#*=}"
      ;;
    --type=?*)
      TYPE="${1#*=}"
      ;;
    --mount=?*)
      VOLUMES_TO_MOUNT+=("${1#*=}")
      ;;
    --privileged)
      USE_PRIVILEGED="1"
      ;;
    --seccomp_unconfined)
      USE_SECCOMP_UNCONFINED_PROFILE="1"
      ;;
    --echo_cmd)
      ECHO_CMD="echo "
      ;;
    --no_audio)
      USE_AUDIO=""
      ;;
    --no_gpu)
      NO_GPU="1"
      ;;
    --use_vgl)
      USE_VGL="1"
      ;;
    --custom_mount=?*)
      CUSTOM_MOUNTS+=("${1#*=}")
      ;;
    --docktop_home=?*)
      DOCKTOP_HOME="${1#*=}"
      ;;
    --device=?*)
      ATTACH_USBS+=("${1#*=}")
      ;;
    --port=?*)
      EXPOSE_PORTS+=("${1#*=}")
      ;;
    --container_port=?*)
      USE_INTERNAL_PORT="${1#*=}"
      ;;
    --add_host=?*)
      ADD_HOSTS+=("${1#*=}")
      ;;
    --dns=?*)
      ADD_DNS+=("${1#*=}")
      ;;
    --network=?*)
      USE_NETWORK="${1#*=}"
      ;;
    --shared_memory_size=?*)
      SHARED_MEMORY_SIZE="${1#*=}"
      ;;
    --max_ulimit)
      MAX_ULIMIT="1"
      ;;
    --viewer=?*)
      USE_VIEWER="${1#*=}"
      ;;
    --daemon)
      RUN_AS_DAEMON="1"
      ;;
    --entrypoint=?*)
      NEW_ENTRYPOINT="${1#*=}"

      if [ "$NEW_ENTRYPOINT" == "empty" ]; then
        NEW_ENTRYPOINT="\"\""
      fi

      ENTRYPOINT="--entrypoint=$NEW_ENTRYPOINT"
      ;;
    --list_usb_devices)
      ./list_usb.sh
      exit 1
      ;;
    *)
      break
  esac

  shift
done

if [ "$DISPLAY_NAME" == "" ]; then
  if [ "$NAME" != "" ]; then
    DISPLAY_NAME="$NAME"
  fi
fi

if [ "$USE_VIEWER" == "x11_forwarding" ]; then
  checkIfRoot "Running with X11 forwarding requires root privileges."
fi

if [ "$SCREEN_RESOLUTION" == "detect" ]; then
  if [ "$(uname -a | grep Darwin)" ]; then
    SCREEN_RESOLUTION=$(system_profiler SPDisplaysDataType | awk '/Resolution/{print $2, $3, $4}' | sed 's/ //g')
  else
    SCREEN_WIDTH=$(xrandr --current | grep '*' -m 1 | uniq | awk '{print $1}' | cut -d 'x' -f1)
    SCREEN_HEIGHT=$(xrandr --current | grep '*' -m 1 | uniq | awk '{print $1}' | cut -d 'x' -f2)
    SCREEN_RESOLUTION="$SCREEN_WIDTH"x"$SCREEN_HEIGHT"
  fi
fi

if [ "$SCREEN_RESOLUTION2" == "detect" ]; then
  if [ "$(uname -a | grep Darwin)" ]; then
    echo "Not supported yet..."

    exit;
  else
    SCREEN_WIDTH2=$(xrandr --current | grep '*' -m 2 | uniq | awk '{getline; print}' | awk '{print $1}' | cut -d 'x' -f1)
    SCREEN_HEIGHT2=$(xrandr --current | grep '*' -m 2 | uniq | awk '{getline; print}' | awk '{print $1}' | cut -d 'x' -f2)
    SCREEN_RESOLUTION2="$SCREEN_WIDTH2"x"$SCREEN_HEIGHT2"
    echo "Not supported yet..."

    exit;
  fi
fi